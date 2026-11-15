#!/usr/bin/env python3
"""Version nuit d'une illustration papier à fond crème (mode nuit des apps).

Le fond crème devient bleu nuit, les bleus sont éclaircis pour rester lisibles, l'or ne
bouge pas, le papier blanc (pages, paquet, étoiles) reste clair. Réglé à la main pour les
deux illustrations concernées :

    python3 scripts/night_illustration.py <source.jpg> <sortie.jpg> hero     # progress_hero
    python3 scripts/night_illustration.py <source.jpg> <sortie.jpg> invite   # invite_poster

Dépendances : pillow, numpy, scipy.
"""
import sys
import numpy as np
from PIL import Image
from scipy import ndimage as ndi

DARK = np.array([27, 36, 52]) / 255.0       # fond nuit du panneau
PAPER = np.array([238, 233, 222]) / 255.0   # papier clair conservé

def smooth(x, lo, hi):
    t = np.clip((x - lo) / (hi - lo), 0, 1)
    return t * t * (3 - 2 * t)

def rgb2hsv(a):
    mx = a.max(2); mn = a.min(2); d = mx - mn
    s = np.where(mx > 0, d / np.maximum(mx, 1e-6), 0)
    h = np.zeros_like(mx)
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    m = d > 1e-6
    hr = ((g - b) / np.maximum(d, 1e-6)) % 6
    hg = (b - r) / np.maximum(d, 1e-6) + 2
    hb = (r - g) / np.maximum(d, 1e-6) + 4
    h = np.where(mx == r, hr, np.where(mx == g, hg, hb)) * 60
    h = np.where(m, h % 360, 0)
    return h, s, mx

def hsv2rgb(h, s, v):
    h = (h % 360) / 60.0
    i = np.floor(h).astype(int) % 6
    f = h - np.floor(h)
    p = v * (1 - s); q = v * (1 - f * s); t = v * (1 - (1 - f) * s)
    out = np.zeros(h.shape + (3,))
    for k, (r, g, b) in enumerate([(v, t, p), (q, v, p), (p, v, t), (p, q, v), (t, p, v), (v, p, q)]):
        m = i == k
        out[m] = np.stack([r, g, b], -1)[m]
    return out

def blur(x, r):
    return ndi.gaussian_filter(x, r)

def convert(src, dst, kind):
    a = np.asarray(Image.open(src).convert('RGB')).astype(float) / 255.0
    H, W, _ = a.shape
    h, s, v = rgb2hsv(a)
    # Couleur du papier de fond, estimée sur les pixels neutres clairs.
    neutral = (s < 0.09) & (v > 0.85)
    paper = np.median(a[neutral], axis=0)
    warm = (h >= 20) & (h <= 70)
    cool = (h >= 185) & (h <= 255)
    a_gold = np.where(warm, np.clip((s - 0.10) / 0.60, 0, 1), 0)
    a_blue = np.where(cool, np.clip((s - 0.08) / 0.55, 0, 1), 0)
    alpha = np.maximum(a_gold, a_blue)
    al = np.maximum(alpha, 1e-3)[..., None]
    ink = np.clip((a - (1 - al) * paper) / al, 0, 1)
    ih, is_, iv = rgb2hsv(ink)
    blue_ink = (ih >= 185) & (ih <= 255) & (a_blue >= a_gold)
    iv2 = np.where(blue_ink, 0.40 + 0.52 * iv, iv)
    is2 = np.where(blue_ink, is_ * 0.82, is_)
    ink2 = hsv2rgb(ih, is2, iv2)

    lum = a.mean(2)
    light = (s < 0.12) & (v > 0.78) & (alpha < 0.3)
    # Les clairs enfermés dans une forme (pages, traits blancs des manteaux) sont du papier ;
    # ceux qui rejoignent le bord de l'image sont le fond.
    lab, n = ndi.label(light)
    border = np.unique(np.concatenate([lab[0], lab[-1], lab[:, 0], lab[:, -1]]))
    sizes = ndi.sum(light, lab, index=np.arange(n + 1))
    big = sizes[lab]
    loose = (alpha < 0.45) & (v > 0.6) & (s < 0.25)
    llab, ln = ndi.label(loose)
    lborder = np.unique(np.concatenate([llab[0], llab[-1], llab[:, 0], llab[:, -1]]))
    lsz = ndi.sum(loose, llab, index=np.arange(ln + 1))
    enclosed = loose & ~np.isin(llab, lborder)
    big = lsz[llab]
    if kind == 'hero':
        # Les pages sont plus blanches que le fond ; le halo de l'étoile aussi, mais il est
        # au-dessus de la pile : le seuil ne s'applique qu'à la pile.
        pb = smooth(blur(np.where(alpha < 0.3, a[..., 2], 0.0), 2.0), 0.905, 0.935)
        pb = ndi.grey_closing(pb, size=(9, 9))
        yy = np.arange(H)[:, None] / H
        pb = pb * smooth(yy, 0.345, 0.36)
        p = blur(pb, 0.7)
        glow = smooth(blur(np.where(light, a[..., 2], paper[2]), 22), paper[2] + 0.008, paper[2] + 0.05) * 0.10
        p = np.maximum(p, glow * (1 - smooth(yy, 0.33, 0.37)))
    else:
        white = blur((a.min(2) >= 251 / 255).astype(float), 1.6)
        p = smooth(white, 0.22, 0.5)
        box = np.zeros((H, W))
        x0, x1, y0, y1 = [int(round(c)) for c in (456 * W / 1200, 764 * W / 1200, 122 * H / 900, 350 * H / 900)]
        box[y0:y1, x0:x1] = 1
        p = np.maximum(p, blur(box, 1.5))
        p = np.maximum(p, blur((enclosed & (big < 0.03 * H * W)).astype(float), 0.8))
        # Traits blancs des manteaux qui débouchent sur le fond : clairs au milieu du bleu.
        inside = blur((alpha > 0.5).astype(float), 10) > 0.6
        p = np.maximum(p, blur((loose & inside).astype(float), 0.8))
    p = np.clip(p, 0, 1)

    # Couverture rose pâle du livre du haut : une teinte claire à part, gardée telle quelle.
    pink = warm & (s > 0.13) & (s < 0.32) & (v > 0.8)
    plab, pn = ndi.label(pink)
    psz = ndi.sum(pink, plab, index=np.arange(pn + 1))
    pink = blur((pink & (psz[plab] > 1500)).astype(float), 1.0)

    # Le grain du papier, mesuré entre pixels neutres seulement (sinon les contours bavent).
    m = light.astype(float)
    local = blur(lum * m, 3) / np.maximum(blur(m, 3), 1e-3)
    grain = ((lum - local) * m)[..., None]
    p3 = p[..., None]
    n_col = DARK * (1 - p3) + PAPER * p3 + grain * (0.5 + 0.5 * p3)
    out = (1 - alpha[..., None]) * n_col + alpha[..., None] * ink2
    out = out * (1 - pink[..., None]) + (a * 0.93) * pink[..., None]
    Image.fromarray((np.clip(out, 0, 1) * 255).round().astype('uint8')).save(dst, quality=90, optimize=True)

convert(sys.argv[1], sys.argv[2], sys.argv[3])

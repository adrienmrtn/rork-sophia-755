#!/usr/bin/env python3
"""Render narration MP3s with the ElevenLabs API.

The key is never passed on the command line and never printed: it is read from
ELEVENLABS_API_KEY, or from a file outside the repository.

    echo -n 'sk_...' > ~/.elevenlabs_key && chmod 600 ~/.elevenlabs_key

    python3 scripts/tts/render_elevenlabs.py --list-voices
    python3 scripts/tts/render_elevenlabs.py --sample 2 --dry-run
    python3 scripts/tts/render_elevenlabs.py --sample 2 --voice <voice_id>

Billing is per character and SSML break tags count, so --dry-run reports the
exact characters a run would spend before anything is sent.
"""

from __future__ import annotations

import argparse
import concurrent.futures as cf
import json
import os
import random
import socket
import sys
import threading
import time
import urllib.error
import urllib.request
from pathlib import Path

API = 'https://api.elevenlabs.io/v1'
LANGS = ('fr', 'en', 'es', 'tr', 'de')
TEXT_ROOT = Path.home() / 'Desktop' / 'sophia_tts'
OUT_ROOT = Path.home() / 'Desktop' / 'sophia_audio' / 'mp3'
KEY_FILE = Path.home() / '.elevenlabs_key'
# Multilingual v2 costs one credit per character and is the quality tier;
# flash costs half but is meant for latency, not for 87 hours of narration.
MODEL = 'eleven_multilingual_v2'


def read_key(path: Path) -> str:
    key = os.environ.get('ELEVENLABS_API_KEY', '').strip()
    if key:
        return key
    if path.exists():
        key = path.read_text(encoding='utf-8').strip()
        if key:
            return key
    sys.exit(
        f'No API key. Put it in {path} (and chmod 600 it), or export\n'
        'ELEVENLABS_API_KEY. Do not paste it into a shell command: it would\n'
        'land in your shell history.'
    )


def call(method: str, path: str, key: str, body: dict | None = None,
         attempts: int = 8) -> tuple[int, bytes]:
    """A dropped connection must not end a run of a thousand files. Network
    faults and the server's own 5xx are retried with a widening wait; a 4xx is
    the request's own fault and comes straight back."""
    data = json.dumps(body).encode() if body is not None else None
    for i in range(attempts):
        req = urllib.request.Request(f'{API}{path}', data=data, method=method)
        req.add_header('xi-api-key', key)
        if data:
            req.add_header('Content-Type', 'application/json')
        try:
            with urllib.request.urlopen(req, timeout=600) as r:
                return r.status, r.read()
        except urllib.error.HTTPError as e:
            # The response body can echo the request; never let it reach stdout raw.
            raw = e.read()[:400]
            if e.code in (429, 500, 502, 503, 504) and i + 1 < attempts:
                time.sleep(min(300, 10 * 2 ** i))
                continue
            return e.code, raw
        except (urllib.error.URLError, socket.timeout, OSError) as e:
            if i + 1 < attempts:
                # Waits out a sleeping laptop or a dropped Wi-Fi: 10 s, 20, 40,
                # 80, 160, then 300 — about fifteen minutes in all.
                time.sleep(min(300, 10 * 2 ** i))
                continue
            return 0, f'reseau: {e}'.encode()
    return 0, 'reseau: abandon'.encode()


def list_voices(key: str) -> int:
    status, raw = call('GET', '/voices', key)
    if status != 200:
        print(f'HTTP {status}: {raw.decode("utf-8", "replace")}')
        return 1
    for v in json.loads(raw).get('voices', []):
        labels = v.get('labels') or {}
        traits = ', '.join(f'{k}={x}' for k, x in labels.items() if k != 'featured')
        print(f"  {v['voice_id']}  {v['name']:22s} {traits}")
    return 0


def pick(sample: int, seed: int, only: list[str] | None,
         langs: tuple[str, ...] = LANGS) -> dict[str, list[Path]]:
    chosen = {}
    for lang in langs:
        files = sorted((TEXT_ROOT / lang).glob('course_*.txt'))
        if not files:
            sys.exit(f'No text for {lang} in {TEXT_ROOT / lang}')
        if only:
            files = [f for f in files if f.stem in only]
        else:
            # Seeded so a re-run renders the same courses instead of quietly
            # spending credits on a different sample.
            files = random.Random(seed).sample(files, min(sample, len(files)))
        chosen[lang] = files
    return chosen


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument('--sample', type=int, default=2, help='courses per language')
    ap.add_argument('--langs', nargs='*', default=list(LANGS),
                    help='restrict to these languages')
    ap.add_argument('--seed', type=int, default=7)
    ap.add_argument('--courses', nargs='*', help='explicit course ids instead of a sample')
    ap.add_argument('--voice', help='one voice id for every language')
    ap.add_argument('--voices', nargs='*', default=[],
                    help='per-language voices: fr=<id> de=<id> …  (overrides --voice)')
    ap.add_argument('--model', default=MODEL)
    ap.add_argument('--out', default=str(OUT_ROOT))
    ap.add_argument('--key-file', default=str(KEY_FILE))
    ap.add_argument('--list-voices', action='store_true')
    ap.add_argument('--dry-run', action='store_true', help='count characters, send nothing')
    ap.add_argument('--all', action='store_true', help='every course, not a sample')
    ap.add_argument('--jobs', type=int, default=3, help='concurrent requests')
    ap.add_argument('--redo', action='store_true', help='re-render files already on disk')
    args = ap.parse_args()

    if args.list_voices:
        return list_voices(read_key(Path(args.key_file)))

    langs = tuple(l for l in LANGS if l in args.langs)
    sample = 10 ** 6 if args.all else args.sample
    chosen = pick(sample, args.seed, args.courses, langs)
    # Never pay twice for a file already on disk: a run stopped by the monthly
    # quota picks up exactly where it left off.
    out_root = Path(os.path.expanduser(args.out))
    if not args.redo:
        chosen = {l: [f for f in fs if not (out_root / l / f'{f.stem}_{l}.mp3').exists()]
                  for l, fs in chosen.items()}
    total = sum(len(f.read_text(encoding='utf-8')) for fs in chosen.values() for f in fs)
    n = sum(len(fs) for fs in chosen.values())

    for lang in langs:
        for f in chosen[lang]:
            print(f'  [{lang}] {f.stem[:56]:58s} {len(f.read_text(encoding="utf-8")):7,d} car.')
    print(f'\n  {n} fichiers · {total:,} caractères · '
          f'{total:,} crédits en {args.model}')

    if args.dry_run:
        print('  --dry-run : rien envoyé')
        return 0
    voices = dict(v.split('=', 1) for v in args.voices)
    missing = [l for l in langs if not voices.get(l, args.voice)]
    if missing:
        sys.exit(f'No voice for {", ".join(missing)}. Use --list-voices, then '
                 '--voice <id> or --voices fr=<id> de=<id> …')

    key = read_key(Path(args.key_file))
    stop = threading.Event()
    lock = threading.Lock()
    tally = {'spent': 0, 'done': 0, 'failed': 0}

    def render(lang, f):
        if stop.is_set():
            return
        text = f.read_text(encoding='utf-8')
        voice = voices.get(lang, args.voice)
        status, raw = call(
            'POST', f'/text-to-speech/{voice}?output_format=mp3_44100_128', key,
            {'text': text, 'model_id': args.model,
             'voice_settings': {'stability': 0.5, 'similarity_boost': 0.75}},
        )
        body = raw.decode('utf-8', 'replace')[:200] if status != 200 else ''
        with lock:
            if status == 200:
                (out_root / lang / f'{f.stem}_{lang}.mp3').write_bytes(raw)
                tally['spent'] += len(text)
                tally['done'] += 1
                print(f"  [{lang}] {tally['done']:4d}/{total}  {f.stem[:54]:56s} "
                      f"{len(raw)/1e6:4.1f} Mo", flush=True)
            else:
                tally['failed'] += 1
                print(f'  [{lang}] {f.stem[:54]}: HTTP {status} {body}', flush=True)
                # The monthly quota is a wall, not a hiccup: stop instead of
                # hammering the API with calls that cannot succeed.
                if status in (401, 429) and ('quota' in body.lower()
                                             or 'limit' in body.lower()):
                    print('\n  quota atteint — arrêt propre, les fichiers déjà '
                          'rendus sont conservés', flush=True)
                    stop.set()

    for lang in langs:
        (out_root / lang).mkdir(parents=True, exist_ok=True)
    # One pool over every language at once: waiting for a language to finish
    # before starting the next drains the pool at each boundary, and the last
    # few files of a language leave most of the workers idle.
    travail = [(lang, f) for lang in langs for f in chosen[lang]]
    total = len(travail)
    with cf.ThreadPoolExecutor(max_workers=args.jobs) as pool:
        list(pool.map(lambda t: render(*t), travail))
    print(f"\n  {tally['done']} fichiers · {tally['spent']:,} caractères facturés"
          + (f" · {tally['failed']} échec(s)" if tally['failed'] else ''))
    return 1 if tally['failed'] else 0


if __name__ == '__main__':
    sys.exit(main())

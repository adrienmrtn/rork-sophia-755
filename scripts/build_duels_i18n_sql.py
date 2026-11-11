#!/usr/bin/env python3
"""Écrit le SQL qui ouvre les duels à toutes les langues.

    python3 scripts/build_duels_i18n_sql.py [--partial --out FICHIER]

Lit content/duels/i18n/<lang>.json (traductions, voir scripts/duels_i18n.py) et
content/duels/i18n/_excluded.json, et écrit :

  supabase/migrations/20261113010000_duels_i18n.sql   schéma, fonctions, questions retirées,
                                                       noms des ligues, toutes les traductions

Le fichier se rejoue sans risque (IF NOT EXISTS, CREATE OR REPLACE, ON CONFLICT DO UPDATE).

Principe : une question garde son identifiant, son type, sa bonne réponse (même rang
d'option), ses bornes et sa valeur dans toutes les langues ; seul le texte change. Le
serveur tire les questions comme avant (dans le vivier anglais, qui sert de référence) et
`duel_question_json` rend chaque question dans la langue du joueur qui appelle
(`duel_profiles.lang`, posée par l'app avec `duel_set_language`, et par `duel_ping`).
Deux joueurs de langues différentes jouent donc la même partie, chacun dans sa langue.
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "scripts"))
from duels_i18n import LANGS, LEAGUE_SLUGS, check, excluded_ids, to_translate  # noqa: E402

I18N = ROOT / "content" / "duels" / "i18n"
OUT = ROOT / "supabase" / "migrations" / "20261113010000_duels_i18n.sql"

SUPPORTED = ["en", *LANGS]


def sql_str(s: str) -> str:
    return "'" + s.replace("'", "''") + "'"


def dollar(payload: str, tag: str = "j") -> str:
    while f"${tag}$" in payload:
        tag += "x"
    return f"${tag}${payload}${tag}$"


SCHEMA = r"""
-- Duels dans toutes les langues de l'app.
--
-- Une question garde son identifiant, son type, sa bonne réponse (même rang d'option), ses
-- bornes et sa valeur dans toutes les langues ; seul le texte change. Le tirage ne bouge pas
-- (vivier anglais, la référence) ; duel_question_json rend chaque question dans la langue de
-- celui qui appelle. Deux joueurs de langues différentes jouent la même partie, chacun dans sa
-- langue. Les questions intraduisibles sont retirées pour tout le monde (active = false).
--
-- Généré par scripts/build_duels_i18n_sql.py — ne pas modifier à la main.
-- Rejouable sans risque.

BEGIN;

-- ------------------------------------------------------------------ schéma
ALTER TABLE public.duel_profiles ADD COLUMN IF NOT EXISTS lang text NOT NULL DEFAULT 'en';
ALTER TABLE public.duel_leagues ADD COLUMN IF NOT EXISTS names jsonb NOT NULL DEFAULT '{}'::jsonb;

CREATE TABLE IF NOT EXISTS public.duel_question_translations (
  question_id text NOT NULL REFERENCES public.duel_questions(id) ON DELETE CASCADE,
  lang text NOT NULL,
  question text NOT NULL,
  options jsonb,
  unit text,
  updated_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (question_id, lang)
);
ALTER TABLE public.duel_question_translations ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE public.duel_question_translations FROM anon, authenticated;

-- ------------------------------------------------------------------ langue du joueur
-- Les langues dont les questions existent ; toute autre valeur retombe sur l'anglais.
CREATE OR REPLACE FUNCTION public.duel_supported_lang(p_lang text)
RETURNS text
LANGUAGE sql
IMMUTABLE
SET search_path TO 'public'
AS $$
  SELECT CASE WHEN p_lang = ANY (ARRAY[__SUPPORTED__]) THEN p_lang ELSE 'en' END;
$$;
REVOKE ALL ON FUNCTION public.duel_supported_lang(text) FROM PUBLIC, anon, authenticated;

-- La langue de celui qui appelle (anglais pour une app d'avant, qui ne la donne pas).
CREATE OR REPLACE FUNCTION public.duel_viewer_lang()
RETURNS text
LANGUAGE sql
STABLE
SET search_path TO 'public'
AS $$
  SELECT coalesce((SELECT dp.lang FROM public.duel_profiles dp WHERE dp.user_id = auth.uid()), 'en');
$$;
REVOKE ALL ON FUNCTION public.duel_viewer_lang() FROM PUBLIC, anon, authenticated;

-- Appelée par l'app avant la page des duels : la langue dans laquelle le joueur reçoit les
-- questions et les noms des ligues.
CREATE OR REPLACE FUNCTION public.duel_set_language(p_lang text)
RETURNS text
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  uid uuid := auth.uid();
  wanted text := public.duel_supported_lang(p_lang);
BEGIN
  IF uid IS NULL THEN
    RAISE EXCEPTION 'not_authenticated';
  END IF;
  PERFORM public.duel_ensure_profile(uid);
  UPDATE public.duel_profiles SET lang = wanted WHERE user_id = uid AND lang IS DISTINCT FROM wanted;
  RETURN wanted;
END;
$$;
REVOKE ALL ON FUNCTION public.duel_set_language(text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.duel_set_language(text) TO authenticated;

-- ------------------------------------------------------------------ questions dans la langue du joueur
-- Toutes les fonctions qui envoient des questions (duel classé, manches, question décisive,
-- duel entre amis) passent par celle-ci. Sans traduction, le texte anglais.
CREATE OR REPLACE FUNCTION public.duel_question_json(q public.duel_questions)
RETURNS jsonb
LANGUAGE sql
STABLE
SET search_path TO 'public'
AS $$
  SELECT jsonb_build_object(
    'id', q.id,
    'kind', q.kind,
    'question', coalesce(t.question, q.question),
    'options', coalesce(t.options, q.options),
    'correct_index', q.correct_index,
    'image_url', q.image_url,
    'image_credit', q.image_credit,
    'slider_min', q.slider_min,
    'slider_max', q.slider_max,
    'slider_step', q.slider_step,
    'correct_value', q.correct_value,
    'unit', coalesce(t.unit, q.unit),
    'time_limit_ms', public.duel_time_limit_ms(q.kind)
  )
  FROM (SELECT public.duel_viewer_lang() AS lang) v
  LEFT JOIN public.duel_question_translations t ON t.question_id = q.id AND t.lang = v.lang;
$$;
REVOKE ALL ON FUNCTION public.duel_question_json(public.duel_questions) FROM PUBLIC, anon, authenticated;

-- ------------------------------------------------------------------ page des duels : noms des ligues
CREATE OR REPLACE FUNCTION public.duel_home()
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  uid uuid := auth.uid();
  prof public.duel_profiles;
  leagues jsonb;
  recent jsonb;
  my_handle text;
BEGIN
  IF uid IS NULL THEN
    RAISE EXCEPTION 'not_authenticated';
  END IF;

  PERFORM public.duel_ensure_profile(uid);
  PERFORM public.duel_resolve_stale(uid, interval '12 minutes');
  SELECT * INTO prof FROM public.duel_profiles WHERE user_id = uid;
  SELECT p.handle INTO my_handle FROM public.profiles p WHERE p.id = uid;

  SELECT coalesce(jsonb_agg(jsonb_build_object(
      'position', l.position,
      'slug', l.slug,
      -- Le nom de la figure dans la langue du joueur (Jeanne d'Arc, ジャンヌ・ダルク…).
      'name', coalesce(l.names ->> prof.lang, l.name),
      'min_trophies', l.min_trophies,
      'background_url', l.background_url,
      'thumb_url', l.thumb_url,
      'accent_hex', l.accent_hex
    ) ORDER BY l.position), '[]'::jsonb)
    INTO leagues
    FROM public.duel_leagues l;

  SELECT coalesce(jsonb_agg(r.item ORDER BY r.finished_at DESC), '[]'::jsonb)
    INTO recent
    FROM (
      SELECT m.finished_at, jsonb_build_object(
        'match_id', m.id,
        'opponent', m.opponent,
        'won', m.status = 'won',
        'abandoned', m.status = 'abandoned',
        'player_score', coalesce(m.player_score, 0),
        'opponent_score', coalesce(m.opponent_score, 0),
        'trophies_delta', coalesce(m.trophies_delta, 0),
        'finished_at', m.finished_at
      ) AS item
      FROM public.duel_matches m
      WHERE m.user_id = uid AND m.status <> 'active'
      ORDER BY m.finished_at DESC
      LIMIT 10
    ) r;

  RETURN jsonb_build_object(
    'handle', my_handle,
    'profile', public.duel_profile_json(prof),
    'leagues', leagues,
    'recent', recent
  );
END;
$$;
REVOKE ALL ON FUNCTION public.duel_home() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.duel_home() TO authenticated;

-- ------------------------------------------------------------------ duels entre amis
-- Signal de présence : il porte aussi la langue de l'app, qui devient celle des questions.
CREATE OR REPLACE FUNCTION public.duel_ping(p_lang text DEFAULT 'en', p_busy boolean DEFAULT false)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  uid uuid := auth.uid();
  inv public.duel_invites;
  wanted text := public.duel_supported_lang(coalesce(p_lang, 'en'));
BEGIN
  IF uid IS NULL THEN
    RAISE EXCEPTION 'not_authenticated';
  END IF;

  -- Une écriture toutes les 8 secondes suffit à tenir la pastille verte.
  INSERT INTO public.duel_presence (user_id, last_seen_at, lang, busy)
  VALUES (uid, now(), wanted, coalesce(p_busy, false))
  ON CONFLICT (user_id) DO UPDATE SET
    last_seen_at = EXCLUDED.last_seen_at,
    lang = EXCLUDED.lang,
    busy = EXCLUDED.busy
  WHERE duel_presence.last_seen_at < now() - interval '8 seconds'
     OR duel_presence.lang IS DISTINCT FROM EXCLUDED.lang
     OR duel_presence.busy IS DISTINCT FROM EXCLUDED.busy;

  -- Ne réécrit le profil que si la langue a changé (le signal part toutes les 4 secondes).
  UPDATE public.duel_profiles SET lang = wanted WHERE user_id = uid AND lang IS DISTINCT FROM wanted;

  SELECT * INTO inv
    FROM public.duel_invites i
    WHERE i.invitee_id = uid AND i.status = 'pending' AND i.expires_at > now()
    ORDER BY i.created_at
    LIMIT 1
    FOR UPDATE SKIP LOCKED;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('invite', NULL);
  END IF;

  IF coalesce(p_busy, false) THEN
    UPDATE public.duel_invites SET status = 'busy' WHERE id = inv.id;
    RETURN jsonb_build_object('invite', NULL);
  END IF;

  RETURN jsonb_build_object('invite', jsonb_build_object(
    'invite_id', inv.id,
    'from', public.duel_player_card(inv.inviter_id),
    'expires_in_ms', round(extract(epoch FROM (inv.expires_at - clock_timestamp())) * 1000)::bigint
  ));
END;
$$;
REVOKE ALL ON FUNCTION public.duel_ping(text, boolean) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.duel_ping(text, boolean) TO authenticated;

-- Tout ami dont l'app a les duels (elle a déjà envoyé un signal de présence), quelle que soit
-- sa langue : un Japonais peut défier un Hongrois.
CREATE OR REPLACE FUNCTION public.duel_can_challenge(p_uid uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SET search_path TO 'public'
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.duel_presence pr
    WHERE pr.user_id = p_uid AND pr.lang = ANY (ARRAY[__SUPPORTED__])
  );
$$;
REVOKE ALL ON FUNCTION public.duel_can_challenge(uuid) FROM PUBLIC, anon, authenticated;
"""


def build(partial: bool = False) -> str:
    qs = to_translate()
    by_id = {q["id"]: q for q in qs}
    parts = [SCHEMA.replace("__SUPPORTED__", ", ".join(sql_str(x) for x in SUPPORTED))]

    skip = sorted(excluded_ids())
    parts.append("-- ------------------------------------------------------------------ questions retirées\n"
                 "-- Leur réponse tient à un mot anglais (content/duels/i18n/_excluded.json) : retirées pour tous.\n"
                 f"UPDATE public.duel_questions SET active = false WHERE id IN ({', '.join(sql_str(x) for x in skip)});\n"
                 f"DELETE FROM public.duel_question_translations WHERE question_id IN ({', '.join(sql_str(x) for x in skip)});\n")

    league_names: dict[str, dict[str, str]] = {slug: {} for slug in LEAGUE_SLUGS}
    problems = []
    for lang in LANGS:
        path = I18N / f"{lang}.json"
        if not path.exists():
            if not partial:
                problems.append(f"{lang} : pas de traduction")
            continue
        data = json.loads(path.read_text(encoding="utf-8"))
        rejects, _ = check(lang, data, qs)
        missing = [qid for qid in by_id if qid not in data["items"]]
        if rejects or missing:
            problems.append(f"{lang} : {len(rejects)} rejet(s), {len(missing)} manquante(s)")
            continue
        for slug in LEAGUE_SLUGS:
            league_names[slug][lang] = data["leagues"][slug]
        tf = data["true_false"]
        rows = {}
        for qid, t in data["items"].items():
            q = by_id.get(qid)
            if q is None:
                continue
            row = {"q": t["q"].strip()}
            if q["kind"] in ("mcq", "portrait"):
                row["o"] = [o.strip() for o in t["o"]]
            elif q["kind"] == "true_false":
                row["o"] = tf
            if q["kind"] == "slider" and (t.get("u") or "").strip():
                row["u"] = t["u"].strip()
            rows[qid] = row
        # Une ligne par question (l'éditeur SQL de Supabase tronque les lignes très longues),
        # par paquets de 200 lignes.
        values = [
            "  (" + ", ".join([
                sql_str(qid), sql_str(lang), sql_str(row["q"]),
                (sql_str(json.dumps(row["o"], ensure_ascii=False)) + "::jsonb") if "o" in row else "NULL",
                sql_str(row["u"]) if "u" in row else "NULL",
            ]) + ")"
            for qid, row in rows.items()
        ]
        block = [f"-- {lang} : {len(rows)} questions\n"]
        for k in range(0, len(values), 200):
            block.append(
                "INSERT INTO public.duel_question_translations (question_id, lang, question, options, unit) VALUES\n"
                + ",\n".join(values[k:k + 200])
                + "\nON CONFLICT (question_id, lang) DO UPDATE SET question = EXCLUDED.question, options = EXCLUDED.options,\n"
                "  unit = EXCLUDED.unit, updated_at = now();\n")
        parts.append("".join(block))
    if problems:
        sys.exit("Traductions incomplètes, SQL non écrit :\n  " + "\n  ".join(problems))

    parts.insert(2, "-- ------------------------------------------------------------------ noms des ligues\n" + "".join(
        f"UPDATE public.duel_leagues SET names = {dollar(json.dumps(names, ensure_ascii=False, separators=(',', ':')))}::jsonb "
        f"WHERE slug = {sql_str(slug)};\n" for slug, names in league_names.items() if names))
    parts.append("COMMIT;\n")
    return "\n".join(parts)


def main() -> None:
    import argparse
    ap = argparse.ArgumentParser()
    ap.add_argument("--partial", action="store_true", help="tests : ignorer les langues absentes")
    ap.add_argument("--out", type=Path, default=OUT)
    a = ap.parse_args()
    sql = build(a.partial)
    a.out.write_text(sql, encoding="utf-8")
    print(f"{a.out} : {len(sql.encode()) / 1e6:.1f} Mo")


if __name__ == "__main__":
    main()

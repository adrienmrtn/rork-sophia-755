-- Duels dans toutes les langues — morceau 01 sur 30. Dans l'ordre, chacun en entier.
BEGIN;

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
  SELECT CASE WHEN p_lang = ANY (ARRAY['en', 'fr', 'es', 'de', 'pt', 'pt-PT', 'it', 'tr', 'pl', 'ro', 'nl', 'el', 'sv', 'hu', 'bg', 'cs', 'da', 'nb', 'ru', 'hr', 'sl', 'sk', 'sr', 'ar', 'he', 'fi', 'et', 'lt', 'lv', 'ja']) THEN p_lang ELSE 'en' END;
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
    WHERE pr.user_id = p_uid AND pr.lang = ANY (ARRAY['en', 'fr', 'es', 'de', 'pt', 'pt-PT', 'it', 'tr', 'pl', 'ro', 'nl', 'el', 'sv', 'hu', 'bg', 'cs', 'da', 'nb', 'ru', 'hr', 'sl', 'sk', 'sr', 'ar', 'he', 'fi', 'et', 'lt', 'lv', 'ja'])
  );
$$;
REVOKE ALL ON FUNCTION public.duel_can_challenge(uuid) FROM PUBLIC, anon, authenticated;

-- ------------------------------------------------------------------ questions retirées
-- Leur réponse tient à un mot anglais (content/duels/i18n/_excluded.json) : retirées pour tous.
UPDATE public.duel_questions SET active = false WHERE id IN ('dq_en_2_132', 'dq_en_3_134', 'dq_en_3_145', 'dq_en_4_135', 'dq_en_6_139', 'dq_en_6_40', 'dq_en_6_67', 'dq_en_8_105', 'dq_en_8_97');
DELETE FROM public.duel_question_translations WHERE question_id IN ('dq_en_2_132', 'dq_en_3_134', 'dq_en_3_145', 'dq_en_4_135', 'dq_en_6_139', 'dq_en_6_40', 'dq_en_6_67', 'dq_en_8_105', 'dq_en_8_97');

-- ------------------------------------------------------------------ noms des ligues
UPDATE public.duel_leagues SET names = $j${"fr":"Ésope","es":"Esopo","de":"Äsop","pt":"Esopo","pt-PT":"Esopo","it":"Esopo","tr":"Ezop","pl":"Ezop","ro":"Esop","nl":"Aesopus","el":"Αίσωπος","sv":"Aisopos","hu":"Aiszóposz","bg":"Езоп","cs":"Ezop","da":"Æsop","nb":"Esop","ru":"Эзоп","hr":"Ezop","sl":"Ezop","sk":"Ezop","sr":"Ezop","ar":"إيسوب","he":"איזופוס","fi":"Aisopos","et":"Aisopose","lt":"Ezopas","lv":"Ēzops","ja":"イソップ"}$j$::jsonb WHERE slug = 'aesop';
UPDATE public.duel_leagues SET names = $j${"fr":"Homère","es":"Homero","de":"Homer","pt":"Homero","pt-PT":"Homero","it":"Omero","tr":"Homeros","pl":"Homer","ro":"Homer","nl":"Homerus","el":"Όμηρος","sv":"Homeros","hu":"Homérosz","bg":"Омир","cs":"Homér","da":"Homer","nb":"Homer","ru":"Гомер","hr":"Homer","sl":"Homer","sk":"Homér","sr":"Homer","ar":"هوميروس","he":"הומרוס","fi":"Homeros","et":"Homerose","lt":"Homeras","lv":"Homērs","ja":"ホメロス"}$j$::jsonb WHERE slug = 'homer';
UPDATE public.duel_leagues SET names = $j${"fr":"Sappho","es":"Safo","de":"Sappho","pt":"Safo","pt-PT":"Safo","it":"Saffo","tr":"Sappho","pl":"Safona","ro":"Sappho","nl":"Sappho","el":"Σαπφώ","sv":"Sapfo","hu":"Szapphó","bg":"Сафо","cs":"Sapfó","da":"Sapfo","nb":"Sapfo","ru":"Сапфо","hr":"Sapfa","sl":"Sapfo","sk":"Sapfo","sr":"Sapfo","ar":"سافو","he":"סאפפו","fi":"Sapfo","et":"Sappho","lt":"Sapfo","lv":"Sapfo","ja":"サッフォー"}$j$::jsonb WHERE slug = 'sappho';
UPDATE public.duel_leagues SET names = $j${"fr":"Confucius","es":"Confucio","de":"Konfuzius","pt":"Confúcio","pt-PT":"Confúcio","it":"Confucio","tr":"Konfüçyüs","pl":"Konfucjusz","ro":"Confucius","nl":"Confucius","el":"Κομφούκιος","sv":"Konfucius","hu":"Konfuciusz","bg":"Конфуций","cs":"Konfucius","da":"Konfutse","nb":"Konfucius","ru":"Конфуций","hr":"Konfucije","sl":"Konfucij","sk":"Konfucius","sr":"Konfučije","ar":"كونفوشيوس","he":"קונפוציוס","fi":"Kungfutse","et":"Konfutsiuse","lt":"Konfucijus","lv":"Konfūcijs","ja":"孔子"}$j$::jsonb WHERE slug = 'confucius';
UPDATE public.duel_leagues SET names = $j${"fr":"Socrate","es":"Sócrates","de":"Sokrates","pt":"Sócrates","pt-PT":"Sócrates","it":"Socrate","tr":"Sokrates","pl":"Sokrates","ro":"Socrate","nl":"Socrates","el":"Σωκράτης","sv":"Sokrates","hu":"Szókratész","bg":"Сократ","cs":"Sókratés","da":"Sokrates","nb":"Sokrates","ru":"Сократ","hr":"Sokrat","sl":"Sokrat","sk":"Sokrates","sr":"Sokrat","ar":"سقراط","he":"סוקרטס","fi":"Sokrates","et":"Sokratese","lt":"Sokratas","lv":"Sokrats","ja":"ソクラテス"}$j$::jsonb WHERE slug = 'socrates';
UPDATE public.duel_leagues SET names = $j${"fr":"Cléopâtre","es":"Cleopatra","de":"Kleopatra","pt":"Cleópatra","pt-PT":"Cleópatra","it":"Cleopatra","tr":"Kleopatra","pl":"Kleopatra","ro":"Cleopatra","nl":"Cleopatra","el":"Κλεοπάτρα","sv":"Kleopatra","hu":"Kleopátra","bg":"Клеопатра","cs":"Kleopatra","da":"Kleopatra","nb":"Kleopatra","ru":"Клеопатра","hr":"Kleopatra","sl":"Kleopatra","sk":"Kleopatra","sr":"Kleopatra","ar":"كليوباترا","he":"קלאופטרה","fi":"Kleopatra","et":"Kleopatra","lt":"Kleopatra","lv":"Kleopatra","ja":"クレオパトラ"}$j$::jsonb WHERE slug = 'cleopatra';
UPDATE public.duel_leagues SET names = $j${"fr":"Hypatie","es":"Hipatia","de":"Hypatia","pt":"Hipátia","pt-PT":"Hipátia","it":"Ipazia","tr":"Hypatia","pl":"Hypatia","ro":"Hypatia","nl":"Hypatia","el":"Υπατία","sv":"Hypatia","hu":"Hüpatia","bg":"Хипатия","cs":"Hypatia","da":"Hypatia","nb":"Hypatia","ru":"Гипатия","hr":"Hipatija","sl":"Hipatija","sk":"Hypatia","sr":"Hipatija","ar":"هيباتيا","he":"היפאטיה","fi":"Hypatia","et":"Hypatia","lt":"Hipatija","lv":"Hipatija","ja":"ヒュパティア"}$j$::jsonb WHERE slug = 'hypatia';
UPDATE public.duel_leagues SET names = $j${"fr":"Avicenne","es":"Avicena","de":"Avicenna","pt":"Avicena","pt-PT":"Avicena","it":"Avicenna","tr":"İbn Sina","pl":"Awicenna","ro":"Avicenna","nl":"Avicenna","el":"Αβικέννας","sv":"Avicenna","hu":"Avicenna","bg":"Авицена","cs":"Avicenna","da":"Avicenna","nb":"Avicenna","ru":"Авиценна","hr":"Avicena","sl":"Avicena","sk":"Avicenna","sr":"Avicena","ar":"ابن سينا","he":"אבן סינא","fi":"Avicenna","et":"Avicenna","lt":"Avicena","lv":"Avicenna","ja":"イブン・シーナー"}$j$::jsonb WHERE slug = 'avicenna';
UPDATE public.duel_leagues SET names = $j${"fr":"Murasaki","es":"Murasaki","de":"Murasaki","pt":"Murasaki","pt-PT":"Murasaki","it":"Murasaki","tr":"Murasaki","pl":"Murasaki","ro":"Murasaki","nl":"Murasaki","el":"Μουρασάκι","sv":"Murasaki","hu":"Muraszaki","bg":"Мурасаки","cs":"Murasaki","da":"Murasaki","nb":"Murasaki","ru":"Мурасаки","hr":"Murasaki","sl":"Murasaki","sk":"Murasaki","sr":"Murasaki","ar":"موراساكي","he":"מורסאקי","fi":"Murasaki","et":"Murasaki","lt":"Murasaki","lv":"Murasaki","ja":"紫式部"}$j$::jsonb WHERE slug = 'murasaki';
UPDATE public.duel_leagues SET names = $j${"fr":"Mansa Moussa","es":"Mansa Musa","de":"Mansa Musa","pt":"Mansa Musa","pt-PT":"Mansa Musa","it":"Mansa Musa","tr":"Mansa Musa","pl":"Mansa Musa","ro":"Mansa Musa","nl":"Mansa Musa","el":"Μάνσα Μούσα","sv":"Mansa Musa","hu":"Mansza Musza","bg":"Манса Муса","cs":"Mansa Músa","da":"Mansa Musa","nb":"Mansa Musa","ru":"Манса Муса","hr":"Mansa Musa","sl":"Mansa Musa","sk":"Mansa Musa","sr":"Mansa Musa","ar":"مانسا موسى","he":"מנסה מוסה","fi":"Mansa Musa","et":"Mansa Musa","lt":"Mansa Musa","lv":"Mansa Musa","ja":"マンサ・ムーサ"}$j$::jsonb WHERE slug = 'mansa_musa';
UPDATE public.duel_leagues SET names = $j${"fr":"Dante","es":"Dante","de":"Dante","pt":"Dante","pt-PT":"Dante","it":"Dante","tr":"Dante","pl":"Dante","ro":"Dante","nl":"Dante","el":"Δάντης","sv":"Dante","hu":"Dante","bg":"Данте","cs":"Dante","da":"Dante","nb":"Dante","ru":"Данте","hr":"Dante","sl":"Dante","sk":"Dante","sr":"Dante","ar":"دانتي","he":"דנטה","fi":"Dante","et":"Dante","lt":"Dantė","lv":"Dante","ja":"ダンテ"}$j$::jsonb WHERE slug = 'dante';
UPDATE public.duel_leagues SET names = $j${"fr":"Jeanne d’Arc","es":"Juana de Arco","de":"Jeanne d'Arc","pt":"Joana d'Arc","pt-PT":"Joana d’Arc","it":"Giovanna d'Arco","tr":"Jeanne d'Arc","pl":"Joanna d'Arc","ro":"Ioana d'Arc","nl":"Jeanne d'Arc","el":"Ιωάννα της Λωρραίνης","sv":"Jeanne d'Arc","hu":"Jeanne d'Arc","bg":"Жана д'Арк","cs":"Johanka z Arku","da":"Jeanne d'Arc","nb":"Jeanne d'Arc","ru":"Жанна д'Арк","hr":"Ivana Orleanska","sl":"Ivana Orleanska","sk":"Jana z Arku","sr":"Jovanka Orleanka","ar":"جان دارك","he":"ז'אן ד'ארק","fi":"Jeanne d'Arc","et":"Jeanne d'Arci","lt":"Žana d'Ark","lv":"Žanna d'Arka","ja":"ジャンヌ・ダルク"}$j$::jsonb WHERE slug = 'joan_of_arc';
UPDATE public.duel_leagues SET names = $j${"fr":"Gutenberg","es":"Gutenberg","de":"Gutenberg","pt":"Gutenberg","pt-PT":"Gutenberg","it":"Gutenberg","tr":"Gutenberg","pl":"Gutenberg","ro":"Gutenberg","nl":"Gutenberg","el":"Γουτεμβέργιος","sv":"Gutenberg","hu":"Gutenberg","bg":"Гутенберг","cs":"Gutenberg","da":"Gutenberg","nb":"Gutenberg","ru":"Гутенберг","hr":"Gutenberg","sl":"Gutenberg","sk":"Gutenberg","sr":"Gutenberg","ar":"غوتنبرغ","he":"גוטנברג","fi":"Gutenberg","et":"Gutenbergi","lt":"Gutenbergas","lv":"Gūtenbergs","ja":"グーテンベルク"}$j$::jsonb WHERE slug = 'gutenberg';
UPDATE public.duel_leagues SET names = $j${"fr":"Léonard de Vinci","es":"Leonardo","de":"Leonardo","pt":"Leonardo","pt-PT":"Leonardo","it":"Leonardo","tr":"Leonardo","pl":"Leonardo","ro":"Leonardo","nl":"Leonardo","el":"Λεονάρντο","sv":"Leonardo","hu":"Leonardo","bg":"Леонардо","cs":"Leonardo","da":"Leonardo","nb":"Leonardo","ru":"Леонардо","hr":"Leonardo","sl":"Leonardo","sk":"Leonardo","sr":"Leonardo","ar":"ليوناردو","he":"לאונרדו","fi":"Leonardo","et":"Leonardo","lt":"Leonardas","lv":"Leonardo","ja":"ダ・ヴィンチ"}$j$::jsonb WHERE slug = 'leonardo';
UPDATE public.duel_leagues SET names = $j${"fr":"Michel-Ange","es":"Miguel Ángel","de":"Michelangelo","pt":"Michelangelo","pt-PT":"Miguel Ângelo","it":"Michelangelo","tr":"Michelangelo","pl":"Michał Anioł","ro":"Michelangelo","nl":"Michelangelo","el":"Μιχαήλ Άγγελος","sv":"Michelangelo","hu":"Michelangelo","bg":"Микеланджело","cs":"Michelangelo","da":"Michelangelo","nb":"Michelangelo","ru":"Микеланджело","hr":"Michelangelo","sl":"Michelangelo","sk":"Michelangelo","sr":"Mikelanđelo","ar":"ميكيلانجيلو","he":"מיכלאנג'לו","fi":"Michelangelo","et":"Michelangelo","lt":"Mikelandželas","lv":"Mikelandželo","ja":"ミケランジェロ"}$j$::jsonb WHERE slug = 'michelangelo';
UPDATE public.duel_leagues SET names = $j${"fr":"Copernic","es":"Copérnico","de":"Kopernikus","pt":"Copérnico","pt-PT":"Copérnico","it":"Copernico","tr":"Kopernik","pl":"Kopernik","ro":"Copernic","nl":"Copernicus","el":"Κοπέρνικος","sv":"Kopernikus","hu":"Kopernikusz","bg":"Коперник","cs":"Koperník","da":"Kopernikus","nb":"Kopernikus","ru":"Коперник","hr":"Kopernik","sl":"Kopernik","sk":"Kopernik","sr":"Kopernik","ar":"كوبرنيكوس","he":"קופרניקוס","fi":"Kopernikus","et":"Koperniku","lt":"Kopernikas","lv":"Koperniks","ja":"コペルニクス"}$j$::jsonb WHERE slug = 'copernicus';
UPDATE public.duel_leagues SET names = $j${"fr":"Shakespeare","es":"Shakespeare","de":"Shakespeare","pt":"Shakespeare","pt-PT":"Shakespeare","it":"Shakespeare","tr":"Shakespeare","pl":"Szekspir","ro":"Shakespeare","nl":"Shakespeare","el":"Σαίξπηρ","sv":"Shakespeare","hu":"Shakespeare","bg":"Шекспир","cs":"Shakespeare","da":"Shakespeare","nb":"Shakespeare","ru":"Шекспир","hr":"Shakespeare","sl":"Shakespeare","sk":"Shakespeare","sr":"Šekspir","ar":"شكسبير","he":"שייקספיר","fi":"Shakespeare","et":"Shakespeare'i","lt":"Shakespeare'as","lv":"Šekspīrs","ja":"シェイクスピア"}$j$::jsonb WHERE slug = 'shakespeare';
UPDATE public.duel_leagues SET names = $j${"fr":"Galilée","es":"Galileo","de":"Galilei","pt":"Galileu","pt-PT":"Galileu","it":"Galileo","tr":"Galileo","pl":"Galileusz","ro":"Galileo","nl":"Galilei","el":"Γαλιλαίος","sv":"Galileo","hu":"Galilei","bg":"Галилей","cs":"Galileo","da":"Galilei","nb":"Galilei","ru":"Галилей","hr":"Galileo","sl":"Galileo","sk":"Galileo","sr":"Galilej","ar":"غاليليو","he":"גלילאו","fi":"Galilei","et":"Galilei","lt":"Galilėjus","lv":"Galilejs","ja":"ガリレオ"}$j$::jsonb WHERE slug = 'galileo';
UPDATE public.duel_leagues SET names = $j${"fr":"Vermeer","es":"Vermeer","de":"Vermeer","pt":"Vermeer","pt-PT":"Vermeer","it":"Vermeer","tr":"Vermeer","pl":"Vermeer","ro":"Vermeer","nl":"Vermeer","el":"Βερμέερ","sv":"Vermeer","hu":"Vermeer","bg":"Вермеер","cs":"Vermeer","da":"Vermeer","nb":"Vermeer","ru":"Вермеер","hr":"Vermeer","sl":"Vermeer","sk":"Vermeer","sr":"Vermer","ar":"فيرمير","he":"ורמיר","fi":"Vermeer","et":"Vermeeri","lt":"Vermeeris","lv":"Vermērs","ja":"フェルメール"}$j$::jsonb WHERE slug = 'vermeer';
UPDATE public.duel_leagues SET names = $j${"fr":"Newton","es":"Newton","de":"Newton","pt":"Newton","pt-PT":"Newton","it":"Newton","tr":"Newton","pl":"Newton","ro":"Newton","nl":"Newton","el":"Νεύτων","sv":"Newton","hu":"Newton","bg":"Нютон","cs":"Newton","da":"Newton","nb":"Newton","ru":"Ньютон","hr":"Newton","sl":"Newton","sk":"Newton","sr":"Njutn","ar":"نيوتن","he":"ניוטון","fi":"Newton","et":"Newtoni","lt":"Niutonas","lv":"Ņūtons","ja":"ニュートン"}$j$::jsonb WHERE slug = 'newton';
UPDATE public.duel_leagues SET names = $j${"fr":"Mozart","es":"Mozart","de":"Mozart","pt":"Mozart","pt-PT":"Mozart","it":"Mozart","tr":"Mozart","pl":"Mozart","ro":"Mozart","nl":"Mozart","el":"Μότσαρτ","sv":"Mozart","hu":"Mozart","bg":"Моцарт","cs":"Mozart","da":"Mozart","nb":"Mozart","ru":"Моцарт","hr":"Mozart","sl":"Mozart","sk":"Mozart","sr":"Mocart","ar":"موتسارت","he":"מוצרט","fi":"Mozart","et":"Mozarti","lt":"Mozartas","lv":"Mocarts","ja":"モーツァルト"}$j$::jsonb WHERE slug = 'mozart';
UPDATE public.duel_leagues SET names = $j${"fr":"Napoléon","es":"Napoleón","de":"Napoleon","pt":"Napoleão","pt-PT":"Napoleão","it":"Napoleone","tr":"Napolyon","pl":"Napoleon","ro":"Napoleon","nl":"Napoleon","el":"Ναπολέων","sv":"Napoleon","hu":"Napóleon","bg":"Наполеон","cs":"Napoleon","da":"Napoleon","nb":"Napoleon","ru":"Наполеон","hr":"Napoleon","sl":"Napoleon","sk":"Napoleon","sr":"Napoleon","ar":"نابليون","he":"נפוליאון","fi":"Napoleon","et":"Napoleoni","lt":"Napoleonas","lv":"Napoleons","ja":"ナポレオン"}$j$::jsonb WHERE slug = 'napoleon';
UPDATE public.duel_leagues SET names = $j${"fr":"Austen","es":"Austen","de":"Austen","pt":"Austen","pt-PT":"Austen","it":"Austen","tr":"Austen","pl":"Austen","ro":"Austen","nl":"Austen","el":"Όστεν","sv":"Austen","hu":"Austen","bg":"Остин","cs":"Jane Austenová","da":"Austen","nb":"Austen","ru":"Остин","hr":"Austen","sl":"Jane Austen","sk":"Jane Austenová","sr":"Ostin","ar":"أوستن","he":"אוסטן","fi":"Austen","et":"Austeni","lt":"Austen","lv":"Ostina","ja":"オースティン"}$j$::jsonb WHERE slug = 'austen';
UPDATE public.duel_leagues SET names = $j${"fr":"Darwin","es":"Darwin","de":"Darwin","pt":"Darwin","pt-PT":"Darwin","it":"Darwin","tr":"Darwin","pl":"Darwin","ro":"Darwin","nl":"Darwin","el":"Δαρβίνος","sv":"Darwin","hu":"Darwin","bg":"Дарвин","cs":"Darwin","da":"Darwin","nb":"Darwin","ru":"Дарвин","hr":"Darwin","sl":"Darwin","sk":"Darwin","sr":"Darvin","ar":"داروين","he":"דרווין","fi":"Darwin","et":"Darwini","lt":"Darwinas","lv":"Darvins","ja":"ダーウィン"}$j$::jsonb WHERE slug = 'darwin';
UPDATE public.duel_leagues SET names = $j${"fr":"Lovelace","es":"Lovelace","de":"Lovelace","pt":"Lovelace","pt-PT":"Lovelace","it":"Lovelace","tr":"Lovelace","pl":"Lovelace","ro":"Lovelace","nl":"Lovelace","el":"Λάβλεϊς","sv":"Lovelace","hu":"Lovelace","bg":"Лъвлейс","cs":"Ada Lovelace","da":"Lovelace","nb":"Lovelace","ru":"Лавлейс","hr":"Lovelace","sl":"Ada Lovelace","sk":"Ada Lovelaceová","sr":"Lavlejs","ar":"لوفليس","he":"לאבלייס","fi":"Lovelace","et":"Lovelace'i","lt":"Lovelace","lv":"Lavleisa","ja":"エイダ・ラブレス"}$j$::jsonb WHERE slug = 'lovelace';
UPDATE public.duel_leagues SET names = $j${"fr":"Van Gogh","es":"Van Gogh","de":"Van Gogh","pt":"Van Gogh","pt-PT":"Van Gogh","it":"Van Gogh","tr":"Van Gogh","pl":"Van Gogh","ro":"Van Gogh","nl":"Van Gogh","el":"Βαν Γκογκ","sv":"Van Gogh","hu":"Van Gogh","bg":"Ван Гог","cs":"Van Gogh","da":"Van Gogh","nb":"Van Gogh","ru":"Ван Гог","hr":"Van Gogh","sl":"Van Gogh","sk":"Van Gogh","sr":"Van Gog","ar":"فان غوخ","he":"ואן גוך","fi":"Van Gogh","et":"Van Goghi","lt":"Van Gogas","lv":"Van Gogs","ja":"ゴッホ"}$j$::jsonb WHERE slug = 'van_gogh';
UPDATE public.duel_leagues SET names = $j${"fr":"Curie","es":"Curie","de":"Curie","pt":"Curie","pt-PT":"Curie","it":"Curie","tr":"Curie","pl":"Skłodowska-Curie","ro":"Curie","nl":"Curie","el":"Κιουρί","sv":"Curie","hu":"Curie","bg":"Кюри","cs":"Marie Curie","da":"Curie","nb":"Curie","ru":"Кюри","hr":"Curie","sl":"Marie Curie","sk":"Marie Curieová","sr":"Kiri","ar":"كوري","he":"קירי","fi":"Curie","et":"Curie","lt":"Curie","lv":"Kirī","ja":"キュリー"}$j$::jsonb WHERE slug = 'curie';
UPDATE public.duel_leagues SET names = $j${"fr":"Einstein","es":"Einstein","de":"Einstein","pt":"Einstein","pt-PT":"Einstein","it":"Einstein","tr":"Einstein","pl":"Einstein","ro":"Einstein","nl":"Einstein","el":"Αϊνστάιν","sv":"Einstein","hu":"Einstein","bg":"Айнщайн","cs":"Einstein","da":"Einstein","nb":"Einstein","ru":"Эйнштейн","hr":"Einstein","sl":"Einstein","sk":"Einstein","sr":"Ajnštajn","ar":"أينشتاين","he":"איינשטיין","fi":"Einstein","et":"Einsteini","lt":"Einšteinas","lv":"Einšteins","ja":"アインシュタイン"}$j$::jsonb WHERE slug = 'einstein';
UPDATE public.duel_leagues SET names = $j${"fr":"Kahlo","es":"Kahlo","de":"Kahlo","pt":"Kahlo","pt-PT":"Kahlo","it":"Kahlo","tr":"Kahlo","pl":"Kahlo","ro":"Kahlo","nl":"Kahlo","el":"Κάλο","sv":"Kahlo","hu":"Kahlo","bg":"Кало","cs":"Frida Kahlo","da":"Kahlo","nb":"Kahlo","ru":"Кало","hr":"Kahlo","sl":"Frida Kahlo","sk":"Frida Kahlová","sr":"Kalo","ar":"كاهلو","he":"קאלו","fi":"Kahlo","et":"Kahlo","lt":"Kahlo","lv":"Kalo","ja":"フリーダ・カーロ"}$j$::jsonb WHERE slug = 'kahlo';
UPDATE public.duel_leagues SET names = $j${"fr":"Sophia","es":"Sophia","de":"Sophia","pt":"Sophia","pt-PT":"Sophia","it":"Sophia","tr":"Sophia","pl":"Sophia","ro":"Sophia","nl":"Sophia","el":"Sophia","sv":"Sophia","hu":"Sophia","bg":"Sophia","cs":"Sophia","da":"Sophia","nb":"Sophia","ru":"Sophia","hr":"Sophia","sl":"Sophia","sk":"Sophia","sr":"Sophia","ar":"Sophia","he":"Sophia","fi":"Sophia","et":"Sophia","lt":"Sophia","lv":"Sophia","ja":"Sophia"}$j$::jsonb WHERE slug = 'sophia';

COMMIT;

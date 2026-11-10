-- Duels : des adversaires aux pseudos bien plus variés, et qu'on ne recroise plus de sitôt.
--
-- Constat : les 300 adversaires de départ sortent d'une seule recette (prénom + chiffres, prénom +
-- nom) sur de petits viviers de prénoms : « sarah97 », « sarah652 », « sarah85 »… Le tirage, lui,
-- n'écartait que les 25 derniers adversaires, sans regarder si deux pseudos se ressemblaient.
--
-- 1. 800 adversaires de plus (1100 en tout) : davantage de prénoms et de pays, et les formes que
--    prennent les vrais pseudos (prénom seul, initiales, « its… », ville, passe-temps, surnoms…).
--    Même format que les comptes (^[a-z][a-z0-9]{2,19}$ : ni point ni tiret bas, un vrai compte
--    ne peut pas en avoir), aucun terme de banned_handle_terms. Un pseudo interdit depuis, ou
--    déjà pris par un vrai compte, n'est pas inséré.
-- 2. duel_pick_bot : le tirage écarte les 150 derniers adversaires (au lieu de 25), ceux dont le
--    pseudo commence comme l'un des 20 derniers (« sarah97 » après « sarah85 »), le pays des
--    deux derniers, et un pseudo porté par un vrai compte. S'il ne reste personne, les règles
--    tombent une à une.
-- 3. duel_start_match_v2 : identique à 20261110020500_duel_credibility.sql, sauf le tirage de
--    l'adversaire (duel_pick_bot) et la mémoire des adversaires (150). Même signature, même
--    réponse : rien ne change pour les apps iOS et Android. Les fonctions d'avant
--    (duel_start_match) restent telles quelles.
--
-- Rejouable. À passer après 20261111020100_duel_long_memory.sql.

INSERT INTO public.duel_bots (handle, country_code, avatar_id)
SELECT v.handle, v.country_code, v.avatar_id
FROM (VALUES
  ('stormywillow', 'CA', 'avatar_60'),
  ('ahm94', 'NG', 'avatar_01'),
  ('milan5', 'NL', 'avatar_13'),
  ('ayoo', 'NG', 'avatar_29'),
  ('kevinwang', 'CA', 'avatar_25'),
  ('sjf86', 'DE', 'avatar_41'),
  ('florenciar', 'MX', 'avatar_48'),
  ('solarmaple43', 'SE', 'avatar_60'),
  ('spacemom', 'PL', 'avatar_59'),
  ('alesza85', 'RO', 'avatar_44'),
  ('niadoy413', 'CA', 'avatar_37'),
  ('thanospappas', 'GR', 'avatar_60'),
  ('brunosp', 'BR', 'avatar_13'),
  ('jesshunt', 'CA', 'avatar_05'),
  ('heyblake', 'GB', 'avatar_20'),
  ('ricardo', 'MX', 'avatar_56'),
  ('albinj', 'FI', 'avatar_13'),
  ('rainypainter', 'CA', 'avatar_44'),
  ('petersf', 'NL', 'avatar_50'),
  ('hendralovesvinyl', 'ID', 'avatar_49'),
  ('vinyldad2', 'FI', 'avatar_13'),
  ('mapgeek1', 'ID', 'avatar_39'),
  ('themuseumhunter', 'DE', 'avatar_13'),
  ('harperk96', 'GB', 'avatar_46'),
  ('sander', 'DK', 'avatar_35'),
  ('lakshmi', 'IN', 'avatar_03'),
  ('dustyotter', 'GB', 'avatar_48'),
  ('itseva', 'FR', 'avatar_32'),
  ('crimsonlynx', 'AU', 'avatar_52'),
  ('ayeshamum', 'IN', 'avatar_26'),
  ('ivorydolphin', 'ZA', 'avatar_13'),
  ('ejones6', 'GB', 'avatar_06'),
  ('franco247', 'ES', 'avatar_12'),
  ('coffeejunkie1', 'DE', 'avatar_13'),
  ('yetundenjoroge', 'TZ', 'avatar_01'),
  ('helmib', 'SE', 'avatar_05'),
  ('brodylovesbook', 'GB', 'avatar_13'),
  ('janr', 'CH', 'avatar_02'),
  ('alfredrasmussen', 'SE', 'avatar_24'),
  ('florence', 'AU', 'avatar_50'),
  ('cleverdumpling', 'JP', 'avatar_09'),
  ('indahexplores', 'TH', 'avatar_34'),
  ('vfletcher6', 'US', 'avatar_48'),
  ('lunabyrne', 'NZ', 'avatar_44'),
  ('amartinelli', 'IT', 'avatar_35'),
  ('lanr93', 'ID', 'avatar_39'),
  ('angelph', 'PH', 'avatar_39'),
  ('randomtundra01', 'DE', 'avatar_56'),
  ('themapperson', 'GR', 'avatar_48'),
  ('cormacr', 'US', 'avatar_56'),
  ('wulannn', 'PH', 'avatar_34'),
  ('philippwerner', 'DE', 'avatar_28'),
  ('damilolatesfaye', 'UG', 'avatar_36'),
  ('geokid59', 'PT', 'avatar_13'),
  ('nunesb', 'BR', 'avatar_13'),
  ('diallosimisola', 'ZA', 'avatar_10'),
  ('scortes369', 'AR', 'avatar_45'),
  ('teanerd668', 'NG', 'avatar_06'),
  ('thandiobi', 'SN', 'avatar_46'),
  ('amberreader', 'NZ', 'avatar_13'),
  ('goldenfalcon', 'NO', 'avatar_13'),
  ('teunmulder', 'BE', 'avatar_24'),
  ('anapet', 'RS', 'avatar_50'),
  ('justlatinhunter73', 'AU', 'avatar_13'),
  ('tesfaye45', 'NG', 'avatar_06'),
  ('electricmaple9', 'GB', 'avatar_52'),
  ('ezrahayes', 'GB', 'avatar_52'),
  ('itsioanna', 'GR', 'avatar_48'),
  ('ethanmurphy', 'US', 'avatar_02'),
  ('tanyamukherjee', 'BD', 'avatar_03'),
  ('sophiemacdonald', 'CA', 'avatar_58'),
  ('rizkyw', 'ID', 'avatar_49'),
  ('mathilda', 'DE', 'avatar_48'),
  ('agustina81', 'CL', 'avatar_05'),
  ('stm90', 'IN', 'avatar_26'),
  ('silverpoet', 'GB', 'avatar_23'),
  ('catbuff', 'CA', 'avatar_11'),
  ('sinead247', 'GB', 'avatar_58'),
  ('hdeng2', 'HK', 'avatar_09'),
  ('tlb66', 'PL', 'avatar_16'),
  ('urbanninja', 'HR', 'avatar_19'),
  ('lindiwe7', 'ET', 'avatar_23'),
  ('noeliap9', 'MX', 'avatar_50'),
  ('mhayashi9', 'JP', 'avatar_22'),
  ('castroxim', 'AR', 'avatar_50'),
  ('jwz17', 'CA', 'avatar_55'),
  ('hamzaa', 'AE', 'avatar_08'),
  ('itsmason', 'US', 'avatar_24'),
  ('tazikerem', 'SA', 'avatar_54'),
  ('femke89', 'BE', 'avatar_44'),
  ('carmentravels', 'MX', 'avatar_05'),
  ('ayakatries', 'JP', 'avatar_22'),
  ('amberalpaca', 'IN', 'avatar_26'),
  ('ccavalcanti', 'BR', 'avatar_18'),
  ('fuzzybadger', 'CL', 'avatar_05'),
  ('emily1999', 'SG', 'avatar_09'),
  ('jml3', 'KR', 'avatar_31'),
  ('avacodes', 'US', 'avatar_37'),
  ('sannedewit', 'NL', 'avatar_48'),
  ('keleching', 'NG', 'avatar_36'),
  ('littlelibrarian', 'AU', 'avatar_13'),
  ('physicsenjoyer', 'NO', 'avatar_05'),
  ('carter5', 'NZ', 'avatar_36'),
  ('joyceruns', 'TW', 'avatar_55'),
  ('fallham', 'KE', 'avatar_06'),
  ('manishjr', 'IN', 'avatar_47'),
  ('chillprofessor05', 'CN', 'avatar_22'),
  ('noeliawins', 'PE', 'avatar_51'),
  ('evarobert', 'CA', 'avatar_42'),
  ('latebaker', 'NG', 'avatar_36'),
  ('thepuzzlejunkie550', 'CN', 'avatar_43'),
  ('yuxzha96', 'US', 'avatar_09'),
  ('cormacexplores', 'US', 'avatar_56'),
  ('imben', 'AU', 'avatar_19'),
  ('humblenebula', 'HR', 'avatar_13'),
  ('lazyotter', 'MY', 'avatar_49'),
  ('juliaaa', 'BR', 'avatar_37'),
  ('crimsonorbit88', 'EG', 'avatar_42'),
  ('jhoang', 'ID', 'avatar_49'),
  ('phoebe6', 'AU', 'avatar_46'),
  ('lostprofessor', 'GB', 'avatar_10'),
  ('indiakl', 'NZ', 'avatar_10'),
  ('neonsage', 'JP', 'avatar_55'),
  ('fernanda', 'CL', 'avatar_44'),
  ('cheruiyotb', 'KE', 'avatar_40'),
  ('rina99', 'PH', 'avatar_57'),
  ('calmpretzel', 'UA', 'avatar_32'),
  ('andreiionescu', 'HU', 'avatar_13'),
  ('xiahu007', 'US', 'avatar_25'),
  ('frozencedar', 'NL', 'avatar_13'),
  ('luckyotter', 'AU', 'avatar_32'),
  ('immarta', 'MX', 'avatar_50'),
  ('mhoang', 'ID', 'avatar_57'),
  ('aadebayo07', 'ET', 'avatar_46'),
  ('camilacdmx', 'MX', 'avatar_16'),
  ('nadia77', 'SG', 'avatar_34'),
  ('kasunjoshi', 'PK', 'avatar_15'),
  ('fabian26', 'CH', 'avatar_13'),
  ('akarii', 'JP', 'avatar_55'),
  ('charlie', 'US', 'avatar_29'),
  ('fergusoconnor', 'AU', 'avatar_12'),
  ('mathlover', 'UG', 'avatar_36'),
  ('ryann', 'CN', 'avatar_31'),
  ('taeyangcodes', 'KR', 'avatar_43'),
  ('yps31', 'CA', 'avatar_09'),
  ('danishhossain', 'PK', 'avatar_15'),
  ('aitanam', 'ES', 'avatar_51'),
  ('seann', 'US', 'avatar_41'),
  ('grace53', 'IE', 'avatar_58'),
  ('benroth', 'DE', 'avatar_13'),
  ('adrienmtl', 'CA', 'avatar_56'),
  ('gurleenbakes', 'PK', 'avatar_26'),
  ('bilalr', 'PK', 'avatar_11'),
  ('thesciencedad', 'AU', 'avatar_15'),
  ('all8', 'US', 'avatar_18'),
  ('aanyathinks', 'GB', 'avatar_03'),
  ('fgp7', 'MX', 'avatar_02'),
  ('margaux', 'FR', 'avatar_10'),
  ('terezashevchenko', 'PL', 'avatar_53'),
  ('benjaming5', 'FR', 'avatar_41'),
  ('thesciencebuff462', 'HU', 'avatar_13'),
  ('theteafan', 'ES', 'avatar_56'),
  ('justquizenjoyer115', 'DE', 'avatar_42'),
  ('quietwhale', 'US', 'avatar_13'),
  ('gurleen101', 'CA', 'avatar_26'),
  ('noorvandenheuvel', 'NL', 'avatar_13'),
  ('beleng1', 'CO', 'avatar_53'),
  ('felipesuarez', 'US', 'avatar_02'),
  ('rheax', 'LK', 'avatar_26'),
  ('anjdhi91', 'BD', 'avatar_26'),
  ('coffeelover3', 'US', 'avatar_48'),
  ('randomorbit3', 'TH', 'avatar_49'),
  ('minacherif', 'MA', 'avatar_30'),
  ('hamzam138', 'PK', 'avatar_15'),
  ('historynerd', 'ID', 'avatar_39'),
  ('itsnaoki', 'JP', 'avatar_25'),
  ('reginax', 'US', 'avatar_27'),
  ('thehub', 'AT', 'avatar_32'),
  ('jvandenberg', 'BE', 'avatar_37'),
  ('erickl', 'MY', 'avatar_04'),
  ('euann', 'US', 'avatar_60'),
  ('whall', 'US', 'avatar_01'),
  ('lachlan', 'NZ', 'avatar_56'),
  ('minhcebu', 'PH', 'avatar_49'),
  ('thedogkid', 'US', 'avatar_16'),
  ('dreed', 'US', 'avatar_28'),
  ('svenjakruger', 'DE', 'avatar_50'),
  ('anjali', 'BD', 'avatar_26'),
  ('hiddenwren', 'KE', 'avatar_06'),
  ('thembadlamini', 'NG', 'avatar_20'),
  ('orlfra913', 'GB', 'avatar_58'),
  ('mythbuff', 'LK', 'avatar_03'),
  ('mteo', 'VN', 'avatar_39'),
  ('htg28', 'NZ', 'avatar_48'),
  ('junwins', 'HK', 'avatar_31'),
  ('sergiohq', 'AR', 'avatar_02'),
  ('zhiweic', 'AU', 'avatar_31'),
  ('dognerd1', 'IL', 'avatar_13'),
  ('akira86', 'JP', 'avatar_25'),
  ('theresa92', 'DE', 'avatar_16'),
  ('haozhu99', 'HK', 'avatar_31'),
  ('nkrishnan', 'IN', 'avatar_26'),
  ('kojoo78', 'GH', 'avatar_52'),
  ('euannn', 'GB', 'avatar_02'),
  ('iyerkavya', 'IN', 'avatar_26'),
  ('rahulhyd', 'IN', 'avatar_15'),
  ('dimdim52', 'GR', 'avatar_13'),
  ('callumscott', 'GB', 'avatar_59'),
  ('zimoxo', 'SG', 'avatar_31'),
  ('kunlee', 'NG', 'avatar_29'),
  ('nordicscholar', 'CA', 'avatar_13'),
  ('rishiii', 'IN', 'avatar_15'),
  ('femin', 'UG', 'avatar_20'),
  ('yumaogawa', 'JP', 'avatar_31'),
  ('merlexd', 'DE', 'avatar_50'),
  ('estebantv', 'CO', 'avatar_21'),
  ('cpj97', 'US', 'avatar_56'),
  ('juncodes', 'HK', 'avatar_04'),
  ('fkaya99', 'US', 'avatar_30'),
  ('nerdyturtle', 'CO', 'avatar_60'),
  ('szymonl', 'CZ', 'avatar_60'),
  ('martacorreia', 'BR', 'avatar_53'),
  ('linah', 'AT', 'avatar_48'),
  ('joytries', 'KE', 'avatar_10'),
  ('mateuszx', 'HU', 'avatar_59'),
  ('crosswordperson', 'CH', 'avatar_28'),
  ('neonscholar', 'LK', 'avatar_03'),
  ('renspeters', 'NL', 'avatar_13'),
  ('mellowwhale59', 'CA', 'avatar_13'),
  ('oscardraws', 'US', 'avatar_35'),
  ('paoloo', 'TH', 'avatar_49'),
  ('ral80', 'PH', 'avatar_39'),
  ('tinysailor', 'NL', 'avatar_13'),
  ('mahmoud', 'NL', 'avatar_54'),
  ('brianknows', 'TZ', 'avatar_52'),
  ('itzjasmijn', 'BE', 'avatar_37'),
  ('kamaubongani', 'UG', 'avatar_36'),
  ('ankitt', 'IN', 'avatar_15'),
  ('rosieee', 'GB', 'avatar_16'),
  ('saltysailor', 'NG', 'avatar_52'),
  ('oler4', 'DE', 'avatar_35'),
  ('spaceaddict83', 'HK', 'avatar_09'),
  ('thepoetrykid23', 'PL', 'avatar_13'),
  ('eric7', 'TW', 'avatar_25'),
  ('macdonaldsea', 'US', 'avatar_52'),
  ('notdaisy', 'NZ', 'avatar_16'),
  ('aaguilar', 'ES', 'avatar_16'),
  ('rafael', 'CL', 'avatar_60'),
  ('adrian36', 'VN', 'avatar_49'),
  ('justsciencemaster', 'IN', 'avatar_11'),
  ('mathis', 'FR', 'avatar_35'),
  ('kiamur', 'AU', 'avatar_46'),
  ('meihashimoto', 'JP', 'avatar_55'),
  ('moritzneumann', 'CH', 'avatar_02'),
  ('tanyag', 'BD', 'avatar_26'),
  ('vgonzalez', 'PE', 'avatar_51'),
  ('catmaster', 'TR', 'avatar_54'),
  ('thepuzzleguy', 'US', 'avatar_33'),
  ('ndogan796', 'NL', 'avatar_30'),
  ('collins88', 'UG', 'avatar_06'),
  ('mrdimas', 'PH', 'avatar_49'),
  ('isaacf', 'IE', 'avatar_59'),
  ('stefan', 'HU', 'avatar_41'),
  ('suarezv', 'ES', 'avatar_16'),
  ('luka99', 'RS', 'avatar_24'),
  ('ronjagustafsson', 'NO', 'avatar_37'),
  ('rocio50', 'AR', 'avatar_51'),
  ('yichenx', 'HK', 'avatar_43'),
  ('nadia13', 'PH', 'avatar_57'),
  ('vittoria9', 'IT', 'avatar_53'),
  ('sunnygardener', 'BE', 'avatar_30'),
  ('kwesiafolabi', 'KE', 'avatar_52'),
  ('dustyfalcon', 'PH', 'avatar_17'),
  ('physicshunter', 'NG', 'avatar_52'),
  ('joaquin6', 'AR', 'avatar_45'),
  ('archie', 'GB', 'avatar_06'),
  ('karammaj', 'DE', 'avatar_33'),
  ('gmurphy', 'CA', 'avatar_53'),
  ('lunarlibrarian360', 'GB', 'avatar_13'),
  ('siennaplays', 'GB', 'avatar_32'),
  ('humblepixel', 'IL', 'avatar_13'),
  ('klambert', 'FR', 'avatar_56'),
  ('abertrand', 'FR', 'avatar_12'),
  ('efua318', 'ET', 'avatar_46'),
  ('riymis', 'IN', 'avatar_26'),
  ('helmiii', 'FI', 'avatar_32'),
  ('pimbos', 'NL', 'avatar_56'),
  ('sachad90', 'CA', 'avatar_35'),
  ('ojohansen1988', 'DK', 'avatar_60'),
  ('mia25', 'CH', 'avatar_37'),
  ('yutongthinks', 'US', 'avatar_55'),
  ('indimills', 'GB', 'avatar_05'),
  ('karimm', 'DE', 'avatar_54'),
  ('reggiem4', 'CA', 'avatar_29'),
  ('abdijhb', 'ZA', 'avatar_36'),
  ('thao7', 'PH', 'avatar_17'),
  ('brunaii', 'BR', 'avatar_10'),
  ('emmapeters', 'NL', 'avatar_13'),
  ('samilearns', 'LB', 'avatar_33'),
  ('aoifelovestea', 'US', 'avatar_01'),
  ('kabirk7', 'IN', 'avatar_38'),
  ('fraserisla', 'IE', 'avatar_53'),
  ('trisha', 'LK', 'avatar_03'),
  ('goldenmonk', 'KR', 'avatar_43'),
  ('abose', 'US', 'avatar_47'),
  ('namhq', 'VN', 'avatar_49'),
  ('sannekoster', 'NL', 'avatar_50'),
  ('biancaxo', 'PL', 'avatar_16'),
  ('damilolaa61', 'GH', 'avatar_29'),
  ('brianotieno', 'TZ', 'avatar_36'),
  ('boldgardener', 'ZA', 'avatar_06'),
  ('rafidesai', 'IN', 'avatar_47'),
  ('apb8', 'FR', 'avatar_48'),
  ('tonyyy', 'US', 'avatar_33'),
  ('thechessmaster', 'EG', 'avatar_54'),
  ('coastalcomet', 'PT', 'avatar_41'),
  ('kaitse', 'CN', 'avatar_43'),
  ('seoahtv', 'KR', 'avatar_22'),
  ('ifeanyi', 'GH', 'avatar_20'),
  ('quizperson2006', 'NO', 'avatar_13'),
  ('estheradebayo', 'SN', 'avatar_46'),
  ('gabriellisboa', 'PT', 'avatar_45'),
  ('maksymlovesscience', 'DE', 'avatar_41'),
  ('urbankoala', 'MY', 'avatar_25'),
  ('niamhwrites', 'US', 'avatar_23'),
  ('neonhistorian', 'US', 'avatar_13'),
  ('aaravyt', 'IN', 'avatar_47'),
  ('ingrid', 'SE', 'avatar_53'),
  ('brunonavarro', 'ES', 'avatar_13'),
  ('dengl', 'TW', 'avatar_22'),
  ('sowc', 'SN', 'avatar_20'),
  ('jzhou1', 'TW', 'avatar_43'),
  ('ramosenzo', 'BR', 'avatar_20'),
  ('notchloe', 'TW', 'avatar_09'),
  ('juliatv', 'US', 'avatar_27'),
  ('crimsonmango90', 'BR', 'avatar_13'),
  ('drewfoster', 'CA', 'avatar_12'),
  ('dariushx', 'MA', 'avatar_54'),
  ('raulh', 'US', 'avatar_60'),
  ('noeliavazquez', 'US', 'avatar_50'),
  ('carmen2007', 'MX', 'avatar_37'),
  ('rousseaumil', 'FR', 'avatar_48'),
  ('lhenry', 'CH', 'avatar_53'),
  ('yantries', 'CN', 'avatar_22'),
  ('emmafr', 'FR', 'avatar_13'),
  ('jgf4', 'CA', 'avatar_12'),
  ('callumthompson', 'GB', 'avatar_35'),
  ('harriselsie', 'GB', 'avatar_01'),
  ('daniel', 'BR', 'avatar_06'),
  ('chinedua', 'NG', 'avatar_36'),
  ('paigek98', 'CA', 'avatar_58'),
  ('wiktorian47', 'UA', 'avatar_16'),
  ('mzeng', 'HK', 'avatar_22'),
  ('akashhh', 'IN', 'avatar_15'),
  ('annabraun', 'DE', 'avatar_13'),
  ('akuaadebayo', 'TZ', 'avatar_23'),
  ('alpineowl84', 'PH', 'avatar_49'),
  ('lazyturtle', 'MX', 'avatar_53'),
  ('aguilarcar', 'US', 'avatar_37'),
  ('priyad17', 'IN', 'avatar_03'),
  ('shreyaj', 'IN', 'avatar_03'),
  ('jensenida', 'SE', 'avatar_37'),
  ('aaliyahatx', 'US', 'avatar_46'),
  ('matildaroberts', 'GB', 'avatar_10'),
  ('emilio', 'PE', 'avatar_02'),
  ('atran2002', 'TH', 'avatar_49'),
  ('danleo7', 'IT', 'avatar_12'),
  ('faisalx', 'LB', 'avatar_54'),
  ('chessmaster2008', 'DE', 'avatar_59'),
  ('spacehunter', 'PL', 'avatar_41'),
  ('woodr', 'CA', 'avatar_13'),
  ('coastalscholar', 'DK', 'avatar_13'),
  ('aaliyahchapman', 'GB', 'avatar_58'),
  ('myang', 'US', 'avatar_22'),
  ('harrymurray', 'ZA', 'avatar_28'),
  ('mkaram', 'MA', 'avatar_42'),
  ('maxberlin', 'DE', 'avatar_60'),
  ('donghyuntravels', 'KR', 'avatar_31'),
  ('kiara980', 'ZA', 'avatar_37'),
  ('hlv43', 'MX', 'avatar_35'),
  ('silverhedgehog', 'ES', 'avatar_44'),
  ('escott', 'GB', 'avatar_23'),
  ('chiamakax', 'TZ', 'avatar_58'),
  ('puzzleperson', 'GB', 'avatar_13'),
  ('oliverf', 'GB', 'avatar_41'),
  ('itzsofia', 'MX', 'avatar_05'),
  ('putrii', 'SG', 'avatar_34'),
  ('mrothmane', 'TR', 'avatar_54'),
  ('fernw', 'PH', 'avatar_39'),
  ('chm97', 'ZA', 'avatar_40'),
  ('nerdypainter', 'CA', 'avatar_36'),
  ('eilidhbyrne', 'GB', 'avatar_53'),
  ('destinywilson', 'GB', 'avatar_01'),
  ('darcywalker', 'IE', 'avatar_60'),
  ('abdiii', 'US', 'avatar_06'),
  ('bekelea', 'NG', 'avatar_29'),
  ('aslmah', 'MA', 'avatar_42'),
  ('elenieconomou', 'AU', 'avatar_48'),
  ('briannacpt', 'ZA', 'avatar_10'),
  ('joanaaa', 'PT', 'avatar_50'),
  ('ngozimokoena', 'NG', 'avatar_01'),
  ('lenahq', 'PL', 'avatar_50'),
  ('hollyy', 'US', 'avatar_37'),
  ('fitrilovesgeo', 'MY', 'avatar_39'),
  ('quinn7', 'GB', 'avatar_05'),
  ('palesaokafor', 'SN', 'avatar_10'),
  ('fmercier9', 'FR', 'avatar_02'),
  ('bohdan', 'HR', 'avatar_13'),
  ('chanr', 'TW', 'avatar_31'),
  ('ivanakovacs', 'PL', 'avatar_44'),
  ('rhh99', 'GB', 'avatar_60'),
  ('uriii', 'IL', 'avatar_24'),
  ('xavier', 'US', 'avatar_02'),
  ('agatad', 'RO', 'avatar_32'),
  ('theniklas', 'AT', 'avatar_02'),
  ('tanya05', 'GB', 'avatar_26'),
  ('catperson6', 'TW', 'avatar_55'),
  ('gonalv', 'MX', 'avatar_59'),
  ('alejandrohq', 'AR', 'avatar_13'),
  ('berfon', 'BR', 'avatar_21'),
  ('tgf01', 'CA', 'avatar_29'),
  ('sciencejunkie', 'VN', 'avatar_39'),
  ('carlos', 'CO', 'avatar_14'),
  ('mihain', 'HU', 'avatar_12'),
  ('philosophyhunter', 'PH', 'avatar_34'),
  ('maicru', 'ID', 'avatar_34'),
  ('alpinetundra', 'PL', 'avatar_13'),
  ('alan2006', 'US', 'avatar_31'),
  ('anjalid90', 'US', 'avatar_03'),
  ('gemwil', 'US', 'avatar_44'),
  ('harsh63', 'IN', 'avatar_47'),
  ('lakshmiperera', 'PK', 'avatar_26'),
  ('zbs18', 'US', 'avatar_26'),
  ('itsarlo', 'IE', 'avatar_35'),
  ('notsneha', 'IN', 'avatar_03'),
  ('triviadad', 'US', 'avatar_19'),
  ('shreyaa', 'US', 'avatar_26'),
  ('itsindi', 'US', 'avatar_58'),
  ('brodyy', 'GB', 'avatar_02'),
  ('lerato953', 'UG', 'avatar_23'),
  ('ebrurezaei', 'NL', 'avatar_42'),
  ('navarrobel', 'CL', 'avatar_32'),
  ('mrbaraka', 'ET', 'avatar_52'),
  ('arifff', 'SG', 'avatar_49'),
  ('asherc2002', 'GB', 'avatar_12'),
  ('ayaanjoshi', 'LK', 'avatar_11'),
  ('lanx', 'ID', 'avatar_17'),
  ('jumaaa', 'KE', 'avatar_20'),
  ('gabinfr', 'FR', 'avatar_59'),
  ('thequizlover', 'UA', 'avatar_13'),
  ('pjk2', 'LK', 'avatar_26'),
  ('johanna', 'DE', 'avatar_32'),
  ('catfan', 'US', 'avatar_13'),
  ('ofletcher445', 'US', 'avatar_32'),
  ('amandinet88', 'FR', 'avatar_58'),
  ('rodrigosf', 'US', 'avatar_56'),
  ('pto6', 'GB', 'avatar_50'),
  ('kelechitravels', 'UG', 'avatar_06'),
  ('iremol430', 'PE', 'avatar_16'),
  ('lucas91', 'SE', 'avatar_35'),
  ('ifeanyiwonders', 'NG', 'avatar_52'),
  ('aryanlovesgeo', 'PK', 'avatar_47'),
  ('nunesnun', 'BR', 'avatar_12'),
  ('museumkid33', 'PE', 'avatar_16'),
  ('kasunm', 'BD', 'avatar_15'),
  ('rajatfernando', 'IN', 'avatar_15'),
  ('tuawon2006', 'MY', 'avatar_49'),
  ('isla9', 'AU', 'avatar_53'),
  ('clairewins', 'ZA', 'avatar_16'),
  ('zoee', 'FR', 'avatar_48'),
  ('rehemac', 'KE', 'avatar_46'),
  ('tumelowrites', 'KE', 'avatar_36'),
  ('tanmay', 'LK', 'avatar_11'),
  ('frozenhistorian', 'US', 'avatar_30'),
  ('poppyyy', 'CA', 'avatar_37'),
  ('biogeek', 'SE', 'avatar_53'),
  ('monicax', 'PE', 'avatar_48'),
  ('mauriciosanchez', 'US', 'avatar_56'),
  ('meeramukherjee', 'US', 'avatar_03'),
  ('rafibautista', 'TH', 'avatar_49'),
  ('fmolina', 'AR', 'avatar_05'),
  ('dineshwins', 'IN', 'avatar_38'),
  ('lintse', 'US', 'avatar_09'),
  ('ousmane9', 'US', 'avatar_52'),
  ('crosswordmaster93', 'PK', 'avatar_38'),
  ('jashus007', 'PK', 'avatar_03'),
  ('bravewren', 'HU', 'avatar_13'),
  ('tyrone1', 'NZ', 'avatar_60'),
  ('copperlibrarian', 'GB', 'avatar_32'),
  ('yerinn', 'KR', 'avatar_09'),
  ('urbanotter', 'DK', 'avatar_28'),
  ('kostas87', 'GR', 'avatar_28'),
  ('lancas', 'PH', 'avatar_39'),
  ('rauljr', 'ES', 'avatar_02'),
  ('emilar544', 'DK', 'avatar_32'),
  ('murphyzac', 'NZ', 'avatar_35'),
  ('rnr5', 'ES', 'avatar_53'),
  ('tonyy', 'US', 'avatar_33'),
  ('jelenanagy', 'PL', 'avatar_53'),
  ('vasilisjr', 'GR', 'avatar_12'),
  ('leratoba', 'KE', 'avatar_58'),
  ('realmoussa', 'KE', 'avatar_06'),
  ('mutualovesmap', 'GH', 'avatar_52'),
  ('mvanleeuwen6', 'NL', 'avatar_28'),
  ('violetl2004', 'US', 'avatar_05'),
  ('onlyasli', 'TR', 'avatar_30'),
  ('mrnico', 'CO', 'avatar_13'),
  ('sph90', 'PH', 'avatar_17'),
  ('desaimar', 'IN', 'avatar_03'),
  ('matiascortes', 'CL', 'avatar_21'),
  ('theathinks', 'FI', 'avatar_53'),
  ('ciaraa', 'IE', 'avatar_23'),
  ('gentlebadger', 'HR', 'avatar_56'),
  ('olajuric', 'PL', 'avatar_53'),
  ('paologoh', 'VN', 'avatar_49'),
  ('itsadela', 'PL', 'avatar_13'),
  ('anaaa', 'US', 'avatar_44'),
  ('chiomax', 'KE', 'avatar_40'),
  ('wongsit', 'VN', 'avatar_57'),
  ('imranxo', 'IN', 'avatar_38'),
  ('imtereza', 'GB', 'avatar_53'),
  ('mapgeek3', 'ES', 'avatar_50'),
  ('ofa81', 'GB', 'avatar_29'),
  ('kairuns', 'US', 'avatar_25'),
  ('matteof360', 'IT', 'avatar_02'),
  ('isabellap', 'MX', 'avatar_32'),
  ('mahnoor', 'IN', 'avatar_03'),
  ('deborac', 'BR', 'avatar_13'),
  ('dmytrojr', 'HU', 'avatar_12'),
  ('latingirl8', 'GB', 'avatar_01'),
  ('markuss88', 'DE', 'avatar_12'),
  ('yliang3', 'CN', 'avatar_22'),
  ('ivyhall', 'IE', 'avatar_44'),
  ('phuongp', 'PH', 'avatar_39'),
  ('schmittben', 'DE', 'avatar_12'),
  ('kaisa217', 'FI', 'avatar_05'),
  ('walid87', 'SA', 'avatar_33'),
  ('aaravc', 'GB', 'avatar_15'),
  ('onlyren', 'JP', 'avatar_04'),
  ('meeramishra', 'US', 'avatar_03'),
  ('realanouk', 'NL', 'avatar_05'),
  ('weii', 'CN', 'avatar_31'),
  ('vivian', 'CA', 'avatar_55'),
  ('joacar', 'PT', 'avatar_27'),
  ('solarsage7', 'UA', 'avatar_13'),
  ('solarfalcon', 'BR', 'avatar_13'),
  ('zliu', 'TW', 'avatar_31'),
  ('zainabquizzes', 'GH', 'avatar_23'),
  ('cvm99', 'MX', 'avatar_51'),
  ('raphaelg', 'FR', 'avatar_13'),
  ('adaezeng', 'NG', 'avatar_40'),
  ('klarareads', 'HR', 'avatar_13'),
  ('tfrancois', 'CH', 'avatar_24'),
  ('rafaelquizzes', 'PE', 'avatar_59'),
  ('liviac', 'BR', 'avatar_51'),
  ('fuzzymaple', 'NO', 'avatar_13'),
  ('zhangjason', 'MY', 'avatar_31'),
  ('katya007', 'HR', 'avatar_13'),
  ('ferguswilson', 'NZ', 'avatar_35'),
  ('ewanyt', 'AU', 'avatar_19'),
  ('aditiv29', 'PK', 'avatar_03'),
  ('ignper35', 'MX', 'avatar_02'),
  ('nordicatlas99', 'IN', 'avatar_03'),
  ('iidaa', 'SE', 'avatar_50'),
  ('abhishekm30', 'BD', 'avatar_11'),
  ('joshua', 'PH', 'avatar_49'),
  ('levibyrne', 'GB', 'avatar_36'),
  ('samuelbarros', 'BR', 'avatar_21'),
  ('littledumpling', 'GB', 'avatar_13'),
  ('gretaloveslatin', 'DE', 'avatar_53'),
  ('iamhiwot', 'UG', 'avatar_18'),
  ('gustavomonteiro', 'BR', 'avatar_52'),
  ('patriciamoreira', 'BR', 'avatar_23'),
  ('leowins', 'US', 'avatar_59'),
  ('rainyprofessor', 'HU', 'avatar_12'),
  ('yutonglovesvinyl', 'TW', 'avatar_22'),
  ('svenvanleeuwen', 'NL', 'avatar_12'),
  ('mperera', 'US', 'avatar_15'),
  ('baraka', 'GH', 'avatar_52'),
  ('karan1', 'CA', 'avatar_15'),
  ('gsmith', 'GB', 'avatar_32'),
  ('henrii', 'DE', 'avatar_02'),
  ('mooneunji', 'KR', 'avatar_55'),
  ('zainabmalik', 'LK', 'avatar_26'),
  ('ice92', 'GR', 'avatar_37'),
  ('mauddd', 'NL', 'avatar_05'),
  ('fsilva', 'IN', 'avatar_15'),
  ('musicnerd', 'AT', 'avatar_16'),
  ('veeeri', 'NO', 'avatar_02'),
  ('busrax', 'LB', 'avatar_42'),
  ('zain95', 'BD', 'avatar_38'),
  ('ebbnie', 'SE', 'avatar_32'),
  ('barborawonders', 'RO', 'avatar_44'),
  ('yasminxo', 'BR', 'avatar_10'),
  ('isav2003', 'NL', 'avatar_05'),
  ('gentlebeetle', 'AT', 'avatar_41'),
  ('jakubshevchenko', 'HU', 'avatar_02'),
  ('lucyhq', 'GB', 'avatar_58'),
  ('coleg', 'NZ', 'avatar_41'),
  ('luca94', 'IT', 'avatar_35'),
  ('karolinam', 'RO', 'avatar_05'),
  ('ddesai', 'US', 'avatar_38'),
  ('bartekkrawczyk', 'RS', 'avatar_56'),
  ('humbleprofessor', 'AT', 'avatar_53'),
  ('lilmariana', 'CO', 'avatar_27'),
  ('domsch2000', 'CH', 'avatar_41'),
  ('oletravels', 'AT', 'avatar_28'),
  ('dusanjuric', 'PL', 'avatar_60'),
  ('imzach', 'US', 'avatar_41'),
  ('cxie38', 'CA', 'avatar_55'),
  ('nabilmahmoud', 'EG', 'avatar_08'),
  ('tianaaa', 'US', 'avatar_53'),
  ('shk4', 'FI', 'avatar_32'),
  ('mapgirl', 'AU', 'avatar_13'),
  ('swiftpoet123', 'CL', 'avatar_19'),
  ('casualbaker', 'RO', 'avatar_44'),
  ('beaflores', 'ID', 'avatar_57'),
  ('bighannes', 'DE', 'avatar_60'),
  ('efuaa', 'ET', 'avatar_10'),
  ('amberraven', 'KE', 'avatar_52'),
  ('chilllynx42', 'PH', 'avatar_34'),
  ('ikerr', 'US', 'avatar_41'),
  ('fuzzydolphin', 'US', 'avatar_50'),
  ('yangjr', 'CN', 'avatar_25'),
  ('minhoseo', 'KR', 'avatar_04'),
  ('nina7', 'NL', 'avatar_05'),
  ('realsergio', 'AR', 'avatar_19'),
  ('ksetiawan', 'TH', 'avatar_49'),
  ('valeriav98', 'MX', 'avatar_32'),
  ('denisak', 'CZ', 'avatar_50'),
  ('fernandamartinez', 'ES', 'avatar_27'),
  ('sopbar', 'PT', 'avatar_07'),
  ('viviant1', 'HK', 'avatar_09'),
  ('irynatravels', 'RO', 'avatar_37'),
  ('faisalt', 'PK', 'avatar_47'),
  ('bravequill', 'PH', 'avatar_49'),
  ('niamhh', 'AU', 'avatar_50'),
  ('wuli', 'CA', 'avatar_55'),
  ('minji90', 'KR', 'avatar_09'),
  ('eturner', 'US', 'avatar_48'),
  ('hugoyt', 'ES', 'avatar_21'),
  ('rustyespresso', 'ES', 'avatar_48'),
  ('sokafor', 'TZ', 'avatar_01'),
  ('felipelovescoffee', 'ES', 'avatar_60'),
  ('codyoconnor', 'GB', 'avatar_20'),
  ('thequizbuff88', 'GB', 'avatar_18'),
  ('nazaninthinks', 'NL', 'avatar_42'),
  ('wambuimensah', 'NG', 'avatar_46'),
  ('lunarmonk26', 'NZ', 'avatar_13'),
  ('andredavies', 'GB', 'avatar_20'),
  ('notfarah', 'SA', 'avatar_30'),
  ('saltygecko', 'GH', 'avatar_20'),
  ('nerdyheron', 'JP', 'avatar_31'),
  ('mariamadraws', 'NG', 'avatar_46'),
  ('fionamcr', 'GB', 'avatar_48'),
  ('puzzlejunkie', 'CA', 'avatar_36'),
  ('matthiasmuc', 'DE', 'avatar_13'),
  ('yasmins', 'BR', 'avatar_13'),
  ('yichen', 'TW', 'avatar_31'),
  ('namloveslatin', 'ID', 'avatar_49'),
  ('matteovitale', 'IT', 'avatar_19'),
  ('teamaster', 'SA', 'avatar_30'),
  ('abenaa', 'UG', 'avatar_58'),
  ('lachlanx', 'GB', 'avatar_12'),
  ('latinaddict82', 'SA', 'avatar_42'),
  ('aibrahim95', 'MA', 'avatar_08'),
  ('abbyvan', 'CA', 'avatar_16'),
  ('itzparth', 'PK', 'avatar_38'),
  ('youssef', 'TR', 'avatar_54'),
  ('thidur27', 'FR', 'avatar_24'),
  ('leilax', 'LB', 'avatar_42'),
  ('belendominguez', 'MX', 'avatar_37'),
  ('dineshmehta', 'US', 'avatar_15'),
  ('thebiomaster', 'LK', 'avatar_11'),
  ('drewr', 'US', 'avatar_28'),
  ('brendandraws', 'GB', 'avatar_19'),
  ('elsayedkian', 'US', 'avatar_08'),
  ('ignacioperez', 'ES', 'avatar_60'),
  ('alm23', 'SE', 'avatar_59'),
  ('eetuuu', 'SE', 'avatar_59'),
  ('tesfayex', 'UG', 'avatar_06'),
  ('imeilidh', 'US', 'avatar_18'),
  ('esmeloveshistory', 'US', 'avatar_13'),
  ('wildhistorian84', 'CN', 'avatar_55'),
  ('rohanii', 'IN', 'avatar_15'),
  ('usmann', 'US', 'avatar_11'),
  ('milliet', 'IE', 'avatar_37'),
  ('denisa80', 'RS', 'avatar_44'),
  ('aperera', 'IN', 'avatar_15'),
  ('meganmcr', 'GB', 'avatar_40'),
  ('ichua', 'PH', 'avatar_57'),
  ('dylansmith', 'CA', 'avatar_59'),
  ('rgm45', 'ZA', 'avatar_40'),
  ('lateprofessor', 'IT', 'avatar_13'),
  ('kentayamada', 'JP', 'avatar_43'),
  ('barborajuric', 'RS', 'avatar_48'),
  ('pdk95', 'AT', 'avatar_60'),
  ('alejandra', 'MX', 'avatar_07'),
  ('kostasx', 'GR', 'avatar_13'),
  ('kiaraphilly', 'US', 'avatar_53'),
  ('kwond', 'KR', 'avatar_43'),
  ('lamax', 'LB', 'avatar_30'),
  ('clopes', 'PT', 'avatar_37'),
  ('dimasv', 'ID', 'avatar_49'),
  ('gustavomartinez', 'CL', 'avatar_19'),
  ('ezragallagher', 'US', 'avatar_13'),
  ('netper', 'IL', 'avatar_50'),
  ('mythgeek', 'MY', 'avatar_22'),
  ('serranosan', 'MX', 'avatar_60'),
  ('ahmedbakes', 'SA', 'avatar_54'),
  ('jonaskaiser', 'AT', 'avatar_59'),
  ('sipho336', 'KE', 'avatar_29'),
  ('kavyalovespoetry', 'AE', 'avatar_03'),
  ('adwoan8', 'ZA', 'avatar_58'),
  ('rfraser', 'US', 'avatar_58'),
  ('mdavies', 'GB', 'avatar_58'),
  ('mennalovesmap', 'TR', 'avatar_42'),
  ('talafarouk', 'MA', 'avatar_42'),
  ('danishgupta', 'PK', 'avatar_15'),
  ('agray', 'US', 'avatar_12'),
  ('alh3', 'IE', 'avatar_40'),
  ('hcheung', 'CA', 'avatar_43'),
  ('florencet', 'IE', 'avatar_32'),
  ('lotte23', 'NL', 'avatar_37'),
  ('tanmay466', 'GB', 'avatar_15'),
  ('museumfan', 'DE', 'avatar_13'),
  ('harryryan', 'US', 'avatar_20'),
  ('manishlearns', 'IN', 'avatar_15'),
  ('lolaleroy', 'FR', 'avatar_32'),
  ('rustysailor', 'PL', 'avatar_53'),
  ('ikerj', 'MX', 'avatar_41'),
  ('thechessnerd', 'HR', 'avatar_48'),
  ('tkk6', 'IL', 'avatar_12'),
  ('bongani1995', 'GB', 'avatar_06'),
  ('rekax', 'HR', 'avatar_37'),
  ('thernandez82', 'CO', 'avatar_28'),
  ('walidcherif', 'CA', 'avatar_33'),
  ('saad6', 'IN', 'avatar_11'),
  ('larver21', 'NL', 'avatar_28'),
  ('lostcedar', 'IN', 'avatar_38'),
  ('stefanweber', 'CH', 'avatar_41'),
  ('tpf246', 'BR', 'avatar_52'),
  ('littlenebula3', 'GB', 'avatar_10'),
  ('facundoxd', 'CO', 'avatar_02'),
  ('korhonena', 'SE', 'avatar_13'),
  ('dmitrikrawczyk', 'HR', 'avatar_59'),
  ('devwonders', 'GB', 'avatar_15'),
  ('jasperruns', 'US', 'avatar_02'),
  ('dineshs', 'IN', 'avatar_47'),
  ('elenaparedes', 'ES', 'avatar_51'),
  ('triviahunter', 'US', 'avatar_51'),
  ('onukil', 'EG', 'avatar_08'),
  ('thequizmom', 'TR', 'avatar_30'),
  ('swiftgardener', 'GB', 'avatar_38'),
  ('jonsch6', 'DE', 'avatar_19'),
  ('nordicotter7', 'US', 'avatar_35'),
  ('theokelly', 'US', 'avatar_35'),
  ('rojasu', 'ES', 'avatar_24'),
  ('theresakruger', 'CH', 'avatar_44'),
  ('mmm83', 'HR', 'avatar_59'),
  ('orlaw', 'GB', 'avatar_10'),
  ('hayato360', 'JP', 'avatar_25'),
  ('ljm89', 'FR', 'avatar_10'),
  ('imconstanza', 'US', 'avatar_53'),
  ('judem', 'US', 'avatar_06'),
  ('finnkrause', 'DE', 'avatar_19'),
  ('namaquino', 'TH', 'avatar_49'),
  ('jonasbaumann', 'DE', 'avatar_24'),
  ('tasdhi123', 'IN', 'avatar_26'),
  ('mellowbiscuit1992', 'US', 'avatar_13'),
  ('iamnina', 'BE', 'avatar_53'),
  ('owens', 'GB', 'avatar_59'),
  ('akashverma', 'PK', 'avatar_15'),
  ('kazukihashimoto', 'JP', 'avatar_31'),
  ('rgallagher', 'IE', 'avatar_06'),
  ('casualhedgehog80', 'AE', 'avatar_26'),
  ('thevinyljunkie', 'AU', 'avatar_13'),
  ('jerome69', 'ID', 'avatar_49'),
  ('xwang', 'CN', 'avatar_43'),
  ('ricfue', 'US', 'avatar_19'),
  ('olakucera', 'RS', 'avatar_13'),
  ('salomelovestea', 'CH', 'avatar_30'),
  ('magdaaa', 'RS', 'avatar_50'),
  ('cristiankozlowski', 'RO', 'avatar_28'),
  ('ines07', 'US', 'avatar_48'),
  ('oceane', 'CH', 'avatar_18'),
  ('noudx', 'NL', 'avatar_41'),
  ('poetrymom101', 'BD', 'avatar_38'),
  ('rizkyv6', 'PH', 'avatar_49'),
  ('graceee', 'US', 'avatar_22'),
  ('ewannn', 'NZ', 'avatar_02'),
  ('tobywonders', 'AU', 'avatar_41'),
  ('rlm1', 'US', 'avatar_05'),
  ('swiftcaptain', 'LK', 'avatar_26'),
  ('itsjamie', 'US', 'avatar_29'),
  ('fabiantravels', 'DE', 'avatar_24'),
  ('eitanxo', 'IL', 'avatar_24'),
  ('minggg', 'SG', 'avatar_43'),
  ('nurulvillanueva', 'PH', 'avatar_34'),
  ('martab1995', 'HU', 'avatar_48')
) AS v(handle, country_code, avatar_id)
WHERE public.handle_is_allowed(v.handle)
  AND NOT EXISTS (SELECT 1 FROM public.profiles p WHERE p.handle = v.handle)
ON CONFLICT (handle) DO NOTHING;

-- Le début d'un pseudo, chiffres retirés : deux pseudos qui le partagent se ressemblent.
CREATE OR REPLACE FUNCTION public.duel_bot_stem(p_handle text)
RETURNS text
LANGUAGE sql
IMMUTABLE
SET search_path TO 'public'
AS $$
  SELECT left(regexp_replace(lower(coalesce(p_handle, '')), '[0-9]', '', 'g'), 4);
$$;

REVOKE ALL ON FUNCTION public.duel_bot_stem(text) FROM PUBLIC, anon, authenticated;

-- Tire un adversaire. p_recent : les adversaires déjà rencontrés, du plus récent au plus ancien.
CREATE OR REPLACE FUNCTION public.duel_pick_bot(p_recent int[])
RETURNS public.duel_bots
LANGUAGE plpgsql
VOLATILE
SET search_path TO 'public'
AS $$
DECLARE
  recent int[] := coalesce(p_recent, '{}');
  recent_stems text[];
  recent_countries text[];
  bot public.duel_bots;
BEGIN
  SELECT coalesce(array_agg(DISTINCT public.duel_bot_stem(b.handle)), '{}') INTO recent_stems
    FROM public.duel_bots b WHERE b.id = ANY (recent[1:20]);
  SELECT coalesce(array_agg(DISTINCT b.country_code), '{}') INTO recent_countries
    FROM public.duel_bots b WHERE b.id = ANY (recent[1:2]);

  -- 1. Jamais rencontré récemment, pseudo et pays différents des derniers, pseudo libre.
  SELECT b.* INTO bot
    FROM public.duel_bots b
    WHERE b.active
      AND NOT (b.id = ANY (recent))
      AND NOT (public.duel_bot_stem(b.handle) = ANY (recent_stems))
      AND NOT (b.country_code = ANY (recent_countries))
      AND NOT EXISTS (SELECT 1 FROM public.profiles p WHERE p.handle = b.handle)
    ORDER BY random()
    LIMIT 1;
  IF FOUND THEN
    RETURN bot;
  END IF;

  -- 2. Jamais rencontré récemment.
  SELECT b.* INTO bot
    FROM public.duel_bots b
    WHERE b.active AND NOT (b.id = ANY (recent))
    ORDER BY random()
    LIMIT 1;
  IF FOUND THEN
    RETURN bot;
  END IF;

  -- 3. N'importe lequel, sauf les tout derniers ; puis n'importe lequel.
  SELECT b.* INTO bot
    FROM public.duel_bots b
    WHERE b.active AND NOT (b.id = ANY (recent[1:10]))
    ORDER BY random()
    LIMIT 1;
  IF FOUND THEN
    RETURN bot;
  END IF;

  SELECT b.* INTO bot FROM public.duel_bots b WHERE b.active ORDER BY random() LIMIT 1;
  RETURN bot;
END;
$$;

REVOKE ALL ON FUNCTION public.duel_pick_bot(int[]) FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION public.duel_start_match_v2(p_can_forfeit boolean DEFAULT false)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  uid uuid := auth.uid();
  prof public.duel_profiles;
  bot public.duel_bots;
  bot_accuracy numeric;
  opponent_trophies int;
  opponent jsonb;
  kind_plan text[];
  part text[];
  used text[] := '{}';
  r1 text[] := '{}';
  r2 text[];
  r3 text[];
  r4 text[] := '{}';
  tb_id text;
  subjects text[];
  k int;
  b1 jsonb;
  b2 jsonb;
  b3 jsonb;
  b4 jsonb;
  btb jsonb;
  option_bot jsonb;
  pick_options jsonb := '{}'::jsonb;
  payload_options jsonb := '[]'::jsonb;
  new_id uuid;
  forfeit int;
BEGIN
  IF uid IS NULL THEN
    RAISE EXCEPTION 'not_authenticated';
  END IF;

  prof := public.duel_ensure_profile(uid);
  PERFORM public.duel_resolve_stale(uid, interval '0 seconds');
  SELECT * INTO prof FROM public.duel_profiles WHERE user_id = uid FOR UPDATE;

  -- L'adversaire : jamais un des 150 derniers, ni un @ qui ressemble à ceux qu'on vient de croiser.
  bot := public.duel_pick_bot(prof.recent_bot_ids);
  IF bot.id IS NULL THEN
    RAISE EXCEPTION 'no_opponent';
  END IF;
  opponent_trophies := greatest(0, prof.trophies + round((random() * 2 - 1) * 60)::int);
  opponent := jsonb_build_object(
    'handle', bot.handle,
    'country_code', bot.country_code,
    -- Un adversaire sur dix n'a pas choisi d'avatar : ses initiales, comme un vrai compte neuf.
    -- Toujours les mêmes (selon le pseudo), pour qu'un adversaire recroisé ne change pas de tête.
    'avatar_id', CASE WHEN abs(hashtext(bot.handle)) % 10 = 0 THEN NULL ELSE bot.avatar_id END,
    'trophies', opponent_trophies,
    'league_position', public.duel_league_position(opponent_trophies)
  );

  IF prof.games < 3 THEN
    bot_accuracy := greatest(0.25, prof.accuracy - 0.28);
  ELSE
    bot_accuracy := prof.accuracy - 0.035
      + 0.03 * least(prof.win_streak, 4)
      - 0.04 * least(prof.loss_streak, 3)
      + 0.004 * (public.duel_league_position(prof.trophies) - 1);
  END IF;
  bot_accuracy := greatest(0.20, least(0.95, bot_accuracy));

  -- Manche 1 (mixte), manche 4 (sprint) et question décisive d'abord : elles imposent leurs types.
  FOREACH kind_plan SLICE 1 IN ARRAY ARRAY[['mcq', '2'], ['true_false', '1'], ['portrait', '1'], ['slider', '1']] LOOP
    part := public.duel_pick_questions(prof.level, prof.recent_question_ids, used, NULL, ARRAY[kind_plan[1]], kind_plan[2]::int);
    r1 := r1 || part;
    used := used || part;
  END LOOP;
  FOREACH kind_plan SLICE 1 IN ARRAY ARRAY[['mcq', '3'], ['true_false', '2']] LOOP
    part := public.duel_pick_questions(prof.level, prof.recent_question_ids, used, NULL, ARRAY[kind_plan[1]], kind_plan[2]::int);
    r4 := r4 || part;
    used := used || part;
  END LOOP;
  part := public.duel_pick_questions(prof.level, prof.recent_question_ids, used, NULL, ARRAY['slider'], 1);
  tb_id := part[1];
  used := used || part;
  r1 := public.duel_shuffle(r1);
  r4 := public.duel_shuffle(r4);

  -- Les matières : trois proposées au joueur (manche 2), une choisie par l'adversaire (manche 3).
  SELECT array_agg(s.subject ORDER BY random()) INTO subjects
    FROM (SELECT DISTINCT q.subject FROM public.duel_questions q WHERE q.active AND q.lang = 'en') s;
  IF coalesce(array_length(subjects, 1), 0) < 4 THEN
    RAISE EXCEPTION 'not_enough_questions';
  END IF;
  FOR k IN 1..4 LOOP
    part := public.duel_pick_questions(prof.level, prof.recent_question_ids, used, subjects[k], NULL, 5);
    IF coalesce(array_length(part, 1), 0) < 5 THEN
      RAISE EXCEPTION 'not_enough_questions';
    END IF;
    used := used || part;
    option_bot := public.duel_bot_answers(part, bot_accuracy, prof.level, 1);
    IF k <= 3 THEN
      pick_options := pick_options || jsonb_build_object(subjects[k], jsonb_build_object('ids', to_jsonb(part), 'bot', option_bot));
      payload_options := payload_options || jsonb_build_array(jsonb_build_object(
        'subject', subjects[k],
        'questions', public.duel_questions_json(part, 1),
        'bot', option_bot));
      IF k = 1 THEN
        r2 := part;
        b2 := option_bot;
      END IF;
    ELSE
      r3 := part;
      b3 := option_bot;
    END IF;
  END LOOP;

  IF coalesce(array_length(r1, 1), 0) < 5 OR coalesce(array_length(r4, 1), 0) < 5 OR tb_id IS NULL THEN
    RAISE EXCEPTION 'not_enough_questions';
  END IF;

  b1 := public.duel_bot_answers(r1, bot_accuracy, prof.level, 1);
  b4 := public.duel_bot_answers(r4, bot_accuracy, prof.level, 0.6);
  btb := public.duel_bot_answers(ARRAY[tb_id], bot_accuracy, prof.level, 1) -> 0;

  -- Très rarement (une partie sur quarante, jamais dans les cinq premières), l'adversaire
  -- « se déconnecte » en cours de partie : après la question forfeit (entre la 6e et la 17e),
  -- le joueur gagne par déconnexion. Seulement pour une app qui sait le montrer.
  IF coalesce(p_can_forfeit, false) AND prof.games >= 5 AND random() < 0.025 THEN
    forfeit := 6 + floor(random() * 12)::int;
  END IF;

  -- La partie est enregistrée avec la première matière proposée ; duel_finish_match_v2 la
  -- remplace par celle que le joueur a réellement choisie.
  INSERT INTO public.duel_matches (user_id, bot_id, opponent, question_ids, tiebreak_id, bot_script, trophies_before, rounds, forfeit_at)
  VALUES (uid, bot.id, opponent, r1 || r2 || r3 || r4, tb_id, b1 || b2 || b3 || b4 || jsonb_build_array(btb), prof.trophies,
    jsonb_build_object('pick', jsonb_build_object('round', 2, 'options', pick_options)), forfeit)
  RETURNING id INTO new_id;

  UPDATE public.duel_profiles SET
    recent_bot_ids = (bot.id || recent_bot_ids)[1:150],
    updated_at = now()
  WHERE user_id = uid;

  RETURN jsonb_build_object(
    'match_id', new_id,
    'opponent', opponent,
    'rounds', jsonb_build_array(
      jsonb_build_object('number', 1, 'kind', 'mixed', 'questions', public.duel_questions_json(r1, 1), 'bot', b1),
      jsonb_build_object('number', 2, 'kind', 'pick', 'picker', 'me', 'options', payload_options),
      jsonb_build_object('number', 3, 'kind', 'pick', 'picker', 'opponent', 'subject', subjects[4],
        'questions', public.duel_questions_json(r3, 1), 'bot', b3),
      jsonb_build_object('number', 4, 'kind', 'sprint', 'questions', public.duel_questions_json(r4, 0.6), 'bot', b4)
    ),
    'tiebreak', (SELECT public.duel_question_json(q) FROM public.duel_questions q WHERE q.id = tb_id),
    'tiebreak_bot', btb,
    'opponent_leaves_after', forfeit,
    'search_ms', 2600 + floor(random() * 3200)::int
  );
END;
$$;

REVOKE ALL ON FUNCTION public.duel_start_match_v2(boolean) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.duel_start_match_v2(boolean) TO authenticated;

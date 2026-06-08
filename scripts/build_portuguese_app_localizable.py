#!/usr/bin/env python3
"""Build the Swift body for AppLocalizable.portuguese from the English dictionary."""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "ios/Sophia/Utilities/AppLocalizable.swift"
ENTRY_RE = re.compile(r'^(?P<indent>\s*)"(?P<key>[^"]+)":\s*"(?P<value>(?:[^"\\]|\\.)*)",\s*$')
PLACEHOLDER_RE = re.compile(r'%[@d]')
PROTECTED_SYMBOLS = ("♥", "→", "—", "👏", "🔥")

TRANSLATIONS: dict[str, str] = {
    # Tabs / library
    "tab.home": "Início",
    "tab.library": "Biblioteca",
    "tab.profile": "Perfil",
    "library.title": "Biblioteca",
    "library.tab.courses": "Cursos",
    "library.tab.collections": "Coleções",
    "library.search.placeholder": "Pesquisar um curso...",
    "language.section": "Idioma",
    "language.french": "Français",
    "language.english": "English",
    "language.portuguese": "Português",
    "onboarding.intro.title": "Cultiva-te\nem 10 minutos\npor dia",
    "onboarding.intro.cta": "Começar",

    # Settings
    "settings.title": "Definições",
    "settings.section.progress": "Progresso",
    "settings.section.premium": "Premium",
    "settings.section.data": "Dados",
    "settings.section.legal": "Jurídico",
    "settings.section.about": "Sobre",
    "settings.section.developer": "Programador",
    "settings.courses.completed": "%d cursos concluídos",
    "settings.courses.available": "de %d disponíveis",
    "settings.streak.title": "%d dias seguidos",
    "settings.streak.subtitle": "Continua assim!",
    "settings.premium.title": "Torna-te Premium",
    "settings.premium.subtitle": "Cursos e quizzes ilimitados",
    "settings.reset.title": "Repor progresso",
    "settings.terms.title": "Termos de Serviço",
    "settings.privacy.title": "Política de Privacidade",
    "settings.restore.title": "Restaurar compras",
    "settings.about.version": "Versão",
    "settings.about.courses": "Cursos disponíveis",
    "settings.debug.resetOnboarding": "Reiniciar onboarding",
    "settings.debug.resetDaily": "Repor curso diário",
    "settings.debug.daily.done": "Concluído hoje",
    "settings.debug.daily.pending": "Ainda por concluir",
    "settings.footer": "Feito com ♥ — Sophia",
    "settings.reset.alert.title": "Repor?",
    "settings.reset.alert.cancel": "Cancelar",
    "settings.reset.alert.confirm": "Repor",
    "settings.reset.alert.message": "Todo o teu progresso será apagado. Esta ação não pode ser anulada.",
    "settings.onboarding.alert.title": "Reiniciar onboarding?",
    "settings.onboarding.alert.confirm": "Reiniciar",
    "settings.onboarding.alert.message": "O onboarding vai recomeçar desde o início (apenas DEBUG).",

    # Legal / subjects / rarities
    "legal.terms.title": "Termos",
    "legal.privacy.title": "Privacidade",
    "subject.histoire": "História",
    "subject.sciences": "Ciências",
    "subject.litterature": "Literatura",
    "subject.art": "Arte",
    "subject.mythologie": "Mitologia",
    "subject.comprendreLeMonde": "Compreender o mundo atual",
    "subject.histoire.short": "História",
    "subject.sciences.short": "Ciências",
    "subject.litterature.short": "Literatura",
    "subject.art.short": "Arte",
    "subject.mythologie.short": "Mitologia",
    "subject.comprendreLeMonde.short": "Mundo atual",
    "rarity.commune": "Comum",
    "rarity.rare": "Rara",
    "rarity.epique": "Épica",
    "rarity.legendaire": "Lendária",

    # Home / library
    "home.skip": "Ignorar",
    "home.bravo": "Boa!",
    "home.allCompleted": "Concluíste todos os cursos disponíveis.",
    "home.locked": "Bloqueado",
    "home.start": "Começar",
    "library.empty.title": "Sem resultados",
    "library.empty.subtitle": "Experimenta outra palavra-chave.",
    "library.seeMore": "Ver mais",
    "library.unlock": "Desbloquear",
    "library.lockedBadge": "BLOQUEADO",

    # Collections / cards / common
    "collections.title": "COLEÇÕES",
    "collections.subtitle": "Percursos guiados para ligar ideias entre si.",
    "collections.complete": "Coleção concluída",
    "collections.progress": "%d / %d cursos concluídos",
    "collections.badge.complete": "CONCLUÍDA",
    "collections.badge.path": "PERCURSO",
    "collections.xpAtEnd": "+%d XP no final",
    "collections.pathComplete": "Percurso concluído",
    "subject.courses.count": "%d cursos",
    "subject.completed.singular": "%d concluído",
    "subject.completed.plural": "%d concluídos",
    "cards.collect.title": "CARTAS A COLECIONAR",
    "cards.seeAll": "Ver tudo →",
    "cards.unit": "cartas",
    "cards.empty": "Conclui um curso para desbloqueares as tuas primeiras cartas.",
    "cards.quizStats.title": "QUIZZES CONCLUÍDOS",
    "cards.correctAnswers": "respostas certas",
    "cards.successRate": "taxa de sucesso",
    "cards.myCards": "As minhas cartas",
    "cards.unlocked": "desbloqueadas",
    "cards.unlocked.title": "Carta desbloqueada!",
    "cards.tapToReveal": "Toca para revelar",
    "cards.globalXP": "+%d XP globais",
    "course.keyTakeaway": "A RETER",
    "common.continue": "Continuar",
    "celebration.collectionAdvanced": "Coleção avançada!",
    "celebration.coursesCompleted": "cursos concluídos",
    "celebration.collectionComplete": "Coleção concluída!",
    "common.next": "Seguinte",
    "common.letsGo": "Vamos!",
    "common.letsGoShort": "Vamos",
    "common.close": "Fechar",
    "common.processing": "A processar…",
    "common.startLearning": "Começar a aprender",
    "common.backHome": "Voltar ao início",
    "common.retryQuiz": "Repetir quiz",
    "common.seeMoreArrow": "Ver mais →",
    "common.streak.day": "DIA",
    "common.streak.days": "DIAS",
    "common.levelShort": "NÍV. %d",
    "common.increaseGoal": "Aumentar objetivo",
    "common.decreaseGoal": "Diminuir objetivo",
    "common.miniQuiz": "Miniquiz",
    "common.xpEarned": "+%d XP ganhos",
    "common.xpBeforeNext": "· %d até ao nív. %d",

    # Onboarding
    "onboarding.welcome.title": "Sophia é a tua parceira para dominares",
    "onboarding.welcome.rotating.histoire": "a história",
    "onboarding.welcome.rotating.sciences": "as ciências",
    "onboarding.welcome.rotating.litterature": "a literatura",
    "onboarding.welcome.rotating.art": "a arte",
    "onboarding.welcome.rotating.mythologie": "a mitologia",
    "onboarding.welcome.rotating.comprendreLeMonde": "a atualidade",
    "onboarding.phone.title": "Quanto tempo\npassas ao telemóvel?",
    "onboarding.phone.subtitle": "Em média, por dia.",
    "onboarding.phone.lessThan1h": "Menos de 1h",
    "onboarding.phone.1to2h": "1h a 2h",
    "onboarding.phone.2to4h": "2h a 4h",
    "onboarding.phone.moreThan4h": "Mais de 4h",
    "onboarding.phone.hours.1": "1 hora",
    "onboarding.phone.hours.2": "2 horas",
    "onboarding.phone.hours.3": "3 horas",
    "onboarding.phone.hours.5": "5 horas",
    "onboarding.wasted.intro": "%@ por dia ao telemóvel, isso são",
    "onboarding.wasted.hoursLost": "horas perdidas por ano.",
    "onboarding.wasted.daysComplete": "Isto dá %@ completos.",
    "onboarding.wasted.transform": "Com a Sophia, transforma esse tempo em cultura.",
    "onboarding.wasted.days.7": "7 dias",
    "onboarding.wasted.days.23": "23 dias",
    "onboarding.wasted.days.45": "45 dias",
    "onboarding.wasted.days.91": "91 dias",
    "onboarding.objectives.title": "Qual é o teu objetivo\ncom a Sophia?",
    "onboarding.objectives.subtitle": "Seleciona um ou mais objetivos.",
    "onboarding.objective.curious": "Ser mais curioso",
    "onboarding.objective.learnNew": "Aprender coisas novas",
    "onboarding.objective.impress": "Impressionar quem te rodeia",
    "onboarding.objective.social": "Sentir-te mais à vontade socialmente",
    "onboarding.objective.reduceScroll": "Reduzir o tempo que passas a fazer scroll",
    "onboarding.interests.title": "Que temas\nte interessam?",
    "onboarding.interests.subtitle": "Seleciona pelo menos um tema.",
    "onboarding.dailyGoal.title": "Todos os dias, queres aprender...",
    "onboarding.dailyGoal.subtitle": "Poderás alterar o teu objetivo mais tarde.",
    "onboarding.dailyGoal.perDay": "%@ por dia!",
    "onboarding.dailyGoal.singular": "lição",
    "onboarding.dailyGoal.plural": "lições",
    "onboarding.loading.title": "Estamos a preparar o teu percurso",
    "onboarding.loading.subtitle": "Só alguns segundos, prometemos.",
    "onboarding.loading.step1": "A analisar as tuas respostas",
    "onboarding.loading.step2": "A selecionar as tuas 3 matérias",
    "onboarding.loading.step3": "A preparar o teu percurso",
    "onboarding.projection.line1": "Pequeno hábito,",
    "onboarding.projection.line2": "resultados incríveis.",
    "onboarding.projection.its": "São",
    "onboarding.projection.newThings": "novas coisas que vais saber",
    "onboarding.projection.inOneYear": "dentro de um ano.",
    "onboarding.social.badge": "Avaliações verificadas",
    "onboarding.social.stat": "dos utilizadores sentem-se\nmais interessantes e mais à vontade\nem contextos sociais graças à Sophia.",
    "onboarding.social.review1.name": "Lucas M.",
    "onboarding.social.review1.text": "Antes sentia-me sem cultura geral; agora tenho sempre algo interessante para contar.",
    "onboarding.social.review2.name": "Camille R.",
    "onboarding.social.review2.text": "10 minutos por dia e sinto que aprendo mais do que nas aulas.",
    "onboarding.social.review3.name": "Thomas D.",
    "onboarding.social.review3.text": "Adoro o formato. É claro, rápido e retenho mesmo o que aprendo.",
    "onboarding.graph.title": "A tua progressão\ncultural",
    "onboarding.graph.subtitle": "Com e sem Sophia",
    "onboarding.graph.culture": "CULTURA",
    "onboarding.graph.withSophia": "Com Sophia",
    "onboarding.graph.withoutSophia": "Sem Sophia",
    "onboarding.graph.today": "Hoje",
    "onboarding.graph.oneYear": "1 ano",
    "onboarding.graph.tagline": "A Sophia acelera a tua cultura\nde forma exponencial.",
    "onboarding.final.title": "Perfil pronto!",
    "onboarding.final.subtitle": "Boas-vindas à Sophia.\nComeça já a aprender.",
    "onboarding.final.subjects": "AS TUAS MATÉRIAS",
    "onboarding.trial.badge": "Oferta de boas-vindas",
    "onboarding.trial.title": "Os teus primeiros 3 dias\nsão grátis",
    "onboarding.trial.unlimitedCourses": "Cursos ilimitados",
    "onboarding.trial.allQuizzes": "Todos os quizzes",
    "onboarding.trial.noSurprise": "Sem surpresas",
    "onboarding.trial.notifyTitle": "Vamos avisar-te\n1 dia antes do fim\ndo teu teste gratuito",
    "onboarding.trial.cancelAnytime": "Cancela a qualquer momento, sem custos.",
    "onboarding.trial.day1": "DIA 1",
    "onboarding.trial.day2": "DIA 2",
    "onboarding.trial.day3": "DIA 3",
    "onboarding.trial.fullAccess": "Acesso total",
    "onboarding.trial.notificationSent": "Notificação enviada",
    "onboarding.trial.trialEnds": "Fim do teste",

    # Paywall / offer / profile
    "paywall.cancelAnytime": "Cancela a qualquer momento, sem custos.",
    "paywall.header": "Torna-te a pessoa\nmais interessante\nda sala.",
    "paywall.freeSubjects": "As tuas 3 matérias gratuitas",
    "paywall.lockedSubjects": "3 matérias por desbloquear",
    "paywall.teaserTitle": "Uma amostra do que te espera",
    "paywall.teaserSubtitle": "Centenas de cursos premium por desbloquear",
    "paywall.featureColumn": "Funcionalidade",
    "paywall.freeColumn": "Grátis",
    "paywall.premiumColumn": "Premium",
    "paywall.feature.3subjects": "3 matérias",
    "paywall.feature.allSubjects": "Todas as matérias",
    "paywall.feature.unlimitedCourses": "Cursos ilimitados",
    "paywall.feature.miniQuiz": "Miniquiz",
    "paywall.feature.fullLibrary": "Biblioteca completa",
    "paywall.plan.yearly": "Anual",
    "paywall.plan.monthly": "Mensal",
    "paywall.plan.yearlySubtitle": "Cobrado anualmente",
    "paywall.plan.monthlySubtitle": "Sem fidelização",
    "paywall.plan.perYear": "/ ano",
    "paywall.plan.perMonth": "/ mês",
    "paywall.plan.discount": "-58%",
    "paywall.plan.fallback.yearlyPrice": "39,99 €",
    "paywall.plan.fallback.monthlyPrice": "9,99 €",
    "paywall.plan.fallback.yearlyMonthly": "3,33 € / mês",
    "paywall.trialBadge": "Teste gratuito de 3 dias",
    "paywall.restoreRow": "Restaurar · Termos · Privacidade",
    "paywall.trialSheet.title": "Começa o teu\nteste gratuito de 3 dias",
    "paywall.trialSheet.start": "Começar teste gratuito",
    "paywall.trial.today": "Hoje",
    "paywall.trial.noPayment": "Sem pagamento",
    "paywall.trial.todayDetail": "Acesso a todas as funcionalidades Premium.",
    "paywall.trial.in2days": "Daqui a 2 dias",
    "paywall.trial.reminder": "Avisamos-te",
    "paywall.trial.reminderDetail": "Notificação 1 dia antes do fim do teste.",
    "paywall.trial.in3days": "Daqui a 3 dias",
    "paywall.trial.starts": "A tua subscrição começa",
    "paywall.trial.startsDetail": "Cancela antes se não quiseres continuar.",
    "paywall.review1.quote": "Perfeito para as deslocações. Aprendo todos os dias sem esforço.",
    "paywall.review1.author": "Marie, 28",
    "paywall.review2.quote": "Finalmente uma app que transforma scroll em cultura.",
    "paywall.review2.author": "Thomas, 34",
    "paywall.review3.quote": "Os cursos são curtos, divertidos e eu retenho mesmo.",
    "paywall.review3.author": "Inès, 22",
    "paywall.review4.quote": "Os meus amigos perguntam-me de onde tiro estas histórias todas.",
    "paywall.review4.author": "Lucas, 31",
    "paywall.review5.quote": "O onboarding personalizado convenceu-me logo no primeiro minuto.",
    "paywall.review5.author": "Sarah, 26",
    "offer.unique": "A tua oferta única",
    "offer.discount": "-70% PARA SEMPRE",
    "offer.perMonth": "/mês",
    "offer.billed": "cobrado",
    "offer.expiresIn": "Expira em",
    "offer.unlock": "Desbloquear o meu acesso -70%",
    "offer.restore": "Restaurar compras",
    "offer.feature1": "240 cursos de cultura geral",
    "offer.feature2": "Quizzes interativos ilimitados",
    "offer.feature3": "Novo conteúdo todas as semanas",
    "profile.title": "Perfil",
    "profile.streak.start": "Lê um curso para começares!",
    "profile.streak.beginning": "Já começaste, continua!",
    "profile.streak.good": "Boa consistência 👏",
    "profile.streak.great": "Estás imparável 🔥",
    "profile.favorites": "Os meus favoritos",
    "profile.favorites.count": "%d cursos guardados",
    "profile.quiz.recent": "QUIZZES RECENTES",
    "profile.quiz.locked": "Quizzes bloqueados",
    "profile.quiz.lockedSubtitle": "Disponíveis com o teste gratuito — 3 dias grátis",
    "profile.quiz.unlock": "Desbloquear os meus quizzes",
    "profile.quiz.emptyTitle": "Ainda não há quizzes",
    "profile.quiz.emptySubtitle": "Conclui um curso para fazeres o teu primeiro quiz.",
    "profile.progress.bySubject": "PROGRESSO POR MATÉRIA",
    "profile.unlock.trial": "Desbloqueia com o teste gratuito",
    "profile.quiz.retry": "Repetir",
    "profile.quiz.all": "Todos os meus quizzes",
    "profile.quiz.none": "Ainda não há quizzes.",
    "profile.progress.max": "%d XP · nível máximo",
    "profile.progress.toNext": "%d XP · %d até ao nív. %d",

    # Quiz / course / ranks
    "quiz.feedback.correct": "Correto!",
    "quiz.feedback.excellent": "Excelente!",
    "quiz.feedback.amazing": "Incrível!",
    "quiz.feedback.wrong": "Quase...",
    "quiz.completed": "Boa, quiz concluído!",
    "quiz.correctAnswers": "respostas certas",
    "quiz.xpProgress": "Progresso de XP",
    "quiz.levelUp": "Subiste de nível!",
    "quiz.breakdown.correct": "Respostas certas",
    "quiz.breakdown.completed": "Quiz concluído",
    "quiz.xpProgress.max": "%d XP · nível máximo",
    "quiz.xpProgress.toNext": "%d XP até ao nív. %d",
    "course.completed": "Curso concluído!",
    "course.dailyFreeDone": "Concluíste o teu curso gratuito de hoje",
    "course.streak.day": "Dia seguido",
    "course.streak.days": "Dias seguidos",
    "course.streak.message": "Estás mesmo a tornar-te culto — vais ficar imbatível em %@!",
    "course.streak.onTrack": "No bom caminho para a tua sequência!",
    "prepaywall.quiz.title": "Desbloqueia gratuitamente\nos quizzes",
    "prepaywall.quiz.subtitle": "Testa os teus conhecimentos e\nprogride todos os dias",
    "prepaywall.course.subtitle": "Continua a aprender e\ndescobre novos temas",
    "prepaywall.course.access": "Aceder ao curso",
    "levelUp.title": "Subiste de nível!",
    "globalRank.curieux": "Curioso",
    "globalRank.erudit": "Erudito",
    "globalRank.savant": "Sábio",
    "globalRank.maitre": "Mestre",
    "globalRank.legende": "Lenda",
    "globalRank.title": "Classificação global",
    "globalRank.badge": "CLASSIFICAÇÃO GLOBAL",
    "globalRank.maxLevel": "Nível máximo",
    "globalRank.xpBefore": "%d XP até %@",
    "globalRank.newRank": "Novo estatuto!",
    "globalRank.reachedLevel": "Acabaste de alcançar o nível %d",
    "paywall.unavailable.title": "Oferta indisponível",
    "paywall.unavailable.message": "Não foi possível carregar esta oferta neste momento.",
}


def decode_swift_string(raw: str) -> str:
    chars: list[str] = []
    index = 0
    while index < len(raw):
        char = raw[index]
        if char != "\\":
            chars.append(char)
            index += 1
            continue
        index += 1
        if index >= len(raw):
            chars.append("\\")
            break
        escaped = raw[index]
        chars.append(
            {
                "n": "\n",
                "r": "\r",
                "t": "\t",
                '"': '"',
                "\\": "\\",
            }.get(escaped, escaped)
        )
        index += 1
    return "".join(chars)


def escape_swift_string(value: str) -> str:
    return (
        value.replace("\\", "\\\\")
        .replace('"', '\\"')
        .replace("\n", "\\n")
        .replace("\r", "\\r")
        .replace("\t", "\\t")
    )


def extract_english_body(source: str) -> list[dict[str, str | None]]:
    match = re.search(
        r"private static let english: \[String: String\] = \[(?P<body>.*?)^\s*\]",
        source,
        re.S | re.M,
    )
    if not match:
        raise SystemExit("Could not locate the English dictionary in AppLocalizable.swift")

    body = match.group("body").strip("\n")
    lines = body.splitlines()
    parsed: list[dict[str, str | None]] = []
    for line in lines:
        if not line.strip():
            parsed.append({"kind": "blank", "indent": None, "key": None, "value": None})
            continue
        entry = ENTRY_RE.match(line)
        if not entry:
            raise SystemExit(f"Unrecognized English dictionary line: {line}")
        parsed.append(
            {
                "kind": "entry",
                "indent": entry.group("indent"),
                "key": entry.group("key"),
                "value": decode_swift_string(entry.group("value")),
            }
        )
    return parsed


def validate_translations(parsed_lines: list[dict[str, str | None]]) -> None:
    english = {line["key"]: line["value"] for line in parsed_lines if line["kind"] == "entry"}
    english_keys = set(english)
    translation_keys = set(TRANSLATIONS)

    missing = sorted(english_keys - translation_keys)
    extras = sorted(translation_keys - english_keys)
    if missing or extras:
        details: list[str] = []
        if missing:
            details.append(f"Missing translations ({len(missing)}): {', '.join(missing)}")
        if extras:
            details.append(f"Unexpected translation keys ({len(extras)}): {', '.join(extras)}")
        raise SystemExit("\n".join(details))

    issues: list[str] = []
    for key, english_value in english.items():
        portuguese_value = TRANSLATIONS[key]
        if PLACEHOLDER_RE.findall(english_value or "") != PLACEHOLDER_RE.findall(portuguese_value):
            issues.append(f"Placeholder mismatch for {key!r}: {english_value!r} -> {portuguese_value!r}")
        if (english_value or "").count("\n") != portuguese_value.count("\n"):
            issues.append(f"Line break mismatch for {key!r}: {english_value!r} -> {portuguese_value!r}")
        for symbol in PROTECTED_SYMBOLS:
            if (english_value or "").count(symbol) != portuguese_value.count(symbol):
                issues.append(f"Protected symbol mismatch for {key!r}: missing or altered {symbol!r}")
    if issues:
        raise SystemExit("\n".join(issues))


def render_body(parsed_lines: list[dict[str, str | None]]) -> str:
    output: list[str] = []
    for line in parsed_lines:
        if line["kind"] == "blank":
            output.append("")
            continue
        key = str(line["key"])
        indent = str(line["indent"])
        output.append(f'{indent}"{key}": "{escape_swift_string(TRANSLATIONS[key])}",')
    return "\n".join(output)


def main() -> None:
    parsed_lines = extract_english_body(SOURCE.read_text(encoding="utf-8"))
    validate_translations(parsed_lines)
    print(render_body(parsed_lines))


if __name__ == "__main__":
    try:
        main()
    except BrokenPipeError:
        sys.exit(0)

#!/usr/bin/env python3

from __future__ import annotations

import json
import re
import sys
from pathlib import Path


SOURCE_FILE = Path("/workspace/ios/Sophia/Utilities/AppLocalizable.swift")
ENTRY_RE = re.compile(r'^\s*"((?:\\.|[^"\\])*)":\s*"((?:\\.|[^"\\])*)",\s*$')
PLACEHOLDER_RE = re.compile(r"%(?:\d+\$)?[@df]")
SYMBOLS_TO_PRESERVE = ("♥", "→", "—", "👏", "🔥", "…", "·")


TRANSLATIONS = {
    "tab.home": "Inicio",
    "tab.library": "Biblioteca",
    "tab.profile": "Perfil",

    "library.title": "Biblioteca",
    "library.tab.courses": "Cursos",
    "library.tab.collections": "Colecciones",
    "library.search.placeholder": "Buscar un curso...",

    "language.section": "Idioma",
    "language.french": "Français",
    "language.english": "English",
    "language.spanish": "Español",

    "onboarding.intro.title": "Cultívate\nen 10 minutos\nal día",
    "onboarding.intro.cta": "Empezar",

    "settings.title": "Ajustes",
    "settings.section.progress": "Progreso",
    "settings.section.premium": "Premium",
    "settings.section.data": "Datos",
    "settings.section.legal": "Legal",
    "settings.section.about": "Acerca de",
    "settings.section.developer": "Desarrollador",
    "settings.courses.completed": "%d cursos completados",
    "settings.courses.available": "de %d disponibles",
    "settings.streak.title": "Racha de %d días",
    "settings.streak.subtitle": "¡Sigue así!",
    "settings.premium.title": "Hazte Premium",
    "settings.premium.subtitle": "Cursos y quizzes ilimitados",
    "settings.reset.title": "Restablecer progreso",
    "settings.terms.title": "Términos del servicio",
    "settings.privacy.title": "Política de privacidad",
    "settings.restore.title": "Restaurar compras",
    "settings.about.version": "Versión",
    "settings.about.courses": "Cursos disponibles",
    "settings.debug.resetOnboarding": "Reiniciar onboarding",
    "settings.debug.resetDaily": "Restablecer curso diario",
    "settings.debug.daily.done": "Hecho hoy",
    "settings.debug.daily.pending": "Aún no hecho",
    "settings.footer": "Hecho con ♥ — Sophia",
    "settings.reset.alert.title": "¿Restablecer?",
    "settings.reset.alert.cancel": "Cancelar",
    "settings.reset.alert.confirm": "Restablecer",
    "settings.reset.alert.message": "Todo tu progreso se borrará. Esta acción no se puede deshacer.",
    "settings.onboarding.alert.title": "¿Reiniciar onboarding?",
    "settings.onboarding.alert.confirm": "Reiniciar",
    "settings.onboarding.alert.message": "El onboarding volverá a empezar desde el principio (solo DEBUG).",

    "legal.terms.title": "Términos",
    "legal.privacy.title": "Privacidad",

    "subject.histoire": "Historia",
    "subject.sciences": "Ciencias",
    "subject.litterature": "Literatura",
    "subject.art": "Arte",
    "subject.mythologie": "Mitología",
    "subject.comprendreLeMonde": "Comprender el mundo actual",
    "subject.histoire.short": "Historia",
    "subject.sciences.short": "Ciencias",
    "subject.litterature.short": "Literatura",
    "subject.art.short": "Arte",
    "subject.mythologie.short": "Mitología",
    "subject.comprendreLeMonde.short": "Actualidad",

    "rarity.commune": "Común",
    "rarity.rare": "Rara",
    "rarity.epique": "Épica",
    "rarity.legendaire": "Legendaria",

    "home.skip": "Saltar",
    "home.bravo": "¡Bravo!",
    "home.allCompleted": "Has completado todos los cursos disponibles.",
    "home.locked": "Bloqueado",
    "home.start": "Empezar",

    "library.empty.title": "Sin resultados",
    "library.empty.subtitle": "Prueba con otra palabra clave.",
    "library.seeMore": "Ver más",
    "library.unlock": "Desbloquear",
    "library.lockedBadge": "BLOQUEADO",

    "collections.title": "COLECCIONES",
    "collections.subtitle": "Recorridos guiados para conectar ideas.",
    "collections.complete": "Colección completada",
    "collections.progress": "%d / %d cursos completados",
    "collections.badge.complete": "COMPLETADA",
    "collections.badge.path": "RECORRIDO",
    "collections.xpAtEnd": "+%d XP al final",
    "collections.pathComplete": "Recorrido completado",

    "subject.courses.count": "%d cursos",
    "subject.completed.singular": "%d completado",
    "subject.completed.plural": "%d completados",

    "cards.collect.title": "CARTAS PARA COLECCIONAR",
    "cards.seeAll": "Ver todo →",
    "cards.unit": "cartas",
    "cards.empty": "Completa un curso para desbloquear tus primeras cartas.",
    "cards.quizStats.title": "QUIZZES SUPERADOS",
    "cards.correctAnswers": "respuestas correctas",
    "cards.successRate": "tasa de acierto",
    "cards.myCards": "Mis cartas",
    "cards.unlocked": "desbloqueadas",
    "cards.unlocked.title": "¡Carta desbloqueada!",
    "cards.tapToReveal": "Toca para revelar",
    "cards.globalXP": "+%d XP global",

    "course.keyTakeaway": "IDEA CLAVE",

    "common.continue": "Continuar",

    "celebration.collectionAdvanced": "¡Has avanzado en la colección!",
    "celebration.coursesCompleted": "cursos completados",
    "celebration.collectionComplete": "¡Colección completada!",

    "common.next": "Siguiente",
    "common.letsGo": "¡Vamos!",
    "common.letsGoShort": "Vamos",
    "common.close": "Cerrar",
    "common.processing": "Procesando…",
    "common.startLearning": "Empezar a aprender",
    "common.backHome": "Volver al inicio",
    "common.retryQuiz": "Repetir quiz",
    "common.seeMoreArrow": "Ver más →",
    "common.streak.day": "DÍA",
    "common.streak.days": "DÍAS",
    "common.levelShort": "NIV. %d",
    "common.increaseGoal": "Aumentar objetivo",
    "common.decreaseGoal": "Reducir objetivo",
    "common.miniQuiz": "Mini Quiz",
    "common.xpEarned": "+%d XP ganados",
    "common.xpBeforeNext": "· %d para niv. %d",

    "onboarding.welcome.title": "Sophia es tu aliado para dominar",
    "onboarding.welcome.rotating.histoire": "la historia",
    "onboarding.welcome.rotating.sciences": "la ciencia",
    "onboarding.welcome.rotating.litterature": "la literatura",
    "onboarding.welcome.rotating.art": "el arte",
    "onboarding.welcome.rotating.mythologie": "la mitología",
    "onboarding.welcome.rotating.comprendreLeMonde": "la actualidad",

    "onboarding.phone.title": "¿Cuánto tiempo\npasas con tu teléfono?",
    "onboarding.phone.subtitle": "Cada día, en promedio.",
    "onboarding.phone.lessThan1h": "Menos de 1h",
    "onboarding.phone.1to2h": "1h a 2h",
    "onboarding.phone.2to4h": "2h a 4h",
    "onboarding.phone.moreThan4h": "Más de 4h",
    "onboarding.phone.hours.1": "1 hora",
    "onboarding.phone.hours.2": "2 horas",
    "onboarding.phone.hours.3": "3 horas",
    "onboarding.phone.hours.5": "5 horas",

    "onboarding.wasted.intro": "%@ al día en tu teléfono son",
    "onboarding.wasted.hoursLost": "horas perdidas al año.",
    "onboarding.wasted.daysComplete": "Eso equivale a %@ completos.",
    "onboarding.wasted.transform": "Con Sophia, convierte ese tiempo en cultura.",
    "onboarding.wasted.days.7": "7 días",
    "onboarding.wasted.days.23": "23 días",
    "onboarding.wasted.days.45": "45 días",
    "onboarding.wasted.days.91": "91 días",

    "onboarding.objectives.title": "¿Cuál es tu objetivo\ncon Sophia?",
    "onboarding.objectives.subtitle": "Selecciona uno o varios objetivos.",
    "onboarding.objective.curious": "Ser más curioso",
    "onboarding.objective.learnNew": "Aprender cosas nuevas",
    "onboarding.objective.impress": "Impresionar a quienes te rodean",
    "onboarding.objective.social": "Sentirte más cómodo socialmente",
    "onboarding.objective.reduceScroll": "Pasar menos tiempo haciendo scroll",

    "onboarding.interests.title": "¿Qué temas\nte interesan?",
    "onboarding.interests.subtitle": "Selecciona al menos un tema.",

    "onboarding.dailyGoal.title": "Cada día, quieres aprender...",
    "onboarding.dailyGoal.subtitle": "Podrás cambiar tu objetivo más adelante.",
    "onboarding.dailyGoal.perDay": "%@ al día!",
    "onboarding.dailyGoal.singular": "lección",
    "onboarding.dailyGoal.plural": "lecciones",

    "onboarding.loading.title": "Estamos preparando tu recorrido",
    "onboarding.loading.subtitle": "Solo unos segundos, lo prometemos.",
    "onboarding.loading.step1": "Analizando tus respuestas",
    "onboarding.loading.step2": "Seleccionando tus 3 materias",
    "onboarding.loading.step3": "Preparando tu recorrido",

    "onboarding.projection.line1": "Un pequeño hábito,",
    "onboarding.projection.line2": "resultados increíbles.",
    "onboarding.projection.its": "Son",
    "onboarding.projection.newThings": "cosas nuevas que sabrás",
    "onboarding.projection.inOneYear": "en un año.",

    "onboarding.social.badge": "Opiniones verificadas",
    "onboarding.social.stat": "de los usuarios se sienten\nmás interesantes y cómodos\nen sociedad gracias a Sophia.",
    "onboarding.social.review1.name": "Lucas M.",
    "onboarding.social.review1.text": "Antes me sentía perdido en cultura general; ahora siempre tengo algo interesante que contar.",
    "onboarding.social.review2.name": "Camille R.",
    "onboarding.social.review2.text": "10 minutos al día y siento que aprendo más que en clase.",
    "onboarding.social.review3.name": "Thomas D.",
    "onboarding.social.review3.text": "Me encanta el formato. Es claro, rápido y de verdad se me queda.",

    "onboarding.graph.title": "Tu progreso\ncultural",
    "onboarding.graph.subtitle": "Con y sin Sophia",
    "onboarding.graph.culture": "CULTURA",
    "onboarding.graph.withSophia": "Con Sophia",
    "onboarding.graph.withoutSophia": "Sin Sophia",
    "onboarding.graph.today": "Hoy",
    "onboarding.graph.oneYear": "1 año",
    "onboarding.graph.tagline": "Sophia acelera tu cultura\nde forma exponencial.",

    "onboarding.final.title": "¡Tu perfil está listo!",
    "onboarding.final.subtitle": "Bienvenido a Sophia.\nEmpieza a aprender ahora mismo.",
    "onboarding.final.subjects": "TUS MATERIAS",

    "onboarding.trial.badge": "Oferta de bienvenida",
    "onboarding.trial.title": "Tus primeros 3 días\nson gratis",
    "onboarding.trial.unlimitedCourses": "Cursos ilimitados",
    "onboarding.trial.allQuizzes": "Todos los quizzes",
    "onboarding.trial.noSurprise": "Sin sorpresas",
    "onboarding.trial.notifyTitle": "Te avisaremos\n1 día antes de que termine\ntu prueba gratuita",
    "onboarding.trial.cancelAnytime": "Cancela en cualquier momento, sin costo.",
    "onboarding.trial.day1": "DÍA 1",
    "onboarding.trial.day2": "DÍA 2",
    "onboarding.trial.day3": "DÍA 3",
    "onboarding.trial.fullAccess": "Acceso completo",
    "onboarding.trial.notificationSent": "Notificación enviada",
    "onboarding.trial.trialEnds": "Termina la prueba",

    "paywall.cancelAnytime": "Cancela en cualquier momento, sin costo.",
    "paywall.header": "Conviértete en la persona\nmás interesante\ndel lugar.",
    "paywall.freeSubjects": "Tus 3 materias gratis",
    "paywall.lockedSubjects": "3 materias por desbloquear",
    "paywall.teaserTitle": "Un adelanto de lo que viene",
    "paywall.teaserSubtitle": "Cientos de cursos premium por desbloquear",
    "paywall.featureColumn": "Función",
    "paywall.freeColumn": "Gratis",
    "paywall.premiumColumn": "Premium",
    "paywall.feature.3subjects": "3 materias",
    "paywall.feature.allSubjects": "Todas las materias",
    "paywall.feature.unlimitedCourses": "Cursos ilimitados",
    "paywall.feature.miniQuiz": "Mini Quiz",
    "paywall.feature.fullLibrary": "Biblioteca completa",
    "paywall.plan.yearly": "Anual",
    "paywall.plan.monthly": "Mensual",
    "paywall.plan.yearlySubtitle": "Facturado anualmente",
    "paywall.plan.monthlySubtitle": "Sin compromiso",
    "paywall.plan.perYear": "/ año",
    "paywall.plan.perMonth": "/ mes",
    "paywall.plan.discount": "-58%",
    "paywall.plan.fallback.yearlyPrice": "€39.99",
    "paywall.plan.fallback.monthlyPrice": "€9.99",
    "paywall.plan.fallback.yearlyMonthly": "€3.33 / mes",
    "paywall.trialBadge": "Prueba gratis de 3 días",
    "paywall.restoreRow": "Restaurar · Términos · Privacidad",
    "paywall.trialSheet.title": "Empieza tu\nprueba gratis de 3 días",
    "paywall.trialSheet.start": "Iniciar prueba gratis",
    "paywall.trial.today": "Hoy",
    "paywall.trial.noPayment": "Sin cargo",
    "paywall.trial.todayDetail": "Acceso a todas las funciones Premium.",
    "paywall.trial.in2days": "En 2 días",
    "paywall.trial.reminder": "Te avisaremos",
    "paywall.trial.reminderDetail": "Notificación 1 día antes de que termine la prueba.",
    "paywall.trial.in3days": "En 3 días",
    "paywall.trial.starts": "Empieza tu suscripción",
    "paywall.trial.startsDetail": "Cancela antes si no quieres continuar.",
    "paywall.review1.quote": "Perfecta para mis trayectos. Aprendo cada día sin esfuerzo.",
    "paywall.review1.author": "Marie, 28",
    "paywall.review2.quote": "Por fin una app que convierte el scroll en cultura.",
    "paywall.review2.author": "Thomas, 34",
    "paywall.review3.quote": "Los cursos son cortos, entretenidos y de verdad los recuerdo.",
    "paywall.review3.author": "Inès, 22",
    "paywall.review4.quote": "Mis amigos me preguntan de dónde saco tantas anécdotas.",
    "paywall.review4.author": "Lucas, 31",
    "paywall.review5.quote": "El onboarding personalizado me convenció desde el primer minuto.",
    "paywall.review5.author": "Sarah, 26",

    "offer.unique": "Tu oferta única",
    "offer.discount": "-70% PARA SIEMPRE",
    "offer.perMonth": "/mes",
    "offer.billed": "facturado",
    "offer.expiresIn": "Expira en",
    "offer.unlock": "Desbloquear mi acceso con -70%",
    "offer.restore": "Restaurar compras",
    "offer.feature1": "240 cursos de cultura general",
    "offer.feature2": "Quizzes interactivos ilimitados",
    "offer.feature3": "Nuevo contenido cada semana",

    "profile.title": "Perfil",
    "profile.streak.start": "¡Lee un curso para empezar!",
    "profile.streak.beginning": "¡Ya empezaste, sigue así!",
    "profile.streak.good": "Gran constancia 👏",
    "profile.streak.great": "¡Estás imparable! 🔥",
    "profile.favorites": "Mis favoritos",
    "profile.favorites.count": "%d cursos guardados",
    "profile.quiz.recent": "QUIZZES RECIENTES",
    "profile.quiz.locked": "Quizzes bloqueados",
    "profile.quiz.lockedSubtitle": "Disponibles con la prueba gratis — 3 días gratis",
    "profile.quiz.unlock": "Desbloquear mis quizzes",
    "profile.quiz.emptyTitle": "Aún no hay quizzes",
    "profile.quiz.emptySubtitle": "Completa un curso para hacer tu primer quiz.",
    "profile.progress.bySubject": "PROGRESO POR TEMA",
    "profile.unlock.trial": "Desbloquear con prueba gratis",
    "profile.quiz.retry": "Repetir",
    "profile.quiz.all": "Todos mis quizzes",
    "profile.quiz.none": "Aún no hay quizzes.",
    "profile.progress.max": "%d XP · nivel máximo",
    "profile.progress.toNext": "%d XP · %d para niv. %d",

    "quiz.feedback.correct": "¡Correcto!",
    "quiz.feedback.excellent": "¡Excelente!",
    "quiz.feedback.amazing": "¡Increíble!",
    "quiz.feedback.wrong": "Casi...",
    "quiz.completed": "¡Bien hecho, quiz completado!",
    "quiz.correctAnswers": "respuestas correctas",
    "quiz.xpProgress": "Progreso XP",
    "quiz.levelUp": "¡Subes de nivel!",
    "quiz.breakdown.correct": "Respuestas correctas",
    "quiz.breakdown.completed": "Quiz completado",
    "quiz.xpProgress.max": "%d XP · nivel máximo",
    "quiz.xpProgress.toNext": "%d XP para niv. %d",

    "course.completed": "¡Lección completada!",
    "course.dailyFreeDone": "Has completado tu curso gratis de hoy",
    "course.streak.day": "Día seguido",
    "course.streak.days": "Días seguidos",
    "course.streak.message": "De verdad te estás cultivando — ¡ya eres imparable en %@!",
    "course.streak.onTrack": "¡Vas por tu racha!",

    "prepaywall.quiz.title": "Desbloquea los quizzes\ngratis",
    "prepaywall.quiz.subtitle": "Pon a prueba tus conocimientos y\navanza cada día",
    "prepaywall.course.subtitle": "Sigue aprendiendo y\ndescubre nuevos temas",
    "prepaywall.course.access": "Acceder al curso",

    "levelUp.title": "¡Subes de nivel!",

    "globalRank.curieux": "Curioso",
    "globalRank.erudit": "Erudito",
    "globalRank.savant": "Sabio",
    "globalRank.maitre": "Maestro",
    "globalRank.legende": "Leyenda",
    "globalRank.title": "Rango global",
    "globalRank.badge": "RANGO GLOBAL",
    "globalRank.maxLevel": "Nivel máximo",
    "globalRank.xpBefore": "%d XP para %@",
    "globalRank.newRank": "¡Nuevo rango!",
    "globalRank.reachedLevel": "Acabas de llegar al nivel %d",

    "paywall.unavailable.title": "Oferta no disponible",
    "paywall.unavailable.message": "No se puede cargar esta oferta en este momento.",
}


def swift_unescape(value: str) -> str:
    pieces: list[str] = []
    i = 0
    replacements = {
        "n": "\n",
        "r": "\r",
        "t": "\t",
        '"': '"',
        "\\": "\\",
    }
    while i < len(value):
        char = value[i]
        if char != "\\":
            pieces.append(char)
            i += 1
            continue

        i += 1
        if i >= len(value):
            raise ValueError(f"Invalid trailing escape in {value!r}")

        escaped = value[i]
        i += 1
        pieces.append(replacements.get(escaped, escaped))

    return "".join(pieces)


def swift_literal(value: str) -> str:
    return json.dumps(value, ensure_ascii=False)


def parse_english_tokens(path: Path) -> list[tuple[str, str, str] | tuple[str]]:
    lines = path.read_text(encoding="utf-8").splitlines()
    in_english = False
    tokens: list[tuple[str, str, str] | tuple[str]] = []

    for line in lines:
        if not in_english:
            if "private static let english" in line:
                in_english = True
            continue

        stripped = line.strip()
        if stripped == "]":
            break

        if not stripped:
            if tokens and tokens[-1][0] != "blank":
                tokens.append(("blank",))
            continue

        match = ENTRY_RE.match(line)
        if not match:
            raise ValueError(f"Could not parse English entry line: {line}")

        key = swift_unescape(match.group(1))
        value = swift_unescape(match.group(2))
        tokens.append(("entry", key, value))

    while tokens and tokens[-1][0] == "blank":
        tokens.pop()

    return tokens


def validate_translations(tokens: list[tuple[str, str, str] | tuple[str]]) -> list[tuple[str, str]]:
    english_entries = [(key, value) for kind, *rest in tokens if kind == "entry" for key, value in [(rest[0], rest[1])]]
    english_keys = [key for key, _ in english_entries]

    missing = [key for key in english_keys if key not in TRANSLATIONS]
    extra = sorted(set(TRANSLATIONS) - set(english_keys))
    if missing or extra:
        message_parts = []
        if missing:
            message_parts.append(f"missing keys ({len(missing)}): {missing}")
        if extra:
            message_parts.append(f"extra keys ({len(extra)}): {extra}")
        raise ValueError("; ".join(message_parts))

    for key, english_value in english_entries:
        spanish_value = TRANSLATIONS[key]

        if not spanish_value:
            raise ValueError(f"Empty translation for {key}")

        english_placeholders = PLACEHOLDER_RE.findall(english_value)
        spanish_placeholders = PLACEHOLDER_RE.findall(spanish_value)
        if english_placeholders != spanish_placeholders:
            raise ValueError(
                f"Placeholder mismatch for {key}: {english_placeholders} != {spanish_placeholders}"
            )

        if english_value.count("\n") != spanish_value.count("\n"):
            raise ValueError(
                f"Newline mismatch for {key}: {english_value.count(chr(10))} != {spanish_value.count(chr(10))}"
            )

        for symbol in SYMBOLS_TO_PRESERVE:
            if english_value.count(symbol) != spanish_value.count(symbol):
                raise ValueError(
                    f"Symbol mismatch for {key} and {symbol!r}: "
                    f"{english_value.count(symbol)} != {spanish_value.count(symbol)}"
                )

    return english_entries


def main() -> int:
    tokens = parse_english_tokens(SOURCE_FILE)
    english_entries = validate_translations(tokens)
    entry_count = len(english_entries)

    if entry_count != 311:
        raise ValueError(f"Expected 311 English entries, found {entry_count}")

    for token in tokens:
        if token[0] == "blank":
            print()
            continue

        _, key, _ = token
        print(f"        {swift_literal(key)}: {swift_literal(TRANSLATIONS[key])},")

    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as exc:  # pragma: no cover - CLI failure path
        print(f"Error: {exc}", file=sys.stderr)
        raise SystemExit(1)

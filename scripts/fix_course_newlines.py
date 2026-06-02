#!/usr/bin/env python3
"""Audit and fix paragraph breaks inside CourseData.swift lesson content."""

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
COURSE_DATA = ROOT / "ios/Sophia/Services/CourseData.swift"

SENTENCE_END = '.!?…»"\')'


def ends_sentence(text: str) -> bool:
    t = text.rstrip()
    while t.endswith("*"):
        t = t[:-1].rstrip()
    return bool(t) and t[-1] in SENTENCE_END


def parse_blocks(raw: str) -> list[tuple[str, str]]:
    raw = raw.replace("\\n", "\n")
    blocks: list[tuple[str, str]] = []
    buffer: list[str] = []
    chars = list(raw)
    i = 0

    def flush_text() -> None:
        nonlocal buffer
        text = "".join(buffer).strip()
        if text:
            blocks.append(("text", text))
        buffer = []

    while i < len(chars):
        c = chars[i]
        if c == "|" and i + 1 < len(chars) and chars[i + 1] == "|":
            end = None
            for j in range(i + 2, len(chars) - 1):
                if chars[j] == "|" and chars[j + 1] == "|":
                    end = j
                    break
            if end is not None:
                flush_text()
                blocks.append(("highlight", "".join(chars[i + 2 : end])))
                i = end + 2
                continue
        if c == "{":
            try:
                end = chars.index("}", i + 1)
            except ValueError:
                end = None
            if end is not None:
                flush_text()
                blocks.append(("funFact", "".join(chars[i + 1 : end])))
                i = end + 1
                continue
        if c == "[":
            try:
                end = chars.index("]", i + 1)
            except ValueError:
                end = None
            if end is not None:
                inner = "".join(chars[i + 1 : end])
                if "\n" not in inner and len(inner) < 200:
                    flush_text()
                    blocks.append(("image", inner))
                    i = end + 1
                    continue
        buffer.append(c)
        i += 1
    flush_text()
    return blocks


def normalize_text_block(body: str) -> str:
    body = re.sub(r"\n{3,}", "\n\n", body)
    segments = re.split(r"\n\n+", body)
    if len(segments) <= 1:
        return body

    rebuilt: list[str] = []
    for index, segment in enumerate(segments):
        if index == 0:
            rebuilt.append(segment)
            continue
        previous = rebuilt[-1].rstrip()
        current = segment.lstrip()
        if not previous or not current:
            rebuilt.append("\n\n" + segment)
            continue
        if not ends_sentence(previous) or (current[0].islower() and ends_sentence(previous)):
            rebuilt.append("\n" + segment)
        else:
            rebuilt.append("\n\n" + segment)
    return "".join(rebuilt)


def normalize_lesson_content(decoded: str) -> str:
    blocks = parse_blocks(decoded)
    result = decoded
    for kind, body in blocks:
        if kind != "text":
            continue
        fixed = normalize_text_block(body)
        if fixed != body:
            result = result.replace(body, fixed, 1)
    return result


def swift_escape(s: str) -> str:
    return s.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n")


MANUAL_FIXES: dict[str, str] = {
    "course_114_fahrenheit_451_bradbury_p2": (
        "**Guy Montag** est pompier, c'est-à-dire brûleur de livres.\n\n"
        "{Le titre vient de la température à laquelle le papier brûle - 451 °F (233 °C). "
        "Bradbury avait demandé le chiffre exact à un pompier. "
        "C'est l'un des titres de roman les plus précis scientifiquement.}\n\n"
        "Dans ce futur proche, les livres ont été bannis car ils rendent les gens malheureux "
        "en leur montrant la complexité du monde. Les gens vivent dans des maisons avec des "
        "«parloirs»\n\n[book burning Nazi Germany 1933]\n\n"
        "(des murs entiers d'écrans) diffusant des émissions interactives sans contenu.\n\n"
        "Sa femme **Mildred** vit dans un état de semi-conscience artificielle, en overdose de "
        "pilules et de télévision. La rencontre avec la jeune **Clarisse**, qui observe le monde, "
        "pose des questions et trouve les feux beaux, provoque l'éveil de Montag. "
        "Il commence à cacher des livres et à les lire."
    ),
    "course_116_la_metamorphose_kafka_p2": (
        "**Gregor Samsa** est commis voyageur : il déteste son travail, souffre de sa relation "
        "avec son chef autoritaire, et travaille uniquement pour rembourser les dettes de sa "
        "famille auprès de son employeur.\n\n"
        "{Le mot allemand «Ungeziefer» utilisé par Kafka pour désigner Gregor n'est pas un insecte "
        "précis - il désigne vaguement un «animal impur» ou une «vermine». L'ambiguïté est "
        "intentionnelle : Kafka refusait de définir exactement ce qu'était devenu Gregor.}\n\n"
        "La métamorphose peut se lire comme la matérialisation de son sentiment de "
        "déshumanisation : il se sentait déjà traité comme un insecte, interchangeable et sans "
        "valeur propre.\n\nParadoxalement, c'est quand il cesse d'être humain qu'il peut enfin "
        "ne plus travailler. Les premières réactions de sa famille sont révélatrices : le père "
        "s'effondre, la mère défaille, mais la sœur **Grete** prend soin de lui avec une douceur "
        "qui, progressivement, s'épuise."
    ),
}


def fix_file() -> None:
    text = COURSE_DATA.read_text(encoding="utf-8")
    changes = 0

    def replacer(match: re.Match[str]) -> str:
        nonlocal changes
        prefix = match.group(1)
        lesson_id = match.group(2)
        content = match.group(3)
        decoded = content.replace("\\n", "\n")

        if lesson_id in MANUAL_FIXES:
            new_body = MANUAL_FIXES[lesson_id]
            if new_body != decoded:
                changes += 1
                return f'{prefix}{swift_escape(new_body)}"'

        new_decoded = normalize_lesson_content(decoded)
        if new_decoded != decoded:
            changes += 1
            return f'{prefix}{swift_escape(new_decoded)}"'
        return match.group(0)

    pattern = re.compile(
        r'(LessonPage\(id:\s*"([^"]+)"[^}]*content:\s*")((?:\\.|[^"\\])*)(")'
    )
    new_text = pattern.sub(replacer, text)

    if new_text != text:
        COURSE_DATA.write_text(new_text, encoding="utf-8")
    print(f"Applied {changes} content normalizations.")


if __name__ == "__main__":
    fix_file()

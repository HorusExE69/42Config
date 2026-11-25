#!/usr/bin/env python3
"""Fusionne la config 42 dans les fichiers VS Code de l'utilisateur.

Merges the 42 config into the user's VS Code files. VS Code files are JSONC
(comments and trailing commas allowed), so they are cleaned before parsing.

Usage:
    merge_json.py settings    SOURCE TARGET [--set KEY=VALUE ...]
    merge_json.py keybindings SOURCE TARGET
    merge_json.py snippets    SOURCE TARGET

If TARGET does not exist (or is empty), SOURCE is copied as is, comments
included. Otherwise TARGET is rewritten as plain JSON (a backup is made by
install.sh beforehand).
"""

import json
import os
import sys


def strip_jsonc(text: str) -> str:
    """Remove // and /* */ comments and trailing commas, outside strings."""
    out = []
    i, n = 0, len(text)
    in_str = False
    while i < n:
        ch = text[i]
        if in_str:
            out.append(ch)
            if ch == "\\" and i + 1 < n:
                out.append(text[i + 1])
                i += 2
                continue
            if ch == '"':
                in_str = False
            i += 1
            continue
        if ch == '"':
            in_str = True
            out.append(ch)
            i += 1
        elif text.startswith("//", i):
            while i < n and text[i] != "\n":
                i += 1
        elif text.startswith("/*", i):
            end = text.find("*/", i + 2)
            i = n if end == -1 else end + 2
        else:
            out.append(ch)
            i += 1
    cleaned = "".join(out)
    # Trailing commas: ", }" or ", ]" (outside strings, comments already gone)
    result = []
    in_str = False
    i, n = 0, len(cleaned)
    while i < n:
        ch = cleaned[i]
        if in_str:
            result.append(ch)
            if ch == "\\" and i + 1 < n:
                result.append(cleaned[i + 1])
                i += 2
                continue
            if ch == '"':
                in_str = False
            i += 1
            continue
        if ch == '"':
            in_str = True
        elif ch == ",":
            j = i + 1
            while j < n and cleaned[j] in " \t\r\n":
                j += 1
            if j < n and cleaned[j] in "}]":
                i += 1
                continue
        result.append(ch)
        i += 1
    return "".join(result)


def load(path: str, default):
    if not os.path.isfile(path):
        return default, False
    with open(path, encoding="utf-8") as fh:
        raw = fh.read()
    if not raw.strip():
        return default, False
    return json.loads(strip_jsonc(raw)), True


def read_text(path: str) -> str:
    with open(path, encoding="utf-8") as fh:
        return fh.read()


def write_text(path: str, text: str) -> None:
    os.makedirs(os.path.dirname(os.path.abspath(path)), exist_ok=True)
    with open(path, "w", encoding="utf-8", newline="\n") as fh:
        fh.write(text)


def write_json(path: str, data) -> None:
    write_text(path, json.dumps(data, indent=4, ensure_ascii=False) + "\n")


def apply_sets(text: str, sets: dict) -> str:
    for key, value in sets.items():
        text = text.replace(key, value)
    return text


def merge_settings(src: str, dst: str, sets: dict) -> None:
    src_text = apply_sets(read_text(src), sets)
    current, exists = load(dst, {})
    if not exists:
        write_text(dst, src_text)
        return
    ours = json.loads(strip_jsonc(src_text))
    for key, value in ours.items():
        # Blocs par langage ("[c]", "[python]"…) : fusion clé par clé
        if isinstance(value, dict) and isinstance(current.get(key), dict):
            current[key].update(value)
        else:
            current[key] = value
    write_json(dst, current)


def merge_keybindings(src: str, dst: str) -> None:
    current, exists = load(dst, [])
    if not exists:
        write_text(dst, read_text(src))
        return
    ours = json.loads(strip_jsonc(read_text(src)))
    ours_ids = {(k.get("key"), k.get("when")) for k in ours}
    kept = [k for k in current
            if (k.get("key"), k.get("when")) not in ours_ids]
    write_json(dst, kept + ours)


def merge_snippets(src: str, dst: str) -> None:
    current, exists = load(dst, {})
    if not exists:
        write_text(dst, read_text(src))
        return
    current.update(json.loads(strip_jsonc(read_text(src))))
    write_json(dst, current)


def main() -> int:
    if len(sys.argv) < 4:
        print(__doc__, file=sys.stderr)
        return 2
    mode, src, dst = sys.argv[1], sys.argv[2], sys.argv[3]
    sets = {}
    rest = sys.argv[4:]
    while rest:
        if rest[0] == "--set" and len(rest) > 1 and "=" in rest[1]:
            key, value = rest[1].split("=", 1)
            sets[key] = value
            rest = rest[2:]
        else:
            print("Unknown argument: %s" % rest[0], file=sys.stderr)
            return 2
    try:
        if mode == "settings":
            merge_settings(src, dst, sets)
        elif mode == "keybindings":
            merge_keybindings(src, dst)
        elif mode == "snippets":
            merge_snippets(src, dst)
        else:
            print("Unknown mode: %s" % mode, file=sys.stderr)
            return 2
    except json.JSONDecodeError as exc:
        print("Invalid JSON in %s: %s" % (dst, exc), file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())

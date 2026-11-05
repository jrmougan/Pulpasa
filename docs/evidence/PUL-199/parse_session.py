#!/usr/bin/env python3
"""Resume una sesión stream-json de sessions.sh en tres líneas, sin rutas absolutas."""
import json
import re
import sys

raw, case, i, created, rc, clone = sys.argv[1:7]
sys.stdout.reconfigure(encoding="utf-8", newline="\n")


def clean(text: str) -> str:
    for variant in {clone, clone.replace("\\", "/"), clone.replace("\\", "\\\\"), clone.replace("/", "\\")}:
        text = text.replace(variant, "<clon>")
    text = re.sub(r"([A-Za-z]:[\\/]|/[a-z]/|/tmp/)[^\s\"']*", "<ruta>", text)
    return " ".join(text.split())[:260]


cwd = "?"
hooks: list[str] = []
tools: list[str] = []
results: list[str] = []
with open(raw, encoding="utf-8", errors="replace") as fh:
    for line in fh:
        try:
            ev = json.loads(line)
        except ValueError:
            continue
        if ev.get("type") == "system" and ev.get("subtype") == "init":
            cwd = clean(ev.get("cwd", "?"))
        if ev.get("type") == "system" and ev.get("subtype") == "hook_response":
            if "PreToolUse" in str(ev.get("hook_event")):
                hooks.append(f"rc={ev.get('exit_code')} {ev.get('outcome')} stderr={clean(str(ev.get('stderr', '')))}")
        msg = ev.get("message")
        content = msg.get("content") if isinstance(msg, dict) else None
        if isinstance(content, list):
            for block in content:
                if block.get("type") == "tool_use":
                    tools.append(block.get("name", "?"))
                if block.get("type") == "tool_result":
                    body = block.get("content")
                    body = body if isinstance(body, str) else json.dumps(body, ensure_ascii=False)
                    results.append(("ERROR " if block.get("is_error") else "OK ") + clean(body))
print(f"{case} #{i} {created} claude_rc={rc} cwd={cwd} tools={tools}")
print(f"    PreToolUse: {hooks if hooks else 'ningún evento'}")
print(f"    resultado: {results if results else 'sin tool_result'}")

#!/data/data/com.termux/files/usr/bin/bash
# SPDX-License-Identifier: GPL-2.0-or-later
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DOLPHIN="${DOLPHIN_SOURCE:-$HOME/dolphin-wiiextract}"
DOLPHIN_BUILD="${DOLPHIN_BUILD:-$DOLPHIN/build-android}"

export ROOT DOLPHIN DOLPHIN_BUILD

python3 - <<'PY'
import json
import os
import shlex
import subprocess
from pathlib import Path

root = Path(os.environ["ROOT"])
dolphin = Path(os.environ["DOLPHIN"])

database = Path(os.environ["DOLPHIN_BUILD"]) / "compile_commands.json"
entries = json.loads(database.read_text())

matches = [
    entry for entry in entries
    if entry["file"].endswith("/IOS/ES/Formats.cpp")
]

if len(matches) != 1:
    raise SystemExit(
        f"Se esperaba una entrada para Formats.cpp, encontradas: {len(matches)}"
    )

entry = matches[0]

args = entry.get("arguments")
if args is None:
    args = shlex.split(entry["command"])

out = root / "build/core-minimal/Formats.rebuilt.o"
out.parent.mkdir(parents=True, exist_ok=True)

for i, arg in enumerate(args):
    if arg == "-o":
        args[i + 1] = str(out)
        break
else:
    raise SystemExit("No se encontró el parámetro -o")

args.extend([
    "-ffunction-sections",
    "-fdata-sections",
])

print("===== COMPILANDO FORMATS CON CONFIGURACIÓN DOLPHIN =====", flush=True)

subprocess.run(
    args,
    cwd=entry["directory"],
    check=True,
)

print("===== RESULTADO =====", flush=True)
subprocess.run(["file", str(out)], check=True)
subprocess.run(["ls", "-lh", str(out)], check=True)
PY

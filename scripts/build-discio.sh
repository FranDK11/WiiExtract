#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DOLPHIN="${DOLPHIN_SOURCE:-$HOME/dolphin}"
BUILD="${DOLPHIN_BUILD:-$DOLPHIN/build-android}"
OUT="$ROOT/build/discio-custom"
SOURCE="$ROOT/native/patches/Volume.cpp"
COMPILE_DB="$BUILD/compile_commands.json"
ORIGINAL="$BUILD/Source/Core/DiscIO/libdiscio.a"

mkdir -p "$OUT"

for file in "$SOURCE" "$COMPILE_DB"; do
    if [ ! -f "$file" ]; then
        echo "ERROR: falta $file"
        exit 1
    fi
done

echo "===== COMPILANDO DISCIO ORIGINAL ====="

ninja -C "$BUILD" Source/Core/DiscIO/libdiscio.a

if [ ! -f "$ORIGINAL" ]; then
    echo "ERROR: Ninja no generó libdiscio.a"
    exit 1
fi

echo "===== COMPILANDO VOLUME PERSONALIZADO ====="

python3 - "$COMPILE_DB" "$SOURCE" "$OUT/Volume.cpp.o" <<'PY'
import json
import os
import shlex
import subprocess
import sys

database, source, output = sys.argv[1:]

with open(database, encoding="utf-8") as f:
    entries = json.load(f)

entry = next(
    (e for e in entries if e["file"].endswith("/DiscIO/Volume.cpp")),
    None
)

if entry is None:
    raise SystemExit("ERROR: Volume.cpp no aparece en compile_commands.json")

args = entry.get("arguments") or shlex.split(entry["command"])

for i, arg in enumerate(args):
    if arg == "-o":
        args[i + 1] = output
    elif arg == "-c":
        args[i + 1] = source

subprocess.run(args, cwd=entry["directory"], check=True)
PY

echo "===== RECONSTRUYENDO BIBLIOTECA ====="

python3 - "$ORIGINAL" "$OUT/Volume.cpp.o" "$OUT/libdiscio.a" <<'PY'
import subprocess
import sys
import tempfile
from pathlib import Path

original, replacement, destination = map(Path, sys.argv[1:])

members = subprocess.check_output(
    ["ar", "t", str(original)],
    text=True
).splitlines()

if members.count("Volume.cpp.o") != 1:
    raise SystemExit("ERROR: Volume.cpp.o no aparece exactamente una vez")

with tempfile.TemporaryDirectory() as directory:
    directory = Path(directory)

    for member in members:
        data = subprocess.check_output(
            ["ar", "p", str(original), member]
        )
        (directory / member).write_bytes(data)

    (directory / "Volume.cpp.o").write_bytes(
        replacement.read_bytes()
    )

    destination.unlink(missing_ok=True)

    subprocess.run(
        ["ar", "rcs", str(destination)] +
        [str(directory / member) for member in members],
        check=True
    )

print("Biblioteca creada:", destination)
PY

echo "===== VERIFICACIÓN ====="

if cmp -s \
    "$OUT/Volume.cpp.o" \
    <(ar p "$OUT/libdiscio.a" Volume.cpp.o)
then
    echo "VOLUME_PERSONALIZADO_OK"
else
    echo "ERROR: el objeto personalizado no coincide"
    exit 1
fi

ls -lh "$OUT/libdiscio.a"

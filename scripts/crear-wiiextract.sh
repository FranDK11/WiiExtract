#!/data/data/com.termux/files/usr/bin/bash
# SPDX-License-Identifier: GPL-2.0-or-later
set -euo pipefail

cd "$HOME/DolphinToolAndroid"

BASE="$PWD/build/apk-native"
OUT="$BASE/WiiExtract-v0.4.0.apk"
MANIFEST="app/src/main/AndroidManifest.xml"
RES="app/src/main/res"

echo "===== PREPARANDO MANIFEST ====="

python - <<'PY'
from pathlib import Path

p = Path("app/src/main/AndroidManifest.xml")
s = p.read_text()

s = s.replace(
    'android:label="Dolphin Tool"',
    'android:label="WiiExtract"'
)

if 'android:icon=' not in s:
    s = s.replace(
        '<application',
        '<application android:icon="@mipmap/ic_launcher"',
        1
    )

p.write_text(s)
print("Nombre e icono configurados.")
PY

echo "===== COMPILANDO RECURSOS ====="

ANDROID_JAR=$(find "$HOME/DolphinToolAndroid/sdk" \
    -name android.jar -print -quit)

if [ -z "$ANDROID_JAR" ]; then
    echo "ERROR: No se encontró android.jar"
    exit 1
fi

aapt package -f \
    -M "$MANIFEST" \
    -S "$RES" \
    -I "$ANDROID_JAR" \
    -F "$BASE/WiiExtract-resources.apk"

echo "===== PREPARANDO APK ====="

python - "$BASE" <<'PY'
from pathlib import Path
import zipfile
import sys

base = Path(sys.argv[1])
resources = base / "WiiExtract-resources.apk"
previous = base / "DolphinTool-v0.4.apk"
output = base / "WiiExtract-unsigned.apk"

with zipfile.ZipFile(previous) as old:
    required = [
        "classes.dex",
        "lib/arm64-v8a/libdolphintool.so",
        "lib/arm64-v8a/libc++_shared.so"
    ]

    for name in required:
        if name not in old.namelist():
            raise SystemExit("Falta: " + name)

    with zipfile.ZipFile(resources) as src:
        with zipfile.ZipFile(output, "w") as dst:
            for item in src.infolist():
                dst.writestr(item, src.read(item.filename))

            for name in required:
                dst.writestr(
                    name,
                    old.read(name),
                    compress_type=zipfile.ZIP_DEFLATED
                )

print("APK preparada con recursos nuevos.")
PY

echo "===== ALINEANDO ====="

zipalign -f -p 4 \
    "$BASE/WiiExtract-unsigned.apk" \
    "$BASE/WiiExtract-aligned.apk"

echo "===== FIRMANDO ====="

apksigner sign \
    --ks "$HOME/DolphinToolAndroid/dolphintool-debug.jks" \
    --ks-pass pass:android \
    --out "$OUT" \
    "$BASE/WiiExtract-aligned.apk"

echo "===== VERIFICANDO ====="

apksigner verify --verbose "$OUT"

echo "===== RESULTADO ====="

ls -lh "$OUT"

echo "===== COPIANDO A DESCARGAS ====="

cp "$OUT" "$HOME/storage/downloads/"

echo "WiiExtract v0.4.0 preparada."

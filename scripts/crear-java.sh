#!/data/data/com.termux/files/usr/bin/bash
# SPDX-License-Identifier: GPL-2.0-or-later
set -e

cd "$HOME/DolphinToolAndroid"

BASE="$PWD/build/apk-native"
PLATFORM="$HOME/android-sdk/platforms/android-35/android.jar"

if [ ! -f "$PLATFORM" ]; then
    PLATFORM=$(find "$HOME" -name android.jar -print -quit)
fi

[ -f "$PLATFORM" ] || {
    echo "ERROR: android.jar no encontrado"
    exit 1
}

mkdir -p "$BASE/v04/classes" "$BASE/v04/dex"
mkdir -p "$BASE/v04/lib/arm64-v8a"

echo "=== COMPILANDO JAVA ==="

javac -source 8 -target 8 \
    -classpath "$PLATFORM" \
    -d "$BASE/v04/classes" \
    app/src/main/java/com/dolphintool/app/MainActivity.java

echo "=== GENERANDO DEX ==="

d8 --min-api 24 \
    --lib "$PLATFORM" \
    --output "$BASE/v04/dex" \
    "$BASE/v04/classes/com/dolphintool/app/"*.class

echo "=== PREPARANDO BIBLIOTECA ==="

cp build/linktest/libdolphin_android.so \
   "$BASE/v04/lib/arm64-v8a/libdolphintool.so"

echo "=== ACTUALIZANDO APK ==="

cp "$BASE/DolphinTool-Final.apk" "$BASE/v04-unsigned.apk"

zip -q -d "$BASE/v04-unsigned.apk" \
    classes.dex \
    lib/arm64-v8a/libdolphintool.so

(
    cd "$BASE/v04"
    zip -q -0 -r "$BASE/v04-unsigned.apk" \
        dex/classes.dex \
        lib/arm64-v8a/libdolphintool.so
)

# classes.dex debe estar en la raíz del APK
python - "$BASE/v04-unsigned.apk" "$BASE/v04/dex/classes.dex" <<'PY'
import sys, zipfile, os
apk, dex = sys.argv[1:]
tmp = apk + ".tmp"
with zipfile.ZipFile(apk, "r") as src, \
     zipfile.ZipFile(tmp, "w") as dst:
    for item in src.infolist():
        if item.filename in ("classes.dex", "dex/classes.dex"):
            continue
        dst.writestr(item, src.read(item.filename))
    dst.write(dex, "classes.dex", compress_type=zipfile.ZIP_DEFLATED)
os.replace(tmp, apk)
PY

echo "=== ALINEANDO ==="

zipalign -f -p 4 \
    "$BASE/v04-unsigned.apk" \
    "$BASE/v04-aligned.apk"

echo "=== FIRMANDO ==="

apksigner sign \
    --ks dolphintool-debug.jks \
    --ks-pass pass:android \
    --out "$BASE/DolphinTool-v0.4.apk" \
    "$BASE/v04-aligned.apk"

echo "=== VERIFICANDO ==="

apksigner verify --verbose "$BASE/DolphinTool-v0.4.apk"

echo "=== RESULTADO ==="

ls -lh "$BASE/DolphinTool-v0.4.apk"

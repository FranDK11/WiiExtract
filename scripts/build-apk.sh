#!/data/data/com.termux/files/usr/bin/bash
# SPDX-License-Identifier: GPL-2.0-or-later
set -euo pipefail

cd "$(dirname "$0")/.."

ROOT="$PWD"
BUILD="$ROOT/build/standalone"
APK="$BUILD/WiiExtract-test.apk"

ANDROID_JAR="$HOME/android-sdk/platforms/android-35/android.jar"

if [ ! -f "$ANDROID_JAR" ]; then
    ANDROID_JAR=$(find "$ROOT/sdk" "$HOME/android-sdk" \
        -name android.jar -type f -print -quit 2>/dev/null || true)
fi

[ -f "$ANDROID_JAR" ] || {
    echo "ERROR: android.jar no encontrado"
    exit 1
}

NATIVE="$ROOT/build/linktest/libdolphin_android.so"
NDK="${ANDROID_NDK_HOME:-$HOME/android-ndk/android-ndk-r27d}"
CPP="$NDK/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/lib/aarch64-linux-android/libc++_shared.so"

for file in "$NATIVE" "$CPP"; do
    [ -f "$file" ] || {
        echo "ERROR: falta $file"
        exit 1
    }
done

mkdir -p "$BUILD/classes" "$BUILD/dex"

echo "===== COMPILANDO JAVA ====="

javac -source 8 -target 8 \
    -classpath "$ANDROID_JAR" \
    -d "$BUILD/classes" \
    app/src/main/java/com/dolphintool/app/MainActivity.java

echo "===== GENERANDO DEX ====="

d8 --min-api 24 \
    --lib "$ANDROID_JAR" \
    --output "$BUILD/dex" \
    "$BUILD/classes/com/dolphintool/app/"*.class

echo "===== COMPILANDO RECURSOS ====="

aapt package -f \
    -M app/src/main/AndroidManifest.xml \
    -S app/src/main/res \
    -I "$ANDROID_JAR" \
    -F "$BUILD/resources.apk"

echo "===== EMPAQUETANDO APK ====="

python - "$BUILD" "$NATIVE" "$CPP" <<'PY'
from pathlib import Path
import sys
import zipfile

build = Path(sys.argv[1])
native = Path(sys.argv[2])
cpp = Path(sys.argv[3])

with zipfile.ZipFile(build / "resources.apk") as src:
    with zipfile.ZipFile(build / "unsigned.apk", "w") as dst:
        for item in src.infolist():
            dst.writestr(item, src.read(item.filename))

        dst.write(
            build / "dex/classes.dex",
            "classes.dex",
            compress_type=zipfile.ZIP_DEFLATED
        )
        dst.write(
            native,
            "lib/arm64-v8a/libdolphintool.so",
            compress_type=zipfile.ZIP_DEFLATED
        )
        dst.write(
            cpp,
            "lib/arm64-v8a/libc++_shared.so",
            compress_type=zipfile.ZIP_DEFLATED
        )
PY

echo "===== ALINEANDO ====="

zipalign -f -p 4 \
    "$BUILD/unsigned.apk" \
    "$BUILD/aligned.apk"

echo "===== FIRMANDO ====="

KEYSTORE="${WIIEXTRACT_KEYSTORE:-$ROOT/dolphintool-debug.jks}"

[ -f "$KEYSTORE" ] || {
    echo "ERROR: no se encontró la clave de firma"
    exit 1
}

apksigner sign \
    --ks "$KEYSTORE" \
    --out "$APK" \
    "$BUILD/aligned.apk"

echo "===== VERIFICANDO ====="

apksigner verify --verbose "$APK"

echo "===== RESULTADO ====="

ls -lh "$APK"

#!/data/data/com.termux/files/usr/bin/bash
# SPDX-License-Identifier: GPL-2.0-or-later
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [ "${WIIEXTRACT_OFFLINE:-0}" = "1" ]; then
    export DOLPHIN_SOURCE="$ROOT/upstream/dolphin"

    echo "===== UTILIZANDO FUENTES LOCALES ====="

    test -f "$DOLPHIN_SOURCE/CMakeLists.txt" || {
        echo "ERROR: faltan las fuentes locales de Dolphin"
        exit 1
    }

    test -f "$ROOT/upstream/fmt-12.2.1/CMakeLists.txt" || {
        echo "ERROR: faltan las fuentes locales de fmt"
        exit 1
    }

    mkdir -p "$ROOT/build"

    if [ ! -e "$ROOT/build/fmt-12.2.1-src" ]; then
        ln -s "$ROOT/upstream/fmt-12.2.1"             "$ROOT/build/fmt-12.2.1-src"
    fi
else
    export DOLPHIN_SOURCE="${DOLPHIN_SOURCE:-$HOME/dolphin-wiiextract}"

    echo "===== 1/8 PREPARANDO DOLPHIN ====="
    ./scripts/prepare-dolphin.sh

    echo "===== 2/8 PREPARANDO FMT ====="
    ./scripts/prepare-fmt.sh
fi

echo "===== 3/8 CONFIGURANDO DOLPHIN ====="
./scripts/configure-dolphin.sh

echo "===== 4/8 COMPILANDO DOLPHIN ====="
cmake --build "$DOLPHIN_SOURCE/build-android" \
    --target common core discio \
    --parallel "${BUILD_JOBS:-4}"

echo "===== 5/8 CONFIGURANDO DEPENDENCIAS ====="
./scripts/configure-dependencies.sh

echo "===== 6/8 COMPILANDO DEPENDENCIAS ====="
./scripts/build-dependencies.sh

echo "===== 7/8 COMPILANDO Y ENLAZANDO NATIVO ====="
./scripts/build-discio.sh
./scripts/enlazar-android.sh

echo "===== 8/8 GENERANDO APK ====="
./scripts/build-apk.sh

echo "===== RESULTADO ====="
ls -lh build/standalone/WiiExtract-test.apk

echo "WIIEXTRACT_BUILD_OK"

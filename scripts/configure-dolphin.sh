#!/data/data/com.termux/files/usr/bin/bash
# SPDX-License-Identifier: GPL-2.0-or-later
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DOLPHIN="${DOLPHIN_SOURCE:-$HOME/dolphin-wiiextract}"
BUILD="$DOLPHIN/build-android"

[ -f "$DOLPHIN/CMakeLists.txt" ] || {
    echo "ERROR: no se encontraron las fuentes de Dolphin"
    exit 1
}

echo "===== CONFIGURANDO DOLPHIN ====="

cmake -S "$DOLPHIN" -B "$BUILD" -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
    -DENABLE_HEADLESS=ON \
    -DENABLE_ALSA=OFF \
    -DENABLE_ANALYTICS=OFF \
    -DENABLE_AUTOUPDATE=OFF \
    -DENABLE_CCACHE=OFF \
    -DENABLE_PULSEAUDIO=OFF \
    -DENABLE_RTTI=OFF \
    -DENABLE_OPT=OFF \
    -DUSE_UPNP=OFF \
    -DENABLE_PROGRAMS=OFF \
    -DENABLE_QT=OFF \
    -DENABLE_VULKAN=OFF \
    -DENABLE_TESTING=OFF \
    -DENABLE_LTO=OFF \
    -DENABLE_CUBEB=OFF \
    -DENABLE_SDL=OFF \
    -DENABLE_EGL=OFF \
    -DENABLE_LLVM=OFF \
    -DUSE_MGBA=OFF \
    -DUSE_RETRO_ACHIEVEMENTS=OFF \
    -DUSE_STATIC_MBEDTLS_LIBRARY=ON

echo "===== VERIFICANDO ====="

test -f "$BUILD/build.ninja"
test -f "$BUILD/compile_commands.json"

echo "DOLPHIN_CONFIGURADO_OK"

#!/data/data/com.termux/files/usr/bin/bash
# SPDX-License-Identifier: GPL-2.0-or-later
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DOLPHIN="${DOLPHIN_SOURCE:-$HOME/dolphin-wiiextract}"
BUILD="$ROOT/build"
TOOLCHAIN="$ROOT/toolchains/android-arm64-termux.cmake"

configure() {
    local name="$1"
    local source="$2"
    shift 2

    echo "===== CONFIGURANDO $name ====="

    if [ ! -f "$source/CMakeLists.txt" ]; then
        echo "ERROR: no existe CMakeLists.txt en $source"
        exit 1
    fi

    cmake \
        -S "$source" \
        -B "$BUILD/ndk-$name" \
        -G Ninja \
        -DCMAKE_TOOLCHAIN_FILE="$TOOLCHAIN" \
        -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
        -DBUILD_SHARED_LIBS=OFF \
        "$@"
}

configure fmt-12.2.1 \
    "$BUILD/fmt-12.2.1-src" \
    -DFMT_TEST=OFF \
    -DFMT_DOC=OFF \
    -DFMT_INSTALL=OFF

configure zlib \
    "$DOLPHIN/Externals/zlib-ng/zlib-ng" \
    -DZLIB_COMPAT=ON \
    -DZLIB_ENABLE_TESTS=OFF \
    -DBUILD_TESTING=OFF \
    -DWITH_GTEST=OFF \
    -DWITH_BENCHMARKS=OFF \
    -DWITH_BENCHMARK_APPS=OFF \
    -DWITH_FUZZERS=OFF \
    -DWITH_CODE_COVERAGE=OFF \
    -DWITH_NATIVE_INSTRUCTIONS=OFF

configure zstd \
    "$DOLPHIN/Externals/zstd/zstd/build/cmake" \
    -DZSTD_BUILD_STATIC=ON \
    -DZSTD_BUILD_SHARED=OFF \
    -DZSTD_BUILD_PROGRAMS=OFF \
    -DZSTD_BUILD_TESTS=OFF \
    -DZSTD_BUILD_COMPRESSION=ON \
    -DZSTD_BUILD_DECOMPRESSION=ON \
    -DZSTD_BUILD_DICTBUILDER=ON \
    -DZSTD_BUILD_DEPRECATED=OFF \
    -DZSTD_BUILD_CONTRIB=OFF

configure bzip2 \
    "$DOLPHIN/Externals/bzip2"

configure lzma \
    "$DOLPHIN/Externals/liblzma"

configure iconv \
    "$DOLPHIN/Externals/libiconv" \
    -DENABLE_EXTRA=OFF \
    -DENABLE_RELOCATABLE=ON

echo "===== CONFIGURACIÓN COMPLETADA ====="

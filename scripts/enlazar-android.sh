#!/data/data/com.termux/files/usr/bin/bash
# SPDX-License-Identifier: GPL-2.0-or-later

set -e

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

DOLPHIN="${DOLPHIN_SOURCE:-$HOME/dolphin-wiiextract}"
LIBS="${DOLPHIN_BUILD:-$DOLPHIN/build-android}"
export DOLPHIN_SOURCE="$DOLPHIN" DOLPHIN_BUILD="$LIBS"
NDK="${ANDROID_NDK_HOME:-$HOME/android-ndk/android-ndk-r27d}"
SYSROOT="$NDK/toolchains/llvm/prebuilt/linux-x86_64/sysroot"
ANDROID_LIBS="$PWD/build/android-libs"
OUTPUT="build/linktest/libdolphin_android.so"

rm -f "$OUTPUT"

echo "=== COMPILANDO FORMATS DESDE FUENTE ==="
./scripts/build-formats.sh

echo "=== ENLAZANDO DOLPHIN PARA ANDROID ==="

if clang++ \
  --target=aarch64-linux-android24 \
  --sysroot="$SYSROOT" \
  -nostdinc++ \
  -nostdlib++ \
  -unwindlib=none \
  -std=c++23 \
  -shared \
  -fPIC \
  -isystem "$SYSROOT/usr/include/c++/v1" \
  -I "$DOLPHIN/Source/Core" \
  -I "$LIBS/Source/Core" \
  -I "$LIBS/include" \
  -I "$ROOT/build/fmt-12.2.1-src/include" \
  -Wl,--no-undefined \
  -Wl,--gc-sections \
  -Wl,--as-needed \
  -Wl,--error-limit=0 \
  -o "$OUTPUT" \
  native/dolphin_extract.cpp \
  -Wl,--start-group \
  build/discio-custom/libdiscio.a \
  "$LIBS/Source/Core/Common/libcommon.a" \
  build/core-minimal/Formats.rebuilt.o \
  "$LIBS/Source/Core/Core/CMakeFiles/core.dir/IOS/IOSC.cpp.o" \
  "$LIBS/Externals/mbedtls/library/libmbedcrypto.a" \
  "$LIBS/Externals/mbedtls/library/libmbedx509.a" \
  "$LIBS/Externals/mbedtls/library/libmbedtls.a" \
  "$LIBS/Externals/pugixml/pugixml/libpugixml.a" \
  "$LIBS/Externals/minizip-ng/minizip-ng/libminizip-ng.a" \
  "$ANDROID_LIBS/libfmt.a" \
  "$ANDROID_LIBS/libz.a" \
  "$ANDROID_LIBS/libzstd.a" \
  "$ANDROID_LIBS/libbzip2.a" \
  "$ANDROID_LIBS/liblzma.a" \
  "$ANDROID_LIBS/libiconv.a" \
  "$ANDROID_LIBS/liblibcharset.a" \
  -Wl,--end-group \
  -L "$SYSROOT/usr/lib/aarch64-linux-android/24" \
  "$NDK/toolchains/llvm/prebuilt/linux-x86_64/lib/clang/18/lib/linux/aarch64/libunwind.a" \
  -lc++_shared \
  -llog \
  -lm \
  > build/linktest/android-errors.txt 2>&1
then
  patchelf --remove-rpath "$OUTPUT"

  echo "=== ENLACE COMPLETADO ==="
  ls -lh "$OUTPUT"

  echo "=== DEPENDENCIAS ==="
  readelf -d "$OUTPUT" | grep NEEDED
else
  echo "=== ERRORES ==="
  grep -E 'fatal error:|error:|undefined symbol:' \
    build/linktest/android-errors.txt | head -n 40
  exit 1
fi

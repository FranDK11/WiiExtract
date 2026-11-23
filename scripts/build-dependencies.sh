#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD="$ROOT/build"
OUT="$BUILD/android-libs"

mkdir -p "$OUT"

echo "===== COMPILANDO DEPENDENCIAS ====="

for name in fmt-12.2.1 zlib zstd bzip2 lzma iconv; do
    echo "===== $name ====="

    DIR="$BUILD/ndk-$name"

    if [ ! -f "$DIR/build.ninja" ]; then
        echo "ERROR: falta la configuración Ninja de $name"
        exit 1
    fi

    ninja -C "$DIR"
done

echo "===== COPIANDO BIBLIOTECAS ====="

cp "$BUILD/ndk-fmt-12.2.1/libfmt.a" "$OUT/libfmt.a"
cp "$BUILD/ndk-zlib/libz.a" "$OUT/libz.a"
cp "$BUILD/ndk-zstd/lib/libzstd.a" "$OUT/libzstd.a"
cp "$BUILD/ndk-bzip2/libbzip2.a" "$OUT/libbzip2.a"
cp "$BUILD/ndk-lzma/liblzma.a" "$OUT/liblzma.a"
cp "$BUILD/ndk-iconv/libiconv.a" "$OUT/libiconv.a"
cp "$BUILD/ndk-iconv/libcharset/liblibcharset.a" "$OUT/liblibcharset.a"

echo "===== RESULTADO ====="

ls -lh "$OUT"/*.a

echo "DEPENDENCIAS_OK"

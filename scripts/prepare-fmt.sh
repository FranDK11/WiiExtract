#!/data/data/com.termux/files/usr/bin/bash
# SPDX-License-Identifier: GPL-2.0-or-later
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEST="$ROOT/build/fmt-12.2.1-src"
REPO="https://github.com/fmtlib/fmt.git"
VERSION="12.2.1"

echo "===== PREPARANDO FMT $VERSION ====="

if [ ! -d "$DEST/.git" ]; then
    if [ -e "$DEST" ]; then
        echo "ERROR: el destino existe y no es un repositorio Git"
        exit 1
    fi

    git clone "$REPO" "$DEST"
fi

cd "$DEST"

if [ -n "$(git status --porcelain)" ]; then
    echo "ERROR: hay modificaciones locales en fmt"
    exit 1
fi

git fetch origin "refs/tags/$VERSION:refs/tags/$VERSION"

EXPECTED="$(git rev-parse "refs/tags/$VERSION^{commit}")"
CURRENT="$(git rev-parse HEAD)"

if [ "$CURRENT" != "$EXPECTED" ]; then
    git checkout --detach "$EXPECTED"
fi

ACTUAL="$(grep -oE 'FMT_VERSION [0-9]+' include/fmt/base.h | head -n 1 | awk '{print $2}')"

if [ "$ACTUAL" != "120201" ]; then
    echo "ERROR: versión de fmt inesperada: $ACTUAL"
    exit 1
fi

echo "FMT_12_2_1_OK"
git rev-parse HEAD

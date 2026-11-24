#!/data/data/com.termux/files/usr/bin/bash
# SPDX-License-Identifier: GPL-2.0-or-later
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEST="${DOLPHIN_SOURCE:-$HOME/dolphin-wiiextract}"
COMMIT="432b41f93cc77cc261a11fd182c74c21cfbcd149"
REPO="${DOLPHIN_REPO:-https://github.com/dolphin-emu/dolphin.git}"
PATCH="$ROOT/patches/dolphin/termux-android.patch"

echo "===== PREPARANDO DOLPHIN ====="

if [ ! -d "$DEST/.git" ]; then
    if [ -e "$DEST" ]; then
        echo "ERROR: el destino existe y no es un repositorio Git"
        exit 1
    fi

    git clone "$REPO" "$DEST"
fi

cd "$DEST"

if [ "$(git rev-parse HEAD)" != "$COMMIT" ]; then
    if [ -n "$(git status --porcelain)" ]; then
        echo "ERROR: hay cambios locales. No se cambiará el commit."
        exit 1
    fi

    git checkout --detach "$COMMIT"
fi

echo "===== INICIALIZANDO SUBMÓDULOS ====="
if [ "${DOLPHIN_SKIP_SUBMODULES:-0}" = "1" ]; then
    echo "SUBMODULOS_OMITIDOS"
else
    git submodule update --init --recursive
fi

echo "===== APLICANDO PARCHE ====="

if git apply --reverse --check "$PATCH" 2>/dev/null; then
    echo "PARCHE_YA_APLICADO"
elif git apply --check "$PATCH" 2>/dev/null; then
    git apply "$PATCH"
    echo "PARCHE_APLICADO_OK"
else
    echo "ERROR: el parche no puede aplicarse limpiamente"
    exit 1
fi

echo "===== RESULTADO ====="
git rev-parse HEAD
echo "DOLPHIN_PREPARADO_OK"

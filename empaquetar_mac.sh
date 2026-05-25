#!/bin/bash
# ═══════════════════════════════════════════════════════
# AureaTranscribe — Empaquetador para macOS
# Genera AureaTranscribe.app y AureaTranscribe.dmg
# ═══════════════════════════════════════════════════════

set -e

echo ""
echo "╔═══════════════════════════════════════════════╗"
echo "║     AureaTranscribe — Empaquetador macOS      ║"
echo "╚═══════════════════════════════════════════════╝"
echo ""

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# Activar entorno virtual
if [ ! -d "venv" ]; then
    echo "✗ No se encontró el entorno virtual."
    echo "  Ejecuta primero: ./instalar_mac.sh"
    exit 1
fi
source venv/bin/activate

# Instalar PyInstaller si no está
echo "→ Verificando PyInstaller..."
pip install pyinstaller --quiet

# Incluir FFmpeg en el paquete
echo "→ Localizando FFmpeg..."
FFMPEG_PATH=$(which ffmpeg)
FFPROBE_PATH=$(which ffprobe)

if [ -z "$FFMPEG_PATH" ]; then
    echo "✗ FFmpeg no encontrado. Instálalo: brew install ffmpeg"
    exit 1
fi

echo "  FFmpeg: $FFMPEG_PATH"
echo "  FFprobe: $FFPROBE_PATH"

# Limpiar builds anteriores
echo "→ Limpiando builds anteriores..."
rm -rf build/ dist/

# Empaquetar con PyInstaller
echo ""
echo "→ Empaquetando aplicación (esto puede tardar varios minutos)..."
echo ""

pyinstaller \
    --name="AureaTranscribe" \
    --windowed \
    --noconfirm \
    --clean \
    --add-data="index.html:." \
    --add-binary="$FFMPEG_PATH:." \
    --add-binary="$FFPROBE_PATH:." \
    --hidden-import=faster_whisper \
    --hidden-import=ctranslate2 \
    --hidden-import=flask \
    --hidden-import=docx \
    --hidden-import=reportlab \
    --hidden-import=reportlab.lib \
    --hidden-import=reportlab.platypus \
    --hidden-import=huggingface_hub \
    --hidden-import=tokenizers \
    --exclude-module=tkinter \
    --exclude-module=pyannote \
    --argv-emulation \
    --osx-bundle-identifier="com.aurealaboral.transcribe" \
    main.py

echo ""
echo "→ Aplicación empaquetada en dist/AureaTranscribe.app"

# Crear DMG
echo ""
echo "→ Creando imagen de disco (.dmg)..."

DMG_NAME="AureaTranscribe-1.0-macOS"
DMG_DIR="dist/dmg_temp"
DMG_PATH="dist/$DMG_NAME.dmg"

rm -rf "$DMG_DIR"
mkdir -p "$DMG_DIR"

# Copiar .app al directorio temporal
cp -R "dist/AureaTranscribe.app" "$DMG_DIR/"

# Crear enlace a Aplicaciones
ln -s /Applications "$DMG_DIR/Aplicaciones"

# Crear DMG
hdiutil create -volname "AureaTranscribe" \
    -srcfolder "$DMG_DIR" \
    -ov -format UDZO \
    "$DMG_PATH"

rm -rf "$DMG_DIR"

echo ""
echo "═══════════════════════════════════════════════════"
echo "✓ Empaquetado completado"
echo ""
echo "  Archivos generados:"
echo "    • dist/AureaTranscribe.app  (aplicación)"
echo "    • dist/$DMG_NAME.dmg  (instalador)"
echo ""
echo "  El .dmg es lo que puedes subir a tu servidor"
echo "  para que cualquiera lo descargue e instale."
echo ""
echo "  El usuario solo tiene que:"
echo "    1. Descargar el .dmg"
echo "    2. Abrirlo"
echo "    3. Arrastrar AureaTranscribe a Aplicaciones"
echo "    4. Abrir AureaTranscribe desde Aplicaciones"
echo "═══════════════════════════════════════════════════"
echo ""

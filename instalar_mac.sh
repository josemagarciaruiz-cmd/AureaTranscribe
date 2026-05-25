#!/bin/bash
# ═══════════════════════════════════════════════════════
# AureaTranscribe — Instalador para macOS
# ═══════════════════════════════════════════════════════

set -e

echo ""
echo "╔═══════════════════════════════════════════════╗"
echo "║         AureaTranscribe — Instalador          ║"
echo "║     Transcripción profesional en local        ║"
echo "╚═══════════════════════════════════════════════╝"
echo ""

# Verificar Python 3.9+
echo "→ Verificando Python..."
if ! command -v python3 &> /dev/null; then
    echo "✗ Python 3 no encontrado."
    echo "  Instálalo desde https://www.python.org/downloads/"
    echo "  O ejecuta: brew install python3"
    exit 1
fi

PYTHON_VERSION=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
echo "  Python $PYTHON_VERSION encontrado ✓"

# Verificar FFmpeg
echo ""
echo "→ Verificando FFmpeg..."
if ! command -v ffmpeg &> /dev/null; then
    echo "  FFmpeg no encontrado. Instalando con Homebrew..."
    if ! command -v brew &> /dev/null; then
        echo "✗ Homebrew no encontrado."
        echo "  Instala Homebrew: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        echo "  Luego ejecuta: brew install ffmpeg"
        exit 1
    fi
    brew install ffmpeg
    echo "  FFmpeg instalado ✓"
else
    echo "  FFmpeg encontrado ✓"
fi

# Crear entorno virtual
echo ""
echo "→ Creando entorno virtual..."
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

python3 -m venv venv
source venv/bin/activate

# Instalar dependencias base
echo ""
echo "→ Instalando dependencias base (esto puede tardar unos minutos)..."
pip install --upgrade pip --quiet
pip install -r requirements.txt --quiet

echo ""
echo "═══════════════════════════════════════════════════"
echo "✓ Instalación base completada"
echo "═══════════════════════════════════════════════════"

# Preguntar por diarización
echo ""
echo "┌───────────────────────────────────────────────┐"
echo "│  ¿Quieres instalar la DIARIZACIÓN?            │"
echo "│                                               │"
echo "│  La diarización permite identificar quién     │"
echo "│  habla en cada momento del audio.             │"
echo "│  Requiere un token gratuito de HuggingFace.   │"
echo "│                                               │"
echo "│  La descarga adicional es de ~2 GB.           │"
echo "└───────────────────────────────────────────────┘"
echo ""
read -p "  ¿Instalar diarización? (s/n): " INSTALL_DIARIZATION

if [[ "$INSTALL_DIARIZATION" =~ ^[sS]$ ]]; then
    echo ""
    echo "→ Instalando dependencias de diarización..."
    echo "  (esto puede tardar varios minutos, se descargan ~2 GB)"
    echo ""
    pip install -r requirements_diarization.txt --quiet
    echo ""
    echo "  ✓ Diarización instalada"
    echo ""
    echo "  IMPORTANTE: Para usar la diarización necesitas un token"
    echo "  gratuito de HuggingFace. Sigue estos pasos:"
    echo ""
    echo "    1. Ve a https://huggingface.co/settings/tokens"
    echo "    2. Crea una cuenta si no tienes (es gratis)"
    echo "    3. Pulsa 'Create new token'"
    echo "    4. Selecciona 'Read' como tipo de acceso"
    echo "    5. Dale un nombre (ej: 'AureaTranscribe')"
    echo "    6. Copia el token generado"
    echo "    7. Acepta las condiciones de uso de estos modelos:"
    echo "       - https://huggingface.co/pyannote/speaker-diarization-3.1"
    echo "       - https://huggingface.co/pyannote/segmentation-3.0"
    echo "    8. Pega el token en AureaTranscribe cuando actives"
    echo "       la diarización (solo la primera vez, se guarda)"
    echo ""
else
    echo ""
    echo "  Diarización no instalada. Puedes instalarla más"
    echo "  adelante ejecutando:"
    echo "    cd $SCRIPT_DIR"
    echo "    source venv/bin/activate"
    echo "    pip install -r requirements_diarization.txt"
    echo ""
fi

echo "═══════════════════════════════════════════════════"
echo ""
echo "  Para ejecutar AureaTranscribe:"
echo "    cd $SCRIPT_DIR"
echo "    ./ejecutar_mac.sh"
echo ""
echo "  Nota: La primera ejecución descargará el modelo"
echo "  Whisper (~1.5 GB para 'medium'). Solo se hace una vez."
echo ""
echo "═══════════════════════════════════════════════════"
echo ""

# Crear script de ejecución rápida
cat > "$SCRIPT_DIR/ejecutar_mac.sh" << 'EXEC'
#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"
source venv/bin/activate
python main.py
EXEC
chmod +x "$SCRIPT_DIR/ejecutar_mac.sh"

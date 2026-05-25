# AureaTranscribe

Aplicación de escritorio para transcripción profesional de audio y vídeo en local. Motor Whisper con soporte multi-idioma, diarización de hablantes (identifica quién habla en cada momento) y exportación a múltiples formatos.

Construida con **Python · Whisper (faster-whisper) · Flask · pyannote.audio**.

Todo el procesamiento se realiza en tu equipo — ningún audio se envía a la nube.

---

## Características

- **Transcripción local** con Whisper (modelos tiny a large-v3)
- **Diarización de hablantes** — identifica quién habla en cada momento (opcional, requiere token gratuito de HuggingFace)
- **Multi-idioma** — español, inglés, francés, alemán, italiano, portugués, catalán, gallego, euskera y más
- **Detección multilingüe** — transcribe conversaciones donde se mezclan idiomas
- **Exportación** a PDF, Word (.docx), TXT, Markdown, SRT, VTT y JSON
- **Perfil personalizable** — tus datos (nombre, empresa, email) aparecen en los documentos exportados
- **Interfaz web local** — se abre en ventana nativa o en tu navegador
- **Formatos de entrada** — MP3, WAV, M4A, OGG, FLAC, MP4, MKV, AVI, MOV y más

---

## Requisitos previos

| Herramienta | Versión | Notas |
|---|---|---|
| Python | **3.9+** | En Windows: marca "Add Python to PATH" durante la instalación |
| FFmpeg | cualquiera | Necesario para procesar audio/vídeo |

### macOS

FFmpeg se instala automáticamente con Homebrew si no lo tienes. Si no tienes Homebrew:

```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew install ffmpeg
```

### Windows

1. Descarga FFmpeg desde https://www.gyan.dev/ffmpeg/builds/ (ffmpeg-release-essentials.zip)
2. Extrae el ZIP en `C:\ffmpeg`
3. Añade `C:\ffmpeg\bin` a la variable PATH del sistema:
   Panel de control → Sistema → Variables de entorno → Path → Editar → Nuevo → `C:\ffmpeg\bin`

---

## Descargar e instalar

### Opción 1: Descargar el ZIP (recomendada)

1. Ve a la sección [**Releases**](../../releases) de este repositorio
2. Descarga el archivo **AureaTranscribe-v1.0.zip** de la última release
3. Descomprime el ZIP en la carpeta que prefieras
4. Ejecuta el instalador:
   - **macOS:** abre Terminal, navega a la carpeta y ejecuta `./instalar_mac.sh`
   - **Windows:** haz doble clic en `instalar_windows.bat`

### Opción 2: Clonar el repositorio

```bash
git clone https://github.com/josemagarciaruiz-cmd/AureaTranscribe.git
cd AureaTranscribe

# macOS
chmod +x instalar_mac.sh
./instalar_mac.sh

# Windows
instalar_windows.bat
```

El instalador:
- Verifica que tengas Python y FFmpeg
- Crea un entorno virtual aislado
- Instala todas las dependencias
- Te pregunta si quieres instalar la **diarización** (identificación de hablantes)

---

## Configurar la diarización (opcional)

La diarización permite identificar quién habla en cada momento del audio. Requiere un token gratuito de HuggingFace y una descarga adicional de ~2 GB.

### Obtener el token de HuggingFace

1. Ve a https://huggingface.co/settings/tokens
2. Crea una cuenta si no tienes (es gratis)
3. Pulsa **Create new token**
4. Selecciona **Read** como tipo de acceso
5. Dale un nombre (ej: "AureaTranscribe")
6. Copia el token generado
7. Acepta las condiciones de uso de estos modelos:
   - https://huggingface.co/pyannote/speaker-diarization-3.1
   - https://huggingface.co/pyannote/segmentation-3.0
8. Pega el token en AureaTranscribe cuando actives la diarización (solo la primera vez, se guarda automáticamente)

---

## Uso diario

```bash
# macOS
cd /ruta/a/AureaTranscribe
./ejecutar_mac.sh

# Windows
# Haz doble clic en ejecutar_windows.bat
```

La aplicación se abre en una ventana nativa. Si `pywebview` no está disponible, se abre en tu navegador por defecto.

### Flujo de trabajo

1. **Sube tu archivo** — arrastra un audio o vídeo a la zona de subida
2. **Configura** — elige modelo, idioma y si quieres diarización
3. **Transcribe** — pulsa el botón y espera (la primera vez descarga el modelo Whisper, ~1.5 GB para "medium")
4. **Revisa** — edita los nombres de los interlocutores si usaste diarización
5. **Exporta** — descarga en PDF, Word, TXT, Markdown, SRT, VTT o JSON

### Perfil personalizable

En la sección **Mi perfil** puedes registrar tu nombre, empresa y email. Estos datos aparecerán en la cabecera de los documentos que exportes. Si los dejas vacíos, solo se muestra la fecha y hora.

---

## Estructura del proyecto

```
AureaTranscribe/
├── main.py                    # Entrada principal de la aplicación
├── server.py                  # Servidor Flask (API REST)
├── transcription_engine.py    # Motor Whisper + diarización + exportadores
├── index.html                 # Interfaz web
├── requirements.txt           # Dependencias base
├── requirements_diarization.txt  # Dependencias de diarización (opcional)
├── instalar_mac.sh            # Instalador para macOS
├── instalar_windows.bat       # Instalador para Windows
├── empaquetar_mac.sh          # Empaquetador .app/.dmg (macOS)
├── empaquetar_windows.bat     # Empaquetador .exe (Windows)
└── Instrucciones_*.docx       # Manuales de instalación
```

---

## Solución de problemas

### "Python no encontrado"

Asegúrate de que Python 3.9+ está instalado y en el PATH del sistema. En Windows, reinstala Python marcando **"Add Python to PATH"**.

### "FFmpeg no encontrado"

- **macOS:** `brew install ffmpeg`
- **Windows:** descarga desde https://www.gyan.dev/ffmpeg/builds/ y añade `C:\ffmpeg\bin` al PATH

### La diarización no funciona

1. Verifica que instalaste las dependencias de diarización (`pip install -r requirements_diarization.txt`)
2. Comprueba que tu token de HuggingFace es válido
3. Confirma que aceptaste las condiciones de uso de los modelos pyannote en HuggingFace

### La primera transcripción tarda mucho

Es normal. La primera vez se descarga el modelo Whisper (~1.5 GB para "medium"). Las siguientes transcripciones serán mucho más rápidas.

### Error de compatibilidad con PyTorch

AureaTranscribe incluye parches automáticos para PyTorch 2.6+ (weights_only) y huggingface_hub 1.0+. Si experimentas problemas, asegúrate de usar las versiones especificadas en `requirements_diarization.txt`.

---

## Nota sobre advertencias de seguridad

Al no estar firmada con certificado de pago:
- **macOS:** Gatekeeper mostrará un aviso → clic derecho → Abrir → Abrir de todas formas
- **Windows:** SmartScreen mostrará un aviso → "Más información" → "Ejecutar de todas formas"

Ambas advertencias son normales para apps de distribución directa no firmadas.

---

## Licencia

Todos los derechos reservados. © Áurea Laboral.

---

*Powered by AureaTranscribe · Áurea Laboral*

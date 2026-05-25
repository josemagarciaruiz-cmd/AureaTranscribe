@echo off
chcp 65001 >nul
REM ═══════════════════════════════════════════════════════
REM AureaTranscribe — Instalador para Windows
REM ═══════════════════════════════════════════════════════

echo.
echo ╔═══════════════════════════════════════════════╗
echo ║         AureaTranscribe — Instalador          ║
echo ║     Transcripcion profesional en local        ║
echo ╚═══════════════════════════════════════════════╝
echo.

REM Verificar Python
echo → Verificando Python...
python --version >nul 2>&1
if errorlevel 1 (
    echo X Python no encontrado.
    echo   Descargalo desde https://www.python.org/downloads/
    echo   IMPORTANTE: Marca "Add Python to PATH" durante la instalacion.
    pause
    exit /b 1
)
python --version
echo   Python encontrado √
echo.

REM Verificar FFmpeg
echo → Verificando FFmpeg...
ffmpeg -version >nul 2>&1
if errorlevel 1 (
    echo   FFmpeg no encontrado.
    echo.
    echo   Para instalar FFmpeg en Windows:
    echo   1. Descarga desde https://www.gyan.dev/ffmpeg/builds/
    echo      ^(ffmpeg-release-essentials.zip^)
    echo   2. Extrae el ZIP en C:\ffmpeg
    echo   3. Anade C:\ffmpeg\bin a la variable PATH del sistema:
    echo      Panel de control → Sistema → Variables de entorno
    echo      → Path → Editar → Nuevo → C:\ffmpeg\bin
    echo   4. Reinicia esta ventana y ejecuta de nuevo este instalador.
    echo.
    pause
    exit /b 1
)
echo   FFmpeg encontrado √
echo.

REM Crear entorno virtual
echo → Creando entorno virtual...
cd /d "%~dp0"
python -m venv venv
call venv\Scripts\activate.bat

REM Instalar dependencias base
echo.
echo → Instalando dependencias base (esto puede tardar unos minutos)...
pip install --upgrade pip --quiet
pip install -r requirements.txt --quiet

echo.
echo ═══════════════════════════════════════════════════
echo √ Instalacion base completada
echo ═══════════════════════════════════════════════════
echo.

REM Preguntar por diarización
echo ┌───────────────────────────────────────────────┐
echo │  ¿Quieres instalar la DIARIZACION?            │
echo │                                               │
echo │  La diarizacion permite identificar quien     │
echo │  habla en cada momento del audio.             │
echo │  Requiere un token gratuito de HuggingFace.   │
echo │                                               │
echo │  La descarga adicional es de ~2 GB.           │
echo └───────────────────────────────────────────────┘
echo.
set /p INSTALL_DIAR="  ¿Instalar diarizacion? (s/n): "

if /i "%INSTALL_DIAR%"=="s" (
    echo.
    echo → Instalando dependencias de diarizacion...
    echo   ^(esto puede tardar varios minutos, se descargan ~2 GB^)
    echo.
    pip install -r requirements_diarization.txt --quiet
    echo.
    echo   √ Diarizacion instalada
    echo.
    echo   IMPORTANTE: Para usar la diarizacion necesitas un token
    echo   gratuito de HuggingFace. Sigue estos pasos:
    echo.
    echo     1. Ve a https://huggingface.co/settings/tokens
    echo     2. Crea una cuenta si no tienes ^(es gratis^)
    echo     3. Pulsa 'Create new token'
    echo     4. Selecciona 'Read' como tipo de acceso
    echo     5. Dale un nombre ^(ej: 'AureaTranscribe'^)
    echo     6. Copia el token generado
    echo     7. Acepta las condiciones de uso de estos modelos:
    echo        - https://huggingface.co/pyannote/speaker-diarization-3.1
    echo        - https://huggingface.co/pyannote/segmentation-3.0
    echo     8. Pega el token en AureaTranscribe cuando actives
    echo        la diarizacion ^(solo la primera vez, se guarda^)
    echo.
) else (
    echo.
    echo   Diarizacion no instalada. Puedes instalarla mas
    echo   adelante ejecutando:
    echo     cd "%~dp0"
    echo     venv\Scripts\activate.bat
    echo     pip install -r requirements_diarization.txt
    echo.
)

echo ═══════════════════════════════════════════════════
echo.
echo   Para ejecutar AureaTranscribe:
echo     Haz doble clic en ejecutar_windows.bat
echo.
echo   Nota: La primera ejecucion descargara el modelo
echo   Whisper (~1.5 GB para 'medium'). Solo se hace una vez.
echo.
echo ═══════════════════════════════════════════════════
echo.

REM Crear script de ejecución rápida
(
echo @echo off
echo cd /d "%%~dp0"
echo call venv\Scripts\activate.bat
echo python main.py
echo pause
) > "%~dp0ejecutar_windows.bat"

pause

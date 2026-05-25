@echo off
chcp 65001 >nul
REM ═══════════════════════════════════════════════════════
REM AureaTranscribe — Empaquetador para Windows
REM Genera AureaTranscribe.exe (instalador autocontenido)
REM ═══════════════════════════════════════════════════════

echo.
echo ╔═══════════════════════════════════════════════╗
echo ║    AureaTranscribe — Empaquetador Windows      ║
echo ╚═══════════════════════════════════════════════╝
echo.

cd /d "%~dp0"

REM Activar entorno virtual
if not exist "venv" (
    echo X No se encontro el entorno virtual.
    echo   Ejecuta primero: instalar_windows.bat
    pause
    exit /b 1
)
call venv\Scripts\activate.bat

REM Instalar PyInstaller
echo → Verificando PyInstaller...
pip install pyinstaller --quiet

REM Localizar FFmpeg
echo → Localizando FFmpeg...
where ffmpeg >nul 2>&1
if errorlevel 1 (
    echo X FFmpeg no encontrado. Instalalo antes de empaquetar.
    pause
    exit /b 1
)
for /f "tokens=*" %%i in ('where ffmpeg') do set FFMPEG_PATH=%%i
for /f "tokens=*" %%i in ('where ffprobe') do set FFPROBE_PATH=%%i
echo   FFmpeg: %FFMPEG_PATH%
echo   FFprobe: %FFPROBE_PATH%

REM Limpiar builds anteriores
echo → Limpiando builds anteriores...
rmdir /s /q build 2>nul
rmdir /s /q dist 2>nul

REM Empaquetar
echo.
echo → Empaquetando aplicacion (esto puede tardar varios minutos)...
echo.

pyinstaller ^
    --name="AureaTranscribe" ^
    --windowed ^
    --noconfirm ^
    --clean ^
    --add-data="index.html;." ^
    --add-binary="%FFMPEG_PATH%;." ^
    --add-binary="%FFPROBE_PATH%;." ^
    --hidden-import=faster_whisper ^
    --hidden-import=ctranslate2 ^
    --hidden-import=flask ^
    --hidden-import=docx ^
    --hidden-import=reportlab ^
    --hidden-import=reportlab.lib ^
    --hidden-import=reportlab.platypus ^
    --hidden-import=huggingface_hub ^
    --hidden-import=tokenizers ^
    --exclude-module=tkinter ^
    --exclude-module=pyannote ^
    --icon=icon.ico ^
    main.py

echo.
echo ═══════════════════════════════════════════════════
echo √ Empaquetado completado
echo.
echo   Archivo generado:
echo     dist\AureaTranscribe\AureaTranscribe.exe
echo.
echo   Para distribuir, comprime la carpeta
echo   dist\AureaTranscribe en un ZIP y subela
echo   a tu servidor.
echo.
echo   El usuario solo tiene que:
echo     1. Descargar el ZIP
echo     2. Extraerlo donde quiera
echo     3. Ejecutar AureaTranscribe.exe
echo ═══════════════════════════════════════════════════
echo.
pause

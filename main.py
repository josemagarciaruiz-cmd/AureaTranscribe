#!/usr/bin/env python3
"""
AureaTranscribe — Transcripción profesional de audio en local.
Aplicación de escritorio con motor Whisper, diarización de hablantes
y soporte para todos los formatos de audio y vídeo.

© Áurea Laboral — Powered by AureaTranscribe.
"""

import sys
import os
import threading
import webbrowser
import signal
import time

def resource_path(relative_path):
    """Obtiene la ruta correcta tanto en desarrollo como empaquetado con PyInstaller."""
    if getattr(sys, '_MEIPASS', None):
        return os.path.join(sys._MEIPASS, relative_path)
    return os.path.join(os.path.dirname(os.path.abspath(__file__)), relative_path)

def main():
    # Importar servidor
    from server import create_app

    app = create_app()
    port = 7860

    # Intentar usar pywebview para ventana nativa
    try:
        import webview

        def start_server():
            app.run(host="127.0.0.1", port=port, debug=False, use_reloader=False)

        server_thread = threading.Thread(target=start_server, daemon=True)
        server_thread.start()
        time.sleep(1.5)  # Esperar a que el servidor arranque

        window = webview.create_window(
            "AureaTranscribe",
            url=f"http://127.0.0.1:{port}",
            width=1200,
            height=800,
            min_size=(900, 600),
            resizable=True,
            confirm_close=True,
            text_select=True,
        )
        webview.start(gui="cef" if sys.platform == "win32" else None)

    except ImportError:
        # Fallback: abrir en navegador por defecto
        print("\n" + "=" * 60)
        print("  AureaTranscribe")
        print("  Transcripción profesional en local")
        print("=" * 60)
        print(f"\n  Abriendo en el navegador: http://127.0.0.1:{port}")
        print("  Pulsa Ctrl+C para cerrar la aplicación.\n")

        def open_browser():
            time.sleep(1.5)
            webbrowser.open(f"http://127.0.0.1:{port}")

        threading.Thread(target=open_browser, daemon=True).start()

        def signal_handler(sig, frame):
            print("\n  Cerrando AureaTranscribe...")
            sys.exit(0)

        signal.signal(signal.SIGINT, signal_handler)
        app.run(host="127.0.0.1", port=port, debug=False, use_reloader=False)


if __name__ == "__main__":
    main()

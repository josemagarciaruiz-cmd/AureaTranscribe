"""
Servidor Flask de AureaTranscribe.
API REST para transcripción, gestión de modelos y exportación.
"""

import os
import uuid
import json
import tempfile
import threading
import logging
from pathlib import Path

from flask import Flask, request, jsonify, send_file

logger = logging.getLogger("AureaTranscribe")
logging.basicConfig(level=logging.INFO)

_engine = None
_jobs = {}
_lock = threading.Lock()

# ── Archivo de configuración persistente ──
_config_dir = os.path.join(os.path.expanduser("~"), ".config", "aurea_transcribe")
_config_file = os.path.join(_config_dir, "config.json")


def _load_config() -> dict:
    try:
        with open(_config_file, "r") as f:
            return json.load(f)
    except Exception:
        return {}


def _save_config(config: dict):
    os.makedirs(_config_dir, exist_ok=True)
    with open(_config_file, "w") as f:
        json.dump(config, f)


def get_engine():
    global _engine
    if _engine is None:
        from transcription_engine import TranscriptionEngine
        _engine = TranscriptionEngine()
    return _engine


def create_app():
    app = Flask(__name__)
    app.config["MAX_CONTENT_LENGTH"] = 2 * 1024 * 1024 * 1024  # 2 GB

    upload_dir = os.path.join(tempfile.gettempdir(), "aurea_transcribe_uploads")
    os.makedirs(upload_dir, exist_ok=True)
    export_dir = os.path.join(tempfile.gettempdir(), "aurea_transcribe_exports")
    os.makedirs(export_dir, exist_ok=True)

    # ── Página principal ──

    @app.route("/")
    def index():
        import sys
        if getattr(sys, '_MEIPASS', None):
            base_dir = sys._MEIPASS
        else:
            base_dir = os.path.dirname(os.path.abspath(__file__))
        html_path = os.path.join(base_dir, "index.html")
        with open(html_path, "r", encoding="utf-8") as f:
            return f.read()

    # ── Info del sistema ──

    @app.route("/api/info")
    def api_info():
        engine = get_engine()
        config = _load_config()
        return jsonify({
            "models": engine.AVAILABLE_MODELS,
            "current_model": engine.model_name,
            "diarization_available": engine.check_diarization(),
            "hf_token_saved": bool(config.get("hf_token")),
            "supported_formats": [
                "mp3", "wav", "m4a", "ogg", "flac", "wma", "aac", "opus",
                "mp4", "mkv", "avi", "mov", "webm", "wmv", "flv", "3gp",
            ],
        })

    # ── Guardar/cargar token HuggingFace ──

    @app.route("/api/hf-token", methods=["GET"])
    def api_get_hf_token():
        config = _load_config()
        has_token = bool(config.get("hf_token"))
        return jsonify({"saved": has_token})

    @app.route("/api/hf-token", methods=["POST"])
    def api_save_hf_token():
        data = request.get_json() or {}
        token = data.get("token", "").strip()
        if not token:
            return jsonify({"error": "Token vacío"}), 400
        config = _load_config()
        config["hf_token"] = token
        _save_config(config)
        return jsonify({"status": "ok", "message": "Token guardado"})

    @app.route("/api/hf-token", methods=["DELETE"])
    def api_delete_hf_token():
        config = _load_config()
        config.pop("hf_token", None)
        _save_config(config)
        return jsonify({"status": "ok"})

    # ── Perfil del usuario ──

    @app.route("/api/profile", methods=["GET"])
    def api_get_profile():
        config = _load_config()
        profile = config.get("user_profile", {"name": "", "firm": "", "email": ""})
        return jsonify(profile)

    @app.route("/api/profile", methods=["POST"])
    def api_save_profile():
        data = request.get_json() or {}
        profile = {
            "name": data.get("name", "").strip(),
            "firm": data.get("firm", "").strip(),
            "email": data.get("email", "").strip(),
        }
        config = _load_config()
        config["user_profile"] = profile
        _save_config(config)
        return jsonify({"status": "ok", "message": "Perfil guardado"})

    # ── Cargar modelo ──

    @app.route("/api/load-model", methods=["POST"])
    def api_load_model():
        data = request.get_json() or {}
        model_name = data.get("model", "medium")
        try:
            get_engine().load_model(model_name)
            return jsonify({"status": "ok", "model": model_name})
        except Exception as e:
            return jsonify({"status": "error", "message": str(e)}), 500

    # ── Transcribir ──

    @app.route("/api/transcribe", methods=["POST"])
    def api_transcribe():
        if "file" not in request.files:
            return jsonify({"error": "No se ha enviado ningún archivo"}), 400

        file = request.files["file"]
        if file.filename == "":
            return jsonify({"error": "Nombre de archivo vacío"}), 400

        ext = Path(file.filename).suffix
        temp_path = os.path.join(upload_dir, f"{uuid.uuid4()}{ext}")
        file.save(temp_path)

        model = request.form.get("model", "medium")
        language = request.form.get("language", "").strip() or None
        multilingual = request.form.get("multilingual", "false").lower() == "true"
        diarize = request.form.get("diarize", "false").lower() == "true"
        hf_token = request.form.get("hf_token", "").strip() or None

        # Si no se proporcionó token pero hay uno guardado, usarlo
        if not hf_token and diarize:
            config = _load_config()
            hf_token = config.get("hf_token")

        # Si se proporcionó un token nuevo, guardarlo para futuras sesiones
        if hf_token and request.form.get("hf_token", "").strip():
            config = _load_config()
            config["hf_token"] = hf_token
            _save_config(config)

        job_id = str(uuid.uuid4())
        with _lock:
            _jobs[job_id] = {
                "status": "running",
                "progress": 0,
                "message": "Iniciando transcripción...",
                "result": None,
                "error": None,
                "file_path": temp_path,
                "original_name": file.filename,
            }

        def run_transcription():
            try:
                engine = get_engine()
                if engine.model_name != model:
                    engine.load_model(
                        model,
                        progress_callback=lambda stage, msg, pct=0:
                            _update_job(job_id, msg, pct)
                    )

                def progress_cb(stage, message, pct=0):
                    _update_job(job_id, message, pct)

                result = engine.transcribe(
                    file_path=temp_path,
                    language=language,
                    multilingual=multilingual,
                    diarize=diarize,
                    hf_token=hf_token,
                    progress_callback=progress_cb,
                )

                with _lock:
                    _jobs[job_id]["status"] = "completed"
                    _jobs[job_id]["progress"] = 100
                    _jobs[job_id]["message"] = "Transcripción completada"
                    _jobs[job_id]["result"] = result

            except Exception as e:
                import traceback
                print("\n" + "=" * 60)
                print("[AureaTranscribe] ERROR EN TRANSCRIPCIÓN:")
                print(f"  Tipo: {type(e).__name__}")
                print(f"  Mensaje: {e}")
                try:
                    traceback.print_exc()
                except Exception:
                    pass
                print("=" * 60 + "\n")
                with _lock:
                    _jobs[job_id]["status"] = "error"
                    _jobs[job_id]["message"] = str(e)
                    _jobs[job_id]["error"] = str(e)
            finally:
                try:
                    if os.path.exists(temp_path):
                        os.unlink(temp_path)
                except Exception:
                    pass

        threading.Thread(target=run_transcription, daemon=True).start()
        return jsonify({"job_id": job_id})

    # ── Estado del job ──

    @app.route("/api/job/<job_id>")
    def api_job_status(job_id):
        with _lock:
            job = _jobs.get(job_id)
        if not job:
            return jsonify({"error": "Job no encontrado"}), 404

        response = {
            "status": job["status"],
            "progress": job["progress"],
            "message": job["message"],
        }
        if job["status"] == "completed" and job["result"]:
            response["result"] = job["result"].to_dict()
        if job["status"] == "error":
            response["error"] = job["error"]
        return jsonify(response)

    # ── Actualizar nombres de hablantes ──

    @app.route("/api/job/<job_id>/speakers", methods=["POST"])
    def api_update_speakers(job_id):
        with _lock:
            job = _jobs.get(job_id)
        if not job or job["status"] != "completed":
            return jsonify({"error": "Transcripción no disponible"}), 404

        data = request.get_json() or {}
        speaker_names = data.get("speaker_names", {})

        with _lock:
            if _jobs[job_id]["result"]:
                _jobs[job_id]["result"].speaker_names = speaker_names

        return jsonify({"status": "ok"})

    # ── Exportar ──

    @app.route("/api/export/<job_id>", methods=["POST"])
    def api_export(job_id):
        with _lock:
            job = _jobs.get(job_id)
        if not job or job["status"] != "completed":
            return jsonify({"error": "Transcripción no disponible"}), 404

        data = request.get_json() or {}
        fmt = data.get("format", "txt")
        result = job["result"]
        original = Path(job.get("original_name", "transcripcion")).stem

        from transcription_engine import (
            export_txt, export_srt, export_vtt, export_docx,
            export_json, export_pdf, export_md
        )

        filename = f"{original}_transcripcion.{fmt}"
        output_path = os.path.join(export_dir, f"{uuid.uuid4()}_{filename}")

        try:
            exporters = {
                "txt": export_txt,
                "srt": export_srt,
                "vtt": export_vtt,
                "docx": export_docx,
                "json": export_json,
                "pdf": export_pdf,
                "md": export_md,
            }
            exporter = exporters.get(fmt)
            if not exporter:
                return jsonify({"error": f"Formato no soportado: {fmt}"}), 400

            # Cargar perfil del usuario para los formatos que lo soportan
            if fmt in ("txt", "md", "docx", "pdf"):
                config = _load_config()
                user_profile = config.get("user_profile", {})
                exporter(result, output_path, user_profile=user_profile)
            else:
                exporter(result, output_path)

            return send_file(
                output_path, as_attachment=True, download_name=filename,
            )
        except Exception as e:
            logger.exception("Error al exportar")
            return jsonify({"error": str(e)}), 500

    return app


def _update_job(job_id: str, message: str, progress: int = 0):
    with _lock:
        if job_id in _jobs:
            _jobs[job_id]["message"] = message
            if progress > 0:
                _jobs[job_id]["progress"] = progress

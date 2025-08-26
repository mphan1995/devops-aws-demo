import os
import uuid
import time
import logging
import json
from flask import Flask, jsonify, request, g

app = Flask(__name__)

# ---------------------------
# Logging JSON Formatter
# ---------------------------
class JsonFormatter(logging.Formatter):
    def format(self, record):
        payload = {
            "ts": int(time.time()),
            "level": record.levelname,
            "message": record.getMessage(),
            "logger": record.name,
            "request_id": getattr(g, "req_id", None),
            "path": request.path if request else None,
            "method": request.method if request else None,
            "remote": request.remote_addr if request else None,
        }
        return json.dumps(payload, ensure_ascii=False)


handler = logging.StreamHandler()
handler.setFormatter(JsonFormatter())
app.logger.setLevel(logging.INFO)
app.logger.addHandler(handler)


# ---------------------------
# Middleware: set request_id
# ---------------------------
@app.before_request
def set_req_id():
    g.req_id = request.headers.get("x-request-id", str(uuid.uuid4()))


# ---------------------------
# Routes
# ---------------------------

@app.get("/health")
def health():
    """Health check endpoint for App Runner"""
    app.logger.info("health check ok")
    return jsonify(status="ok")


@app.get("/")
def index():
    """Default root endpoint"""
    app.logger.info("hello endpoint called")
    return jsonify(message="Hello from DevSecOps demo (advanced)")


@app.get("/version")
def version():
    """Return app version and env info"""
    version = os.getenv("APP_VERSION", "1.0.0")
    env = os.getenv("FLASK_ENV", "production")
    return jsonify(version=version, environment=env)


@app.post("/echo")
def echo():
    """Echo back posted JSON"""
    data = request.get_json(force=True, silent=True) or {}
    app.logger.info("echo called")
    return jsonify(received=data, request_id=g.req_id)


@app.get("/error")
def trigger_error():
    """Intentional error to test monitoring"""
    app.logger.warning("error endpoint triggered")
    return jsonify(error="Something went wrong"), 500


# ---------------------------
# Main entry
# ---------------------------
if __name__ == "__main__":
    app.run(
        host="0.0.0.0",
        port=int(os.getenv("PORT", "8080")),
        debug=False,
    )

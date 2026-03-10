"""
Lab 3: Aplicación Flask — API REST Básica
==========================================
Aplicación web sencilla con página principal y endpoints REST.
Demuestra buenas prácticas: usuario non-root, health checks.
"""

import os
import socket
from datetime import datetime

from flask import Flask, jsonify, render_template

app = Flask(__name__)


# ─── PÁGINA PRINCIPAL ──────────────────────────────
@app.route("/")
def index():
    return render_template(
        "index.html",
        hostname=socket.gethostname(),
        timestamp=datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
    )


# ─── HEALTH CHECK ──────────────────────────────────
@app.route("/health")
def health():
    return jsonify({"status": "ok", "service": "flask-lab3"})


# ─── API INFO ──────────────────────────────────────
@app.route("/api/info")
def api_info():
    return jsonify(
        {
            "app": "Flask Lab 3",
            "version": "1.0",
            "hostname": socket.gethostname(),
            "platform": os.uname().sysname,
            "python": os.popen("python --version").read().strip(),
            "timestamp": datetime.now().isoformat(),
        }
    )


if __name__ == "__main__":
    print("=" * 50)
    print("  Flask Lab 3 — API REST Básica")
    print("  http://0.0.0.0:5000")
    print("=" * 50)
    app.run(host="0.0.0.0", port=5000)

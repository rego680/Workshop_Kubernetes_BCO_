"""
Lab 2 - Unidad 2: Imagen Flask para practicar push a DockerHub.
Servidor web simple con health check y metadata.
"""

import os
import socket
from datetime import datetime
from flask import Flask, jsonify

app = Flask(__name__)

VERSION = "1.0.0"


@app.route("/")
def index():
    hostname = socket.gethostname()
    return f"""<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<title>Lab 2 - DockerHub Push</title>
<style>
  * {{ margin: 0; padding: 0; box-sizing: border-box; }}
  body {{
    font-family: 'Segoe UI', sans-serif;
    background: linear-gradient(135deg, #0c0c1d, #1a1a3e, #2d1b69);
    color: #fff;
    min-height: 100vh;
    display: flex;
    align-items: center;
    justify-content: center;
  }}
  .card {{
    background: rgba(255,255,255,0.06);
    border: 1px solid rgba(255,255,255,0.12);
    border-radius: 16px;
    padding: 40px;
    max-width: 520px;
    text-align: center;
    backdrop-filter: blur(10px);
  }}
  .icon {{ font-size: 3.5rem; margin-bottom: 10px; }}
  h1 {{ font-size: 1.6rem; margin-bottom: 6px; color: #a78bfa; }}
  .sub {{ color: #888; font-size: 0.85rem; margin-bottom: 24px; }}
  .info {{
    background: rgba(0,0,0,0.3);
    border-radius: 8px;
    padding: 16px;
    text-align: left;
    font-family: monospace;
    font-size: 0.85rem;
    line-height: 2;
  }}
  .label {{ color: #888; }}
  .value {{ color: #a78bfa; }}
  .footer {{ margin-top: 20px; color: #555; font-size: 0.7rem; }}
</style>
</head>
<body>
<div class="card">
  <div class="icon">&#x1F4E6;</div>
  <h1>DockerHub Push</h1>
  <div class="sub">Unidad 2 - Lab 2 | Build, Tag &amp; Push</div>
  <div class="info">
    <span class="label">Hostname:</span> <span class="value">{hostname}</span><br>
    <span class="label">Version:</span> <span class="value">{VERSION}</span><br>
    <span class="label">Framework:</span> <span class="value">Flask 3.0.0</span><br>
    <span class="label">Runtime:</span> <span class="value">Python 3.12-slim</span><br>
    <span class="label">Puerto:</span> <span class="value">5000</span>
  </div>
  <div class="footer">Imagen lista para push a DockerHub</div>
</div>
</body>
</html>"""


@app.route("/health")
def health():
    return jsonify({"status": "ok", "service": "flask-hub", "version": VERSION})


@app.route("/api/info")
def info():
    return jsonify({
        "hostname": socket.gethostname(),
        "version": VERSION,
        "timestamp": datetime.now().isoformat(),
        "python": os.popen("python --version").read().strip(),
    })


if __name__ == "__main__":
    print("=" * 50)
    print(f"  Flask Hub v{VERSION} - Lab 2 Unidad 2")
    print(f"  http://0.0.0.0:5000")
    print("=" * 50)
    app.run(host="0.0.0.0", port=5000)

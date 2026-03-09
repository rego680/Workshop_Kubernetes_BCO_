"""
Lab 5: VulnFlask - Aplicación Vulnerable para Laboratorio de Seguridad
========================================================================
⚠️  SOLO PARA USO EDUCATIVO EN ENTORNOS AISLADOS
⚠️  Contiene vulnerabilidades INTENCIONALES para prácticas de pentesting

Vulnerabilidades incluidas:
  1. SQL Injection en login y búsqueda
  2. XSS Reflected y Stored
  3. Command Injection via ping
  4. Path Traversal (LFI)
  5. Information Disclosure
  6. Hardcoded credentials
  7. Ejecución como root
"""

import os
import sqlite3
import subprocess
import socket
from flask import Flask, request, render_template, redirect, url_for, session, jsonify

app = Flask(__name__)

# ⚠️  VULNERABILIDAD: Secret key hardcodeada y débil
app.secret_key = "super_secret_key_123"

DB_PATH = "/app/vulnapp.db"


def get_db():
    """Conexión a SQLite."""
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn


# ─── PÁGINA PRINCIPAL ──────────────────────────────
@app.route("/")
def index():
    return render_template("vuln_index.html")


# ─── LOGIN (Vulnerable a SQL Injection) ────────────
@app.route("/login", methods=["GET", "POST"])
def login():
    error = None
    if request.method == "POST":
        username = request.form.get("username", "")
        password = request.form.get("password", "")

        # ⚠️ VULNERABILIDAD: SQL Injection - concatenación directa
        # Payload ejemplo: ' OR '1'='1' --
        query = f"SELECT * FROM users WHERE username='{username}' AND password='{password}'"

        try:
            db = get_db()
            user = db.execute(query).fetchone()
            db.close()

            if user:
                session["user"] = user["username"]
                session["role"] = user["role"]
                return redirect(url_for("dashboard"))
            else:
                error = "Credenciales inválidas"
        except Exception as e:
            # ⚠️ VULNERABILIDAD: Information Disclosure - error expuesto
            error = f"Error en la consulta: {str(e)}"

    return render_template("vuln_login.html", error=error)


# ─── DASHBOARD ─────────────────────────────────────
@app.route("/dashboard")
def dashboard():
    if "user" not in session:
        return redirect(url_for("login"))
    return render_template("vuln_dashboard.html",
                         user=session.get("user"),
                         role=session.get("role"))


# ─── BÚSQUEDA DE USUARIOS (SQL Injection) ─────────
@app.route("/search")
def search():
    query = request.args.get("q", "")
    results = []
    error = None

    if query:
        # ⚠️ VULNERABILIDAD: SQL Injection en búsqueda
        # Payload ejemplo: ' UNION SELECT 1,username,password,email,role,secret_note FROM users--
        sql = f"SELECT id, username, email, role FROM users WHERE username LIKE '%{query}%'"
        try:
            db = get_db()
            results = db.execute(sql).fetchall()
            db.close()
        except Exception as e:
            error = f"Error SQL: {str(e)}"

    # ⚠️ VULNERABILIDAD: XSS Reflected - query sin sanitizar en respuesta
    return render_template("vuln_search.html", query=query, results=results, error=error)


# ─── TABLÓN DE MENSAJES (XSS Stored) ──────────────
@app.route("/messages", methods=["GET", "POST"])
def messages():
    db = get_db()

    if request.method == "POST":
        author = request.form.get("author", "Anónimo")
        content = request.form.get("content", "")

        # ⚠️ VULNERABILIDAD: XSS Stored - contenido sin sanitizar
        # Payload ejemplo: <script>alert('XSS')</script>
        db.execute("INSERT INTO messages (author, content) VALUES (?, ?)",
                  (author, content))
        db.commit()

    msgs = db.execute("SELECT * FROM messages ORDER BY created_at DESC").fetchall()
    db.close()
    return render_template("vuln_messages.html", messages=msgs)


# ─── HERRAMIENTA PING (Command Injection) ─────────
@app.route("/ping", methods=["GET", "POST"])
def ping():
    output = None
    host = ""

    if request.method == "POST":
        host = request.form.get("host", "")

        # ⚠️ VULNERABILIDAD: Command Injection - input directo a shell
        # Payload ejemplo: 127.0.0.1; cat /etc/passwd
        # Payload ejemplo: 127.0.0.1 && whoami
        try:
            result = subprocess.run(
                f"ping -c 2 {host}",
                shell=True,            # ⚠️ shell=True es peligroso
                capture_output=True,
                text=True,
                timeout=10
            )
            output = result.stdout + result.stderr
        except subprocess.TimeoutExpired:
            output = "Timeout: el comando tardó demasiado"
        except Exception as e:
            output = f"Error: {str(e)}"

    return render_template("vuln_ping.html", output=output, host=host)


# ─── LECTOR DE ARCHIVOS (Path Traversal / LFI) ────
@app.route("/readfile")
def readfile():
    filename = request.args.get("file", "")
    content = None
    error = None

    if filename:
        # ⚠️ VULNERABILIDAD: Path Traversal - sin validación de ruta
        # Payload ejemplo: ../../../../etc/passwd
        # Payload ejemplo: ../../../../etc/shadow
        try:
            filepath = f"/app/uploads/{filename}"
            with open(filepath, "r") as f:
                content = f.read()
        except Exception as e:
            error = f"No se pudo leer: {str(e)}"

    return render_template("vuln_readfile.html",
                         filename=filename, content=content, error=error)


# ─── INFO DEL SISTEMA (Information Disclosure) ─────
@app.route("/sysinfo")
def sysinfo():
    # ⚠️ VULNERABILIDAD: Exposición de información sensible del sistema
    info = {
        "hostname": socket.gethostname(),
        "ip": socket.gethostbyname(socket.gethostname()),
        "user": os.popen("whoami").read().strip(),
        "uid": os.getuid(),
        "cwd": os.getcwd(),
        "env_vars": dict(os.environ),
        "kernel": os.popen("uname -a").read().strip(),
        "processes": os.popen("ps aux").read(),
    }
    return render_template("vuln_sysinfo.html", info=info)


# ─── LOGOUT ───────────────────────────────────────
@app.route("/logout")
def logout():
    session.clear()
    return redirect(url_for("index"))


# ─── HEALTH CHECK ──────────────────────────────────
@app.route("/health")
def health():
    return jsonify({"status": "vulnerable", "service": "vulnflask-lab5"})


if __name__ == "__main__":
    print("=" * 50)
    print("  VulnFlask Lab 5 - Aplicación Vulnerable")
    print("  ⚠️  SOLO PARA LABORATORIO")
    print(f"  http://0.0.0.0:5001")
    print("=" * 50)
    # ⚠️ VULNERABILIDAD: Debug mode en producción
    app.run(host="0.0.0.0", port=5001, debug=True)

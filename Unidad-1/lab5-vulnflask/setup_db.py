"""
Setup de la base de datos SQLite para VulnFlask Lab 5.
Crea las tablas e inserta datos iniciales.

⚠️  Las credenciales son intencionales para laboratorio.
"""

import sqlite3
import os

DB_PATH = "/app/vulnapp.db"


def setup():
    """Crear tablas e insertar datos iniciales."""
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()

    # ── Tabla de usuarios ──────────────────────
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT NOT NULL UNIQUE,
            password TEXT NOT NULL,
            email TEXT,
            role TEXT DEFAULT 'user',
            secret_note TEXT
        )
    """)

    # ── Tabla de mensajes (para XSS Stored) ────
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS messages (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            author TEXT NOT NULL,
            content TEXT NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    """)

    # ── Insertar usuarios de prueba ────────────
    users = [
        ("admin", "admin123", "admin@lab.local", "admin",
         "Flag: CTF{sql_injection_master}"),
        ("usuario1", "password1", "user1@lab.local", "user",
         "Nota secreta del usuario 1"),
        ("usuario2", "password2", "user2@lab.local", "user",
         "Nota secreta del usuario 2"),
        ("invitado", "guest", "guest@lab.local", "guest",
         "Cuenta de invitado"),
        ("db_backup", "backup_s3cur3!", "backup@lab.local", "admin",
         "Flag: CTF{union_select_found}"),
    ]

    for user in users:
        try:
            cursor.execute(
                "INSERT INTO users (username, password, email, role, secret_note) "
                "VALUES (?, ?, ?, ?, ?)", user
            )
        except sqlite3.IntegrityError:
            pass  # Usuario ya existe

    # ── Insertar mensajes iniciales ────────────
    messages = [
        ("Sistema", "Bienvenido al tablón de mensajes de VulnFlask."),
        ("Admin", "Recuerden: esta app es solo para laboratorio."),
    ]

    cursor.execute("SELECT COUNT(*) FROM messages")
    if cursor.fetchone()[0] == 0:
        for msg in messages:
            cursor.execute(
                "INSERT INTO messages (author, content) VALUES (?, ?)", msg
            )

    conn.commit()
    conn.close()
    print(f"Base de datos inicializada en {DB_PATH}")
    print(f"  - {len(users)} usuarios creados")
    print(f"  - {len(messages)} mensajes iniciales")


if __name__ == "__main__":
    setup()

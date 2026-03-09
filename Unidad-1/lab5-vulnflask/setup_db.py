"""
Setup de base de datos SQLite para VulnFlask Lab 5.
Crea tablas y datos de prueba.
"""

import sqlite3
import os

DB_PATH = "/app/vulnapp.db"


def setup():
    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()

    # Tabla de usuarios
    c.execute("""
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT NOT NULL,
            password TEXT NOT NULL,
            email TEXT,
            role TEXT DEFAULT 'user',
            secret_note TEXT
        )
    """)

    # Tabla de mensajes (para XSS Stored)
    c.execute("""
        CREATE TABLE IF NOT EXISTS messages (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            author TEXT NOT NULL,
            content TEXT NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    """)

    # Datos de prueba
    users = [
        ("admin", "password", "admin@lab.local", "admin", "Flag: DVWA_S3CR3T_4DM1N"),
        ("user1", "123456", "user1@lab.local", "user", "Nota privada de user1"),
        ("analyst", "analyst2024", "analyst@lab.local", "analyst", "DB backup en /tmp/backup.sql"),
        ("guest", "guest", "guest@lab.local", "guest", "Sin privilegios"),
    ]

    c.execute("SELECT COUNT(*) FROM users")
    if c.fetchone()[0] == 0:
        c.executemany(
            "INSERT INTO users (username, password, email, role, secret_note) VALUES (?, ?, ?, ?, ?)",
            users
        )

    messages = [
        ("Sistema", "Bienvenido al tablero de mensajes de VulnFlask."),
        ("admin", "Recordatorio: cambiar credenciales por defecto."),
    ]

    c.execute("SELECT COUNT(*) FROM messages")
    if c.fetchone()[0] == 0:
        c.executemany(
            "INSERT INTO messages (author, content) VALUES (?, ?)",
            messages
        )

    conn.commit()
    conn.close()
    print(f"Database initialized at {DB_PATH}")


if __name__ == "__main__":
    setup()

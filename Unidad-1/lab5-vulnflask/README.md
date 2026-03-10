# Lab 5: VulnFlask - Aplicacion Vulnerable

Aplicacion web Flask intencionalmente vulnerable para practicas de **pentesting educativo**, desplegada en contenedor Docker.

```
 ⚠️  SOLO PARA ENTORNOS DE LABORATORIO AISLADOS
 ⚠️  NUNCA EXPONER A INTERNET
 ⚠️  CONTIENE VULNERABILIDADES INTENCIONALES
```

| Propiedad        | Valor                                  |
|------------------|----------------------------------------|
| **Imagen base**  | `python:3.11-slim`                     |
| **Puerto**       | `5001` (host) → `5001` (contenedor)   |
| **Framework**    | Flask 3.0.0                            |
| **Base de datos**| SQLite (embebida)                      |
| **Ejecucion**    | Como `root` (vulnerabilidad intencional)|
| **Health check** | `GET /health`                          |

---

## Vulnerabilidades Incluidas

| #  | Tipo                       | Ruta           | Payload de ejemplo                                          |
|----|----------------------------|----------------|-------------------------------------------------------------|
| 1  | SQL Injection (Login)      | `/login`       | `' OR '1'='1' --`                                          |
| 2  | SQL Injection (Busqueda)   | `/search`      | `' UNION SELECT 1,username,password,email,role,secret_note FROM users--` |
| 3  | XSS Reflected              | `/search`      | `<script>alert('XSS')</script>`                             |
| 4  | XSS Stored                 | `/messages`    | `<script>alert('XSS')</script>`                             |
| 5  | Command Injection          | `/ping`        | `127.0.0.1; cat /etc/passwd`                                |
| 6  | Path Traversal (LFI)       | `/readfile`    | `../../../../etc/passwd`                                    |
| 7  | Information Disclosure     | `/sysinfo`     | (acceso directo, expone env vars y procesos)                |
| 8  | Hardcoded Credentials      | Codigo fuente  | Secret key: `super_secret_key_123`                          |
| 9  | Debug Mode en Produccion   | Toda la app    | Flask debug=True expone debugger interactivo                |

---

## Credenciales por Defecto

| Usuario   | Password      | Rol      |
|-----------|---------------|----------|
| admin     | password      | admin    |
| user1     | 123456        | user     |
| analyst   | analyst2024   | analyst  |
| guest     | guest         | guest    |

---

## Requisitos Previos

- **Docker** instalado (version 20+)
- Puerto **5001** libre

```bash
docker --version
```

---

## Despliegue Paso a Paso

### 1. Ir al directorio del lab

```bash
cd Unidad-1/lab5-vulnflask/
```

### 2. Construir la imagen

```bash
docker build -t vulnflask:v1 .
```

### 3. Ejecutar el contenedor

```bash
docker run -d --name vulnflask -p 5001:5001 vulnflask:v1
```

### 4. Verificar

```bash
# Contenedor activo
docker ps --filter name=vulnflask

# Health check
curl http://localhost:5001/health
```

Respuesta esperada:
```json
{"status":"vulnerable","service":"vulnflask-lab5"}
```

### 5. Abrir en el navegador

```
http://localhost:5001
```

Se vera el menu principal con acceso a cada modulo vulnerable.

---

## Rutas de la Aplicacion

| Ruta         | Metodo     | Descripcion                              |
|--------------|------------|------------------------------------------|
| `/`          | GET        | Menu principal con links a cada modulo   |
| `/login`     | GET, POST  | Login vulnerable a SQL Injection         |
| `/dashboard` | GET        | Panel post-login                         |
| `/search`    | GET        | Busqueda vulnerable (SQLi + XSS)         |
| `/messages`  | GET, POST  | Tablon de mensajes (XSS Stored)          |
| `/ping`      | GET, POST  | Herramienta ping (Command Injection)     |
| `/readfile`  | GET        | Lector de archivos (Path Traversal)      |
| `/sysinfo`   | GET        | Info del sistema (Information Disclosure) |
| `/health`    | GET        | Health check JSON                        |
| `/logout`    | GET        | Cerrar sesion                            |

---

## Estructura del Proyecto

```
lab5-vulnflask/
├── Dockerfile               # python:3.11-slim + nmap + sqlite3
├── requirements.txt         # flask==3.0.0
├── app.py                   # App Flask con 7 vulnerabilidades
├── setup_db.py              # Inicializa SQLite con datos de prueba
├── templates/
│   ├── vuln_index.html      # Menu principal
│   ├── vuln_login.html      # Formulario de login
│   ├── vuln_dashboard.html  # Panel de usuario
│   ├── vuln_search.html     # Busqueda de usuarios
│   ├── vuln_messages.html   # Tablon de mensajes
│   ├── vuln_ping.html       # Herramienta ping
│   ├── vuln_readfile.html   # Lector de archivos
│   └── vuln_sysinfo.html   # Info del sistema
└── README.md
```

---

## Ejemplos de Explotacion

### SQL Injection en Login
```
Username: ' OR '1'='1' --
Password: (cualquier cosa)
```

### Command Injection en Ping
```
Host: 127.0.0.1; whoami
Host: 127.0.0.1 && cat /etc/passwd
Host: 127.0.0.1; ls -la /app/
```

### Path Traversal en Lector de Archivos
```
File: ../../../../etc/passwd
File: ../../../../etc/hostname
File: ../app.py
```

### XSS Stored en Mensajes
```
Mensaje: <script>alert(document.cookie)</script>
Mensaje: <img src=x onerror=alert('XSS')>
```

---

## Comandos Utiles

```bash
# Ver logs en tiempo real
docker logs -f vulnflask

# Entrar al contenedor
docker exec -it vulnflask bash
#   sqlite3 /app/vulnapp.db ".tables"
#   sqlite3 /app/vulnapp.db "SELECT * FROM users;"
#   whoami   # -> root (vulnerabilidad intencional)

# Reiniciar
docker restart vulnflask
```

---

## Limpieza

```bash
# Detener y eliminar
docker stop vulnflask && docker rm vulnflask

# Eliminar imagen
docker rmi vulnflask:v1
```

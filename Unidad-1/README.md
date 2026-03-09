# 🐳 Laboratorio de Contenedores — Unidad 1
## Fundamentos de Contenedores: 5 Laboratorios Prácticos

---

## 📋 Requisitos Previos

- Linux (Ubuntu 22.04+ / Debian 12+)
- Docker Engine 24+
- Docker Compose v2+
- Mínimo 4GB RAM disponible
- Puertos libres: 8080, 8081, 3307, 5000, 5001, 5432

---

## 🔧 Paso 0: Instalación de Docker

```bash
# 1. Actualizar e instalar dependencias
sudo apt update && sudo apt install -y ca-certificates curl gnupg

# 2. Agregar clave GPG de Docker
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# 3. Agregar repositorio de Docker
echo "deb [arch=$(dpkg --print-architecture) \
  signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" \
  | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# 4. Instalar Docker Engine + Compose
sudo apt update && sudo apt install -y \
  docker-ce docker-ce-cli containerd.io \
  docker-buildx-plugin docker-compose-plugin

# 5. Agregar tu usuario al grupo docker (evita usar sudo)
sudo usermod -aG docker $USER
newgrp docker

# 6. Verificar instalación
docker --version
docker compose version
docker run hello-world
```

---

## 🟢 Lab 1: Nginx — Servidor Web

| Propiedad      | Valor                |
|----------------|----------------------|
| **Imagen base** | `nginx:alpine`      |
| **Puerto**      | `8080:80`           |
| **Tamaño**      | ~40 MB              |
| **Tipo**        | Servidor web estático |

### Despliegue paso a paso:

```bash
# Entrar al directorio del lab
cd lab1-nginx/

# Construir la imagen
docker build -t mi-nginx:v1 .

# Ejecutar el contenedor
docker run -d \
  --name web-nginx \
  -p 8080:80 \
  mi-nginx:v1

# Verificar que está corriendo
docker ps | grep web-nginx

# Probar el servidor
curl http://localhost:8080
curl http://localhost:8080/health

# Ver logs
docker logs -f web-nginx

# Acceder al contenedor
docker exec -it web-nginx sh

# Dentro del contenedor, verificar:
#   ls /usr/share/nginx/html/
#   nginx -v
#   exit
```

### Verificación:
- Abrir navegador: `http://localhost:8080`
- Health check: `http://localhost:8080/health`

### Limpieza:
```bash
docker stop web-nginx && docker rm web-nginx
docker rmi mi-nginx:v1
```

---

## 🟠 Lab 2: PostgreSQL — Base de Datos

| Propiedad       | Valor                    |
|-----------------|--------------------------|
| **Imagen base**  | `postgres:16-alpine`    |
| **Puerto**       | `5432:5432`             |
| **Tamaño**       | ~80 MB                  |
| **Volumen**      | `pgdata` (persistencia) |
| **Base de datos** | `labdb`                |

### Despliegue paso a paso:

```bash
# Entrar al directorio del lab
cd lab2-postgres/

# Construir la imagen
docker build -t mi-postgres:v1 .

# Ejecutar con volumen persistente
docker run -d \
  --name db-postgres \
  -p 5432:5432 \
  -v pgdata:/var/lib/postgresql/data \
  mi-postgres:v1

# Verificar que está corriendo
docker ps | grep db-postgres

# Esperar 10 segundos para inicialización
sleep 10

# Conectar a la base de datos desde el host
docker exec -it db-postgres psql -U labuser -d labdb

# Dentro de psql, ejecutar:
#   \dt                              -- Ver tablas creadas
#   SELECT * FROM alumnos;           -- Ver alumnos
#   SELECT * FROM cursos;            -- Ver cursos
#   SELECT * FROM v_resumen_alumnos; -- Ver vista resumen
#   \q                               -- Salir

# Ver logs
docker logs db-postgres
```

### Verificación:
```bash
# Health check
docker exec db-postgres pg_isready -U labuser -d labdb

# Consulta rápida
docker exec db-postgres psql -U labuser -d labdb \
  -c "SELECT alumno, curso, estado FROM v_resumen_alumnos;"
```

### Persistencia — probar que los datos sobreviven al reinicio:
```bash
# Detener y eliminar el contenedor
docker stop db-postgres && docker rm db-postgres

# Recrear el contenedor con el MISMO volumen
docker run -d \
  --name db-postgres \
  -p 5432:5432 \
  -v pgdata:/var/lib/postgresql/data \
  mi-postgres:v1

# Verificar que los datos siguen ahí
sleep 5
docker exec db-postgres psql -U labuser -d labdb \
  -c "SELECT * FROM alumnos;"
```

### Limpieza:
```bash
docker stop db-postgres && docker rm db-postgres
docker volume rm pgdata
docker rmi mi-postgres:v1
```

---

## 🟣 Lab 3: Python Flask — Aplicación Web

| Propiedad       | Valor                 |
|-----------------|-----------------------|
| **Imagen base**  | `python:3.11-slim`   |
| **Puerto**       | `5000:5000`          |
| **Tamaño**       | ~150 MB              |
| **Framework**    | Flask 3.0            |
| **Seguridad**    | Usuario no-root      |

### Despliegue paso a paso:

```bash
# Entrar al directorio del lab
cd lab3-flask/

# Construir la imagen
docker build -t mi-flask:v1 .

# Ejecutar el contenedor
docker run -d \
  --name app-flask \
  -p 5000:5000 \
  mi-flask:v1

# Verificar que está corriendo
docker ps | grep app-flask

# Probar la aplicación
curl http://localhost:5000
curl http://localhost:5000/health
curl http://localhost:5000/api/info | python3 -m json.tool

# Ver logs
docker logs -f app-flask

# Verificar que corre como usuario no-root
docker exec app-flask whoami
# Debe mostrar: appuser
```

### Verificación:
- Página principal: `http://localhost:5000`
- Health check JSON: `http://localhost:5000/health`
- Info del contenedor: `http://localhost:5000/api/info`

### Limpieza:
```bash
docker stop app-flask && docker rm app-flask
docker rmi mi-flask:v1
```

---

## 🔴 Lab 4: DVWA — Damn Vulnerable Web Application

> ⚠️ **SOLO PARA ENTORNOS DE LABORATORIO AISLADOS**
> Contiene vulnerabilidades intencionales: SQLi, XSS, Command Injection, File Upload, CSRF, Brute Force

| Propiedad        | Valor                        |
|------------------|------------------------------|
| **Stack**         | PHP 8.2 + Apache + MySQL 8  |
| **Puerto web**    | `8081:80`                   |
| **Puerto MySQL**  | `3307:3306`                 |
| **Login**         | `admin` / `password`        |
| **Compose**       | Sí (2 contenedores)         |

### Despliegue paso a paso:

```bash
# Entrar al directorio del lab
cd lab4-dvwa/

# Construir y levantar con Docker Compose
docker compose up -d --build

# Ver el estado de los contenedores
docker compose ps

# Ver logs en tiempo real
docker compose logs -f

# Esperar a que MySQL esté listo (~30 segundos)
# Verás en los logs: "MySQL disponible. Iniciando Apache..."
```

### Configuración inicial de DVWA:

1. Abrir navegador: `http://localhost:8081`
2. Ir a `http://localhost:8081/setup.php`
3. Click en **"Create / Reset Database"** (al final de la página)
4. Login con: `admin` / `password`
5. En **"DVWA Security"** → Seleccionar nivel **"Low"**

### Vulnerabilidades para practicar:

| Módulo              | Ruta                    | Tipo                 |
|---------------------|-------------------------|----------------------|
| SQL Injection       | `/vulnerabilities/sqli` | SQLi clásica         |
| SQL Injection Blind | `/vulnerabilities/sqli_blind` | SQLi ciega     |
| XSS Reflected      | `/vulnerabilities/xss_r`| XSS reflejado       |
| XSS Stored         | `/vulnerabilities/xss_s`| XSS almacenado      |
| Command Injection   | `/vulnerabilities/exec` | Inyección de comandos|
| File Upload         | `/vulnerabilities/upload`| Subida maliciosa    |
| Brute Force        | `/vulnerabilities/brute` | Fuerza bruta        |
| CSRF               | `/vulnerabilities/csrf`  | Cross-Site Request  |

### Limpieza:
```bash
cd lab4-dvwa/
docker compose down -v    # -v elimina también los volúmenes
docker rmi lab4-dvwa-dvwa-web
```

---

## ☠️ Lab 5: VulnFlask — Aplicación Vulnerable Personalizada

> ⚠️ **SOLO PARA ENTORNOS DE LABORATORIO AISLADOS**
> Aplicación Python con vulnerabilidades intencionales documentadas en el código fuente

| Propiedad        | Valor                         |
|------------------|-------------------------------|
| **Imagen base**   | `python:3.11-slim`           |
| **Puerto**        | `5001:5001`                  |
| **Base de datos** | SQLite (embebida)            |
| **Framework**     | Flask 3.0                    |
| **Corre como**    | root (⚠️ intencionado)       |

### Despliegue paso a paso:

```bash
# Entrar al directorio del lab
cd lab5-vulnflask/

# Opción A: Con Docker Compose
docker compose up -d --build

# Opción B: Build manual
docker build -t vulnflask:v1 .
docker run -d \
  --name vulnflask-lab5 \
  -p 5001:5001 \
  vulnflask:v1

# Verificar
docker ps | grep vulnflask
curl http://localhost:5001/health
```

### Vulnerabilidades para practicar:

| # | Vulnerabilidad       | Ruta          | Ejemplo de Payload                              |
|---|----------------------|---------------|------------------------------------------------|
| 1 | SQL Injection Login  | `/login`      | Usuario: `' OR '1'='1' --`                    |
| 2 | SQL Injection UNION  | `/search?q=`  | `' UNION SELECT 1,username,password,email FROM users--` |
| 3 | XSS Stored           | `/messages`   | Mensaje: `<script>alert('XSS')</script>`       |
| 4 | XSS Reflected        | `/search?q=`  | `<img src=x onerror=alert(1)>`                 |
| 5 | Command Injection    | `/ping`       | Host: `127.0.0.1; whoami`                      |
| 6 | Path Traversal (LFI) | `/readfile`   | Archivo: `../../etc/passwd`                     |
| 7 | Info Disclosure      | `/sysinfo`    | Variables de entorno, procesos, kernel          |

### Ejercicios guiados:

```bash
# 1. SQL Injection - Bypass de login
#    En /login → Usuario: ' OR '1'='1' --
#    Contraseña: (cualquier cosa)

# 2. SQL Injection - Extraer contraseñas
#    En /search → Buscar:
#    ' UNION SELECT 1,username,password,email FROM users--

# 3. Command Injection - Leer archivos del sistema
#    En /ping → Host: 127.0.0.1; cat /etc/passwd

# 4. Path Traversal - Leer archivos sensibles
#    En /readfile → Archivo: ../../etc/passwd
#    En /readfile → Archivo: ../../app/app.py

# 5. Verificar que corre como root (mala práctica)
docker exec vulnflask-lab5 whoami
docker exec vulnflask-lab5 id
```

### Limpieza:
```bash
cd lab5-vulnflask/
docker compose down
docker rmi vulnflask:v1 2>/dev/null
docker rmi lab5-vulnflask-vulnflask 2>/dev/null
```

---

## 🧹 Limpieza Total

```bash
# Detener todos los contenedores de los labs
docker stop web-nginx db-postgres app-flask dvwa-web dvwa-mysql vulnflask-lab5 2>/dev/null

# Eliminar contenedores
docker rm web-nginx db-postgres app-flask dvwa-web dvwa-mysql vulnflask-lab5 2>/dev/null

# Eliminar imágenes
docker rmi mi-nginx:v1 mi-postgres:v1 mi-flask:v1 vulnflask:v1 2>/dev/null

# Eliminar volúmenes
docker volume rm pgdata dvwa-mysql-data 2>/dev/null

# Eliminar redes huérfanas
docker network prune -f

# Limpieza profunda (todo lo no utilizado)
docker system prune -a --volumes
```

---

## 📊 Resumen de Puertos

| Lab | Servicio      | Puerto Host | Puerto Container |
|-----|---------------|-------------|------------------|
| 1   | Nginx         | 8080        | 80               |
| 2   | PostgreSQL    | 5432        | 5432             |
| 3   | Flask App     | 5000        | 5000             |
| 4   | DVWA Web      | 8081        | 80               |
| 4   | DVWA MySQL    | 3307        | 3306             |
| 5   | VulnFlask     | 5001        | 5001             |

---

## 📁 Estructura de Archivos

```
├── lab1-nginx/
│   ├── Dockerfile
│   ├── nginx.conf
│   ├── index.html
│   ├── styles.css
│   └── .dockerignore
├── lab2-postgres/
│   ├── Dockerfile
│   ├── 01-schema.sql
│   ├── 02-seed-data.sql
│   ├── postgresql-custom.conf
│   └── .dockerignore
├── lab3-flask/
│   ├── Dockerfile
│   ├── requirements.txt
│   ├── app.py
│   └── templates/
│       └── index.html
├── lab4-dvwa/
│   ├── Dockerfile
│   ├── docker-compose.yml
│   ├── config.inc.php
│   ├── php-dvwa.ini
│   └── entrypoint.sh
├── lab5-vulnflask/
│   ├── Dockerfile
│   ├── docker-compose.yml
│   ├── requirements.txt
│   ├── app.py
│   ├── setup_db.py
│   └── templates/
│       ├── vuln_index.html
│       ├── vuln_login.html
│       ├── vuln_dashboard.html
│       ├── vuln_search.html
│       ├── vuln_messages.html
│       ├── vuln_ping.html
│       ├── vuln_readfile.html
│       └── vuln_sysinfo.html
└── README.md
```

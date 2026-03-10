# Lab 4: DVWA — Damn Vulnerable Web Application

> **SOLO PARA ENTORNOS DE LABORATORIO AISLADOS**
> Contiene vulnerabilidades intencionales: SQLi, XSS, Command Injection, File Upload, CSRF, Brute Force

## Descripcion

Stack completo con Docker Compose: DVWA (PHP/Apache) + MySQL.
Plataforma de entrenamiento para practicas de seguridad ofensiva.

| Propiedad        | Valor                        |
|------------------|------------------------------|
| **Stack**        | PHP 8.2 + Apache + MySQL 8   |
| **Puerto web**   | `8081:80`                    |
| **Puerto MySQL** | `3307:3306`                  |
| **Login**        | `admin` / `password`         |
| **Compose**      | 2 contenedores               |

---

## Archivos del Lab

| Archivo              | Descripcion                           |
|----------------------|---------------------------------------|
| `Dockerfile`         | Imagen DVWA (PHP + Apache + DVWA)     |
| `docker-compose.yml` | Orquestacion DVWA + MySQL             |
| `config.inc.php`     | Configuracion de DVWA                 |
| `php-dvwa.ini`       | Configuracion PHP para DVWA           |
| `entrypoint.sh`      | Script que espera a MySQL antes de iniciar |

---

## Ejecucion

### Paso 1 — Levantar con Docker Compose

```bash
cd lab4-dvwa/

docker compose up -d --build
```

### Paso 2 — Verificar el estado

```bash
docker compose ps

# Ver logs en tiempo real (esperar ~30s a que MySQL este listo)
docker compose logs -f
# Esperar el mensaje: "MySQL disponible. Iniciando Apache..."
# Ctrl+C para salir de los logs
```

### Paso 3 — Configuracion inicial de DVWA

1. Abrir navegador: `http://localhost:8081`
2. Ir a `http://localhost:8081/setup.php`
3. Click en **"Create / Reset Database"** (al final de la pagina)
4. Login con: `admin` / `password`
5. En **"DVWA Security"** -> Seleccionar nivel **"Low"**

---

## Vulnerabilidades para Practicar

| Modulo              | Ruta                          | Tipo                  |
|---------------------|-------------------------------|-----------------------|
| SQL Injection       | `/vulnerabilities/sqli`       | SQLi clasica          |
| SQL Injection Blind | `/vulnerabilities/sqli_blind` | SQLi ciega            |
| XSS Reflected       | `/vulnerabilities/xss_r`     | XSS reflejado         |
| XSS Stored          | `/vulnerabilities/xss_s`     | XSS almacenado        |
| Command Injection   | `/vulnerabilities/exec`       | Inyeccion de comandos |
| File Upload         | `/vulnerabilities/upload`     | Subida maliciosa      |
| Brute Force         | `/vulnerabilities/brute`      | Fuerza bruta          |
| CSRF                | `/vulnerabilities/csrf`       | Cross-Site Request    |

### Ejemplos rapidos (nivel Low)

**SQL Injection** (`/vulnerabilities/sqli`):
```
User ID: ' OR '1'='1' #
```

**Command Injection** (`/vulnerabilities/exec`):
```
127.0.0.1; cat /etc/passwd
```

**XSS Reflected** (`/vulnerabilities/xss_r`):
```
<script>alert('XSS')</script>
```

---

## Verificacion

| Prueba             | Accion                              | Resultado esperado      |
|--------------------|-------------------------------------|-------------------------|
| Web accesible      | `http://localhost:8081`             | Pagina de login DVWA    |
| Setup DB           | Click "Create / Reset Database"     | Database created        |
| Login              | `admin` / `password`                | Dashboard DVWA          |
| MySQL conectado    | `docker compose ps`                 | Ambos contenedores Up   |

---

## Limpieza

```bash
cd lab4-dvwa/
docker compose down -v    # -v elimina tambien los volumenes
docker rmi lab4-dvwa-dvwa-web
```

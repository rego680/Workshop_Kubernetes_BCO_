# Lab 4: DVWA - Damn Vulnerable Web Application

Aplicacion web intencionalmente vulnerable para practicas de seguridad ofensiva, desplegada con Docker Compose (PHP/Apache + MySQL).

```
 ⚠️  SOLO PARA ENTORNOS DE LABORATORIO
 ⚠️  NUNCA EXPONER A INTERNET
```

| Propiedad          | Valor                                |
|--------------------|--------------------------------------|
| **Imagen web**     | `php:8.2-apache`                     |
| **Imagen DB**      | `mysql:8.0`                          |
| **Puerto web**     | `8081` (host) → `80` (contenedor)    |
| **Puerto MySQL**   | `3307` (host) → `3306` (contenedor)  |
| **Login**          | `admin` / `password`                 |
| **Red**            | `dvwa-lab-network` (bridge aislada)  |

---

## Vulnerabilidades Incluidas

| #  | Tipo                  | Nivel por defecto |
|----|-----------------------|-------------------|
| 1  | SQL Injection         | Low               |
| 2  | XSS (Reflected)       | Low               |
| 3  | XSS (Stored)          | Low               |
| 4  | Command Injection     | Low               |
| 5  | File Upload           | Low               |
| 6  | CSRF                  | Low               |
| 7  | Brute Force           | Low               |
| 8  | File Inclusion (LFI)  | Low               |

Cada vulnerabilidad tiene 4 niveles: **Low**, **Medium**, **High**, **Impossible**.

---

## Requisitos Previos

- **Docker** y **Docker Compose** instalados
- Puertos **8081** y **3307** libres

```bash
docker --version
docker compose version
```

---

## Despliegue Paso a Paso

### 1. Ir al directorio del lab

```bash
cd Unidad-1/lab4-dvwa/
```

### 2. Levantar los servicios

```bash
docker compose up -d --build
```

Esto construye la imagen DVWA y levanta 2 contenedores:
- `dvwa-web` → PHP/Apache con DVWA
- `dvwa-mysql` → MySQL 8.0 con base de datos `dvwa`

### 3. Verificar que estan corriendo

```bash
# Ver ambos contenedores
docker compose ps

# Logs del web
docker compose logs dvwa-web
```

Esperar a ver en los logs:
```
MySQL is ready!
DVWA available at http://localhost:80
```

### 4. Configurar DVWA (primera vez)

1. Abrir en el navegador:
   ```
   http://localhost:8081/setup.php
   ```

2. Hacer scroll hacia abajo y click en **"Create / Reset Database"**

3. Esperar la confirmacion y luego ir al login

### 5. Iniciar sesion

```
http://localhost:8081/login.php
```

| Campo    | Valor      |
|----------|------------|
| Username | `admin`    |
| Password | `password` |

### 6. Practicar

En el menu lateral seleccionar la vulnerabilidad a practicar (SQL Injection, XSS, etc.).
Cambiar nivel de dificultad en **DVWA Security** (menu lateral).

---

## Estructura del Proyecto

```
lab4-dvwa/
├── Dockerfile           # php:8.2-apache + extensiones + DVWA
├── docker-compose.yml   # Orquesta web + MySQL
├── config.inc.php       # Config de DVWA (conexion a MySQL)
├── php-dvwa.ini         # Overrides de PHP (allow_url_include, etc)
├── entrypoint.sh        # Script que espera a MySQL antes de iniciar
└── README.md
```

---

## Comandos Utiles

```bash
# Ver logs en tiempo real
docker compose logs -f

# Entrar al contenedor web
docker compose exec dvwa-web bash

# Conectar a MySQL
docker compose exec dvwa-mysql mysql -u dvwa -pdvwa_pass123 dvwa

# Reiniciar servicios
docker compose restart

# Ver redes
docker network ls | grep dvwa
```

---

## Limpieza

```bash
# Detener y eliminar contenedores + red
docker compose down

# Eliminar tambien el volumen de datos
docker compose down -v

# Eliminar imagen construida
docker rmi lab4-dvwa-dvwa-web
```

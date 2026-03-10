# Lab Pac-Man - Docker

Juego clasico de **Pac-Man** (HTML5/Canvas) desplegado en un contenedor Docker con Nginx Alpine.

```
 ╔══════════════════════════════════════╗
 ║            PAC-MAN                   ║
 ║   SCORE: 1280    HIGH: 5000          ║
 ║  ┌─────────────────────────────┐     ║
 ║  │ · · · · · █ · · · · · · ·  │     ║
 ║  │ · ██ · █████ · ██ · █ · ·  │     ║
 ║  │ · · · · · · · · · · · · ·  │     ║
 ║  │ · ██ · █ ═════ █ · ██ · ·  │     ║
 ║  │ · · · · ║ ◉ ◉ ║ · · · · ·│     ║
 ║  │ · ██ · █ ═════ █ · ██ · · │     ║
 ║  │ · · · ◗ · · · · · ᗣ · · · │     ║
 ║  │ ● ██ · █████ · ██ · █ · ● │     ║
 ║  │ · · · · · █ · · · · · · ·  │     ║
 ║  └─────────────────────────────┘     ║
 ║   ◗ = Pac-Man  ᗣ = Fantasma         ║
 ║   · = Punto    ● = Power Pellet     ║
 ╚══════════════════════════════════════╝
```

| Propiedad        | Valor                                  |
|------------------|----------------------------------------|
| **Imagen base**  | `nginx:alpine`                         |
| **Puerto**       | `8082` (host) → `80` (contenedor)      |
| **Tamano aprox.**| ~40 MB                                 |
| **Tecnologia**   | HTML5 Canvas + JavaScript vanilla       |
| **Health check** | `GET /health` → `{"status":"ok"}`      |

---

## Requisitos Previos

- **Docker** instalado (version 20+)
- Puerto **8082** libre en tu maquina

```bash
# Verificar Docker
docker --version
```

---

## Paso a Paso para Desplegar

### 1. Ir al directorio del lab

```bash
cd Unidad-1/lab-pacman/
```

### 2. Construir la imagen Docker

```bash
docker build -t pacman-lab:v1 .
```

Salida esperada:

```
[+] Building ...
 => [1/4] FROM docker.io/library/nginx:alpine
 => [2/4] RUN rm -rf /usr/share/nginx/html/*
 => [3/4] COPY nginx.conf /etc/nginx/conf.d/default.conf
 => [4/4] COPY game/ /usr/share/nginx/html/
 => => naming to docker.io/library/pacman-lab:v1   DONE
```

### 3. Ejecutar el contenedor

```bash
docker run -d --name pacman -p 8082:80 pacman-lab:v1
```

### 4. Verificar que esta corriendo

```bash
# Ver contenedor activo
docker ps --filter name=pacman

# Probar el health check
curl http://localhost:8082/health
```

Respuesta esperada:
```json
{"status":"ok","game":"pacman"}
```

### 5. Abrir en el navegador y jugar

```
http://localhost:8082
```

**Controles del juego:**

| Tecla                     | Accion              |
|---------------------------|----------------------|
| Flechas `↑ ↓ ← →`       | Mover a Pac-Man      |
| `W` `A` `S` `D`          | Mover (alternativo)  |
| `P`                       | Pausa                |
| `R`                       | Reiniciar juego      |
| Deslizar (touch)          | Mover (celulares)    |

---

## Estructura del Proyecto

```
lab-pacman/
├── Dockerfile        # nginx:alpine + copia de archivos
├── nginx.conf        # Servidor web con cache y health check
├── game/
│   └── index.html    # Juego completo (HTML5 Canvas + JS + CSS)
└── README.md
```

---

## Comandos Utiles

```bash
# Ver logs en tiempo real
docker logs -f pacman

# Entrar al contenedor
docker exec -it pacman sh
#   ls /usr/share/nginx/html/
#   nginx -v
#   exit

# Reiniciar
docker restart pacman
```

---

## Limpieza

```bash
# Detener y eliminar contenedor
docker stop pacman && docker rm pacman

# Eliminar imagen
docker rmi pacman-lab:v1
```

# Pacman Docker Lab

Juego clasico de Pac-Man desplegado en un contenedor Docker con Nginx Alpine.

![Pacman Docker Lab](screenshot.png)

| Propiedad        | Valor                          |
|------------------|--------------------------------|
| **Imagen base**  | `nginx:alpine`                 |
| **Puerto**       | `8082:80`                      |
| **Tamano**       | ~40 MB                         |
| **Tipo**         | Aplicacion web estatica (HTML5/JS/CSS) |
| **Health check** | `http://localhost:8082/health`  |

---

## Requisitos Previos

- Docker Engine 24+ instalado
- Puerto **8082** disponible en el host

```bash
# Verificar que Docker esta instalado
docker --version
```

---

## Despliegue Paso a Paso

### Paso 1: Ir al directorio del lab

```bash
cd Unidad-1/lab-pacman/
```

### Paso 2: Construir la imagen

```bash
docker build -t pacman-lab:v1 .
```

Salida esperada:
```
 => [1/4] FROM docker.io/library/nginx:alpine
 => [2/4] RUN rm -rf /usr/share/nginx/html/*
 => [3/4] COPY nginx.conf /etc/nginx/conf.d/default.conf
 => [4/4] COPY game/ /usr/share/nginx/html/
 => exporting to image
 => => naming to docker.io/library/pacman-lab:v1
```

### Paso 3: Ejecutar el contenedor

```bash
docker run -d \
  --name pacman \
  -p 8082:80 \
  pacman-lab:v1
```

### Paso 4: Verificar que esta corriendo

```bash
# Ver el contenedor activo
docker ps | grep pacman

# Health check
curl http://localhost:8082/health
```

Respuesta esperada del health check:
```json
{"status":"ok","game":"pacman"}
```

### Paso 5: Jugar

Abrir el navegador en:

```
http://localhost:8082
```

Usar las **flechas del teclado** para mover a Pac-Man por el laberinto.

---

## Estructura de Archivos

```
lab-pacman/
├── Dockerfile          # Imagen basada en nginx:alpine
├── nginx.conf          # Configuracion del servidor web
├── game/               # Archivos del juego (HTML5, JS, CSS)
│   └── index.html
├── screenshot.png      # Captura de pantalla del juego
└── README.md           # Este archivo
```

---

## Comandos Utiles

```bash
# Ver logs del contenedor
docker logs -f pacman

# Acceder al contenedor
docker exec -it pacman sh

# Dentro del contenedor:
#   ls /usr/share/nginx/html/    # Ver archivos del juego
#   nginx -v                      # Version de Nginx
#   exit

# Reiniciar el contenedor
docker restart pacman

# Ver detalles de la imagen
docker inspect pacman-lab:v1
```

---

## Limpieza

```bash
# Detener y eliminar el contenedor
docker stop pacman && docker rm pacman

# Eliminar la imagen
docker rmi pacman-lab:v1
```

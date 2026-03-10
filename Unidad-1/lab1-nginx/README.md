# Lab 1: Nginx — Servidor Web Personalizado

## Descripcion

Construccion y despliegue de un contenedor Nginx con pagina HTML personalizada.
Introduce los conceptos fundamentales: `docker build`, `docker run`, port mapping y health checks.

| Propiedad       | Valor              |
|-----------------|--------------------|
| **Imagen base** | `nginx:alpine`     |
| **Puerto**      | `8080:80`          |
| **Tamano**      | ~40 MB             |
| **Tipo**        | Servidor web       |

---

## Archivos del Lab

| Archivo      | Descripcion                          |
|--------------|--------------------------------------|
| `Dockerfile` | Imagen Nginx con pagina custom       |
| `index.html` | Pagina HTML del workshop             |
| `style.css`  | Estilos de la pagina                 |

---

## Ejecucion

### Paso 1 — Construir la imagen

```bash
cd lab1-nginx/

docker build -t mi-nginx:v1 .
```

### Paso 2 — Ejecutar el contenedor

```bash
docker run -d \
  --name web-nginx \
  -p 8080:80 \
  mi-nginx:v1
```

### Paso 3 — Verificar que esta corriendo

```bash
docker ps | grep web-nginx
```

### Paso 4 — Probar el servidor

```bash
# Desde terminal
curl http://localhost:8080

# Health check
curl http://localhost:8080/health
```

Tambien se puede abrir en el navegador: `http://localhost:8080`

### Paso 5 — Explorar el contenedor

```bash
# Acceder al contenedor
docker exec -it web-nginx sh

# Dentro del contenedor:
ls /usr/share/nginx/html/
nginx -v
cat /etc/nginx/conf.d/default.conf
exit
```

### Paso 6 — Ver logs

```bash
docker logs -f web-nginx
# Ctrl+C para salir
```

---

## Verificacion

| Prueba                 | Comando / URL                 | Resultado esperado         |
|------------------------|-------------------------------|----------------------------|
| Pagina principal       | `curl http://localhost:8080`  | HTML del workshop          |
| Health check           | `curl http://localhost:8080/health` | Respuesta 200        |
| Contenedor activo      | `docker ps \| grep web-nginx` | STATUS: Up               |
| Imagen creada          | `docker images mi-nginx`      | ~40 MB                    |

---

## Limpieza

```bash
docker stop web-nginx && docker rm web-nginx
docker rmi mi-nginx:v1
```

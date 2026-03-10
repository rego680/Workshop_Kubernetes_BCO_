# Pacman Lab — Juego Pac-Man en Contenedor

## Descripcion

Juego de Pac-Man clasico servido desde un contenedor Nginx sin privilegios.
Lab bonus que demuestra como contenerizar una aplicacion web estatica
usando una imagen non-root (`nginx-unprivileged`).

| Propiedad       | Valor                                      |
|-----------------|--------------------------------------------|
| **Imagen base** | `nginxinc/nginx-unprivileged:alpine`       |
| **Puerto**      | `8082:8080`                                |
| **Tipo**        | Juego web (HTML + CSS + JS)                |
| **Usuario**     | non-root (imagen unprivileged)             |

---

## Archivos del Lab

| Archivo      | Descripcion                               |
|--------------|-------------------------------------------|
| `Dockerfile` | Imagen Nginx unprivileged con el juego    |
| `index.html` | Pagina HTML del juego Pac-Man             |
| `style.css`  | Estilos del grid y personajes             |
| `app.js`     | Logica del juego (movimiento, fantasmas)  |

---

## Ejecucion

### Paso 1 — Construir la imagen

```bash
cd pacman-lab/

docker build -t pacman:v1 .
```

### Paso 2 — Ejecutar el contenedor

```bash
docker run -d \
  --name pacman-game \
  -p 8082:8080 \
  pacman:v1
```

### Paso 3 — Jugar

Abrir en el navegador: `http://localhost:8082`

Controles:
- Flechas del teclado para mover a Pac-Man
- Comer todos los puntos para ganar
- Puntos grandes activan el modo power (fantasmas azules = comestibles)

### Paso 4 — Verificar que corre como non-root

```bash
# Ver el usuario del contenedor (NO es root)
docker exec pacman-game whoami
docker exec pacman-game id
```

---

## Verificacion

| Prueba              | Comando / URL                           | Resultado esperado     |
|---------------------|-----------------------------------------|------------------------|
| Web accesible       | `http://localhost:8082`                 | Juego Pac-Man          |
| Contenedor activo   | `docker ps \| grep pacman-game`         | STATUS: Up             |
| Non-root            | `docker exec pacman-game whoami`        | No es root             |

---

## Limpieza

```bash
docker stop pacman-game && docker rm pacman-game
docker rmi pacman:v1
```

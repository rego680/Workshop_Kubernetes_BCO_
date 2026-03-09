# ── Imagen base nginx sin privilegios (ghcr.io)
FROM ghcr.io/nginxinc/nginx-unprivileged:alpine

# ── Metadata del lab
LABEL maintainer="docker-lab"
LABEL description="Pacman game - Docker Lab"

# ── Copiar el código fuente al directorio que sirve nginx
COPY index.html /usr/share/nginx/html/index.html
COPY style.css  /usr/share/nginx/html/style.css
COPY app.js     /usr/share/nginx/html/app.js

# ── Esta imagen usa el puerto 8080 por defecto (no root)
EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]

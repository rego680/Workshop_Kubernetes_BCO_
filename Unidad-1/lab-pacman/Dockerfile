###############################################
# Lab Pacman: Juego Pac-Man en contenedor
# Imagen base: nginx:alpine (~40MB)
# Puerto: 8082 -> 80
# Tipo: Aplicación web estática (HTML5/JS/CSS)
###############################################
FROM nginx:alpine

LABEL maintainer="DevOps Lab"
LABEL description="Pacman Docker Lab - Juego clasico en contenedor"
LABEL version="1.0"

# Eliminar contenido por defecto de Nginx
RUN rm -rf /usr/share/nginx/html/*

# Copiar configuración personalizada de Nginx
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copiar archivos del juego
COPY game/ /usr/share/nginx/html/

# Exponer el puerto 80
EXPOSE 80

# Health check
HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -qO- http://localhost/ || exit 1

# Nginx se inicia automáticamente con la imagen base
CMD ["nginx", "-g", "daemon off;"]

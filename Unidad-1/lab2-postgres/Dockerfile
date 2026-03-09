###############################################
# Lab 2: PostgreSQL - Base de Datos
# Imagen base: postgres:16-alpine (~80MB)
# Puerto: 5432
# Volumen: pgdata para persistencia
###############################################

FROM postgres:16-alpine

LABEL maintainer="DevOps Lab"
LABEL description="Lab 2 - PostgreSQL con datos iniciales y persistencia"
LABEL version="1.0"

# Variables de entorno para configuración inicial
ENV POSTGRES_DB=labdb
ENV POSTGRES_USER=labuser
ENV POSTGRES_PASSWORD=labpass123
ENV PGDATA=/var/lib/postgresql/data/pgdata

# Copiar scripts de inicialización
# Los archivos en docker-entrypoint-initdb.d/ se ejecutan
# automáticamente en orden alfabético al crear la BD
COPY 01-schema.sql /docker-entrypoint-initdb.d/
COPY 02-seed-data.sql /docker-entrypoint-initdb.d/

# Copiar configuración personalizada de PostgreSQL
COPY postgresql-custom.conf /etc/postgresql/custom.conf

# Exponer el puerto de PostgreSQL
EXPOSE 5432

# Health check para verificar que la BD está lista
HEALTHCHECK --interval=10s --timeout=5s --start-period=30s --retries=5 \
  CMD pg_isready -U $POSTGRES_USER -d $POSTGRES_DB || exit 1

# El CMD por defecto de la imagen postgres ya inicia el servidor

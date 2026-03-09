###############################################
# LAB 2 — UNIDAD 2: DockerHub — Build, Tag & Push
#
# Objetivo: Practicar el flujo completo de
#   build -> tag -> push a DockerHub
#
# Build:
#   docker build -t flask-hub:1.0.0 .
# Run:
#   docker run -d --name flask-hub -p 5000:5000 flask-hub:1.0.0
# Test:
#   curl http://localhost:5000
###############################################

FROM python:3.12-slim

LABEL maintainer="DevOps Lab - Unidad 2"
LABEL description="Lab 2 - Imagen para practicar push a DockerHub"
LABEL version="1.0.0"

# Directorio de trabajo
WORKDIR /app

# Dependencias (cache)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Codigo fuente
COPY app.py .

# Seguridad: usuario no-root
RUN adduser --disabled-password --gecos "" appuser \
    && chown -R appuser:appuser /app
USER appuser

# Puerto
EXPOSE 5000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:5000/health')" || exit 1

# Ejecutar
CMD ["python", "app.py"]

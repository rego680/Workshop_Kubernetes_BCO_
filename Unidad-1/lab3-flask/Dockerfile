###############################################
# Lab 3: Python Flask - Aplicación Web
# Imagen base: python:3.11-slim (~120MB)
# Puerto: 5000
# Multi-instrucción con cache de dependencias
###############################################

FROM python:3.11-slim

LABEL maintainer="DevOps Lab"
LABEL description="Lab 3 - Aplicación Flask con API REST básica"
LABEL version="1.0"

# Variables de entorno
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV FLASK_APP=app.py
ENV FLASK_ENV=production

# Crear usuario no-root por seguridad
RUN groupadd -r appuser && useradd -r -g appuser appuser

# Directorio de trabajo
WORKDIR /app

# Instalar dependencias primero (aprovecha cache de Docker)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copiar código fuente de la aplicación
COPY app.py .
COPY templates/ templates/

# Cambiar propietario de los archivos
RUN chown -R appuser:appuser /app

# Ejecutar como usuario no-root
USER appuser

# Exponer el puerto de Flask
EXPOSE 5000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:5000/health')" || exit 1

# Ejecutar la aplicación
CMD ["python", "app.py"]

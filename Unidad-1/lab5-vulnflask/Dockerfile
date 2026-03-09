###############################################
# Lab 5: VulnFlask - Aplicación Vulnerable
# Imagen base: python:3.11-slim
# Puerto: 5001
#
# ⚠️  SOLO PARA ENTORNOS DE LABORATORIO
# ⚠️  NUNCA EXPONER A INTERNET
# ⚠️  Vulnerabilidades intencionales:
#     - SQL Injection (SQLite)
#     - Cross-Site Scripting (XSS)
#     - Command Injection (OS)
#     - Path Traversal (LFI)
#     - Insecure Deserialization
#     - Hardcoded Credentials
#     - Information Disclosure
###############################################

FROM python:3.11-slim

LABEL maintainer="Security Lab"
LABEL description="Lab 5 - Aplicación Flask vulnerable para pentesting educativo"
LABEL version="1.0"
LABEL warning="CONTIENE VULNERABILIDADES INTENCIONALES - SOLO LABORATORIO"

# Instalar herramientas del sistema necesarias
RUN apt-get update && apt-get install -y \
    sqlite3 \
    curl \
    net-tools \
    iputils-ping \
    nmap \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Instalar dependencias Python
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copiar toda la aplicación
COPY app.py .
COPY templates/ templates/
COPY setup_db.py .

# Inicializar la base de datos SQLite
RUN python setup_db.py

# Crear directorio para uploads (con permisos inseguros - intencionado)
RUN mkdir -p /app/uploads && chmod 777 /app/uploads

# Exponer puerto
EXPOSE 5001

# Health check
HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
  CMD curl -f http://localhost:5001/ || exit 1

# ⚠️  Ejecutando como root intencionalmente (vulnerabilidad)
CMD ["python", "app.py"]

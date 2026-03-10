#!/bin/bash
###############################################
# Entrypoint: espera a que MySQL este listo
# y luego inicia Apache
###############################################

set -e

DB_HOST="${DB_HOST:-dvwa-mysql}"
DB_USER="${DB_USER:-dvwa}"
DB_PASS="${DB_PASS:-dvwa_pass123}"
DB_PORT="${DB_PORT:-3306}"

echo "========================================"
echo "  DVWA Lab 4 - Starting..."
echo "  Waiting for MySQL at $DB_HOST..."
echo "========================================"

# Esperar a que MySQL acepte conexiones
# Usa PHP mysqli para verificar conectividad (compatible con mysql_native_password y caching_sha2_password)
MAX_RETRIES=30
RETRY=0
until php -r "new mysqli('$DB_HOST', '$DB_USER', '$DB_PASS', '', $DB_PORT);" 2>/dev/null; do
    RETRY=$((RETRY + 1))
    if [ $RETRY -ge $MAX_RETRIES ]; then
        echo "ERROR: MySQL not available after $MAX_RETRIES attempts"
        echo "Attempting diagnostic connection..."
        php -r "new mysqli('$DB_HOST', '$DB_USER', '$DB_PASS', '', $DB_PORT);" || true
        exit 1
    fi
    echo "Waiting for MySQL... ($RETRY/$MAX_RETRIES)"
    sleep 2
done

echo "MySQL is ready!"
echo "DVWA available at http://localhost:80"
echo "========================================"

# Ejecutar el comando original (apache2-foreground)
exec "$@"

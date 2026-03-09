#!/bin/bash
###############################################
# Entrypoint: espera a que MySQL este listo
# y luego inicia Apache
###############################################

set -e

DB_HOST="${DB_HOST:-dvwa-mysql}"
DB_USER="${DB_USER:-dvwa}"
DB_PASS="${DB_PASS:-dvwa_pass123}"

echo "========================================"
echo "  DVWA Lab 4 - Starting..."
echo "  Waiting for MySQL at $DB_HOST..."
echo "========================================"

# Esperar a que MySQL acepte conexiones
MAX_RETRIES=30
RETRY=0
until mysqladmin ping -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" --silent 2>/dev/null; do
    RETRY=$((RETRY + 1))
    if [ $RETRY -ge $MAX_RETRIES ]; then
        echo "ERROR: MySQL not available after $MAX_RETRIES attempts"
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

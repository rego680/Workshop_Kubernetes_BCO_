#!/bin/bash
###############################################
# Entrypoint Lab 4 - DVWA
# Espera a que MySQL esté disponible antes
# de iniciar Apache
###############################################

set -e

DB_HOST="${DB_HOST:-dvwa-mysql}"
DB_USER="${DB_USER:-dvwa}"
DB_PASS="${DB_PASS:-dvwa_pass123}"

echo "============================================="
echo "  DVWA Lab 4 - Iniciando..."
echo "  Esperando a MySQL ($DB_HOST)..."
echo "============================================="

MAX_RETRIES=30
RETRY=0

while [ $RETRY -lt $MAX_RETRIES ]; do
    if mysqladmin ping -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" --silent 2>/dev/null; then
        echo "MySQL disponible. Iniciando Apache..."
        break
    fi
    RETRY=$((RETRY + 1))
    echo "Intento $RETRY/$MAX_RETRIES - MySQL no disponible, esperando 2s..."
    sleep 2
done

if [ $RETRY -eq $MAX_RETRIES ]; then
    echo "ADVERTENCIA: MySQL no respondio despues de $MAX_RETRIES intentos."
    echo "Iniciando Apache de todas formas..."
fi

# Asegurar permisos correctos
chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html
chmod 777 /var/www/html/hackable/uploads 2>/dev/null || true
chmod 777 /var/www/html/config 2>/dev/null || true

echo "============================================="
echo "  DVWA disponible en http://localhost:80"
echo "  Setup: http://localhost/setup.php"
echo "  Login: admin / password"
echo "============================================="

# Ejecutar el CMD (apache2-foreground)
exec "$@"

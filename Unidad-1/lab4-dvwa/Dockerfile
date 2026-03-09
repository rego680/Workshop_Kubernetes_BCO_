###############################################
# Lab 4: DVWA - Damn Vulnerable Web Application
# Imagen base: php:8.2-apache (~450MB)
# Puerto: 80 (mapeado a 8081 en el host)
#
# ⚠️  SOLO PARA ENTORNOS DE LABORATORIO
# ⚠️  NUNCA EXPONER A INTERNET
# ⚠️  Contiene vulnerabilidades intencionales:
#     - SQL Injection
#     - XSS (Reflected & Stored)
#     - Command Injection
#     - File Upload
#     - CSRF
#     - Brute Force
###############################################

FROM php:8.2-apache

LABEL maintainer="Security Lab"
LABEL description="Lab 4 - DVWA para prácticas de seguridad ofensiva"
LABEL version="1.0"
LABEL warning="SOLO PARA USO EN LABORATORIO - CONTIENE VULNERABILIDADES INTENCIONALES"

# Instalar extensiones PHP necesarias para DVWA
RUN apt-get update && apt-get install -y \
    git \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    default-mysql-client \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
        gd \
        mysqli \
        pdo \
        pdo_mysql \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Habilitar módulos de Apache necesarios
RUN a2enmod rewrite

# Configurar PHP para DVWA
RUN mv "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini"
COPY php-dvwa.ini "$PHP_INI_DIR/conf.d/dvwa.ini"

# Descargar DVWA desde el repositorio oficial
RUN rm -rf /var/www/html/* \
    && git clone https://github.com/digininja/DVWA.git /var/www/html \
    && chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html

# Copiar configuración de DVWA
COPY config.inc.php /var/www/html/config/config.inc.php

# Crear directorios con permisos necesarios
RUN mkdir -p /var/www/html/hackable/uploads \
    && chmod 777 /var/www/html/hackable/uploads \
    && chmod 777 /var/www/html/config

# Copiar script de entrada que espera a MySQL
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
  CMD curl -f http://localhost/ || exit 1

ENTRYPOINT ["/entrypoint.sh"]
CMD ["apache2-foreground"]

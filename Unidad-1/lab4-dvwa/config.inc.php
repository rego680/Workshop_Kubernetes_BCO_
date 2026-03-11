<?php
###############################################
# Configuración DVWA para Lab 4
# Conexión a MySQL via Docker Compose
#
# ⚠️  SOLO PARA LABORATORIO
###############################################

# Database Settings
$_DVWA = array();
$_DVWA['db_server']   = getenv('DB_HOST') ?: 'dvwa-mysql';
$_DVWA['db_database'] = getenv('DB_NAME') ?: 'dvwa';
$_DVWA['db_user']     = getenv('DB_USER') ?: 'dvwa';
$_DVWA['db_password'] = getenv('DB_PASS') ?: 'dvwa_pass123';
$_DVWA['db_port']     = '3306';

# reCAPTCHA Settings (opcional - dejar vacío para lab)
$_DVWA['recaptcha_public_key']  = '';
$_DVWA['recaptcha_private_key'] = '';

# Security Level: low, medium, high, impossible
$_DVWA['default_security_level'] = 'low';

# PHPIDS (dejar deshabilitado para laboratorio)
$_DVWA['default_phpids_level'] = '0';
$_DVWA['default_phpids_verbose'] = '0';

?>

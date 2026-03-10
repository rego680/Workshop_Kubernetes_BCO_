<?php

# DVWA Configuration
# SOLO PARA USO EN LABORATORIO

# Database settings (from docker-compose environment)
$_DVWA = array();
$_DVWA['db_server']   = getenv('DB_HOST') ?: 'dvwa-mysql';
$_DVWA['db_database'] = getenv('DB_NAME') ?: 'dvwa';
$_DVWA['db_user']     = getenv('DB_USER') ?: 'dvwa';
$_DVWA['db_password'] = getenv('DB_PASS') ?: 'dvwa_pass123';
$_DVWA['db_port']     = '3306';

# reCAPTCHA (optional - leave blank to skip)
$_DVWA['recaptcha_public_key']  = '';
$_DVWA['recaptcha_private_key'] = '';

# Default security level: low, medium, high, impossible
$_DVWA['default_security_level'] = 'low';

# Default PHPIDS status
$_DVWA['default_phpids_level'] = 'disabled';
$_DVWA['default_phpids_verbose'] = 'false';

?>

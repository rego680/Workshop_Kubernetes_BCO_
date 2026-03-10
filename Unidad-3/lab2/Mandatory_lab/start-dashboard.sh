#!/bin/bash
###############################################
# Inicia el dashboard web de Minikube
#
# Requisito:
#   minikube addons enable dashboard
#
# Uso:
#   chmod +x start-dashboard.sh
#   ./start-dashboard.sh
###############################################
minikube addons enable dashboard 2>/dev/null
minikube dashboard --url &

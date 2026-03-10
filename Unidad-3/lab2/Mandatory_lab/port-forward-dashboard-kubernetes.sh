#!/bin/bash
###############################################
# Port-forward del Kubernetes Dashboard
# Accesible en: http://<IP_SERVIDOR>:65500
#
# Requisito:
#   minikube addons enable dashboard
#
# Uso:
#   chmod +x port-forward-dashboard-kubernetes.sh
#   ./port-forward-dashboard-kubernetes.sh
###############################################

# Habilitar addon si no esta activo
minikube addons enable dashboard 2>/dev/null

# Esperar a que el Service este disponible
echo "Esperando a que el dashboard este listo..."
kubectl wait --for=condition=available deployment/kubernetes-dashboard-web \
  -n kubernetes-dashboard --timeout=60s 2>/dev/null || \
kubectl wait --for=condition=available deployment/kubernetes-dashboard \
  -n kubernetes-dashboard --timeout=60s 2>/dev/null

# Intentar con el nombre de servicio segun la version de Minikube
# Versiones recientes: kubernetes-dashboard-web (puerto 8000)
# Versiones anteriores: kubernetes-dashboard (puerto 80 o 443)
if kubectl get svc kubernetes-dashboard-web -n kubernetes-dashboard &>/dev/null; then
  SVC_NAME="kubernetes-dashboard-web"
  SVC_PORT="8000"
elif kubectl get svc kubernetes-dashboard -n kubernetes-dashboard &>/dev/null; then
  SVC_NAME="kubernetes-dashboard"
  SVC_PORT="80"
else
  echo "ERROR: No se encontro el Service del dashboard."
  echo "Ejecuta: minikube addons enable dashboard"
  exit 1
fi

echo "Redirigiendo $SVC_NAME:$SVC_PORT -> localhost:65500"
nohup kubectl port-forward -n kubernetes-dashboard "svc/$SVC_NAME" "65500:$SVC_PORT" \
  --address='0.0.0.0' > /var/log/k8s-dashboard.log 2>&1 &

echo "Dashboard disponible en: http://localhost:65500"

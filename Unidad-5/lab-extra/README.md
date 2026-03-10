# Lab Extra: Herramientas Ofensivas Automatizadas

## Objetivo

Usar herramientas de pentesting automatizadas para descubrir vulnerabilidades,
enumerar recursos y evaluar la postura de seguridad del cluster desde dentro.

| Propiedad        | Valor                                    |
|------------------|------------------------------------------|
| **Namespace**    | `lab-extra`                              |
| **Herramientas** | kube-hunter, peirates, netshoot          |
| **Ataque**       | Reconocimiento + enumeracion automatizada|
| **Dificultad**   | Intermedia                               |

---

## Requisitos

- Cluster Kubernetes activo
- kubectl configurado

---

## Archivos

| Archivo | Descripcion |
|---------|-------------|
| `offensive-tools.yaml` | Job kube-hunter + Pod peirates + Pod recon con SA permisivo |

---

## Paso 1 — Desplegar las herramientas

```bash
kubectl apply -f offensive-tools.yaml

# Verificar que todo esta corriendo
kubectl get all -n lab-extra
kubectl wait --for=condition=Ready pod/peirates-pod -n lab-extra --timeout=120s
kubectl wait --for=condition=Ready pod/recon-pod -n lab-extra --timeout=120s
```

---

## Paso 2 — kube-hunter: Escaneo automatizado

```bash
# Esperar a que el Job termine
kubectl wait --for=condition=Complete job/kube-hunter -n lab-extra --timeout=300s

# Ver resultados del escaneo
kubectl logs -n lab-extra -l tool=kube-hunter

# Los resultados muestran:
# - Vulnerabilidades encontradas
# - Servicios expuestos
# - Configuraciones inseguras
```

---

## Paso 3 — peirates: Pentesting interactivo

```bash
# Entrar al pod de peirates
kubectl exec -it -n lab-extra peirates-pod -- /peirates

# Dentro de peirates, opciones utiles:
# [1] Get pods
# [2] Get secrets
# [3] Get service accounts
# [5] Check RBAC permissions
# [9] Attempt to use discovered credentials
# [20] Run kubectl command

# Ejemplo: listar pods en todos los namespaces
# Seleccionar opcion 20 → kubectl get pods --all-namespaces
```

---

## Paso 4 — Reconocimiento manual con netshoot

```bash
# Entrar al pod de reconocimiento
kubectl exec -it -n lab-extra recon-pod -- bash

# Enumerar el API Server
TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
APISERVER="https://kubernetes.default.svc"

# Listar namespaces
curl -sk -H "Authorization: Bearer $TOKEN" $APISERVER/api/v1/namespaces | grep '"name"'

# Listar pods en todos los namespaces
curl -sk -H "Authorization: Bearer $TOKEN" $APISERVER/api/v1/pods | grep '"name"' | head -30

# Listar RBAC roles
curl -sk -H "Authorization: Bearer $TOKEN" $APISERVER/apis/rbac.authorization.k8s.io/v1/clusterroles | grep '"name"' | head -20

# Verificar permisos del SA
curl -sk -H "Authorization: Bearer $TOKEN" \
  $APISERVER/apis/authorization.k8s.io/v1/selfsubjectaccessreviews \
  -X POST -H "Content-Type: application/json" \
  -d '{"apiVersion":"authorization.k8s.io/v1","kind":"SelfSubjectAccessReview","spec":{"resourceAttributes":{"verb":"list","resource":"secrets"}}}'

# Escaneo de red interna
nmap -sn 10.96.0.0/16 2>/dev/null | head -30

# Descubrimiento DNS
nslookup kubernetes.default.svc.cluster.local

exit
```

---

## Paso 5 — Analisis de resultados

Revisar los hallazgos de cada herramienta:

| Herramienta | Que buscar |
|-------------|------------|
| **kube-hunter** | CVEs, endpoints expuestos, SA tokens accesibles |
| **peirates** | Secrets leibles, pods privilegiados, RBAC excesivo |
| **netshoot** | Servicios internos alcanzables, falta de NetworkPolicies |

---

## Limpieza

```bash
kubectl delete namespace lab-extra
kubectl delete clusterrole lab-extra-recon
kubectl delete clusterrolebinding lab-extra-recon-binding
```

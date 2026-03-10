# Lab 3: Secrets en Texto Plano (Variables de Entorno)

## Objetivo

Demostrar como los Secrets de Kubernetes expuestos como variables de entorno son
facilmente accesibles para un atacante: visibles con `env`, legibles en `/proc`,
y heredados por procesos hijo.

| Propiedad        | Valor                                    |
|------------------|------------------------------------------|
| **Namespace**    | `lab3-secrets`                           |
| **Ataque**       | `env` / `/proc` -> credenciales en claro |
| **Defensa**      | Volumen read-only + Vault + etcd encrypt |
| **Dificultad**   | Basica                                   |

---

## Requisitos

- minikube corriendo (`minikube start`)
- kubectl configurado

---

## Parte 1: Escenario Vulnerable (Red Team)

### Paso 1 — Desplegar el escenario vulnerable

```bash
kubectl apply -f vulnerable-secrets.yaml

# Verificar recursos
kubectl get secrets -n lab3-secrets
kubectl get pods -n lab3-secrets

kubectl wait --for=condition=Ready pod/app-with-secrets -n lab3-secrets --timeout=120s
```

### Paso 2 — Explotar: Leer credenciales desde env vars

```bash
# Entrar al pod
kubectl exec -it app-with-secrets -n lab3-secrets -- bash

# Metodo 1: comando env
env | grep DB_

# Resultado esperado:
# DB_HOST=postgres.default.svc.cluster.local
# DB_USER=admin
# DB_PASSWORD=Sup3rSecretP@ssw0rd!2024
# DB_NAME=production_db
```

### Paso 3 — Explotar: Leer desde /proc

```bash
# Dentro del pod: leer variables de entorno del PID 1
cat /proc/1/environ | tr '\0' '\n' | grep DB_

# Tambien accesible desde cualquier proceso hijo
cat /proc/self/environ | tr '\0' '\n' | grep DB_

exit
```

### Paso 4 — Ver el Secret "codificado" en base64

```bash
# Desde fuera del pod: los secrets en K8s son base64, NO cifrados
kubectl get secret db-credentials -n lab3-secrets -o jsonpath='{.data.DB_PASSWORD}' | base64 -d
# Resultado: Sup3rSecretP@ssw0rd!2024
```

---

## Parte 2: Escenario Seguro (Blue Team)

### Paso 1 — Limpiar el escenario vulnerable

```bash
kubectl delete -f vulnerable-secrets.yaml
```

### Paso 2 — Desplegar la configuracion segura

```bash
kubectl apply -f secure-secrets.yaml

kubectl get pods -n lab3-secrets
kubectl wait --for=condition=Ready pod/app-secure-secrets -n lab3-secrets --timeout=120s
```

### Paso 3 — Verificar que los secrets NO estan en env vars

```bash
kubectl exec -it app-secure-secrets -n lab3-secrets -- sh

# Intentar leer desde env
env | grep DB_
# Resultado: VACIO (no hay variables DB_*)

# Los secrets estan montados como archivos read-only
ls -la /etc/secrets/db/
cat /etc/secrets/db/DB_PASSWORD

# Verificar permisos restrictivos (0400 = solo lectura por owner)
stat /etc/secrets/db/DB_PASSWORD

exit
```

---

## Diferencias Clave

| Aspecto                  | Vulnerable              | Seguro                     |
|--------------------------|-------------------------|----------------------------|
| Metodo de exposicion     | `envFrom` (env vars)    | `volumeMount` (archivos)   |
| Visible con `env`        | Si                      | No                         |
| Visible en `/proc`       | Si                      | No                         |
| Heredado por hijos       | Si                      | No                         |
| Permisos de archivo      | N/A                     | `0400` (read-only owner)   |
| Read-only filesystem     | No                      | Si                         |
| SecurityContext           | Ninguno                | Non-root + drop ALL        |

---

## Recomendaciones para Produccion

1. **External Secrets Operator** + **HashiCorp Vault** para gestion centralizada
2. **Encryption at rest** en etcd (`EncryptionConfiguration`)
3. **RBAC** restrictivo para acceso a secrets
4. **Audit logging** para detectar accesos no autorizados

---

## Limpieza

```bash
kubectl delete namespace lab3-secrets
```

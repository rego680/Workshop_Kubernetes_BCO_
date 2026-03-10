# Lab 3: Deployment con Replicas y Self-Healing

## Descripcion

Diferencia fundamental entre un Pod suelto y un Deployment. El Deployment
garantiza que siempre haya el numero deseado de replicas corriendo.
Si un Pod muere, Kubernetes lo recrea automaticamente (self-healing).

| Propiedad          | Valor                       |
|--------------------|-----------------------------|
| **Recurso**        | Deployment                  |
| **Imagen**         | `httpd:2.4-alpine` (~55 MB) |
| **Replicas**       | 2 (escalable)               |
| **Puerto Pod**     | `80`                        |
| **Concepto**       | Deployment, ReplicaSet, Scaling, Self-healing |

---

## Archivos del Lab

| Archivo                    | Descripcion                              |
|----------------------------|------------------------------------------|
| `lab2-app-deployment.yaml` | Deployment Apache con 2 replicas         |

---

## Ejecucion

### Paso 1 — Desplegar el Deployment

```bash
cd Unidad-3/lab3/

kubectl apply -f lab2-app-deployment.yaml
```

### Paso 2 — Verificar los recursos creados

```bash
# Ver el Deployment
kubectl get deploy httpd-lab2

# Ver los Pods creados por el Deployment
kubectl get pods -l app=httpd-lab2

# Ver el ReplicaSet (creado automaticamente por el Deployment)
kubectl get replicaset -l app=httpd-lab2

# Ver todo junto
kubectl get deploy,rs,pods -l app=httpd-lab2
```

### Paso 3 — Exponer el Deployment con un Service

```bash
# Crear un Service para acceder a los Pods
kubectl expose deployment httpd-lab2 --type=NodePort --port=80

# Ver el Service creado
kubectl get svc httpd-lab2

# Acceder via port-forward
kubectl port-forward --address 0.0.0.0 svc/httpd-lab2 8080:80 &
curl http://localhost:8080
# Resultado: "It works!" (pagina por defecto de Apache)
```

### Paso 4 — Demostrar Self-Healing

```bash
# Ver los pods actuales
kubectl get pods -l app=httpd-lab2

# Eliminar uno de los pods (copiar el nombre del pod)
kubectl delete pod <NOMBRE_DEL_POD>

# Inmediatamente verificar: K8s recrea el pod!
kubectl get pods -l app=httpd-lab2
# Resultado: un pod nuevo aparece para mantener las 2 replicas
```

### Paso 5 — Escalar replicas

```bash
# Escalar a 5 replicas
kubectl scale deployment httpd-lab2 --replicas=5

# Verificar
kubectl get pods -l app=httpd-lab2
# Resultado: 5 pods corriendo

# Ver el Deployment actualizado
kubectl get deploy httpd-lab2
# READY: 5/5
```

### Paso 6 — Reducir replicas

```bash
# Escalar a 1 replica
kubectl scale deployment httpd-lab2 --replicas=1

# Verificar: los pods extra se terminan
kubectl get pods -l app=httpd-lab2
# Resultado: solo 1 pod corriendo
```

### Paso 7 — Ver el rollout y los eventos

```bash
# Ver el estado del rollout
kubectl rollout status deployment httpd-lab2

# Ver el historial de cambios
kubectl rollout history deployment httpd-lab2

# Ver eventos del Deployment
kubectl describe deployment httpd-lab2
```

---

## Comparacion: Pod Suelto vs Deployment

| Aspecto           | Pod Suelto (Lab 1)         | Deployment (Lab 3)            |
|-------------------|----------------------------|-------------------------------|
| Self-healing      | No (si muere, no se recrea)| Si (siempre mantiene replicas)|
| Replicas          | Solo 1                     | Configurable (1, 2, 5, N)    |
| Escalado          | No                         | `kubectl scale`               |
| Rolling updates   | No                         | Si (actualiza sin downtime)   |
| Rollback          | No                         | `kubectl rollout undo`        |
| Recurso intermedio| N/A                        | ReplicaSet (automatico)       |

---

## Verificacion

| Prueba              | Comando                                   | Resultado esperado        |
|---------------------|-------------------------------------------|---------------------------|
| Deployment creado   | `kubectl get deploy httpd-lab2`           | READY: 2/2                |
| Pods corriendo      | `kubectl get pods -l app=httpd-lab2`      | 2 pods Running            |
| Self-healing        | Eliminar un pod y verificar               | Pod nuevo creado           |
| Escalar a 5         | `kubectl scale deploy httpd-lab2 --replicas=5` | 5 pods Running      |
| Apache accesible    | `curl` via port-forward                   | "It works!"               |

---

## Conceptos Clave

- **Deployment**: Controlador que gestiona Pods via ReplicaSets. Garantiza N replicas corriendo.
- **ReplicaSet**: Mantiene el numero deseado de Pods identicos. Creado automaticamente por el Deployment.
- **Self-healing**: Si un Pod muere, el ReplicaSet lo detecta y crea uno nuevo.
- **Scaling**: Cambiar el numero de replicas en caliente con `kubectl scale`.
- **matchLabels**: El Deployment encuentra sus Pods usando este selector de labels.
- **template**: Plantilla que define como crear cada Pod replica.

---

## Limpieza

```bash
kubectl delete svc httpd-lab2 2>/dev/null
kubectl delete -f lab2-app-deployment.yaml
# Detener port-forwards activos
kill %1 2>/dev/null
```

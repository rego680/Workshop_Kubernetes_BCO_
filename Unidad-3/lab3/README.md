# Lab 3: Deployment con Replicas y Self-Healing

Introduce el concepto de **Deployment**: un controlador que mantiene un numero deseado de replicas de Pods y los recrea automaticamente si fallan (**self-healing**).

```
                        Deployment: httpd-lab2
                        replicas: 2
                    ┌───────────┴───────────┐
                    │                       │
              ┌─────┴─────┐          ┌──────┴────┐
              │  Pod 1    │          │  Pod 2     │
              │  httpd    │          │  httpd     │
              │  :80      │          │  :80       │
              └───────────┘          └────────────┘
              httpd:2.4-alpine       httpd:2.4-alpine

   Si un Pod muere → Kubernetes crea uno nuevo automaticamente
```

| Propiedad          | Valor                            |
|--------------------|----------------------------------|
| **Recurso**        | Deployment                       |
| **Imagen**         | `httpd:2.4-alpine` (~55 MB)      |
| **Replicas**       | `2`                              |
| **Puerto**         | `80`                             |
| **Namespace**      | `default`                        |
| **apiVersion**     | `apps/v1`                        |
| **RAM**            | 32Mi (request) / 64Mi (limit)    |
| **CPU**            | 50m (request) / 100m (limit)     |

---

## Conceptos Clave

### Pod vs Deployment

| Caracteristica     | Pod (Lab 1)                      | Deployment (Lab 3)                  |
|--------------------|----------------------------------|-------------------------------------|
| **Self-healing**   | NO - si muere, se pierde         | SI - K8s recrea Pods automaticamente |
| **Replicas**       | Solo 1                           | Multiples (configurable)             |
| **Escalado**       | No escalable                     | `kubectl scale` para escalar         |
| **Rolling update** | No soportado                     | Actualizaciones sin downtime         |
| **Uso tipico**     | Labs, pruebas simples            | Produccion, aplicaciones reales      |

### Componentes del Deployment

| Componente          | Descripcion                                                    |
|---------------------|----------------------------------------------------------------|
| **replicas**        | Numero de Pods que K8s debe mantener corriendo en todo momento |
| **selector**        | Conecta el Deployment con sus Pods via matchLabels              |
| **template**        | Plantilla para crear cada replica del Pod                       |
| **matchLabels**     | DEBE coincidir exactamente con las labels del template          |

---

## Requisitos Previos

- **Minikube** instalado y corriendo
- **kubectl** configurado y conectado al cluster

```bash
minikube status
kubectl cluster-info
kubectl get nodes
```

---

## Despliegue Paso a Paso

### 1. Ir al directorio del lab

```bash
cd Unidad-3/lab3/
```

### 2. Crear el Deployment

```bash
kubectl apply -f lab2-app-deployment.yaml
```

Salida esperada:
```
deployment.apps/httpd-lab2 created
```

### 3. Verificar el Deployment y los Pods

```bash
# Ver el Deployment
kubectl get deploy httpd-lab2

# Ver los Pods creados
kubectl get pods
```

Salida esperada:
```
NAME                          READY   STATUS    RESTARTS   AGE
httpd-lab2-xxxxxxxxx-xxxxx    1/1     Running   0          10s
httpd-lab2-xxxxxxxxx-yyyyy    1/1     Running   0          10s
```

> Notar que los nombres de los Pods tienen un sufijo aleatorio generado por el Deployment.

### 4. Ver detalles del Deployment

```bash
kubectl describe deploy httpd-lab2
```

Informacion relevante:
- **Replicas**: 2 desired | 2 updated | 2 available
- **Selector**: app=httpd-lab2
- **Strategy**: RollingUpdate

---

## Probar el Self-Healing

Esta es la diferencia clave respecto al Lab 1. Si un Pod muere, el Deployment crea uno nuevo.

### 5. Eliminar un Pod manualmente

```bash
# Ver los Pods actuales
kubectl get pods

# Copiar el nombre de uno de los Pods y eliminarlo
kubectl delete pod <NOMBRE_DEL_POD>

# Ver inmediatamente como K8s crea un reemplazo
kubectl get pods
```

Resultado esperado:
```
NAME                          READY   STATUS    RESTARTS   AGE
httpd-lab2-xxxxxxxxx-xxxxx    1/1     Running   0          5m    ← Pod original
httpd-lab2-xxxxxxxxx-zzzzz    1/1     Running   0          3s    ← Pod NUEVO (reemplazo)
```

> El Deployment detecto que solo habia 1 Pod (deseado: 2) y creo uno nuevo automaticamente.

---

## Escalar el Deployment

### 6. Aumentar replicas

```bash
# Escalar a 5 replicas
kubectl scale deployment httpd-lab2 --replicas=5

# Verificar
kubectl get pods
```

Salida esperada:
```
NAME                          READY   STATUS    RESTARTS   AGE
httpd-lab2-xxxxxxxxx-aaaaa    1/1     Running   0          5m
httpd-lab2-xxxxxxxxx-bbbbb    1/1     Running   0          5m
httpd-lab2-xxxxxxxxx-ccccc    1/1     Running   0          5s
httpd-lab2-xxxxxxxxx-ddddd    1/1     Running   0          5s
httpd-lab2-xxxxxxxxx-eeeee    1/1     Running   0          5s
```

### 7. Reducir replicas

```bash
# Reducir a 1 replica
kubectl scale deployment httpd-lab2 --replicas=1

# Verificar - K8s eliminara los Pods sobrantes
kubectl get pods
```

---

## Estructura del Manifiesto

```yaml
apiVersion: apps/v1          # Grupo "apps" (no v1 core)
kind: Deployment
metadata:
  name: httpd-lab2
spec:
  replicas: 2                # Cuantos Pods mantener
  selector:
    matchLabels:
      app: httpd-lab2        # Debe coincidir con template.labels
  template:                  # Plantilla del Pod
    metadata:
      labels:
        app: httpd-lab2      # Debe coincidir con selector
    spec:
      containers:
      - name: httpd
        image: httpd:2.4-alpine
        ports:
        - containerPort: 80
```

> El `template` es como un Pod sin `apiVersion` ni `kind` — esos estan implicitos.

---

## Estructura del Proyecto

```
lab3/
├── lab2-app-deployment.yaml    # Deployment: httpd:2.4-alpine, 2 replicas
├── lab2-app-service.yaml       # Service NodePort para exponer el Deployment
└── README.md
```

---

## Comandos Utiles

```bash
# Ver estado del Deployment
kubectl rollout status deployment httpd-lab2

# Ver historial de despliegues
kubectl rollout history deployment httpd-lab2

# Ver los ReplicaSets (creados internamente por el Deployment)
kubectl get replicasets

# Ver los Pods con sus labels
kubectl get pods --show-labels

# Acceder al contenedor de un Pod
kubectl exec -it <NOMBRE_POD> -- sh

# Ver la pagina servida por Apache
kubectl exec <NOMBRE_POD> -- cat /usr/local/apache2/htdocs/index.html
# Mostrara: "It works!"
```

---

## Exponer el Deployment (Minikube)

Se incluye un Service NodePort para acceder al Deployment desde el navegador:

### 8. Crear el Service

```bash
kubectl apply -f lab2-app-service.yaml
```

### 9. Verificar el Service

```bash
kubectl get svc httpd-lab2-svc
```

Salida esperada:
```
NAME             TYPE       CLUSTER-IP     EXTERNAL-IP   PORT(S)        AGE
httpd-lab2-svc   NodePort   10.x.x.x      <none>        80:30081/TCP   5s
```

### 10. Acceder a la aplicacion (Minikube)

**Opcion A — `minikube service` (recomendada):**
```bash
minikube service httpd-lab2-svc
```

**Opcion B — `port-forward`:**
```bash
kubectl port-forward svc/httpd-lab2-svc 8080:80
curl http://localhost:8080
```

**Opcion C — IP del nodo (solo driver VirtualBox/KVM):**
```bash
curl http://$(minikube ip):30081
```

Se mostrara la pagina por defecto de Apache: **"It works!"**

> El Service balancea el trafico entre las 2 replicas del Deployment automaticamente.

---

## Limpieza

```bash
# Eliminar el Service y el Deployment (y todos sus Pods)
kubectl delete -f lab2-app-service.yaml
kubectl delete -f lab2-app-deployment.yaml

# Verificar que todo se elimino
kubectl get deploy,pods,svc
```

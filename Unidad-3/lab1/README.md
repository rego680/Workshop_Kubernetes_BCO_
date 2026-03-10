# Lab 1: Nginx Pod + Service (NodePort)

## Descripcion

Primer contacto con manifiestos de Kubernetes. Despliega un Pod con Nginx
y lo expone fuera del cluster usando un Service de tipo NodePort.

| Propiedad        | Valor                      |
|------------------|----------------------------|
| **Recurso**      | Pod + Service              |
| **Imagen**       | `nginx:1.25-alpine`        |
| **Puerto Pod**   | `80`                       |
| **NodePort**     | `30080`                    |
| **Concepto**     | Pod, Service, Labels, Selector |

---

## Archivos del Lab

| Archivo                  | Descripcion                            |
|--------------------------|----------------------------------------|
| `lab1-nginx-pod.yaml`    | Pod Nginx con labels y resource limits |
| `lab1-nginx-service.yaml`| Service NodePort en puerto 30080       |

---

## Ejecucion

### Paso 1 — Desplegar el Pod

```bash
cd Unidad-3/lab1/

kubectl apply -f lab1-nginx-pod.yaml
```

### Paso 2 — Verificar que el Pod esta corriendo

```bash
# Ver estado del pod
kubectl get pods

# Ver detalles completos (eventos, IP, nodo asignado)
kubectl describe pod nginx-lab1

# Ver logs del contenedor
kubectl logs nginx-lab1
```

### Paso 3 — Desplegar el Service

```bash
kubectl apply -f lab1-nginx-service.yaml

# Verificar el service
kubectl get svc nginx-lab1-svc
```

### Paso 4 — Acceder a Nginx

```bash
# Opcion A: Usando minikube service
minikube service nginx-lab1-svc --url
# Copiar la URL y abrir en navegador o usar curl

# Opcion B: Port-forward (funciona siempre)
kubectl port-forward --address 0.0.0.0 svc/nginx-lab1-svc 30080:80 &
curl http://localhost:30080

# Opcion C: Usando la IP del nodo minikube
minikube ip
# curl http://<MINIKUBE_IP>:30080
```

### Paso 5 — Explorar el Pod

```bash
# Entrar al contenedor
kubectl exec -it nginx-lab1 -- sh

# Dentro del contenedor:
nginx -v
ls /usr/share/nginx/html/
cat /usr/share/nginx/html/index.html
exit
```

### Paso 6 — Inspeccionar labels y selectores

```bash
# Ver labels del pod
kubectl get pods --show-labels

# Ver como el Service selecciona el Pod
kubectl describe svc nginx-lab1-svc
# En "Selector" debe decir: app=nginx-lab1
# En "Endpoints" debe aparecer la IP del Pod
```

### Paso 7 — Probar self-healing (Pod suelto NO se recrea)

```bash
# Eliminar el pod
kubectl delete pod nginx-lab1

# Verificar: NO se recrea (es un Pod suelto, no un Deployment)
kubectl get pods
# Resultado: No resources found

# El Service queda sin endpoints
kubectl describe svc nginx-lab1-svc
# Endpoints: <none>

# Recrear el pod
kubectl apply -f lab1-nginx-pod.yaml
```

---

## Flujo del Trafico

```
Cliente --> <IP_NODO>:30080 --> Service:80 --> Pod:80 (Nginx)
```

El Service encuentra el Pod usando el **selector** `app: nginx-lab1`
que coincide con las **labels** del Pod.

---

## Verificacion

| Prueba              | Comando                                 | Resultado esperado      |
|---------------------|-----------------------------------------|-------------------------|
| Pod corriendo       | `kubectl get pods`                      | STATUS: Running         |
| Service creado      | `kubectl get svc nginx-lab1-svc`        | TYPE: NodePort          |
| Endpoints asignados | `kubectl describe svc nginx-lab1-svc`   | IP del pod visible      |
| Nginx accesible     | `curl` a la URL del service             | HTML de Nginx           |
| Labels correctos    | `kubectl get pods --show-labels`        | app=nginx-lab1          |

---

## Conceptos Clave

- **Pod**: Unidad minima de ejecucion en Kubernetes. Envuelve uno o mas contenedores.
- **Service**: Punto de acceso estable al Pod (los Pods tienen IPs efimeras).
- **NodePort**: Tipo de Service que abre un puerto (30000-32767) en cada nodo del cluster.
- **Labels**: Etiquetas clave:valor para identificar y agrupar recursos.
- **Selector**: Filtro que usa el Service para encontrar sus Pods por labels.
- **Resources requests/limits**: Garantias y limites de CPU y memoria por contenedor.

---

## Limpieza

```bash
kubectl delete -f lab1-nginx-service.yaml
kubectl delete -f lab1-nginx-pod.yaml
```

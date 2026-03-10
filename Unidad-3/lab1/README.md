# Lab 1: Mi Primer Pod y Service en Kubernetes

Crea un **Pod** con Nginx y lo expone al exterior con un **Service NodePort**. Es el primer contacto con manifiestos YAML de Kubernetes.

```
 ┌──────────────┐         ┌──────────────────┐         ┌──────────────┐
 │   Cliente    │         │    Service        │         │     Pod      │
 │  (Navegador) │──────►  │  nginx-lab1-svc   │──────►  │  nginx-lab1  │
 │              │         │  NodePort: 30080  │         │  Puerto: 80  │
 └──────────────┘         └──────────────────┘         └──────────────┘
   IP:30080                    port: 80                  nginx:1.25-alpine
```

| Propiedad          | Valor                          |
|--------------------|--------------------------------|
| **Recurso**        | Pod + Service                  |
| **Imagen**         | `nginx:1.25-alpine` (~40 MB)   |
| **Puerto externo** | `30080` (NodePort)             |
| **Puerto interno** | `80`                           |
| **Namespace**      | `default`                      |
| **RAM**            | 32Mi (request) / 64Mi (limit)  |
| **CPU**            | 50m (request) / 100m (limit)   |

---

## Conceptos Clave

| Concepto         | Descripcion                                                       |
|------------------|-------------------------------------------------------------------|
| **Pod**          | Unidad minima de ejecucion en Kubernetes. Envuelve 1+ contenedores |
| **Service**      | Punto de acceso estable para llegar a los Pods                     |
| **NodePort**     | Tipo de Service que abre un puerto (30000-32767) en cada nodo      |
| **Labels**       | Etiquetas clave:valor que conectan Services con Pods               |
| **apiVersion**   | `v1` para Pod/Service, `apps/v1` para Deployments                  |

### Tipos de Service

| Tipo             | Acceso                           | Uso tipico                     |
|------------------|----------------------------------|--------------------------------|
| **ClusterIP**    | Solo dentro del cluster          | Comunicacion entre microservicios |
| **NodePort**     | Desde cualquier maquina en la red | Labs, desarrollo, acceso directo |
| **LoadBalancer** | IP publica via balanceador       | Produccion en la nube (AWS, GCP)  |

---

## Requisitos Previos

- Cluster de **Kubernetes** funcionando (minikube, kubeadm, etc.)
- **kubectl** configurado y conectado al cluster

```bash
kubectl cluster-info
kubectl get nodes
```

---

## Despliegue Paso a Paso

### 1. Ir al directorio del lab

```bash
cd Unidad-3/lab1/
```

### 2. Crear el Pod de Nginx

```bash
kubectl apply -f lab1-nginx-pod.yaml
```

Salida esperada:
```
pod/nginx-lab1 created
```

### 3. Verificar que el Pod esta corriendo

```bash
kubectl get pods
```

Salida esperada:
```
NAME         READY   STATUS    RESTARTS   AGE
nginx-lab1   1/1     Running   0          10s
```

> Si STATUS muestra `ContainerCreating`, esperar unos segundos y repetir el comando.

### 4. Inspeccionar el Pod en detalle

```bash
# Ver todos los detalles del Pod (eventos, IP, nodo, etc.)
kubectl describe pod nginx-lab1

# Ver los logs del contenedor Nginx
kubectl logs nginx-lab1
```

### 5. Crear el Service NodePort

```bash
kubectl apply -f lab1-nginx-service.yaml
```

Salida esperada:
```
service/nginx-lab1-svc created
```

### 6. Verificar el Service

```bash
kubectl get svc nginx-lab1-svc
```

Salida esperada:
```
NAME             TYPE       CLUSTER-IP     EXTERNAL-IP   PORT(S)        AGE
nginx-lab1-svc   NodePort   10.x.x.x      <none>        80:30080/TCP   5s
```

### 7. Acceder a Nginx desde el navegador

```bash
# Desde el propio servidor
curl http://localhost:30080

# Desde otra maquina en la red
curl http://<IP_SERVIDOR>:30080
```

Abrir en el navegador:
```
http://<IP_SERVIDOR>:30080
```

Se mostrara la pagina por defecto de Nginx: **"Welcome to nginx!"**

---

## Flujo del Trafico

```
Cliente (navegador)
      │
      ▼
IP_SERVIDOR:30080    ← NodePort (puerto externo en el nodo)
      │
      ▼
Service:80           ← El Service recibe en puerto 80
      │
      ▼
Pod:80               ← El contenedor Nginx escucha en puerto 80
```

El Service encuentra al Pod usando el **selector** `app: nginx-lab1`, que coincide con la **label** del Pod.

---

## Estructura del Proyecto

```
lab1/
├── lab1-nginx-pod.yaml        # Manifiesto del Pod (nginx:1.25-alpine)
├── lab1-nginx-service.yaml    # Manifiesto del Service (NodePort 30080)
└── README.md
```

---

## Comandos Utiles

```bash
# Ver Pods con labels
kubectl get pods --show-labels

# Ver todos los Services
kubectl get svc

# Ver endpoints (la IP interna del Pod asociada al Service)
kubectl get endpoints nginx-lab1-svc

# Entrar al contenedor del Pod
kubectl exec -it nginx-lab1 -- sh

# Ver la pagina HTML servida dentro del contenedor
kubectl exec nginx-lab1 -- cat /usr/share/nginx/html/index.html
```

---

## Limpieza

```bash
# Eliminar Service y Pod
kubectl delete -f lab1-nginx-service.yaml
kubectl delete -f lab1-nginx-pod.yaml

# Verificar que se eliminaron
kubectl get pods,svc
```

# Lab 2: Reto Paraiso — Enumeracion de Kubernetes

## Descripcion

Reto practico de enumeracion: localizar un Pod oculto en el namespace `kube-public`,
descubrir su Service NodePort y acceder a la pagina que contiene el flag.
Incluye tambien el despliegue del Dashboard de Kubernetes.

| Propiedad        | Valor                          |
|------------------|--------------------------------|
| **Pod**          | `paraiso` en `kube-public`     |
| **Service**      | `paraiso-svc` (NodePort 32767) |
| **Imagen**       | `nginx:1.25-alpine`            |
| **Flag**         | Visible al acceder al servicio |
| **Concepto**     | Namespaces, enumeracion, NodePort, Dashboard |

---

## Archivos del Lab

| Archivo                                 | Descripcion                                |
|-----------------------------------------|--------------------------------------------|
| `paraiso-pod.yaml`                      | Pod Nginx + ConfigMap con HTML del flag     |
| `paraiso-service.yaml`                  | Service NodePort en puerto 32767            |
| `start-dashboard.sh`                    | Script para iniciar el Dashboard de minikube|
| `port-forward-dashboard-kubernetes.sh`  | Port-forward del Dashboard                  |

---

## Ejecucion

### Parte A: Desplegar el Reto

#### Paso 1 — Desplegar el Pod y Service

```bash
cd Unidad-3/lab2/Mandatory_lab/

# Crear el Pod con su ConfigMap
kubectl apply -f paraiso-pod.yaml

# Crear el Service
kubectl apply -f paraiso-service.yaml

# Verificar que estan corriendo en kube-public
kubectl get pods -n kube-public
kubectl get svc -n kube-public
```

#### Paso 2 — Acceder al reto

```bash
# Opcion A: Port-forward (recomendado en minikube)
kubectl port-forward --address 0.0.0.0 -n kube-public svc/paraiso-svc 32767:80 &

# Abrir en navegador o curl
curl http://localhost:32767

# Opcion B: Usando la IP de minikube
minikube ip
# curl http://<MINIKUBE_IP>:32767
```

---

### Parte B: El Reto (perspectiva del estudiante)

El objetivo es que el estudiante descubra el Pod por su cuenta.
Los pasos que debe seguir:

#### Paso 1 — Enumerar todos los namespaces

```bash
kubectl get namespaces
```

#### Paso 2 — Buscar pods en todos los namespaces

```bash
kubectl get pods -A
# Debe encontrar el pod "paraiso" en namespace "kube-public"
```

#### Paso 3 — Buscar services en todos los namespaces

```bash
kubectl get svc -A
# Debe encontrar "paraiso-svc" con NodePort 32767
```

#### Paso 4 — Investigar el pod

```bash
kubectl describe pod paraiso -n kube-public
# Ver imagen, labels, volumeMounts, ConfigMap
```

#### Paso 5 — Acceder al Service

```bash
# Port-forward
kubectl port-forward --address 0.0.0.0 -n kube-public svc/paraiso-svc 32767:80 &
curl http://localhost:32767

# El flag esta en la pagina: Flag{S3rvice_Identificado}
```

---

### Parte C: Dashboard de Kubernetes

#### Paso 1 — Iniciar el Dashboard de minikube

```bash
# Opcion A: Usando el script
minikube dashboard --url &
# Copiar la URL que aparece

# Opcion B: Port-forward del dashboard
kubectl port-forward -n kubernetes-dashboard svc/kubernetes-dashboard 65500:80 --address='0.0.0.0' &
# Acceder a: http://localhost:65500
```

#### Paso 2 — Explorar el Dashboard

En el Dashboard se puede:
- Ver todos los namespaces y sus recursos
- Inspeccionar Pods, Services, ConfigMaps
- Ver logs y eventos en tiempo real
- Encontrar el pod "paraiso" navegando a namespace `kube-public`

---

## Verificacion

| Prueba                    | Comando                              | Resultado esperado             |
|---------------------------|--------------------------------------|--------------------------------|
| Pod en kube-public        | `kubectl get pods -n kube-public`    | paraiso Running                |
| Service NodePort          | `kubectl get svc -n kube-public`     | paraiso-svc NodePort 32767     |
| Pagina accesible          | `curl http://localhost:32767`        | HTML con el flag               |
| Flag encontrado           | Ver pagina en navegador              | `Flag{S3rvice_Identificado}`   |
| Dashboard activo          | Abrir URL del dashboard              | Interfaz grafica de Kubernetes |

---

## Conceptos Clave

- **Namespace**: Particion logica del cluster. `kube-public` es accesible para todos.
- **kubectl get -A**: Lista recursos de TODOS los namespaces.
- **kubectl describe**: Muestra detalles completos de un recurso.
- **ConfigMap**: Almacena configuracion (en este caso, el HTML) como un recurso de Kubernetes.
- **NodePort**: Expone un Service en un puerto fijo de cada nodo (32767 en este caso).
- **Dashboard**: Interfaz web para visualizar y gestionar recursos del cluster.

---

## Limpieza

```bash
kubectl delete -f paraiso-service.yaml
kubectl delete -f paraiso-pod.yaml
# Detener port-forwards activos
kill %1 2>/dev/null
```

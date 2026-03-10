# Lab 2: Reto de Enumeracion - Paraiso (Mandatory)

Reto practico de **enumeracion en Kubernetes**: encontrar un Pod oculto en un namespace no predeterminado, identificar su Service y acceder a la pagina con el flag de completado.

```
 ┌─────────────────────────────────────────────────────────┐
 │                    RETO: PARAISO                        │
 │                                                         │
 │  Objetivo: Encontrar el Pod oculto y acceder al flag    │
 │                                                         │
 │  Pistas:                                                │
 │    1. No esta en el namespace "default"                 │
 │    2. Usa kubectl para enumerar TODOS los namespaces    │
 │    3. Busca el Service para saber el puerto             │
 │                                                         │
 │  Flag: Flag{S3rvice_Identificado}                       │
 └─────────────────────────────────────────────────────────┘
```

| Propiedad          | Valor                          |
|--------------------|--------------------------------|
| **Recurso**        | ConfigMap + Pod + Service      |
| **Imagen**         | `nginx:1.25-alpine` (~40 MB)   |
| **Namespace**      | `kube-public`                  |
| **Puerto externo** | `32767` (NodePort)             |
| **Puerto interno** | `80`                           |
| **Flag**           | `Flag{S3rvice_Identificado}`   |

---

## Conceptos Clave

| Concepto         | Descripcion                                                         |
|------------------|---------------------------------------------------------------------|
| **Namespace**    | Agrupacion logica de recursos. Aisla entornos dentro del cluster     |
| **kube-public**  | Namespace especial accesible por todos, incluso sin autenticacion    |
| **ConfigMap**    | Recurso para inyectar configuraciones/archivos en contenedores       |
| **VolumeMount**  | Monta un volumen (como un ConfigMap) dentro del contenedor           |
| **Enumeracion**  | Tecnica de reconocimiento: descubrir recursos ocultos en el cluster  |

### Namespaces Comunes en Kubernetes

| Namespace              | Proposito                                        |
|------------------------|--------------------------------------------------|
| `default`              | Namespace por defecto si no se especifica otro    |
| `kube-system`          | Componentes internos de Kubernetes                |
| `kube-public`          | Recursos publicos, accesibles por todos           |
| `kube-node-lease`      | Heartbeats de los nodos                           |
| `kubernetes-dashboard` | Dashboard web de Kubernetes (si esta instalado)   |

---

## Requisitos Previos

- **Minikube** instalado y corriendo
- **kubectl** configurado y conectado al cluster

```bash
minikube status
kubectl cluster-info
kubectl get namespaces
```

---

## Despliegue Paso a Paso (Instructor)

> Estos pasos los ejecuta el instructor para preparar el reto. Los alumnos deben descubrir el Pod por su cuenta.

### 1. Ir al directorio del lab

```bash
cd Unidad-3/lab2/Mandatory_lab/
```

### 2. Crear el ConfigMap y el Pod

El archivo `paraiso-pod.yaml` contiene dos recursos:
- **ConfigMap** `paraiso-html`: pagina HTML con el flag del reto
- **Pod** `paraiso`: Nginx que sirve la pagina del ConfigMap

```bash
kubectl apply -f paraiso-pod.yaml
```

Salida esperada:
```
configmap/paraiso-html created
namespace/kube-public configured
pod/paraiso created
```

### 3. Crear el Service

```bash
kubectl apply -f paraiso-service.yaml
```

Salida esperada:
```
service/paraiso-svc created
```

### 4. Verificar el despliegue

```bash
# Ver el Pod en kube-public
kubectl get pods -n kube-public

# Ver el Service
kubectl get svc -n kube-public
```

### 5. Habilitar acceso (Minikube)

En Minikube con driver Docker, el NodePort no es accesible directamente. Elegir una opcion:

**Opcion A — port-forward (recomendada):**
```bash
kubectl port-forward --address 0.0.0.0 -n kube-public svc/paraiso-svc 32767:80 &
```

**Opcion B — minikube service:**
```bash
minikube service paraiso-svc -n kube-public
```

**Opcion C — IP del nodo (solo driver VirtualBox/KVM):**
```bash
curl http://$(minikube ip):32767
```

### 6. Verificar acceso

```bash
curl http://localhost:32767
```

Se mostrara la pagina HTML con el flag `Flag{S3rvice_Identificado}`.

---

## Resolucion del Reto (Alumno)

Estos son los pasos que el alumno debe descubrir por su cuenta:

### Paso 1: Listar Pods en todos los namespaces

```bash
kubectl get pods -A
```

Resultado: se descubre el Pod `paraiso` en el namespace `kube-public`.

### Paso 2: Inspeccionar el Pod

```bash
kubectl describe pod paraiso -n kube-public
```

Esto revela la imagen, labels, volumenes y estado del Pod.

### Paso 3: Buscar el Service asociado

```bash
kubectl get svc -A
```

Resultado: se descubre `paraiso-svc` en `kube-public` con NodePort `32767`.

### Paso 4: Acceder al flag

```bash
# Opcion A — port-forward:
kubectl port-forward --address 0.0.0.0 -n kube-public svc/paraiso-svc 32767:80 &
curl http://localhost:32767

# Opcion B — minikube service (abre navegador):
minikube service paraiso-svc -n kube-public
```

Se muestra la pagina de completado con:
- Lo que demostro el alumno (enumerar pods, encontrar services, etc.)
- Datos del Pod (nombre, namespace, imagen, puerto)
- Conceptos aplicados
- **Flag: `Flag{S3rvice_Identificado}`**

---

## Herramientas Adicionales: Kubernetes Dashboard

El lab incluye scripts para habilitar el dashboard web de Kubernetes:

### Opcion A: Minikube Dashboard

```bash
# Iniciar el dashboard de Minikube
./start-dashboard.sh
# Ejecuta: minikube dashboard --url &
```

### Opcion B: Port-forward del Dashboard

```bash
# Habilitar addon y redirigir al puerto 65500
# Detecta automaticamente el nombre del servicio segun la version de Minikube
./port-forward-dashboard-kubernetes.sh
```

Acceder al dashboard:
```
http://<IP_SERVIDOR>:65500
```

---

## Arquitectura del Reto

```
 paraiso-pod.yaml contiene:
 ┌────────────────────────────────────────────┐
 │ ConfigMap: paraiso-html                     │
 │   index.html → Pagina con flag del reto     │
 └──────────────────┬─────────────────────────┘
                    │ se monta como volumen
                    ▼
 ┌────────────────────────────────────────────┐
 │ Pod: paraiso  (namespace: kube-public)      │
 │   nginx:1.25-alpine                         │
 │   /usr/share/nginx/html ← ConfigMap         │
 │   Puerto: 80                                │
 └──────────────────┬─────────────────────────┘
                    │ selector: app=paraiso
                    ▼
 ┌────────────────────────────────────────────┐
 │ Service: paraiso-svc (NodePort: 32767)      │
 │   namespace: kube-public                    │
 │   80:80 → Pod                               │
 └────────────────────────────────────────────┘
```

---

## Estructura del Proyecto

```
lab2/Mandatory_lab/
├── paraiso-pod.yaml                        # ConfigMap + Pod (namespace kube-public)
├── paraiso-service.yaml                    # Service NodePort en puerto 32767
├── Pasos_despliegue_paraiso-services.txt   # Referencia rapida de comandos
├── port-forward-dashboard-kubernetes.sh    # Script: dashboard en puerto 65500
├── start-dashboard.sh                      # Script: minikube dashboard
└── README.md
```

---

## Comandos Utiles para Enumeracion

```bash
# Listar TODOS los Pods en TODOS los namespaces
kubectl get pods -A

# Listar TODOS los Services
kubectl get svc -A

# Ver detalles de un Pod en otro namespace
kubectl describe pod <nombre> -n <namespace>

# Ver los logs de un Pod en otro namespace
kubectl logs <nombre> -n <namespace>

# Ver los endpoints de un Service
kubectl get endpoints -n kube-public
```

---

## Limpieza

```bash
# Eliminar Service y Pod
kubectl delete -f paraiso-service.yaml
kubectl delete -f paraiso-pod.yaml

# Verificar
kubectl get pods,svc -n kube-public
```

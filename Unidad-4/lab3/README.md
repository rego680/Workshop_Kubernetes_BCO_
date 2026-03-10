# Lab 3: Network Policies — Microsegmentacion de Red

Implementa **microsegmentacion** en Kubernetes usando **Network Policies**. Demuestra como aislar trafico entre namespaces aplicando el principio de **denegacion por defecto** y luego permitiendo solo las conexiones necesarias.

```
 ANTES (sin Network Policies):
 ┌──────────┐     ┌──────────┐     ┌──────────┐
 │ default  │────►│ frontend │────►│ backend  │
 │ test-    │     │ web-     │     │ api-     │
 │ client   │────►│ frontend │◄────│ backend  │
 └──────────┘     └──────────┘     └──────────┘
   Todos pueden hablar con todos (INSEGURO)

 DESPUES (con Network Policies):
 ┌──────────┐     ┌──────────┐     ┌──────────┐
 │ default  │  X  │ frontend │────►│ backend  │
 │ test-    │     │ web-     │     │ api-     │
 │ client   │  X  │ frontend │     │ backend  │
 └──────────┘     └──────────┘     └──────────┘
   Solo frontend puede hablar con backend (SEGURO)
```

| Propiedad          | Valor                              |
|--------------------|------------------------------------|
| **Recursos**       | Namespaces + Pods + Services + NetworkPolicies |
| **Namespaces**     | `frontend`, `backend`, `default`   |
| **Imagenes**       | `nginx:1.25-alpine`, `httpd:2.4-alpine`, `curlimages/curl` |
| **CNI requerido**  | Calico (soporta Network Policies)  |

---

## Conceptos Clave

| Concepto              | Descripcion                                                    |
|-----------------------|----------------------------------------------------------------|
| **Network Policy**    | Recurso que controla trafico de red entre Pods                  |
| **Microsegmentacion** | Aislar trafico a nivel de Pod/namespace (no solo perimetro)     |
| **Deny All**          | Politica base: bloquear todo y luego permitir lo necesario      |
| **Ingress**           | Trafico de ENTRADA al Pod (quien puede enviarle datos)          |
| **Egress**            | Trafico de SALIDA del Pod (a donde puede conectarse)            |
| **podSelector**       | Filtra a que Pods aplica la politica                            |
| **namespaceSelector** | Permite trafico desde/hacia Pods en namespaces especificos      |
| **CNI**               | Container Network Interface — plugin de red del cluster         |
| **Calico**            | CNI que soporta Network Policies (el default de Minikube no)    |

### Tipos de reglas

| Tipo                | Uso                                               |
|---------------------|---------------------------------------------------|
| **podSelector**     | Permitir trafico desde Pods con labels especificas |
| **namespaceSelector** | Permitir trafico desde namespaces completos      |
| **ipBlock**         | Permitir trafico desde rangos de IP (CIDR)         |
| **ports**           | Limitar a puertos especificos                      |

---

## Requisitos Previos

- **Minikube** instalado y corriendo **con CNI Calico**
- **kubectl** configurado y conectado al cluster

### IMPORTANTE: Minikube necesita Calico para Network Policies

El CNI por defecto de Minikube (kindnet) **NO soporta** Network Policies. Debes iniciar Minikube con Calico:

```bash
# Si ya tienes Minikube corriendo, detenerlo
minikube stop

# Eliminar el cluster actual (los labs anteriores se perderan)
minikube delete

# Crear nuevo cluster con Calico (CNI que soporta Network Policies)
minikube start --cni=calico --memory=2048 --cpus=2

# Verificar que Calico esta corriendo
kubectl get pods -n kube-system | grep calico
```

Salida esperada:
```
calico-kube-controllers-xxx   1/1     Running   0   1m
calico-node-xxx               1/1     Running   0   1m
```

> Si los Pods de Calico no aparecen, esperar 1-2 minutos y verificar de nuevo.

```bash
# Verificar que el cluster esta listo
minikube status
kubectl cluster-info
kubectl get nodes
```

---

## Despliegue Paso a Paso

### 1. Ir al directorio del lab

```bash
cd Unidad-4/lab3/
```

### 2. Crear los namespaces

```bash
kubectl apply -f lab3-namespace.yaml
```

Salida esperada:
```
namespace/frontend created
namespace/backend created
```

### 3. Verificar los namespaces

```bash
kubectl get namespaces --show-labels | grep -E "frontend|backend"
```

Salida esperada:
```
backend    Active   10s   team=backend,lab=unidad4-lab3
frontend   Active   10s   team=frontend,lab=unidad4-lab3
```

> Las labels `team=frontend` y `team=backend` son cruciales — las Network Policies las usan para filtrar trafico.

### 4. Desplegar las aplicaciones

```bash
kubectl apply -f lab3-apps.yaml
```

Salida esperada:
```
pod/web-frontend created
service/web-frontend-svc created
pod/api-backend created
service/api-backend-svc created
pod/test-client created
```

### 5. Verificar que todo esta corriendo

```bash
kubectl get pods -n frontend
kubectl get pods -n backend
kubectl get pods -n default | grep test-client
```

> Esperar hasta que todos los Pods esten en STATUS `Running`.

### 6. Probar conectividad SIN Network Policies

Primero, verificar que todos pueden comunicarse libremente:

```bash
# Desde test-client (default) → backend: FUNCIONA
kubectl exec test-client -- curl -s --max-time 5 api-backend-svc.backend.svc.cluster.local
# Salida: <html>...<h1>It works!</h1>...</html>

# Desde test-client (default) → frontend: FUNCIONA
kubectl exec test-client -- curl -s --max-time 5 web-frontend-svc.frontend.svc.cluster.local
# Salida: pagina de nginx

# Desde frontend → backend: FUNCIONA
kubectl exec -n frontend web-frontend -- curl -s --max-time 5 api-backend-svc.backend.svc.cluster.local
# Salida: <html>...<h1>It works!</h1>...</html>
```

> Sin Network Policies, cualquier Pod puede hablar con cualquier otro Pod en el cluster. Esto es **inseguro** en produccion.

---

## Aplicar Network Policies

### 7. Aplicar politica Deny-All en el backend

```bash
kubectl apply -f lab3-netpol-deny-all.yaml
```

Salida esperada:
```
networkpolicy.networking.k8s.io/deny-all-ingress created
```

### 8. Verificar la politica

```bash
kubectl get networkpolicy -n backend
kubectl describe networkpolicy deny-all-ingress -n backend
```

### 9. Probar que el trafico esta BLOQUEADO

```bash
# Desde test-client → backend: BLOQUEADO (timeout)
kubectl exec test-client -- curl -s --max-time 5 api-backend-svc.backend.svc.cluster.local
# Salida: (timeout despues de 5 segundos, sin respuesta)

# Desde frontend → backend: BLOQUEADO (timeout)
kubectl exec -n frontend web-frontend -- curl -s --max-time 5 api-backend-svc.backend.svc.cluster.local
# Salida: (timeout)

# Frontend sigue accesible (no tiene Network Policy)
kubectl exec test-client -- curl -s --max-time 5 web-frontend-svc.frontend.svc.cluster.local
# Salida: pagina de nginx (FUNCIONA — no esta bloqueado)
```

> La politica deny-all bloquea TODO el trafico de entrada al namespace backend. Nadie puede acceder a la API.

### 10. Permitir trafico SOLO desde frontend

```bash
kubectl apply -f lab3-netpol-allow-frontend.yaml
```

Salida esperada:
```
networkpolicy.networking.k8s.io/allow-frontend-to-backend created
```

### 11. Verificar las politicas activas

```bash
kubectl get networkpolicy -n backend
```

Salida esperada:
```
NAME                         POD-SELECTOR   AGE
deny-all-ingress             <none>         2m
allow-frontend-to-backend    <none>         5s
```

### 12. Probar la microsegmentacion

```bash
# Desde frontend → backend: PERMITIDO (por la nueva politica)
kubectl exec -n frontend web-frontend -- curl -s --max-time 5 api-backend-svc.backend.svc.cluster.local
# Salida: <html>...<h1>It works!</h1>...</html>

# Desde test-client (default) → backend: SIGUE BLOQUEADO
kubectl exec test-client -- curl -s --max-time 5 api-backend-svc.backend.svc.cluster.local
# Salida: (timeout — solo frontend tiene acceso)
```

> Solo los Pods en el namespace `frontend` pueden acceder al `backend`. Cualquier otro namespace esta bloqueado. Esto es **microsegmentacion**.

---

## Diagrama de trafico final

```
 ┌───────────────────────────────────────────────┐
 │              Network Policies                  │
 │                                                │
 │  frontend ──── PERMITIDO ────► backend         │
 │                (port 80)        (deny-all +    │
 │                                  allow-frontend)│
 │                                                │
 │  default ───── BLOQUEADO ─── X  backend        │
 │  (test-client)                                 │
 │                                                │
 │  default ──── SIN POLITICA ──► frontend        │
 │  (test-client) (permitido)                     │
 └───────────────────────────────────────────────┘
```

---

## Estructura del Proyecto

```
lab3/
├── lab3-namespace.yaml            # Namespaces: frontend y backend
├── lab3-apps.yaml                 # Pods + Services + test-client
├── lab3-netpol-deny-all.yaml      # Network Policy: bloquear TODO en backend
├── lab3-netpol-allow-frontend.yaml # Network Policy: permitir solo frontend
└── README.md
```

---

## Comandos Utiles

```bash
# Ver todas las Network Policies del cluster
kubectl get networkpolicy -A

# Ver detalles de una politica
kubectl describe networkpolicy <nombre> -n <namespace>

# Ver las labels de un namespace (usadas por namespaceSelector)
kubectl get namespace --show-labels

# Probar conectividad con timeout corto
kubectl exec <pod> -- curl -s --max-time 3 <service>.<namespace>.svc.cluster.local

# DNS interno de Kubernetes:
# <service-name>.<namespace>.svc.cluster.local
```

---

## Limpieza

```bash
# Eliminar Network Policies
kubectl delete -f lab3-netpol-allow-frontend.yaml
kubectl delete -f lab3-netpol-deny-all.yaml

# Eliminar aplicaciones
kubectl delete -f lab3-apps.yaml

# Eliminar namespaces (elimina todo lo que contienen)
kubectl delete -f lab3-namespace.yaml

# Verificar
kubectl get pods,svc,networkpolicy -n frontend 2>/dev/null
kubectl get pods,svc,networkpolicy -n backend 2>/dev/null
kubectl get pods | grep test-client
```

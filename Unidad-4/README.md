# Unidad 4: Seguridad en Kubernetes — 4 Laboratorios Practicos

Aplica las mejores practicas de **seguridad en Kubernetes**: gestion de configuracion sensible, hardening de contenedores, microsegmentacion de red y control de acceso basado en roles.

---

## Requisitos Previos

- **Minikube** instalado y corriendo
- **kubectl** configurado y conectado al cluster
- Minimo **2 GB RAM** y **2 CPUs** para Minikube

```bash
# Iniciar Minikube (con Calico para el Lab 3)
minikube start --cni=calico --memory=2048 --cpus=2

# Verificar
minikube status
kubectl cluster-info
kubectl get nodes
```

> **Nota**: El Lab 3 (Network Policies) requiere **Calico** como CNI. Si tu Minikube ya esta corriendo sin Calico, deberas recrearlo con `minikube delete && minikube start --cni=calico`.

---

## Laboratorios

| Lab | Tema                           | Concepto de Seguridad                      | Dificultad |
|-----|--------------------------------|--------------------------------------------|------------|
| 1   | ConfigMaps y Secrets           | Gestion de configuracion sensible          | Basico     |
| 2   | Security Context               | Hardening de contenedores (non-root, R/O)  | Intermedio |
| 3   | Network Policies               | Microsegmentacion de red                   | Intermedio |
| 4   | RBAC y ServiceAccounts         | Control de acceso (minimo privilegio)      | Avanzado   |

---

## Lab 1: ConfigMaps y Secrets

| Propiedad     | Valor                            |
|---------------|----------------------------------|
| **Recursos**  | ConfigMap + Secret + Pod + Service |
| **Imagen**    | `nginx:1.25-alpine`              |
| **Puerto**    | `30100` (NodePort)               |

Aprende a separar la configuracion del codigo:
- **ConfigMap**: variables de entorno y archivos de configuracion
- **Secret**: credenciales codificadas en base64
- Inyeccion via `env`, `envFrom` y `volumeMount`
- Por que base64 no es encriptacion

```bash
cd Unidad-4/lab1/
kubectl apply -f lab1-configmap.yaml
kubectl apply -f lab1-secret.yaml
kubectl apply -f lab1-pod-config.yaml
kubectl apply -f lab1-service.yaml

# Verificar variables inyectadas
kubectl exec webapp-lab1 -- env | grep -E "APP_|DB_|API_"

# Verificar archivo montado
kubectl exec webapp-lab1 -- cat /etc/app/app.conf

# Acceder (Minikube)
minikube service webapp-lab1-svc
```

### Limpieza Lab 1:
```bash
kubectl delete -f lab1-service.yaml -f lab1-pod-config.yaml -f lab1-secret.yaml -f lab1-configmap.yaml
```

---

## Lab 2: Security Context

| Propiedad     | Pod Inseguro     | Pod Seguro              |
|---------------|------------------|-------------------------|
| **Usuario**   | root (UID 0)     | non-root (UID 1000)     |
| **Filesystem** | Read-write      | Read-only               |
| **Capabilities** | Todas         | Ninguna (drop ALL)      |

Compara un Pod vulnerable contra uno hardened:
- `runAsNonRoot`, `runAsUser`, `readOnlyRootFilesystem`
- `allowPrivilegeEscalation: false`
- `capabilities.drop: [ALL]`
- Volumenes `emptyDir` para directorios de escritura

```bash
cd Unidad-4/lab2/
kubectl apply -f lab2-pod-inseguro.yaml
kubectl apply -f lab2-pod-seguro.yaml

# Comparar usuarios
kubectl exec pod-inseguro -- id    # uid=0(root)
kubectl exec pod-seguro -- id      # uid=1000

# Probar escritura
kubectl exec pod-inseguro -- touch /usr/bin/malware   # Funciona
kubectl exec pod-seguro -- touch /usr/bin/malware      # Read-only file system
```

### Limpieza Lab 2:
```bash
kubectl delete -f lab2-pod-inseguro.yaml -f lab2-pod-seguro.yaml
```

---

## Lab 3: Network Policies

| Propiedad     | Valor                                |
|---------------|--------------------------------------|
| **Namespaces** | `frontend`, `backend`, `default`    |
| **CNI**       | Calico (requerido)                   |
| **Politicas** | deny-all + allow-frontend            |

Implementa microsegmentacion:
- Deny-all: bloquear todo trafico al backend
- Allow-frontend: permitir solo trafico desde frontend
- Probar aislamiento entre namespaces

```bash
cd Unidad-4/lab3/
kubectl apply -f lab3-namespace.yaml
kubectl apply -f lab3-apps.yaml

# Sin politicas: todos se comunican
kubectl exec test-client -- curl -s --max-time 5 api-backend-svc.backend.svc.cluster.local

# Aplicar deny-all
kubectl apply -f lab3-netpol-deny-all.yaml

# Backend bloqueado para todos
kubectl exec test-client -- curl -s --max-time 5 api-backend-svc.backend.svc.cluster.local
# (timeout)

# Permitir solo frontend
kubectl apply -f lab3-netpol-allow-frontend.yaml

# Frontend → backend: PERMITIDO
kubectl exec -n frontend web-frontend -- curl -s --max-time 5 api-backend-svc.backend.svc.cluster.local

# Default → backend: BLOQUEADO
kubectl exec test-client -- curl -s --max-time 5 api-backend-svc.backend.svc.cluster.local
```

### Limpieza Lab 3:
```bash
kubectl delete -f lab3-netpol-allow-frontend.yaml -f lab3-netpol-deny-all.yaml -f lab3-apps.yaml -f lab3-namespace.yaml
```

---

## Lab 4: RBAC y ServiceAccounts

| Propiedad          | dev-reader      | dev-deployer           |
|--------------------|-----------------|------------------------|
| **Pods**           | get, list       | get, list, create, delete |
| **Secrets**        | NO              | NO                     |
| **Otro namespace** | NO              | NO                     |

Implementa control de acceso:
- ServiceAccounts con diferentes niveles de permisos
- Roles que definen acciones permitidas
- RoleBindings que conectan identidad con permisos
- Principio de minimo privilegio

```bash
cd Unidad-4/lab4/
kubectl apply -f lab4-namespace.yaml
kubectl apply -f lab4-serviceaccount.yaml
kubectl apply -f lab4-roles.yaml
kubectl apply -f lab4-rolebindings.yaml
kubectl apply -f lab4-test-pods.yaml

# Reader: puede listar pero NO crear
kubectl exec -n lab-rbac pod-reader-test -- kubectl get pods -n lab-rbac        # OK
kubectl exec -n lab-rbac pod-reader-test -- kubectl run test --image=nginx -n lab-rbac  # Forbidden

# Deployer: puede listar Y crear
kubectl exec -n lab-rbac pod-deployer-test -- kubectl get pods -n lab-rbac      # OK
kubectl exec -n lab-rbac pod-deployer-test -- kubectl run test --image=nginx -n lab-rbac # OK

# Ninguno puede ver Secrets
kubectl exec -n lab-rbac pod-reader-test -- kubectl get secrets -n lab-rbac     # Forbidden
kubectl exec -n lab-rbac pod-deployer-test -- kubectl get secrets -n lab-rbac   # Forbidden
```

### Limpieza Lab 4:
```bash
kubectl delete -f lab4-test-pods.yaml -f lab4-rolebindings.yaml -f lab4-roles.yaml -f lab4-serviceaccount.yaml -f lab4-namespace.yaml
```

---

## Resumen de Puertos

| Lab | Servicio        | Puerto NodePort | Puerto Interno |
|-----|-----------------|-----------------|----------------|
| 1   | webapp-lab1-svc | 30100           | 80             |

> Los Labs 2, 3 y 4 no requieren puertos externos — se acceden via `kubectl exec` o `port-forward`.

---

## Estructura de Archivos

```
Unidad-4/
├── lab1/                              # ConfigMaps y Secrets
│   ├── lab1-configmap.yaml            #   ConfigMap con config no sensible
│   ├── lab1-secret.yaml               #   Secret con credenciales (base64)
│   ├── lab1-pod-config.yaml           #   Pod que consume ConfigMap + Secret
│   ├── lab1-service.yaml              #   Service NodePort
│   └── README.md
├── lab2/                              # Security Context
│   ├── lab2-pod-inseguro.yaml         #   Pod sin seguridad (root)
│   ├── lab2-pod-seguro.yaml           #   Pod hardened (non-root, R/O)
│   └── README.md
├── lab3/                              # Network Policies
│   ├── lab3-namespace.yaml            #   Namespaces: frontend, backend
│   ├── lab3-apps.yaml                 #   Pods + Services + test-client
│   ├── lab3-netpol-deny-all.yaml      #   Deny-all ingress en backend
│   ├── lab3-netpol-allow-frontend.yaml #  Permitir solo frontend → backend
│   └── README.md
├── lab4/                              # RBAC
│   ├── lab4-namespace.yaml            #   Namespace: lab-rbac
│   ├── lab4-serviceaccount.yaml       #   ServiceAccounts: reader, deployer
│   ├── lab4-roles.yaml                #   Roles con permisos diferentes
│   ├── lab4-rolebindings.yaml         #   RoleBindings
│   ├── lab4-test-pods.yaml            #   Pods con kubectl para probar
│   └── README.md
└── README.md
```

---

## Limpieza Total

```bash
# Lab 1
kubectl delete -f Unidad-4/lab1/lab1-service.yaml -f Unidad-4/lab1/lab1-pod-config.yaml \
  -f Unidad-4/lab1/lab1-secret.yaml -f Unidad-4/lab1/lab1-configmap.yaml 2>/dev/null

# Lab 2
kubectl delete -f Unidad-4/lab2/lab2-pod-inseguro.yaml -f Unidad-4/lab2/lab2-pod-seguro.yaml 2>/dev/null

# Lab 3
kubectl delete -f Unidad-4/lab3/lab3-netpol-allow-frontend.yaml -f Unidad-4/lab3/lab3-netpol-deny-all.yaml \
  -f Unidad-4/lab3/lab3-apps.yaml -f Unidad-4/lab3/lab3-namespace.yaml 2>/dev/null

# Lab 4
kubectl delete -f Unidad-4/lab4/lab4-test-pods.yaml -f Unidad-4/lab4/lab4-rolebindings.yaml \
  -f Unidad-4/lab4/lab4-roles.yaml -f Unidad-4/lab4/lab4-serviceaccount.yaml \
  -f Unidad-4/lab4/lab4-namespace.yaml 2>/dev/null

# Verificar que todo se elimino
kubectl get pods,svc,configmap,secret,networkpolicy -A | grep -E "lab|frontend|backend|rbac"
```

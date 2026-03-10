# Lab 4: RBAC — Control de Acceso Basado en Roles

Implementa **RBAC** (Role-Based Access Control) en Kubernetes para controlar **quien** puede hacer **que** en el cluster. Crea ServiceAccounts con diferentes niveles de permisos y demuestra el principio de **minimo privilegio**.

```
 ┌─────────────────────────────────────────────────────────┐
 │                    RBAC en Kubernetes                    │
 │                                                         │
 │  QUIEN            QUE puede hacer      DONDE            │
 │  ─────            ───────────────      ─────            │
 │  ServiceAccount → Role             → Namespace          │
 │       │              │                                  │
 │       └── RoleBinding ┘                                 │
 │                                                         │
 │  dev-reader ──► pod-reader ──► lab-rbac                 │
 │    (solo leer)   (get, list)                            │
 │                                                         │
 │  dev-deployer ─► pod-deployer ─► lab-rbac               │
 │    (leer+crear)  (get, list,                            │
 │                   create, delete)                        │
 └─────────────────────────────────────────────────────────┘
```

| Propiedad          | Valor                                       |
|--------------------|---------------------------------------------|
| **Recursos**       | Namespace + ServiceAccounts + Roles + RoleBindings + Pods |
| **Namespace**      | `lab-rbac`                                  |
| **ServiceAccounts** | `dev-reader`, `dev-deployer`               |
| **Imagen**         | `bitnami/kubectl`, `nginx:1.25-alpine`      |
| **RAM total**      | ~160Mi (3 Pods con limites bajos)           |

---

## Conceptos Clave

| Concepto              | Descripcion                                                       |
|-----------------------|-------------------------------------------------------------------|
| **RBAC**             | Sistema de control de acceso basado en roles de Kubernetes         |
| **ServiceAccount**   | Identidad para Pods — determina sus permisos en la API             |
| **Role**             | Define QUE acciones estan permitidas sobre QUE recursos            |
| **RoleBinding**      | Conecta un ServiceAccount (QUIEN) con un Role (QUE puede hacer)   |
| **ClusterRole**      | Como un Role pero aplica a TODO el cluster (no solo un namespace)  |
| **ClusterRoleBinding** | Vincula un ClusterRole a nivel de cluster                       |
| **Verbs**            | Acciones: get, list, watch, create, update, patch, delete          |
| **apiGroups**        | Grupo de la API: "" (core), "apps", "rbac.authorization.k8s.io"   |

### Role vs ClusterRole

| Caracteristica   | Role                            | ClusterRole                     |
|------------------|---------------------------------|---------------------------------|
| **Alcance**      | Un solo namespace               | Todo el cluster                 |
| **Uso tipico**   | Permisos para un equipo/app     | Permisos globales (admin, monitoring) |
| **Vinculado con** | RoleBinding                    | ClusterRoleBinding              |

### Verbs (acciones) disponibles

| Verb       | Descripcion                              | Equivalente REST |
|------------|------------------------------------------|------------------|
| `get`      | Ver un recurso especifico por nombre     | GET /resource/name |
| `list`     | Listar todos los recursos de un tipo     | GET /resources    |
| `watch`    | Observar cambios en tiempo real          | GET /resources?watch=true |
| `create`   | Crear un nuevo recurso                   | POST /resources   |
| `update`   | Reemplazar un recurso completo           | PUT /resource/name |
| `patch`    | Modificar parcialmente un recurso        | PATCH /resource/name |
| `delete`   | Eliminar un recurso                      | DELETE /resource/name |

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
cd Unidad-4/lab4/
```

### 2. Crear el namespace

```bash
kubectl apply -f lab4-namespace.yaml
```

Salida esperada:
```
namespace/lab-rbac created
```

### 3. Crear los ServiceAccounts

```bash
kubectl apply -f lab4-serviceaccount.yaml
```

Salida esperada:
```
serviceaccount/dev-reader created
serviceaccount/dev-deployer created
```

### 4. Verificar los ServiceAccounts

```bash
kubectl get sa -n lab-rbac
```

Salida esperada:
```
NAME           SECRETS   AGE
default        0         30s
dev-deployer   0         5s
dev-reader     0         5s
```

> Cada namespace tiene un ServiceAccount `default`. Los Pods que no especifican uno usan este.

### 5. Crear los Roles

```bash
kubectl apply -f lab4-roles.yaml
```

Salida esperada:
```
role.rbac.authorization.k8s.io/pod-reader created
role.rbac.authorization.k8s.io/pod-deployer created
```

### 6. Ver los permisos de cada Role

```bash
# Ver permisos del Role reader
kubectl describe role pod-reader -n lab-rbac

# Ver permisos del Role deployer
kubectl describe role pod-deployer -n lab-rbac
```

Salida esperada para `pod-reader`:
```
Name:         pod-reader
PolicyRule:
  Resources         Verbs
  ---------         -----
  pods              [get list watch]
  pods/log          [get list watch]
  services          [get list watch]
  deployments.apps  [get list watch]
```

Salida esperada para `pod-deployer`:
```
Name:         pod-deployer
PolicyRule:
  Resources         Verbs
  ---------         -----
  pods              [get list watch create delete]
  pods/log          [get list watch create delete]
  services          [get list watch create delete]
  deployments.apps  [get list watch create update delete]
  configmaps        [get list]
```

> Notar que `pod-deployer` NO tiene acceso a Secrets — principio de minimo privilegio.

### 7. Crear los RoleBindings

```bash
kubectl apply -f lab4-rolebindings.yaml
```

Salida esperada:
```
rolebinding.rbac.authorization.k8s.io/reader-binding created
rolebinding.rbac.authorization.k8s.io/deployer-binding created
```

### 8. Verificar los RoleBindings

```bash
kubectl get rolebindings -n lab-rbac
kubectl describe rolebinding reader-binding -n lab-rbac
```

### 9. Desplegar los Pods de prueba

```bash
kubectl apply -f lab4-test-pods.yaml
```

Salida esperada:
```
pod/pod-reader-test created
pod/pod-deployer-test created
pod/app-ejemplo created
```

### 10. Esperar a que los Pods esten listos

```bash
kubectl get pods -n lab-rbac -w
```

> Esperar hasta que los 3 Pods esten en STATUS `Running`. Presionar Ctrl+C para salir.

---

## Probar los permisos RBAC

### 11. Probar permisos del dev-reader (solo lectura)

```bash
# PUEDE listar Pods (tiene permiso "list")
kubectl exec -n lab-rbac pod-reader-test -- kubectl get pods -n lab-rbac
# Salida: lista de pods (app-ejemplo, pod-reader-test, pod-deployer-test)

# PUEDE ver detalles de un Pod (tiene permiso "get")
kubectl exec -n lab-rbac pod-reader-test -- kubectl describe pod app-ejemplo -n lab-rbac

# NO PUEDE crear un Pod (no tiene permiso "create")
kubectl exec -n lab-rbac pod-reader-test -- kubectl run test-pod --image=nginx -n lab-rbac
# Salida: Error from server (Forbidden): pods is forbidden: User "system:serviceaccount:lab-rbac:dev-reader"
#         cannot create resource "pods" in API group "" in the namespace "lab-rbac"

# NO PUEDE eliminar un Pod (no tiene permiso "delete")
kubectl exec -n lab-rbac pod-reader-test -- kubectl delete pod app-ejemplo -n lab-rbac
# Salida: Error from server (Forbidden): ...cannot delete resource "pods"...

# NO PUEDE ver Secrets (no tiene permiso)
kubectl exec -n lab-rbac pod-reader-test -- kubectl get secrets -n lab-rbac
# Salida: Error from server (Forbidden): ...cannot list resource "secrets"...
```

> El dev-reader solo puede observar. No puede modificar ni eliminar nada.

### 12. Probar permisos del dev-deployer (lectura + escritura)

```bash
# PUEDE listar Pods
kubectl exec -n lab-rbac pod-deployer-test -- kubectl get pods -n lab-rbac
# Salida: lista de pods

# PUEDE crear un nuevo Pod
kubectl exec -n lab-rbac pod-deployer-test -- kubectl run nuevo-pod --image=nginx:1.25-alpine -n lab-rbac
# Salida: pod/nuevo-pod created

# Verificar que el Pod fue creado
kubectl exec -n lab-rbac pod-deployer-test -- kubectl get pods -n lab-rbac
# Salida: incluye "nuevo-pod"

# PUEDE eliminar el Pod que creo
kubectl exec -n lab-rbac pod-deployer-test -- kubectl delete pod nuevo-pod -n lab-rbac
# Salida: pod "nuevo-pod" deleted

# PUEDE leer ConfigMaps (pero no crear)
kubectl exec -n lab-rbac pod-deployer-test -- kubectl get configmaps -n lab-rbac

# NO PUEDE ver Secrets (no tiene permiso — minimo privilegio)
kubectl exec -n lab-rbac pod-deployer-test -- kubectl get secrets -n lab-rbac
# Salida: Error from server (Forbidden): ...cannot list resource "secrets"...

# NO PUEDE acceder a otros namespaces
kubectl exec -n lab-rbac pod-deployer-test -- kubectl get pods -n kube-system
# Salida: Error from server (Forbidden): ...cannot list resource "pods" in the namespace "kube-system"
```

> El dev-deployer puede crear y eliminar recursos en su namespace, pero NO puede acceder a Secrets ni a otros namespaces.

### 13. Probar con kubectl auth can-i (desde fuera)

```bash
# Verificar permisos del dev-reader
kubectl auth can-i get pods -n lab-rbac --as=system:serviceaccount:lab-rbac:dev-reader
# Salida: yes

kubectl auth can-i create pods -n lab-rbac --as=system:serviceaccount:lab-rbac:dev-reader
# Salida: no

kubectl auth can-i delete pods -n lab-rbac --as=system:serviceaccount:lab-rbac:dev-reader
# Salida: no

kubectl auth can-i get secrets -n lab-rbac --as=system:serviceaccount:lab-rbac:dev-reader
# Salida: no

# Verificar permisos del dev-deployer
kubectl auth can-i create pods -n lab-rbac --as=system:serviceaccount:lab-rbac:dev-deployer
# Salida: yes

kubectl auth can-i delete pods -n lab-rbac --as=system:serviceaccount:lab-rbac:dev-deployer
# Salida: yes

kubectl auth can-i get secrets -n lab-rbac --as=system:serviceaccount:lab-rbac:dev-deployer
# Salida: no

# Verificar acceso fuera del namespace
kubectl auth can-i get pods -n default --as=system:serviceaccount:lab-rbac:dev-deployer
# Salida: no
```

> `kubectl auth can-i` es la forma rapida de verificar permisos sin tener que ejecutar el comando real.

---

## Resumen de permisos

```
 ┌───────────────────────────────────────────────────────┐
 │ Accion              │ dev-reader │ dev-deployer       │
 │─────────────────────│────────────│────────────────────│
 │ Listar Pods         │    SI      │       SI           │
 │ Ver logs            │    SI      │       SI           │
 │ Crear Pods          │    NO      │       SI           │
 │ Eliminar Pods       │    NO      │       SI           │
 │ Crear Deployments   │    NO      │       SI           │
 │ Leer ConfigMaps     │    NO      │       SI           │
 │ Leer Secrets        │    NO      │       NO           │
 │ Acceso otro NS      │    NO      │       NO           │
 └───────────────────────────────────────────────────────┘
```

---

## Estructura del Proyecto

```
lab4/
├── lab4-namespace.yaml        # Namespace: lab-rbac
├── lab4-serviceaccount.yaml   # ServiceAccounts: dev-reader, dev-deployer
├── lab4-roles.yaml            # Roles: pod-reader, pod-deployer
├── lab4-rolebindings.yaml     # RoleBindings que conectan SA con Roles
├── lab4-test-pods.yaml        # Pods con kubectl para probar permisos
└── README.md
```

---

## Comandos Utiles

```bash
# Ver todos los Roles en un namespace
kubectl get roles -n lab-rbac

# Ver todos los RoleBindings
kubectl get rolebindings -n lab-rbac

# Ver ClusterRoles del sistema
kubectl get clusterroles | head -20

# Verificar permisos de un ServiceAccount
kubectl auth can-i <verbo> <recurso> -n <namespace> \
  --as=system:serviceaccount:<namespace>:<nombre-sa>

# Ver todos los permisos de un ServiceAccount
kubectl auth can-i --list -n lab-rbac \
  --as=system:serviceaccount:lab-rbac:dev-reader

# Ver que ServiceAccount usa un Pod
kubectl get pod <nombre> -n lab-rbac -o jsonpath='{.spec.serviceAccountName}'
```

---

## Limpieza

```bash
# Eliminar Pods de prueba
kubectl delete -f lab4-test-pods.yaml

# Eliminar RoleBindings
kubectl delete -f lab4-rolebindings.yaml

# Eliminar Roles
kubectl delete -f lab4-roles.yaml

# Eliminar ServiceAccounts
kubectl delete -f lab4-serviceaccount.yaml

# Eliminar namespace (elimina todo lo que contiene)
kubectl delete -f lab4-namespace.yaml

# Verificar
kubectl get namespace lab-rbac 2>/dev/null || echo "Namespace eliminado"
```

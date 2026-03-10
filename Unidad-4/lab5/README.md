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

---

## Parte 2: Escenario Seguro (Blue Team)

### Paso 1 — Limpiar el escenario vulnerable

```bash
kubectl delete -f vulnerable-network.yaml
```

### Paso 2 — Desplegar con NetworkPolicies + autenticacion

```bash
kubectl apply -f secure-network.yaml

# Esperar a que los pods esten listos
kubectl get pods -n lab5-network -w
kubectl wait --for=condition=Ready pod/redis-secure -n lab5-network --timeout=120s
kubectl wait --for=condition=Ready pod/webapp-secure -n lab5-network --timeout=120s
kubectl wait --for=condition=Ready pod/attacker-blocked -n lab5-network --timeout=120s
```

### Paso 3 — Verificar que la webapp SI puede conectar

```bash
# Ver logs de la webapp (debe estar escribiendo en Redis exitosamente)
kubectl logs webapp-secure -n lab5-network
```

### Paso 4 — Verificar que el atacante NO puede conectar

```bash
# Entrar al pod atacante
kubectl exec -it attacker-blocked -n lab5-network -- sh

# Intentar conectar a Redis (bloqueado por NetworkPolicy)
redis-cli -h redis-secure.lab5-network.svc.cluster.local -p 6379 PING
# Resultado: timeout / connection refused

# Intentar DNS (tambien bloqueado por deny-all egress)
nslookup redis-secure.lab5-network.svc.cluster.local
# Resultado: timeout

exit
```

### Paso 5 — Verificar las NetworkPolicies aplicadas

```bash
# Ver las politicas creadas
kubectl get networkpolicies -n lab5-network

# Ver detalle de cada politica
kubectl describe networkpolicy default-deny-all -n lab5-network
kubectl describe networkpolicy allow-webapp-to-redis -n lab5-network
kubectl describe networkpolicy allow-webapp-egress -n lab5-network
```

---

## Diferencias Clave

| Aspecto              | Vulnerable                | Seguro                           |
|----------------------|---------------------------|----------------------------------|
| NetworkPolicy        | Ninguna                   | deny-all + allow selectivo       |
| Redis autenticacion  | Sin password              | `requirepass` configurado        |
| DNS discovery        | Libre                     | Solo permitido para webapp       |
| Pod-to-Pod           | Cualquiera a cualquiera   | Solo webapp -> redis             |
| Egress               | Sin restriccion           | Solo redis:6379 + DNS            |

---

## Nota sobre minikube

Las NetworkPolicies **solo funcionan** si minikube fue iniciado con un CNI compatible:

```bash
# Correcto (soporta NetworkPolicies):
minikube start --cni=calico

# Incorrecto (NO soporta NetworkPolicies):
minikube start              # usa bridge por defecto
minikube start --cni=kindnet
```

Si las NetworkPolicies no bloquean el trafico, verifica que Calico este corriendo:

```bash
kubectl get pods -n kube-system -l k8s-app=calico-node
```

---

## Limpieza

```bash
kubectl delete namespace lab5-network
```

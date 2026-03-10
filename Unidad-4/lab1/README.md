# Lab 1: ConfigMaps y Secrets — Gestion de Configuracion

Aprende a separar la **configuracion** del codigo usando **ConfigMaps** (datos no sensibles) y **Secrets** (datos sensibles). Estas son las dos formas nativas de Kubernetes para inyectar configuracion en los contenedores.

```
 ┌──────────────────┐     ┌──────────────────┐
 │    ConfigMap      │     │     Secret       │
 │   app-config     │     │   app-secret     │
 │                  │     │                  │
 │ APP_ENV=prod     │     │ DB_USER=admin    │
 │ APP_COLOR=#2563  │     │ DB_PASSWORD=***  │
 │ app.conf (file)  │     │ API_KEY=***      │
 └────────┬─────────┘     └────────┬─────────┘
          │  env + volumen          │  env
          └──────────┬──────────────┘
                     ▼
          ┌──────────────────┐
          │   Pod: webapp    │
          │  nginx:1.25      │
          │                  │
          │  env: APP_ENV    │
          │  env: DB_USER    │
          │  /etc/app/       │
          │    └─ app.conf   │
          └──────────────────┘
```

| Propiedad          | Valor                          |
|--------------------|--------------------------------|
| **Recursos**       | ConfigMap + Secret + Pod + Service |
| **Imagen**         | `nginx:1.25-alpine` (~40 MB)   |
| **Puerto externo** | `30100` (NodePort)             |
| **Puerto interno** | `80`                           |
| **Namespace**      | `default`                      |
| **RAM**            | 32Mi (request) / 64Mi (limit)  |
| **CPU**            | 50m (request) / 100m (limit)   |

---

## Conceptos Clave

| Concepto         | Descripcion                                                          |
|------------------|----------------------------------------------------------------------|
| **ConfigMap**    | Almacena configuracion NO sensible como pares clave:valor            |
| **Secret**       | Almacena datos sensibles (credenciales, tokens) codificados en base64 |
| **base64**       | Codificacion, NO encriptacion. Cualquiera puede decodificarlo        |
| **env**          | Inyecta un valor como variable de entorno dentro del contenedor       |
| **volumeMount**  | Monta un ConfigMap/Secret como archivo dentro del contenedor          |

### ConfigMap vs Secret

| Caracteristica   | ConfigMap                          | Secret                                 |
|------------------|------------------------------------|----------------------------------------|
| **Datos**        | No sensibles (URLs, flags, config) | Sensibles (passwords, tokens, claves)  |
| **Almacenamiento** | Texto plano en etcd              | Base64 en etcd (no encriptado por defecto) |
| **Visibilidad**  | `kubectl describe` muestra valores | `kubectl describe` oculta valores       |
| **Uso tipico**   | Archivos .conf, variables de app   | Credenciales de DB, API keys, TLS certs |

### Formas de inyectar configuracion en un Pod

| Metodo                  | Descripcion                                        | Cuando usar                         |
|-------------------------|----------------------------------------------------|-------------------------------------|
| **env + valueFrom**     | Variable individual desde un ConfigMap/Secret       | Pocas variables, control granular   |
| **envFrom**             | TODAS las claves como variables de entorno          | Importar todo el ConfigMap/Secret   |
| **volumeMount**         | Monta como archivos dentro del contenedor           | Archivos de configuracion (.conf)   |

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
cd Unidad-4/lab1/
```

### 2. Crear el ConfigMap

```bash
kubectl apply -f lab1-configmap.yaml
```

Salida esperada:
```
configmap/app-config created
```

### 3. Verificar el ConfigMap

```bash
# Ver el ConfigMap
kubectl get configmap app-config

# Ver los detalles (muestra TODOS los valores)
kubectl describe configmap app-config
```

Salida esperada de `describe`:
```
Name:         app-config
Data
====
APP_COLOR:
----
#2563EB
APP_ENV:
----
production
APP_TITLE:
----
Workshop K8s - Lab ConfigMap
LOG_LEVEL:
----
info
app.conf:
----
# Configuracion de la aplicacion
server.port=80
...
```

> Notar que `kubectl describe` muestra los valores en texto plano para ConfigMaps.

### 4. Crear el Secret

```bash
kubectl apply -f lab1-secret.yaml
```

Salida esperada:
```
secret/app-secret created
```

### 5. Verificar el Secret

```bash
# Ver el Secret (no muestra los valores)
kubectl get secret app-secret

# Ver detalles (muestra el tamano en bytes, NO los valores)
kubectl describe secret app-secret
```

Salida esperada de `describe`:
```
Name:         app-secret
Type:         Opaque
Data
====
API_KEY:      16 bytes
DB_PASSWORD:  12 bytes
DB_USER:      5 bytes
```

> A diferencia del ConfigMap, `kubectl describe` NO muestra los valores del Secret — solo el tamano.

### 6. Decodificar un Secret manualmente

```bash
# Ver el valor codificado en base64
kubectl get secret app-secret -o jsonpath='{.data.DB_PASSWORD}'
# Salida: UzNjdXIxdHlLOHMh

# Decodificar el valor
kubectl get secret app-secret -o jsonpath='{.data.DB_PASSWORD}' | base64 -d
# Salida: S3cur1tyK8s!

# Decodificar todos los valores
kubectl get secret app-secret -o jsonpath='{.data.DB_USER}' | base64 -d && echo
kubectl get secret app-secret -o jsonpath='{.data.API_KEY}' | base64 -d && echo
```

> **IMPORTANTE**: base64 NO es encriptacion. Cualquier usuario con acceso al cluster puede decodificar los Secrets. En produccion se usa encriptacion at-rest o herramientas como HashiCorp Vault.

### 7. Crear el Pod que consume ConfigMap y Secret

```bash
kubectl apply -f lab1-pod-config.yaml
```

Salida esperada:
```
pod/webapp-lab1 created
```

### 8. Verificar que el Pod esta corriendo

```bash
kubectl get pods webapp-lab1
```

Salida esperada:
```
NAME          READY   STATUS    RESTARTS   AGE
webapp-lab1   1/1     Running   0          10s
```

> Si STATUS muestra `ContainerCreating`, esperar unos segundos y repetir.

### 9. Verificar variables de entorno inyectadas

```bash
# Ver TODAS las variables de entorno del contenedor
kubectl exec webapp-lab1 -- env | sort

# Filtrar solo las variables del lab
kubectl exec webapp-lab1 -- env | grep -E "APP_|DB_|API_|LOG_"
```

Salida esperada:
```
API_KEY=abcdef1234567890
APP_COLOR=#2563EB
APP_ENV=production
APP_TITLE=Workshop K8s - Lab ConfigMap
DB_PASSWORD=S3cur1tyK8s!
DB_USER=admin
LOG_LEVEL=info
```

> Los valores del Secret aparecen decodificados automaticamente dentro del contenedor. Kubernetes se encarga de decodificar el base64.

### 10. Verificar archivo de configuracion montado

```bash
# Ver los archivos montados en /etc/app/
kubectl exec webapp-lab1 -- ls -la /etc/app/

# Ver el contenido del archivo de configuracion
kubectl exec webapp-lab1 -- cat /etc/app/app.conf
```

Salida esperada:
```
# Configuracion de la aplicacion
server.port=80
server.host=0.0.0.0
app.name=Workshop Kubernetes
app.version=1.0
features.debug=false
features.metrics=true
```

> Cada clave del ConfigMap se convierte en un archivo separado dentro de `/etc/app/`.

### 11. Crear el Service y acceder al Pod

```bash
kubectl apply -f lab1-service.yaml
kubectl get svc webapp-lab1-svc
```

**Acceder (Minikube):**

```bash
# Opcion A — minikube service (recomendada):
minikube service webapp-lab1-svc

# Opcion B — port-forward:
kubectl port-forward svc/webapp-lab1-svc 8080:80
curl http://localhost:8080
```

Se mostrara la pagina por defecto de Nginx: **"Welcome to nginx!"**

---

## Experimento: Actualizar ConfigMap en caliente

Los ConfigMaps montados como volumen se actualizan automaticamente (con un delay de ~30-60 segundos). Las variables de entorno NO se actualizan hasta que el Pod se reinicie.

### 12. Modificar el ConfigMap

```bash
# Editar el ConfigMap directamente
kubectl edit configmap app-config
# Cambiar LOG_LEVEL de "info" a "debug" y guardar

# Esperar ~30 segundos y verificar el archivo montado
kubectl exec webapp-lab1 -- cat /etc/app/LOG_LEVEL
# Salida: debug (actualizado automaticamente)

# Verificar la variable de entorno (NO se actualiza)
kubectl exec webapp-lab1 -- env | grep LOG_LEVEL
# Salida: LOG_LEVEL=info (sigue con el valor original)
```

> **Conclusion**: Los volumenes se actualizan en caliente. Las variables de entorno requieren reiniciar el Pod.

---

## Estructura del Proyecto

```
lab1/
├── lab1-configmap.yaml    # ConfigMap: configuracion no sensible
├── lab1-secret.yaml       # Secret: credenciales sensibles (base64)
├── lab1-pod-config.yaml   # Pod que consume ConfigMap + Secret
├── lab1-service.yaml      # Service NodePort para acceso externo
└── README.md
```

---

## Comandos Utiles

```bash
# Crear un ConfigMap desde la linea de comandos
kubectl create configmap mi-config --from-literal=key1=valor1 --from-literal=key2=valor2

# Crear un ConfigMap desde un archivo
kubectl create configmap mi-config --from-file=config.properties

# Crear un Secret desde la linea de comandos
kubectl create secret generic mi-secret --from-literal=password=mi-clave

# Ver un Secret en formato YAML (muestra base64)
kubectl get secret app-secret -o yaml

# Codificar un valor en base64
echo -n "mi-password" | base64

# Decodificar un valor base64
echo "bWktcGFzc3dvcmQ=" | base64 -d
```

---

## Limpieza

```bash
# Eliminar todos los recursos del lab
kubectl delete -f lab1-service.yaml
kubectl delete -f lab1-pod-config.yaml
kubectl delete -f lab1-secret.yaml
kubectl delete -f lab1-configmap.yaml

# Verificar que se eliminaron
kubectl get pods,svc,configmap,secret
```

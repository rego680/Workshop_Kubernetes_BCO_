# Lab 2: DockerHub - Build, Tag & Push

Practicar el flujo completo de publicar una imagen Docker en **DockerHub**: crear cuenta, login, build, tag, push y pull.

```
 Dockerfile ──► docker build ──► docker tag ──► docker push ──► DockerHub
                                                                    │
 docker run  ◄── docker pull ◄──────────────────────────────────────┘
```

| Propiedad        | Valor                                  |
|------------------|----------------------------------------|
| **Imagen base**  | `python:3.12-slim`                     |
| **Puerto**       | `5000`                                 |
| **Framework**    | Flask 3.0.0                            |
| **Seguridad**    | Usuario no-root (`appuser`)            |
| **Health check** | `GET /health`                          |
| **Tamano aprox.**| ~150 MB (comprimido ~50-60 MB en Hub)  |

---

## Requisitos Previos

- **Docker** instalado (version 20+)
- **Cuenta en DockerHub** (se crea en el paso 1)
- Puerto **5000** libre

```bash
docker --version
```

---

## Despliegue Paso a Paso

### Paso 1: Crear cuenta en DockerHub

1. Ir a [https://hub.docker.com](https://hub.docker.com)
2. Click en **"Sign Up"**
3. Completar:
   - **Docker ID**: tu-nombre-usuario (sera tu namespace)
   - **Email**: tu email
   - **Password**: minimo 9 caracteres
4. Verificar email (revisar bandeja de entrada)
5. Elegir plan **Personal** (gratuito)
   - Repos publicos ilimitados + 1 privado
   - Sin limite de pulls autenticado

### Paso 2: Crear repositorio en DockerHub (web)

1. En DockerHub click en **"Create Repository"**
2. **Repository Name**: `flask-hub`
3. **Description**: "Lab 2 - Unidad 2 Contenedores"
4. **Visibility**: Public
5. Click **"Create"**

Tu repo sera: `TU_DOCKER_ID/flask-hub`

### Paso 3: Login desde la terminal

```bash
# Opcion A: Login interactivo (pide password)
docker login -u TU_DOCKER_ID

# Opcion B: Login con Access Token (mas seguro)
# 1. Ir a hub.docker.com > Account Settings > Security
# 2. Click "New Access Token"
# 3. Permisos: "Read, Write, Delete"
# 4. Copiar el token y usarlo como password:
echo 'dckr_pat_TU_TOKEN' | docker login -u TU_DOCKER_ID --password-stdin

# Verificar login exitoso
docker info | grep Username
```

### Paso 4: Ir al directorio del lab

```bash
cd Unidad-2/lab2/
```

### Paso 5: Construir la imagen

```bash
docker build -t flask-hub:1.0.0 .
```

Verificar que se creo:
```bash
docker images | grep flask-hub
```

### Paso 6: Probar localmente antes de subir

```bash
# Ejecutar
docker run -d --name flask-hub-test -p 5000:5000 flask-hub:1.0.0

# Probar
curl http://localhost:5000
curl http://localhost:5000/health

# Abrir en navegador
# http://localhost:5000

# Limpiar test local
docker stop flask-hub-test && docker rm flask-hub-test
```

### Paso 7: Etiquetar (Tag) para DockerHub

```bash
# Formato: docker tag <imagen-local> <usuario>/<repo>:<tag>
docker tag flask-hub:1.0.0 TU_DOCKER_ID/flask-hub:1.0.0
docker tag flask-hub:1.0.0 TU_DOCKER_ID/flask-hub:latest

# Verificar los tags
docker images | grep flask-hub
```

Resultado esperado:
```
flask-hub                    1.0.0   abc123   X seconds ago   ~150MB
TU_DOCKER_ID/flask-hub       1.0.0   abc123   X seconds ago   ~150MB
TU_DOCKER_ID/flask-hub       latest  abc123   X seconds ago   ~150MB
```

> Notar que las 3 lineas comparten el mismo IMAGE ID (es la misma imagen con diferentes nombres).

### Paso 8: Push a DockerHub

```bash
# Subir version especifica
docker push TU_DOCKER_ID/flask-hub:1.0.0

# Subir latest
docker push TU_DOCKER_ID/flask-hub:latest
```

Salida esperada:
```
The push refers to repository [docker.io/TU_DOCKER_ID/flask-hub]
abc123: Pushed
def456: Pushed
1.0.0: digest: sha256:xxxx size: 1234
```

### Paso 9: Verificar en la web

Ir a: `https://hub.docker.com/r/TU_DOCKER_ID/flask-hub`

Verificar que aparecen:
- Tag: `1.0.0`
- Tag: `latest`
- Tamano comprimido (~50-60 MB)

### Paso 10: Simular pull desde otra maquina

```bash
# Eliminar imagenes locales
docker rmi TU_DOCKER_ID/flask-hub:1.0.0
docker rmi TU_DOCKER_ID/flask-hub:latest
docker rmi flask-hub:1.0.0

# Descargar desde DockerHub
docker pull TU_DOCKER_ID/flask-hub:1.0.0

# Ejecutar la imagen descargada
docker run -d --name flask-from-hub -p 5000:5000 TU_DOCKER_ID/flask-hub:1.0.0

# Probar
curl http://localhost:5000
# Funciona! La imagen se descargo de DockerHub
```

---

## Flujo Completo Resumido

```bash
# 1. Login
docker login -u TU_DOCKER_ID

# 2. Build
docker build -t flask-hub:1.0.0 .

# 3. Tag
docker tag flask-hub:1.0.0 TU_DOCKER_ID/flask-hub:1.0.0

# 4. Push
docker push TU_DOCKER_ID/flask-hub:1.0.0

# 5. Pull (en otra maquina)
docker pull TU_DOCKER_ID/flask-hub:1.0.0
```

---

## Endpoints

| Ruta         | Descripcion                              |
|--------------|------------------------------------------|
| `/`          | Pagina principal con info del contenedor |
| `/health`    | Health check JSON                        |
| `/api/info`  | Info del sistema (hostname, version)     |

---

## Estructura del Proyecto

```
lab2/
├── Dockerfile                          # python:3.12-slim, usuario no-root
├── Dockerfile.lab3-dockerhub-push.txt  # Referencia original del curso
├── lab3-guia-dockerhub.sh              # Guia paso a paso (script)
├── requirements.txt                    # flask==3.0.0
├── app.py                              # App Flask con 3 endpoints
└── README.md
```

---

## Limpieza

```bash
# Detener y eliminar contenedor
docker stop flask-from-hub && docker rm flask-from-hub

# Eliminar imagenes locales
docker rmi TU_DOCKER_ID/flask-hub:1.0.0
docker rmi TU_DOCKER_ID/flask-hub:latest
docker rmi flask-hub:1.0.0

# Cerrar sesion de DockerHub (opcional)
docker logout
```

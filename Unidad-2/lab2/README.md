# Lab 2: Push a DockerHub

## Descripcion

Practicar el flujo completo de publicacion de una imagen Docker a DockerHub:
login, build, tag, push y pull. Incluye uso de Access Tokens como alternativa
segura al password.

| Propiedad         | Valor                        |
|-------------------|------------------------------|
| **Imagen base**   | `python:3.12-slim`           |
| **Puerto**        | `5000:5000`                  |
| **Framework**     | Flask                        |
| **Registro**      | DockerHub (hub.docker.com)   |
| **Concepto**      | Tag + Push + Pull            |

---

## Archivos del Lab

| Archivo                              | Descripcion                           |
|--------------------------------------|---------------------------------------|
| `Dockerfile.lab3-dockerhub-push.txt` | Dockerfile Flask con usuario non-root |
| `lab3-guia-dockerhub.sh`            | Script guia paso a paso               |

> **Nota:** Se necesitan crear `app.py` y `requirements.txt` antes de construir.

---

## Ejecucion

### Paso 1 — Crear los archivos de la aplicacion

```bash
cd Unidad-2/lab2/

# Crear requirements.txt
cat > requirements.txt << 'EOF'
flask==3.0.0
EOF

# Crear app.py
cat > app.py << 'PYEOF'
from flask import Flask, jsonify
import socket, os

app = Flask(__name__)

@app.route("/")
def index():
    return f"<h1>Workshop K8s BCO - DockerHub Lab</h1><p>Host: {socket.gethostname()}</p>"

@app.route("/health")
def health():
    return jsonify({"status": "ok", "service": "flask-hub"})

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
PYEOF
```

### Paso 2 — Construir la imagen

```bash
# Copiar el Dockerfile
cp Dockerfile.lab3-dockerhub-push.txt Dockerfile

# Construir
docker build -t flask-hub:1.0.0 .
```

### Paso 3 — Probar localmente

```bash
docker run -d --name flask-hub-test -p 5000:5000 flask-hub:1.0.0

curl http://localhost:5000
curl http://localhost:5000/health

# Limpiar el test
docker stop flask-hub-test && docker rm flask-hub-test
```

### Paso 4 — Login en DockerHub

```bash
# Opcion A: Login interactivo
docker login -u TU_DOCKER_ID
# Ingresa tu password cuando lo pida

# Opcion B: Con Access Token (mas seguro)
# 1. Ir a hub.docker.com > Account Settings > Security
# 2. Click "New Access Token"
# 3. Permisos: Read, Write, Delete
# 4. Copiar el token
echo 'dckr_pat_TU_TOKEN' | docker login -u TU_DOCKER_ID --password-stdin

# Verificar login
docker info | grep Username
```

### Paso 5 — Tag para DockerHub

```bash
# Formato: docker tag <local> <usuario>/<repo>:<tag>
docker tag flask-hub:1.0.0 TU_DOCKER_ID/flask-hub:1.0.0
docker tag flask-hub:1.0.0 TU_DOCKER_ID/flask-hub:latest

# Verificar los tags
docker images | grep flask-hub
```

### Paso 6 — Push a DockerHub

```bash
docker push TU_DOCKER_ID/flask-hub:1.0.0
docker push TU_DOCKER_ID/flask-hub:latest

# Verificar en: https://hub.docker.com/r/TU_DOCKER_ID/flask-hub
```

### Paso 7 — Simular pull desde otra maquina

```bash
# Eliminar imagenes locales
docker rmi TU_DOCKER_ID/flask-hub:1.0.0
docker rmi TU_DOCKER_ID/flask-hub:latest
docker rmi flask-hub:1.0.0

# Descargar desde DockerHub
docker pull TU_DOCKER_ID/flask-hub:1.0.0

# Ejecutar la imagen descargada
docker run -d --name flask-from-hub -p 5000:5000 \
  TU_DOCKER_ID/flask-hub:1.0.0

curl http://localhost:5000
```

---

## Verificacion

| Prueba              | Comando                                    | Resultado esperado           |
|---------------------|--------------------------------------------|------------------------------|
| Build exitoso       | `docker images \| grep flask-hub`          | Imagen ~150 MB               |
| App funciona        | `curl http://localhost:5000`               | HTML del workshop            |
| Login OK            | `docker info \| grep Username`             | Tu Docker ID                 |
| Push exitoso        | Verificar en hub.docker.com                | Tags 1.0.0 y latest visibles|
| Pull funciona       | `docker pull TU_DOCKER_ID/flask-hub:1.0.0` | Descarga exitosa            |

---

## Conceptos Clave

- **docker tag**: Crea un alias de la imagen con el formato `usuario/repo:tag` necesario para push.
- **docker push**: Sube las capas de la imagen al registro (DockerHub).
- **docker pull**: Descarga la imagen desde el registro.
- **Access Token**: Alternativa mas segura que el password para autenticacion.
- **latest**: Tag por defecto si no se especifica version. Siempre usar tags explicitos en produccion.

---

## Limpieza

```bash
docker stop flask-from-hub && docker rm flask-from-hub
docker rmi TU_DOCKER_ID/flask-hub:1.0.0
docker rmi TU_DOCKER_ID/flask-hub:latest 2>/dev/null
docker rmi flask-hub:1.0.0 2>/dev/null
docker logout   # Opcional: cerrar sesion
rm -f app.py requirements.txt Dockerfile
```

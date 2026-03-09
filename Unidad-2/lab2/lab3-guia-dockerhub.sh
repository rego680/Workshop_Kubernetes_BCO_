#!/bin/bash
###############################################
# LAB 3 — GUÍA COMPLETA: DockerHub Cuenta + Push
# Archivo: guia-dockerhub.sh
#
# Este script documenta TODOS los pasos.
# Ejecutar línea por línea (no como script completo)
# ya que requiere interacción del usuario.
###############################################

echo "═══════════════════════════════════════════════"
echo "  Lab 3 - Crear Cuenta DockerHub + Push"
echo "  Archivo: Dockerfile.lab3-dockerhub-push"
echo "═══════════════════════════════════════════════"

# ══════════════════════════════════════════════════
# PASO 1: CREAR CUENTA EN DOCKERHUB
# ══════════════════════════════════════════════════
# 1. Abrir navegador: https://hub.docker.com
# 2. Click en "Sign Up" (esquina superior derecha)
# 3. Completar el formulario:
#    - Docker ID: tu-nombre-usuario (será tu namespace)
#    - Email: tu-email@ejemplo.com
#    - Password: (mínimo 9 caracteres)
# 4. Aceptar los términos de servicio
# 5. Verificar email (revisar bandeja de entrada)
# 6. Elegir plan: "Personal" (gratuito)
#    - Incluye: repos públicos ilimitados + 1 privado
#    - 200 pulls/6hrs desde IP anónima
#    - Sin límite de pulls autenticado

# ══════════════════════════════════════════════════
# PASO 2: CREAR REPOSITORIO EN DOCKERHUB (Web)
# ══════════════════════════════════════════════════
# 1. Ir a https://hub.docker.com → "Create Repository"
# 2. Repository Name: flask-hub
# 3. Description: "Lab 3 - Unidad 2 Contenedores"
# 4. Visibility: Public
# 5. Click "Create"
# → Tu repo será: TU_USER/flask-hub

# ══════════════════════════════════════════════════
# PASO 3: LOGIN DESDE TERMINAL
# ══════════════════════════════════════════════════

# Opción A: Login interactivo (pide password)
docker login -u TU_DOCKER_ID
# Ingresa tu password cuando lo pida

# Opción B: Login con Access Token (más seguro)
# 1. Ir a hub.docker.com > Account Settings > Security
# 2. Click "New Access Token"
# 3. Descripción: "Lab Unidad 2"
# 4. Permisos: "Read, Write, Delete"
# 5. Copiar el token generado
echo 'dckr_pat_TU_TOKEN_AQUI' | docker login -u TU_DOCKER_ID --password-stdin

# Verificar que el login fue exitoso
docker info | grep Username
# Debe mostrar: Username: TU_DOCKER_ID

# ══════════════════════════════════════════════════
# PASO 4: CONSTRUIR LA IMAGEN
# ══════════════════════════════════════════════════

cd ~/lab3-dockerhub-push

# Build usando el Dockerfile nombrado
docker build -t flask-hub:1.0.0 -f Dockerfile.lab3-dockerhub-push .

# Verificar que se creó
docker images | grep flask-hub
# flask-hub   1.0.0   xxxxxxxxxxxx   X seconds ago   ~150MB

# Probar localmente antes de subir
docker run -d --name flask-hub-test -p 5000:5000 flask-hub:1.0.0
curl http://localhost:5000
curl http://localhost:5000/health
# Limpiar test
docker stop flask-hub-test && docker rm flask-hub-test

# ══════════════════════════════════════════════════
# PASO 5: TAG PARA DOCKERHUB
# ══════════════════════════════════════════════════

# Formato: docker tag <local> <usuario>/<repo>:<tag>
docker tag flask-hub:1.0.0 TU_DOCKER_ID/flask-hub:1.0.0
docker tag flask-hub:1.0.0 TU_DOCKER_ID/flask-hub:latest

# Verificar los tags
docker images | grep flask-hub
# flask-hub                     1.0.0    abc123
# TU_DOCKER_ID/flask-hub        1.0.0    abc123  (mismo ID = misma imagen)
# TU_DOCKER_ID/flask-hub        latest   abc123

# ══════════════════════════════════════════════════
# PASO 6: PUSH A DOCKERHUB
# ══════════════════════════════════════════════════

docker push TU_DOCKER_ID/flask-hub:1.0.0
# Verás las capas subiendo una por una:
# 1.0.0: digest: sha256:xxxx size: 1234

docker push TU_DOCKER_ID/flask-hub:latest

# ══════════════════════════════════════════════════
# PASO 7: VERIFICAR EN LA WEB
# ══════════════════════════════════════════════════
# Ir a: https://hub.docker.com/r/TU_DOCKER_ID/flask-hub
# Verificar que aparecen:
#   - Tag: 1.0.0
#   - Tag: latest
#   - Tamaño comprimido (~50-60MB)

# ══════════════════════════════════════════════════
# PASO 8: PULL (simular descarga en otra máquina)
# ══════════════════════════════════════════════════

# Eliminar imagen local
docker rmi TU_DOCKER_ID/flask-hub:1.0.0
docker rmi TU_DOCKER_ID/flask-hub:latest
docker rmi flask-hub:1.0.0

# Descargar desde DockerHub
docker pull TU_DOCKER_ID/flask-hub:1.0.0

# Ejecutar la imagen descargada
docker run -d --name flask-from-hub -p 5000:5000 \
  TU_DOCKER_ID/flask-hub:1.0.0

curl http://localhost:5000
# ¡Funciona! La imagen se descargó de DockerHub

# ══════════════════════════════════════════════════
# LIMPIEZA
# ══════════════════════════════════════════════════
docker stop flask-from-hub && docker rm flask-from-hub
docker rmi TU_DOCKER_ID/flask-hub:1.0.0
docker logout  # Opcional: cerrar sesión

echo "════════════════════════════════════════════"
echo "  ✅ Lab 3 completado exitosamente"
echo "════════════════════════════════════════════"

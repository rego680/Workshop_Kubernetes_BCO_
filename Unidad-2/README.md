# Unidad 2: Creacion de Imagenes y Gestion en DockerHub

Dockerfile - Buenas Practicas - Build, Tag & Push - DockerHub - Escaneo de Vulnerabilidades

---

## Contenido Teorico

### 1. Que es una Imagen Docker

Paquete ligero, standalone y ejecutable que incluye todo lo necesario para correr una aplicacion: codigo fuente, runtime, librerias y configuracion.

| Concepto             | Descripcion                                                              |
|----------------------|--------------------------------------------------------------------------|
| **Capas (Layers)**   | Cada instruccion del Dockerfile crea una capa de solo lectura            |
| **Inmutable**        | Una vez construida no cambia; cambios van en capa de escritura temporal  |
| **Tags**             | Nombre + tag (ej: `nginx:1.25-alpine`). Default: `:latest`              |
| **Registry**         | Se almacenan en DockerHub, ECR, GCR, ACR, Harbor                        |

### 2. Instrucciones del Dockerfile

| Instruccion   | Funcion                                      | Ejemplo                           |
|---------------|----------------------------------------------|-----------------------------------|
| `FROM`        | Imagen base (obligatoria, primera linea)     | `FROM python:3.11-slim`           |
| `WORKDIR`     | Directorio de trabajo                        | `WORKDIR /app`                    |
| `COPY`        | Copiar archivos del host al contenedor       | `COPY . /app`                     |
| `ADD`         | Como COPY pero soporta URLs y tar            | `ADD app.tar.gz /opt/`            |
| `RUN`         | Ejecutar comandos durante el build           | `RUN pip install flask`           |
| `ENV`         | Variables de entorno                         | `ENV APP_ENV=production`          |
| `EXPOSE`      | Documentar puerto de la app                  | `EXPOSE 8080`                     |
| `CMD`         | Comando por defecto al iniciar               | `CMD ["python","app.py"]`         |
| `ENTRYPOINT`  | Ejecutable principal del contenedor          | `ENTRYPOINT ["nginx"]`            |
| `USER`        | Usuario para RUN, CMD, ENTRYPOINT            | `USER appuser`                    |

### 3. Sistema de Capas

```
Container Layer (R/W)        ← Escritura temporal
─────────────────────────
COPY src/ ./src/             ← Capa 4 (solo lectura)
RUN npm ci                   ← Capa 3
COPY package*.json ./        ← Capa 2
WORKDIR /app                 ← Capa 1
node:20-alpine (base)        ← Capas base compartidas
```

**Beneficios:**
- **Cache inteligente**: si una capa no cambia, Docker la reutiliza
- **Capas compartidas**: multiples imagenes comparten capas base
- **Builds rapidos**: separar dependencias del codigo = 90% usa cache
- **Eficiencia de red**: solo se transfieren capas faltantes

### 4. Buenas Practicas

#### Optimizacion

| Practica                        | Malo                                    | Bueno                                         |
|---------------------------------|-----------------------------------------|-----------------------------------------------|
| Imagenes base ligeras           | `FROM ubuntu:22.04` (77MB)              | `FROM python:3.11-slim` (45MB)                |
| Minimizar capas                 | Multiples `RUN` separados               | Un solo `RUN` con `&&`                         |
| Aprovechar cache                | `COPY . /app` antes de instalar deps    | `COPY requirements.txt` primero, luego codigo |
| Usar `.dockerignore`            | Copiar `.git`, `node_modules`, `.env`   | Archivo `.dockerignore` con exclusiones        |

#### Seguridad

- **No ejecutar como root**: `RUN adduser -D appuser && USER appuser`
- **Multi-stage builds**: compilar en una etapa, copiar solo el binario al runtime
- **Fijar versiones**: `python:3.11.7-slim` en vez de `python:latest`
- **Escanear vulnerabilidades**: Trivy o Docker Scout antes de cada push
- **HEALTHCHECK y LABEL**: monitoreo y trazabilidad
- **Limpiar en la misma capa**: `rm -rf /var/lib/apt/lists/*` en el mismo `RUN`

### 5. Multi-Stage Build

```
 ┌──────────────────────────┐      ┌──────────────────────────┐
 │    STAGE 1: Build         │      │    STAGE 2: Runtime       │
 │    golang:1.22-alpine     │──►   │    scratch / alpine       │
 │         ~1.2 GB           │      │        ~15 MB             │
 │                           │      │                           │
 │  - Compilador             │      │  - Binario compilado      │
 │  - Librerias de build     │      │  - Certificados CA        │
 │  - Codigo fuente          │      │  - Usuario no-root        │
 └──────────────────────────┘      └──────────────────────────┘
        Se descarta                     Imagen final
```

### 6. Build, Tag y Push

```
 Dockerfile ──► docker build ──► docker tag ──► docker push ──► DockerHub
```

```bash
docker build -t mi-app:1.0.0 .
docker tag mi-app:1.0.0 miusuario/mi-app:1.0.0
docker login -u miusuario
docker push miusuario/mi-app:1.0.0
```

### 7. Estrategia de Tags

| Tag              | Descripcion                                       | Riesgo |
|------------------|---------------------------------------------------|--------|
| `latest`         | Mutable, se sobreescribe con cada push             | Alto   |
| `1.0.0`          | Semantic Versioning (MAJOR.MINOR.PATCH). Inmutable | Bajo   |
| `1.0`            | Ultimo patch de esa minor                          | Medio  |
| `sha-a3f4b2c`   | Hash del commit Git. Maxima trazabilidad           | Bajo   |
| `alpine` / `slim`| Variante de imagen base                            | N/A    |

### 8. DockerHub

- Registry publico mas grande (8M+ imagenes)
- Imagenes oficiales verificadas por Docker Inc. (`nginx`, `postgres`, `python`)
- Plan gratuito: repos publicos ilimitados + 1 privado
- Docker Scout para escaneo de CVEs
- Webhooks para integracion con CI/CD

### 9. Vulnerabilidades en Imagenes

| Riesgo                    | Descripcion                                                        |
|---------------------------|--------------------------------------------------------------------|
| CVEs en imagen base       | Paquetes del SO con vulnerabilidades conocidas                     |
| Dependencias inseguras    | Librerias de la app (pip, npm) con CVEs                            |
| Secretos expuestos        | API keys o passwords hardcodeados, visibles con `docker history`   |
| Ejecutar como root        | Escape del contenedor = root en el host                            |
| Imagenes sin verificar    | Registries no oficiales, riesgo de malware                         |
| Capas con datos sensibles | Archivos borrados siguen en capas anteriores                       |

### 10. Herramientas de Escaneo

| Herramienta       | Comando                               | Descripcion                              |
|--------------------|---------------------------------------|------------------------------------------|
| **Trivy**          | `trivy image mi-app:1.0.0`           | Open source (Aqua Security), el mas popular |
| **Docker Scout**   | `docker scout cves mi-app:1.0.0`     | Integrado en Docker Desktop              |
| **Grype**          | `grype mi-app:1.0.0`                 | Open source (Anchore) + SBOM con syft    |
| **Snyk Container** | `snyk container test mi-app:1.0.0`   | SaaS con tier gratuito                   |

---

## Laboratorios

### Lab 1: Multi-Stage Build con Go

Demuestra multi-stage build: compilar con `golang:1.22-alpine` (~300MB) y producir imagen final con `scratch` (~10-15MB), reduccion del 95%.

```
lab1/
├── Dockerfile       # Multi-stage: golang → scratch
├── main.go          # Servidor HTTP Go (/, /health, /info)
└── README.md        # Guia paso a paso
```

```bash
cd Unidad-2/lab1/
docker build -t go-server:v1 .
docker run -d --name go-app -p 8080:8080 go-server:v1
curl http://localhost:8080
```

Ver [lab1/README.md](lab1/README.md) para la guia completa.

---

### Lab 2: DockerHub - Build, Tag & Push

Flujo completo: crear cuenta en DockerHub, login, build, tag, push y pull de una app Flask.

```
lab2/
├── Dockerfile       # python:3.12-slim, non-root, healthcheck
├── app.py           # App Flask (/, /health, /api/info)
├── requirements.txt # flask==3.0.0
└── README.md        # Guia de 10 pasos
```

```bash
cd Unidad-2/lab2/
docker build -t flask-hub:1.0.0 .
docker tag flask-hub:1.0.0 TU_DOCKER_ID/flask-hub:1.0.0
docker push TU_DOCKER_ID/flask-hub:1.0.0
```

Ver [lab2/README.md](lab2/README.md) para la guia completa.

---

## Comandos Referencia Rapida

### Imagenes y Build

```bash
docker build -t name:tag .              # Construir imagen
docker build -f Dockerfile.lab1 .       # Build con Dockerfile especifico
docker build --no-cache .               # Build sin cache
docker images                           # Listar imagenes locales
docker history <img>                    # Ver capas y tamano
docker rmi <img>                        # Eliminar imagen
```

### Tags, Push y Registry

```bash
docker tag img:v1 user/img:v1           # Etiquetar para registry
docker login                            # Autenticar en DockerHub
docker push user/img:v1                 # Subir imagen
docker pull user/img:v1                 # Descargar imagen
docker search nginx                     # Buscar en DockerHub
docker system prune -a                  # Eliminar todo sin uso
```

### Escaneo de Vulnerabilidades

```bash
# Escaneo con Trivy (contenedor, sin instalar)
docker run -v trivy-cache:/root/.cache/trivy \
  aquasec/trivy image --severity CRITICAL,HIGH \
  mi-app:1.0.0

# Escaneo con Docker Scout
docker scout cves mi-app:1.0.0
```

---

## Estructura de la Unidad

```
Unidad-2/
├── README.md                          # Este archivo
├── Unidad2.pdf                        # Presentacion teorica
├── Reto-Unidad-2.yaml                 # Reto de seguridad
├── escaneo-vulns.txt                  # Ejemplo de escaneo con Trivy
├── lab1/                              # Multi-Stage Build con Go
│   ├── Dockerfile
│   ├── Dockerfile.lab1-multistage-go.txt
│   ├── main.go
│   └── README.md
└── lab2/                              # DockerHub Build, Tag & Push
    ├── Dockerfile
    ├── Dockerfile.lab3-dockerhub-push.txt
    ├── lab3-guia-dockerhub.sh
    ├── app.py
    ├── requirements.txt
    └── README.md
```

---

## Resumen

1. El **Dockerfile** define la imagen capa por capa — cada instruccion es determinista e inmutable
2. **Buenas practicas**: imagenes slim, cache de deps, multi-stage, non-root, .dockerignore
3. Flujo **Build → Tag (semver) → Push** para publicar imagenes
4. **DockerHub**: crear cuenta, login CLI, crear repositorio, push y pull
5. **Escanear siempre**: Trivy y Docker Scout detectan CVEs antes de llegar a produccion

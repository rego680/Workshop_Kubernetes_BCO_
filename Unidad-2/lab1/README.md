# Lab 1: Multi-Stage Build con Go

Demuestra el concepto de **multi-stage build** en Docker: compilar en una etapa pesada y copiar solo el binario a una imagen minima.

```
 ┌─────────────────────┐      ┌─────────────────────┐
 │   STAGE 1: Build    │      │  STAGE 2: Runtime    │
 │                     │      │                      │
 │  golang:1.22-alpine │──►   │  scratch (0 bytes)   │
 │      ~300 MB        │      │     ~10-15 MB        │
 │                     │      │                      │
 │  - Compilador Go    │      │  - Solo el binario   │
 │  - Librerias        │      │  - Nada mas          │
 │  - Codigo fuente    │      │                      │
 └─────────────────────┘      └─────────────────────┘
        Se descarta              Imagen final
```

| Propiedad              | Valor                            |
|------------------------|----------------------------------|
| **Stage 1 (build)**    | `golang:1.22-alpine` (~300 MB)   |
| **Stage 2 (runtime)**  | `scratch` (0 bytes)              |
| **Imagen final**       | ~10-15 MB                        |
| **Puerto**             | `8080`                           |
| **Lenguaje**           | Go 1.22                          |
| **Reduccion**          | ~95% menos tamano vs stage 1     |

---

## Por que Multi-Stage?

| Sin multi-stage                    | Con multi-stage                   |
|------------------------------------|-----------------------------------|
| Imagen final: ~300 MB              | Imagen final: ~10-15 MB           |
| Incluye compilador, librerias, src | Solo el binario ejecutable        |
| Superficie de ataque grande        | Superficie de ataque minima       |
| Mas lento de transferir/desplegar  | Pull/push ultra rapido            |

---

## Requisitos Previos

- **Docker** instalado (version 20+)
- Puerto **8080** libre

```bash
docker --version
```

---

## Despliegue Paso a Paso

### 1. Ir al directorio del lab

```bash
cd Unidad-2/lab1/
```

### 2. Construir la imagen (multi-stage)

```bash
docker build -t go-server:v1 .
```

Salida esperada:
```
 => [builder 1/3] FROM docker.io/library/golang:1.22-alpine
 => [builder 2/3] COPY main.go .
 => [builder 3/3] RUN CGO_ENABLED=0 GOOS=linux go build ...
 => [stage-1 1/1] COPY --from=builder /app/server /server
 => => naming to docker.io/library/go-server:v1   DONE
```

### 3. Comparar tamanos de imagen

```bash
docker images | grep -E "go-server|golang"
```

Resultado esperado:
```
go-server    v1      xxxx   X seconds ago   ~10MB
golang       1.22    xxxx   X days ago      ~300MB
```

### 4. Ejecutar el contenedor

```bash
docker run -d --name go-app -p 8080:8080 go-server:v1
```

### 5. Verificar

```bash
# Contenedor activo
docker ps --filter name=go-app

# Health check
curl http://localhost:8080/health

# Info del servidor
curl http://localhost:8080/info
```

### 6. Abrir en el navegador

```
http://localhost:8080
```

Mostrara una pagina con hostname, version de Go, OS/Arch, uptime y tamano de la imagen.

---

## Endpoints

| Ruta       | Descripcion                                    |
|------------|------------------------------------------------|
| `/`        | Pagina principal con info del contenedor       |
| `/health`  | Health check → `{"status":"ok"}`               |
| `/info`    | Info en JSON (hostname, go version, uptime)    |

---

## Estructura del Proyecto

```
lab1/
├── Dockerfile                          # Multi-stage: golang → scratch
├── Dockerfile.lab1-multistage-go.txt   # Referencia original del curso
├── main.go                             # Servidor HTTP en Go
└── README.md
```

---

## Ejercicio Extra: Analizar las capas

```bash
# Ver historial de capas de la imagen final
docker history go-server:v1

# Comparar con la imagen de build
docker history golang:1.22-alpine
```

Notar que `go-server:v1` tiene solo 2 capas (scratch + binario), mientras que `golang:1.22-alpine` tiene muchas mas.

---

## Comandos Utiles

```bash
# Ver logs
docker logs go-app

# Inspeccionar la imagen
docker inspect go-server:v1 | grep -i size

# Ver que NO hay shell dentro del contenedor
docker exec -it go-app sh
# Error: no shell in scratch image (esto es esperado!)
```

---

## Limpieza

```bash
# Detener y eliminar contenedor
docker stop go-app && docker rm go-app

# Eliminar imagen
docker rmi go-server:v1
```

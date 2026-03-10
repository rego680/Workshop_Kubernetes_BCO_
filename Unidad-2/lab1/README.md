# Lab 1: Multi-Stage Build con Go

## Descripcion

Construccion de una imagen ultra-ligera usando multi-stage build.
El primer stage compila una aplicacion Go (~300 MB), el segundo stage
copia solo el binario a una imagen `scratch` (0 bytes), resultando
en una imagen final de ~10-15 MB.

| Propiedad        | Valor                          |
|------------------|--------------------------------|
| **Stage 1**      | `golang:1.22-alpine` (~300 MB) |
| **Stage 2**      | `scratch` (0 bytes)            |
| **Imagen final** | ~10-15 MB                      |
| **Puerto**       | `8080:8080`                    |
| **Concepto**     | Multi-stage build              |

---

## Archivos del Lab

| Archivo                            | Descripcion                       |
|------------------------------------|-----------------------------------|
| `Dockerfile.lab1-multistage-go.txt`| Dockerfile multi-stage (Go + scratch) |

> **Nota:** Se necesita crear el archivo `main.go` antes de construir.

---

## Ejecucion

### Paso 1 — Crear el codigo fuente Go

```bash
cd Unidad-2/lab1/

# Crear el archivo main.go (servidor HTTP basico)
cat > main.go << 'GOEOF'
package main

import (
    "fmt"
    "log"
    "net/http"
    "os"
    "runtime"
    "time"
)

func main() {
    http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
        hostname, _ := os.Hostname()
        fmt.Fprintf(w, "Workshop Kubernetes BCO - Lab 1 Multi-Stage\n")
        fmt.Fprintf(w, "Hostname: %s\n", hostname)
        fmt.Fprintf(w, "Go Version: %s\n", runtime.Version())
        fmt.Fprintf(w, "OS/Arch: %s/%s\n", runtime.GOOS, runtime.GOARCH)
        fmt.Fprintf(w, "Time: %s\n", time.Now().Format(time.RFC3339))
    })

    http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
        w.Header().Set("Content-Type", "application/json")
        fmt.Fprintf(w, `{"status":"ok","service":"go-server"}`)
    })

    log.Println("Server starting on :8080")
    log.Fatal(http.ListenAndServe(":8080", nil))
}
GOEOF
```

### Paso 2 — Renombrar el Dockerfile y construir

```bash
# Copiar el Dockerfile (remover .txt)
cp Dockerfile.lab1-multistage-go.txt Dockerfile

# Construir la imagen multi-stage
docker build -t go-server:v1 .
```

### Paso 3 — Verificar el tamano de la imagen

```bash
# Comparar tamanos
docker images | grep -E "go-server|golang"

# La imagen go-server:v1 debe ser ~10-15 MB
# vs golang:1.22-alpine que es ~300 MB
```

### Paso 4 — Ejecutar el contenedor

```bash
docker run -d \
  --name go-app \
  -p 8080:8080 \
  go-server:v1
```

### Paso 5 — Probar la aplicacion

```bash
# Pagina principal
curl http://localhost:8080

# Health check
curl http://localhost:8080/health
```

### Paso 6 — Inspeccionar las capas de la imagen

```bash
# Ver el historial de capas
docker history go-server:v1

# Notar que solo hay 2 capas: COPY del binario + CMD
# No hay sistema operativo, shell ni librerias
```

### Paso 7 — Intentar acceder al contenedor (falla)

```bash
# Esto FALLA porque scratch no tiene shell
docker exec -it go-app sh
# Error: OCI runtime exec failed: exec failed: unable to start container process: exec: "sh": executable file not found

# Esto es una ventaja de seguridad: no hay shell para un atacante
```

---

## Comparacion de Tamanos

| Imagen              | Tamano  | Contenido                    |
|---------------------|---------|------------------------------|
| `golang:1.22-alpine`| ~300 MB | Go compiler + tools + Alpine |
| `go-server:v1`      | ~10 MB  | Solo el binario compilado    |
| `scratch`           | 0 bytes | Imagen vacia (base)          |

---

## Conceptos Clave

- **Multi-stage build**: Usar multiples `FROM` en un Dockerfile. Solo la ultima etapa queda en la imagen final.
- **`scratch`**: Imagen base vacia. No tiene shell, librerias ni sistema operativo.
- **`CGO_ENABLED=0`**: Compila sin dependencias de C (binario estatico).
- **`-ldflags='-s -w'`**: Elimina info de debug, reduce tamano del binario.
- **`COPY --from=builder`**: Copia archivos de un stage anterior.

---

## Limpieza

```bash
docker stop go-app && docker rm go-app
docker rmi go-server:v1
rm -f main.go Dockerfile
```

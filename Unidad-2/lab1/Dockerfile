###############################################
# LAB 1 — UNIDAD 2: Multi-Stage Build con Go
#
# Objetivo: Demostrar multi-stage build
#   Stage 1: golang:1.22-alpine (~300MB) compila
#   Stage 2: scratch (0MB) solo binario
#   Resultado final: ~10-15MB
#
# Build:
#   docker build -t go-server:v1 .
# Run:
#   docker run -d --name go-app -p 8080:8080 go-server:v1
# Test:
#   curl http://localhost:8080
###############################################

# === STAGE 1: Compilacion =====================
FROM golang:1.22-alpine AS builder

LABEL stage="build"

WORKDIR /src

# Copiar codigo fuente
COPY main.go .

# Compilar binario estatico sin dependencias C
# -ldflags='-s -w' elimina debug info -> binario mas pequeno
RUN CGO_ENABLED=0 GOOS=linux go build \
    -ldflags='-s -w' \
    -o /app/server .

# === STAGE 2: Runtime (imagen minima) =========
# scratch = imagen completamente vacia, 0 bytes
FROM scratch

LABEL maintainer="DevOps Lab - Unidad 2"
LABEL description="Lab 1 - Multi-stage Go server (~10MB)"
LABEL version="1.0"

# Copiar SOLO el binario desde el stage de build
COPY --from=builder /app/server /server

# Puerto de la aplicacion
EXPOSE 8080

# Ejecutar el binario
CMD ["/server"]

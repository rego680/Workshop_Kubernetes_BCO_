# Lab 3: Python Flask - Aplicacion Web

Aplicacion web con Flask desplegada en contenedor Docker con imagen `python:3.11-slim`.

| Propiedad        | Valor                                  |
|------------------|----------------------------------------|
| **Imagen base**  | `python:3.11-slim`                     |
| **Puerto**       | `5000` (host) → `5000` (contenedor)   |
| **Framework**    | Flask 3.0.0                            |
| **Seguridad**    | Usuario no-root (`appuser`)            |
| **Health check** | `GET /health`                          |

---

## Endpoints

| Ruta        | Descripcion                              |
|-------------|------------------------------------------|
| `/`         | Pagina principal con info del contenedor |
| `/health`   | Health check → `{"status":"ok"}`         |
| `/api/info` | Info del sistema en JSON                 |

---

## Despliegue Paso a Paso

### 1. Ir al directorio del lab

```bash
cd Unidad-1/lab3-flask/
```

### 2. Construir la imagen

```bash
docker build -t mi-flask:v1 .
```

### 3. Ejecutar el contenedor

```bash
docker run -d --name app-flask -p 5000:5000 mi-flask:v1
```

### 4. Verificar

```bash
# Contenedor activo
docker ps --filter name=app-flask

# Health check
curl http://localhost:5000/health

# Pagina principal
curl http://localhost:5000/

# Info del sistema
curl http://localhost:5000/api/info
```

### 5. Abrir en el navegador

```
http://localhost:5000
```

---

## Estructura del Proyecto

```
lab3-flask/
├── Dockerfile           # python:3.11-slim, usuario no-root
├── requirements.txt     # flask==3.0.0
├── app.py               # Aplicacion Flask con 3 rutas
├── templates/
│   └── index.html       # Pagina principal con info del host
└── README.md
```

---

## Limpieza

```bash
docker stop app-flask && docker rm app-flask
docker rmi mi-flask:v1
```

# Lab 3: Python Flask — Aplicacion Web con API REST

## Descripcion

Aplicacion Flask con pagina web y endpoints REST. Demuestra buenas practicas:
usuario non-root, cache de dependencias en el build, y health checks.

| Propiedad       | Valor              |
|-----------------|--------------------|
| **Imagen base** | `python:3.11-slim` |
| **Puerto**      | `5000:5000`        |
| **Tamano**      | ~150 MB            |
| **Framework**   | Flask 3.0          |
| **Usuario**     | `appuser` (non-root) |

---

## Archivos del Lab

| Archivo            | Descripcion                        |
|--------------------|------------------------------------|
| `Dockerfile`       | Imagen multi-step con usuario non-root |
| `app.py`           | Aplicacion Flask                   |
| `requirements.txt` | Dependencias Python                |
| `templates/`       | Templates HTML                     |

---

## Ejecucion

### Paso 1 — Construir la imagen

```bash
cd lab3-flask/

docker build -t mi-flask:v1 .
```

### Paso 2 — Ejecutar el contenedor

```bash
docker run -d \
  --name app-flask \
  -p 5000:5000 \
  mi-flask:v1
```

### Paso 3 — Probar la aplicacion

```bash
# Pagina principal
curl http://localhost:5000

# Health check
curl http://localhost:5000/health

# API info (JSON formateado)
curl http://localhost:5000/api/info | python3 -m json.tool
```

Tambien se puede abrir en el navegador: `http://localhost:5000`

### Paso 4 — Verificar seguridad (usuario non-root)

```bash
# Debe mostrar: appuser
docker exec app-flask whoami

# Ver uid/gid
docker exec app-flask id
```

### Paso 5 — Ver logs

```bash
docker logs -f app-flask
# Ctrl+C para salir
```

---

## Verificacion

| Prueba              | Comando / URL                        | Resultado esperado       |
|---------------------|--------------------------------------|--------------------------|
| Pagina principal    | `curl http://localhost:5000`         | HTML de la app           |
| Health check        | `curl http://localhost:5000/health`  | JSON status ok           |
| API info            | `curl http://localhost:5000/api/info`| JSON con info container  |
| Usuario non-root    | `docker exec app-flask whoami`       | `appuser`                |

---

## Limpieza

```bash
docker stop app-flask && docker rm app-flask
docker rmi mi-flask:v1
```

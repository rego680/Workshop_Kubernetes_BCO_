# Lab 2: PostgreSQL — Base de Datos con Persistencia

## Descripcion

Despliegue de PostgreSQL con datos iniciales pre-cargados y volumen persistente.
Demuestra el uso de variables de entorno, scripts de inicializacion y volumenes Docker.

| Propiedad        | Valor                    |
|------------------|--------------------------|
| **Imagen base**  | `postgres:16-alpine`     |
| **Puerto**       | `5432:5432`              |
| **Tamano**       | ~80 MB                   |
| **Volumen**      | `pgdata` (persistencia)  |
| **Base de datos**| `labdb`                  |
| **Usuario**      | `labuser` / `labpass123` |

---

## Archivos del Lab

| Archivo                  | Descripcion                                |
|--------------------------|--------------------------------------------|
| `Dockerfile`             | Imagen PostgreSQL con scripts init         |
| `01-schema.sql`          | Esquema de tablas (se ejecuta al crear BD) |
| `02-seed-data.sql`       | Datos iniciales                            |
| `postgresql-custom.conf` | Configuracion personalizada                |

---

## Ejecucion

### Paso 1 — Construir la imagen

```bash
cd lab2-postgres/

docker build -t mi-postgres:v1 .
```

### Paso 2 — Ejecutar con volumen persistente

```bash
docker run -d \
  --name db-postgres \
  -p 5432:5432 \
  -v pgdata:/var/lib/postgresql/data \
  mi-postgres:v1
```

### Paso 3 — Esperar la inicializacion

```bash
# Esperar ~10 segundos para que PostgreSQL inicialice
sleep 10

# Verificar que esta listo
docker exec db-postgres pg_isready -U labuser -d labdb
```

### Paso 4 — Conectar a la base de datos

```bash
docker exec -it db-postgres psql -U labuser -d labdb
```

Dentro de `psql`:

```sql
-- Ver tablas creadas
\dt

-- Ver alumnos
SELECT * FROM alumnos;

-- Ver cursos
SELECT * FROM cursos;

-- Ver vista resumen
SELECT * FROM v_resumen_alumnos;

-- Salir
\q
```

### Paso 5 — Consulta rapida (sin entrar a psql)

```bash
docker exec db-postgres psql -U labuser -d labdb \
  -c "SELECT alumno, curso, estado FROM v_resumen_alumnos;"
```

---

## Prueba de Persistencia

Demostrar que los datos sobreviven al reinicio del contenedor:

```bash
# 1. Detener y eliminar el contenedor
docker stop db-postgres && docker rm db-postgres

# 2. Recrear con el MISMO volumen
docker run -d \
  --name db-postgres \
  -p 5432:5432 \
  -v pgdata:/var/lib/postgresql/data \
  mi-postgres:v1

# 3. Esperar y verificar que los datos siguen ahi
sleep 5
docker exec db-postgres psql -U labuser -d labdb \
  -c "SELECT * FROM alumnos;"
```

---

## Verificacion

| Prueba                | Comando                                      | Resultado esperado   |
|-----------------------|----------------------------------------------|----------------------|
| BD lista              | `docker exec db-postgres pg_isready -U labuser -d labdb` | accepting connections |
| Tablas creadas        | `\dt` dentro de psql                         | alumnos, cursos      |
| Datos cargados        | `SELECT * FROM alumnos;`                     | Registros visibles   |
| Persistencia          | Recrear contenedor con mismo volumen         | Datos intactos       |

---

## Limpieza

```bash
docker stop db-postgres && docker rm db-postgres
docker volume rm pgdata
docker rmi mi-postgres:v1
```

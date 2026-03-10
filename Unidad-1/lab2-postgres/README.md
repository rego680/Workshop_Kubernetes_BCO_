# Lab 2: PostgreSQL — Base de Datos con Persistencia

## Descripcion

Despliegue de PostgreSQL 16 con esquema, datos iniciales pre-cargados y volumen
persistente. Demuestra el uso de variables de entorno, scripts de inicializacion
(`docker-entrypoint-initdb.d/`), configuracion personalizada y volumenes Docker.

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

| Archivo                  | Descripcion                                         |
|--------------------------|-----------------------------------------------------|
| `Dockerfile`             | Imagen PostgreSQL con scripts init y config custom   |
| `01-schema.sql`          | Esquema: tablas `cursos`, `alumnos`, `notas` y vista |
| `02-seed-data.sql`       | Datos iniciales: 4 cursos, 8 alumnos, 8 notas       |
| `postgresql-custom.conf` | Configuracion: logging, rendimiento, conexiones      |

---

## Ejecucion

### Paso 1 — Construir la imagen

```bash
cd Unidad-1/lab2-postgres/

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
# Esperar ~10 segundos para que PostgreSQL inicialice y ejecute los scripts SQL
sleep 10

# Verificar que esta listo
docker exec db-postgres pg_isready -U labuser -d labdb
# Resultado: /var/run/postgresql:5432 - accepting connections
```

### Paso 4 — Conectar a la base de datos

```bash
docker exec -it db-postgres psql -U labuser -d labdb
```

Dentro de `psql`:

```sql
-- Ver tablas creadas por 01-schema.sql
\dt

-- Resultado esperado:
--  Schema |  Name   | Type  | Owner
-- --------+---------+-------+---------
--  public | alumnos | table | labuser
--  public | cursos  | table | labuser
--  public | notas   | table | labuser

-- Ver cursos disponibles
SELECT * FROM cursos;

-- Ver alumnos inscritos
SELECT * FROM alumnos;

-- Ver notas
SELECT * FROM notas;

-- Usar la vista resumen (JOIN alumnos + cursos)
SELECT * FROM v_resumen_alumnos;

-- Salir de psql
\q
```

### Paso 5 — Consultas rapidas (sin entrar a psql)

```bash
# Ver resumen de alumnos con su curso y estado
docker exec db-postgres psql -U labuser -d labdb \
  -c "SELECT alumno, curso, estado FROM v_resumen_alumnos;"

# Contar alumnos por curso
docker exec db-postgres psql -U labuser -d labdb \
  -c "SELECT c.nombre AS curso, COUNT(a.id) AS total_alumnos
      FROM cursos c LEFT JOIN alumnos a ON c.id = a.curso_id
      GROUP BY c.nombre ORDER BY total_alumnos DESC;"

# Ver notas con nombre del alumno
docker exec db-postgres psql -U labuser -d labdb \
  -c "SELECT a.nombre, n.evaluacion, n.calificacion
      FROM notas n JOIN alumnos a ON n.alumno_id = a.id
      ORDER BY n.calificacion DESC;"
```

### Paso 6 — Insertar datos nuevos

```bash
docker exec db-postgres psql -U labuser -d labdb \
  -c "INSERT INTO alumnos (nombre, email, curso_id, estado)
      VALUES ('Tu Nombre', 'tu.email@lab.local', 1, 'activo');"

# Verificar
docker exec db-postgres psql -U labuser -d labdb \
  -c "SELECT * FROM alumnos WHERE email = 'tu.email@lab.local';"
```

---

## Prueba de Persistencia

Demostrar que los datos sobreviven al reinicio del contenedor:

```bash
# 1. Detener y eliminar el contenedor
docker stop db-postgres && docker rm db-postgres

# 2. Verificar que el volumen sigue existiendo
docker volume ls | grep pgdata

# 3. Recrear con el MISMO volumen
docker run -d \
  --name db-postgres \
  -p 5432:5432 \
  -v pgdata:/var/lib/postgresql/data \
  mi-postgres:v1

# 4. Esperar y verificar que los datos siguen ahi
sleep 5
docker exec db-postgres psql -U labuser -d labdb \
  -c "SELECT * FROM alumnos;"
# Resultado: TODOS los datos intactos, incluyendo los insertados manualmente
```

---

## Verificar la configuracion personalizada

```bash
# Ver que PostgreSQL cargo la config custom
docker exec db-postgres psql -U labuser -d labdb \
  -c "SHOW log_statement;"
# Resultado: all

docker exec db-postgres psql -U labuser -d labdb \
  -c "SHOW shared_buffers;"
# Resultado: 64MB

docker exec db-postgres psql -U labuser -d labdb \
  -c "SHOW max_connections;"
# Resultado: 50
```

---

## Verificacion

| Prueba                | Comando                                                    | Resultado esperado        |
|-----------------------|------------------------------------------------------------|---------------------------|
| BD lista              | `docker exec db-postgres pg_isready -U labuser -d labdb`  | accepting connections     |
| Tablas creadas        | `\dt` dentro de psql                                       | alumnos, cursos, notas    |
| Datos cargados        | `SELECT * FROM alumnos;`                                   | 8 registros               |
| Vista funciona        | `SELECT * FROM v_resumen_alumnos;`                         | Alumnos con nombre de curso |
| Notas cargadas        | `SELECT * FROM notas;`                                     | 8 calificaciones          |
| Config custom         | `SHOW log_statement;`                                      | all                       |
| Persistencia          | Recrear contenedor con mismo volumen                       | Datos intactos            |

---

## Conceptos Clave

- **docker-entrypoint-initdb.d/**: Directorio especial de la imagen postgres. Los archivos `.sql` y `.sh` se ejecutan automaticamente en orden alfabetico al crear la BD por primera vez.
- **Volumen (`-v pgdata:...`)**: Almacena los datos fuera del contenedor. Si el contenedor se elimina, los datos persisten en el volumen.
- **PGDATA**: Variable que define donde PostgreSQL almacena sus archivos de datos.
- **pg_isready**: Utilidad de PostgreSQL para verificar si el servidor esta aceptando conexiones.
- **HEALTHCHECK**: Docker verifica periodicamente la salud del contenedor usando el comando especificado.
- **CMD con config_file**: Inicia PostgreSQL cargando la configuracion personalizada en lugar de la default.

---

## Limpieza

```bash
docker stop db-postgres && docker rm db-postgres
docker volume rm pgdata
docker rmi mi-postgres:v1
```

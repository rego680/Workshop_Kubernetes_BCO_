# Lab 2: PostgreSQL - Base de Datos en Contenedor

Base de datos PostgreSQL 16 con esquema predefinido, datos iniciales y persistencia mediante volumenes Docker.

| Propiedad        | Valor                                    |
|------------------|------------------------------------------|
| **Imagen base**  | `postgres:16-alpine`                     |
| **Puerto**       | `5432` (host) → `5432` (contenedor)     |
| **Base de datos**| `labdb`                                  |
| **Usuario**      | `labuser`                                |
| **Password**     | `labpass123`                             |
| **Volumen**      | `pgdata` → `/var/lib/postgresql/data`    |
| **Tamano aprox.**| ~80 MB                                   |
| **Health check** | `pg_isready -U labuser -d labdb`         |

---

## Esquema de la Base de Datos

```
┌──────────────────────┐       ┌──────────────────────────┐
│       cursos          │       │         alumnos           │
├──────────────────────┤       ├──────────────────────────┤
│ id          SERIAL PK│◄──────│ curso_id   FK → cursos.id│
│ nombre      VARCHAR   │       │ id         SERIAL PK     │
│ descripcion TEXT      │       │ nombre     VARCHAR        │
│ duracion_horas INT    │       │ email      VARCHAR UNIQUE │
│ activo      BOOLEAN   │       │ estado     CHECK(activo/  │
│ fecha_creacion TIMESTAMP│     │            inactivo/      │
└──────────────────────┘       │            graduado)      │
                                │ fecha_inscripcion DATE    │
   ┌────────────────────┐       └──────────────────────────┘
   │ v_resumen_alumnos  │
   │ (VISTA)            │
   │ alumno, email,     │
   │ curso, estado,     │
   │ fecha_inscripcion  │
   └────────────────────┘
```

**Datos iniciales:** 4 cursos + 8 alumnos precargados automaticamente.

---

## Requisitos Previos

- **Docker** instalado (version 20+)
- Puerto **5432** libre
- (Opcional) Cliente `psql` para conectarse desde el host

```bash
docker --version
```

---

## Despliegue Paso a Paso

### 1. Ir al directorio del lab

```bash
cd Unidad-1/lab2-postgres/
```

### 2. Construir la imagen

```bash
docker build -t mi-postgres:v1 .
```

Salida esperada:
```
 => [1/4] FROM docker.io/library/postgres:16-alpine
 => [2/4] COPY 01-schema.sql /docker-entrypoint-initdb.d/
 => [3/4] COPY 02-seed-data.sql /docker-entrypoint-initdb.d/
 => [4/4] COPY postgresql-custom.conf /etc/postgresql/custom.conf
 => => naming to docker.io/library/mi-postgres:v1   DONE
```

### 3. Ejecutar el contenedor con volumen persistente

```bash
docker run -d \
  --name db-postgres \
  -p 5432:5432 \
  -v pgdata:/var/lib/postgresql/data \
  mi-postgres:v1
```

> El volumen `pgdata` asegura que los datos sobrevivan si el contenedor se elimina.

### 4. Verificar que esta corriendo

```bash
# Ver contenedor activo
docker ps --filter name=db-postgres

# Ver logs (debe mostrar "database system is ready to accept connections")
docker logs db-postgres
```

Buscar en los logs:
```
NOTICE:  ========================================
NOTICE:  Base de datos labdb inicializada
NOTICE:  Cursos insertados: 4
NOTICE:  Alumnos insertados: 8
NOTICE:  ========================================
...
database system is ready to accept connections
```

### 5. Conectarse a la base de datos

**Opcion A: Desde dentro del contenedor**
```bash
docker exec -it db-postgres psql -U labuser -d labdb
```

**Opcion B: Desde el host (requiere psql instalado)**
```bash
psql -h localhost -p 5432 -U labuser -d labdb
```
(Password: `labpass123`)

### 6. Probar consultas SQL

```sql
-- Ver todos los cursos
SELECT * FROM cursos;

-- Ver todos los alumnos
SELECT * FROM alumnos;

-- Usar la vista resumen (JOIN cursos + alumnos)
SELECT * FROM v_resumen_alumnos;

-- Contar alumnos por curso
SELECT c.nombre AS curso, COUNT(a.id) AS total_alumnos
FROM cursos c
LEFT JOIN alumnos a ON c.id = a.curso_id
GROUP BY c.nombre
ORDER BY total_alumnos DESC;

-- Filtrar alumnos activos de Kubernetes
SELECT a.nombre, a.email
FROM alumnos a
JOIN cursos c ON a.curso_id = c.id
WHERE c.nombre LIKE '%Kubernetes%'
  AND a.estado = 'activo';

-- Salir de psql
\q
```

---

## Estructura del Proyecto

```
lab2-postgres/
├── Dockerfile                # postgres:16-alpine + scripts de init
├── 01-schema.sql             # Crea tablas (cursos, alumnos) + vista
├── 02-seed-data.sql          # Inserta 4 cursos + 8 alumnos
├── postgresql-custom.conf    # Config optimizada para lab (logging, memoria)
├── .dockerignore             # Excluye archivos innecesarios del build
└── README.md
```

---

## Comandos Utiles

```bash
# Ver logs en tiempo real
docker logs -f db-postgres

# Entrar al contenedor
docker exec -it db-postgres sh

# Ejecutar una consulta rapida sin entrar a psql
docker exec db-postgres psql -U labuser -d labdb -c "SELECT * FROM v_resumen_alumnos;"

# Ver tamano de la base de datos
docker exec db-postgres psql -U labuser -d labdb -c "SELECT pg_size_pretty(pg_database_size('labdb'));"

# Verificar health check
docker inspect --format='{{.State.Health.Status}}' db-postgres

# Ver volumen persistente
docker volume inspect pgdata
```

---

## Persistencia de Datos

El volumen `pgdata` mantiene los datos aunque se elimine el contenedor:

```bash
# Detener y eliminar contenedor
docker stop db-postgres && docker rm db-postgres

# Volver a crear -> los datos siguen ahi
docker run -d --name db-postgres -p 5432:5432 -v pgdata:/var/lib/postgresql/data mi-postgres:v1

# Verificar que los datos persisten
docker exec db-postgres psql -U labuser -d labdb -c "SELECT COUNT(*) FROM alumnos;"
```

---

## Limpieza

```bash
# Detener y eliminar contenedor
docker stop db-postgres && docker rm db-postgres

# Eliminar volumen (borra todos los datos)
docker volume rm pgdata

# Eliminar imagen
docker rmi mi-postgres:v1
```

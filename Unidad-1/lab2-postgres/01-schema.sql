-- ============================================================
-- Lab 2 - Unidad 1: Esquema de Base de Datos
-- Se ejecuta automaticamente al iniciar el contenedor
-- (docker-entrypoint-initdb.d/ en orden alfabetico)
-- ============================================================

-- Tabla de cursos
CREATE TABLE IF NOT EXISTS cursos (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    descripcion TEXT,
    duracion_horas INTEGER DEFAULT 40,
    activo BOOLEAN DEFAULT true,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de alumnos
CREATE TABLE IF NOT EXISTS alumnos (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    curso_id INTEGER REFERENCES cursos(id),
    estado VARCHAR(20) DEFAULT 'activo' CHECK (estado IN ('activo', 'inactivo', 'graduado')),
    fecha_inscripcion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de notas
CREATE TABLE IF NOT EXISTS notas (
    id SERIAL PRIMARY KEY,
    alumno_id INTEGER REFERENCES alumnos(id) ON DELETE CASCADE,
    evaluacion VARCHAR(50) NOT NULL,
    calificacion NUMERIC(5,2) CHECK (calificacion >= 0 AND calificacion <= 100),
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Vista resumen de alumnos con su curso
CREATE OR REPLACE VIEW v_resumen_alumnos AS
SELECT
    a.id,
    a.nombre AS alumno,
    a.email,
    c.nombre AS curso,
    a.estado,
    a.fecha_inscripcion
FROM alumnos a
LEFT JOIN cursos c ON a.curso_id = c.id;

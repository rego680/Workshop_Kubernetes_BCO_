-- =============================================
-- Lab 2: PostgreSQL - Esquema de Base de Datos
-- Se ejecuta automáticamente al iniciar el contenedor
-- =============================================

-- Tabla de cursos
CREATE TABLE IF NOT EXISTS cursos (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    descripcion TEXT,
    duracion_horas INTEGER DEFAULT 40,
    activo BOOLEAN DEFAULT TRUE,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de alumnos
CREATE TABLE IF NOT EXISTS alumnos (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    curso_id INTEGER REFERENCES cursos(id),
    estado VARCHAR(20) DEFAULT 'activo'
        CHECK (estado IN ('activo', 'inactivo', 'graduado')),
    fecha_inscripcion DATE DEFAULT CURRENT_DATE,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Índices para mejorar consultas
CREATE INDEX idx_alumnos_curso ON alumnos(curso_id);
CREATE INDEX idx_alumnos_estado ON alumnos(estado);

-- Vista resumen: combina alumnos con su curso
CREATE OR REPLACE VIEW v_resumen_alumnos AS
SELECT
    a.nombre AS alumno,
    a.email,
    c.nombre AS curso,
    a.estado,
    a.fecha_inscripcion
FROM alumnos a
JOIN cursos c ON a.curso_id = c.id
ORDER BY a.nombre;

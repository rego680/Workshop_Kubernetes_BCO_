-- =============================================
-- Lab 2: PostgreSQL - Datos Iniciales (Seed)
-- Se ejecuta después de 01-schema.sql
-- =============================================

-- Insertar cursos
INSERT INTO cursos (nombre, descripcion, duracion_horas) VALUES
    ('Kubernetes Básico', 'Fundamentos de orquestación de contenedores con Kubernetes', 40),
    ('Docker Avanzado', 'Contenedores, imágenes y Docker Compose en profundidad', 30),
    ('DevOps CI/CD', 'Pipelines de integración y entrega continua', 35),
    ('Seguridad en Contenedores', 'Hardening y buenas prácticas de seguridad', 25);

-- Insertar alumnos
INSERT INTO alumnos (nombre, email, curso_id, estado) VALUES
    ('Ana García', 'ana.garcia@lab.local', 1, 'activo'),
    ('Carlos López', 'carlos.lopez@lab.local', 1, 'activo'),
    ('María Rodríguez', 'maria.rodriguez@lab.local', 2, 'activo'),
    ('Pedro Martínez', 'pedro.martinez@lab.local', 2, 'graduado'),
    ('Laura Sánchez', 'laura.sanchez@lab.local', 3, 'activo'),
    ('Jorge Hernández', 'jorge.hernandez@lab.local', 3, 'inactivo'),
    ('Sofía Díaz', 'sofia.diaz@lab.local', 4, 'activo'),
    ('Miguel Torres', 'miguel.torres@lab.local', 1, 'activo');

-- Verificación: mostrar resumen de datos insertados
DO $$
BEGIN
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Base de datos labdb inicializada';
    RAISE NOTICE 'Cursos insertados: %', (SELECT count(*) FROM cursos);
    RAISE NOTICE 'Alumnos insertados: %', (SELECT count(*) FROM alumnos);
    RAISE NOTICE '========================================';
END $$;

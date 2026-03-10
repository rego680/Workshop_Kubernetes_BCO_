-- ============================================================
-- Lab 2 - Unidad 1: Datos Iniciales (Seed Data)
-- Se ejecuta despues de 01-schema.sql (orden alfabetico)
-- ============================================================

-- Insertar cursos
INSERT INTO cursos (nombre, descripcion, duracion_horas) VALUES
    ('Kubernetes Basico', 'Introduccion a contenedores y orquestacion con K8s', 40),
    ('Docker Avanzado', 'Multi-stage builds, networking y seguridad en Docker', 32),
    ('Seguridad en Contenedores', 'Hardening, RBAC, NetworkPolicies y mejores practicas', 48),
    ('DevOps CI/CD', 'Pipelines de integracion y despliegue continuo', 36);

-- Insertar alumnos
INSERT INTO alumnos (nombre, email, curso_id, estado) VALUES
    ('Ana Garcia', 'ana.garcia@lab.local', 1, 'activo'),
    ('Carlos Lopez', 'carlos.lopez@lab.local', 1, 'activo'),
    ('Maria Rodriguez', 'maria.rodriguez@lab.local', 2, 'activo'),
    ('Pedro Martinez', 'pedro.martinez@lab.local', 3, 'activo'),
    ('Laura Sanchez', 'laura.sanchez@lab.local', 1, 'graduado'),
    ('Diego Fernandez', 'diego.fernandez@lab.local', 4, 'activo'),
    ('Sofia Morales', 'sofia.morales@lab.local', 2, 'inactivo'),
    ('Andres Torres', 'andres.torres@lab.local', 3, 'activo');

-- Insertar notas
INSERT INTO notas (alumno_id, evaluacion, calificacion) VALUES
    (1, 'Examen Parcial', 85.50),
    (1, 'Proyecto Final', 92.00),
    (2, 'Examen Parcial', 78.00),
    (3, 'Examen Parcial', 91.25),
    (4, 'Examen Parcial', 88.75),
    (5, 'Examen Final', 95.00),
    (6, 'Examen Parcial', 72.50),
    (8, 'Examen Parcial', 84.00);

# Tickets de trabajo en Jira · PrestaLab

Proyecto PLAB (https://curso-lidr-ai4devs.atlassian.net). Generado desde `docs/plans/jira-mapping.json` y `docs/plans/tickets-jira-propuesta.md` (v6.2). Estado inicial de todos los tickets: Por hacer. 8 épicas, 29 historias, 94 subtareas, 149 puntos (MUST 71, SHOULD 60, habilitadores 18).

## Épicas

| Clave | Título | Tipo | Épica | Prioridad | Puntos | Estado |
|---|---|---|---|---|---|---|
| PLAB-1 | E0 Fundación técnica | Epic | - | - | - | Por hacer |
| PLAB-2 | E1 Autenticación y sesión | Epic | - | - | - | Por hacer |
| PLAB-3 | E2 Catálogo | Epic | - | - | - | Por hacer |
| PLAB-4 | E3 Solicitud de préstamo | Epic | - | - | - | Por hacer |
| PLAB-5 | E4 Ciclo del préstamo | Epic | - | - | - | Por hacer |
| PLAB-6 | E5 Notificaciones y sanciones | Epic | - | - | - | Por hacer |
| PLAB-7 | E6 Métricas y exportación | Epic | - | - | - | Por hacer |
| PLAB-8 | E7 Administración de cuentas | Epic | - | - | - | Por hacer |

## Tickets (orden de implementación)

| Clave | Título | Tipo | Épica | Prioridad | Puntos | Estado | Subtareas |
|---|---|---|---|---|---|---|---|
| PLAB-9 | [H0b] Infraestructura y despliegue | Historia | PLAB-1 (E0) | MUST (habilitador) | 5 | Por hacer | BACK PLAB-38, FRONT PLAB-39, TEST PLAB-40 |
| PLAB-10 | [H0] Fundación técnica | Historia | PLAB-1 (E0) | MUST (habilitador) | 8 | Por hacer | BACK PLAB-41, FRONT PLAB-42, TEST PLAB-43 |
| PLAB-11 | [HU-01a] Registro de cuenta de estudiante | Historia | PLAB-2 (E1) | MUST | 3 | Por hacer | DB PLAB-44, BACK PLAB-45, FRONT PLAB-46, TEST PLAB-47 |
| PLAB-12 | [HU-01b] Inicio de sesión y acceso según rol (con sesión base) | Historia | PLAB-2 (E1) | MUST | 8 | Por hacer | DB PLAB-48, BACK PLAB-49, FRONT PLAB-50, TEST PLAB-51 |
| PLAB-13 | [HU-02a] Crear y editar equipos del catálogo | Historia | PLAB-3 (E2) | MUST | 5 | Por hacer | DB PLAB-52, BACK PLAB-53, FRONT PLAB-54, TEST PLAB-55 |
| PLAB-14 | [HU-03] Consulta de disponibilidad (con esquema de préstamos) | Historia | PLAB-4 (E3) | MUST | 8 | Por hacer | DB PLAB-56, BACK PLAB-57, FRONT PLAB-58, TEST PLAB-59 |
| PLAB-15 | [HU-04] Solicitud de préstamo | Historia | PLAB-4 (E3) | MUST | 8 | Por hacer | BACK PLAB-60, FRONT PLAB-61, TEST PLAB-62 |
| PLAB-16 | [H-Alertas] Base de alertas dentro de la aplicación | Historia | PLAB-6 (E5) | MUST (habilitador) | 3 | Por hacer | DB PLAB-63, BACK PLAB-64, FRONT PLAB-65, TEST PLAB-66 |
| PLAB-17 | [HU-05a.1] Aprobar solicitudes | Historia | PLAB-5 (E4) | MUST | 8 | Por hacer | BACK PLAB-67, FRONT PLAB-68, TEST PLAB-69 |
| PLAB-18 | [HU-05a.2] Rechazar solicitudes con motivo | Historia | PLAB-5 (E4) | MUST | 3 | Por hacer | BACK PLAB-70, FRONT PLAB-71, TEST PLAB-72 |
| PLAB-19 | [HU-05a.3] Rechazo automático "Sin resolver a tiempo" con tarea programada | Historia | PLAB-5 (E4) | MUST | 3 | Por hacer | BACK PLAB-73, TEST PLAB-74 |
| PLAB-20 | [HU-05b] Registrar la entrega | Historia | PLAB-5 (E4) | MUST | 5 | Por hacer | BACK PLAB-75, FRONT PLAB-76, TEST PLAB-77 |
| PLAB-21 | [HU-05c] Registrar la devolución | Historia | PLAB-5 (E4) | MUST | 5 | Por hacer | DB PLAB-78, BACK PLAB-79, FRONT PLAB-80, TEST PLAB-81 |
| PLAB-22 | [HU-05d] Registrar la devolución con daños o pérdidas | Historia | PLAB-5 (E4) | MUST | 5 | Por hacer | BACK PLAB-82, FRONT PLAB-83, TEST PLAB-84 |
| PLAB-23 | [HU-02b] Dar de baja un equipo | Historia | PLAB-3 (E2) | MUST | 5 | Por hacer | BACK PLAB-85, FRONT PLAB-86, TEST PLAB-87 |
| PLAB-24 | [HU-05e] Cierre automático de préstamos no recogidos | Historia | PLAB-5 (E4) | MUST | 5 | Por hacer | BACK PLAB-88, FRONT PLAB-89, TEST PLAB-90 |
| PLAB-25 | [H-Demo] Datos de demostración | Historia | PLAB-1 (E0) | MUST (habilitador) | 2 | Por hacer | BACK PLAB-91, TEST PLAB-92 |
| PLAB-26 | [SH-09] Duración de la sesión por rol e inactividad | Historia | PLAB-2 (E1) | SHOULD | 8 | Por hacer | BACK PLAB-93, FRONT PLAB-94, TEST PLAB-95 |
| PLAB-27 | [SH-11] Bloqueo temporal por intentos fallidos | Historia | PLAB-2 (E1) | SHOULD | 5 | Por hacer | DB PLAB-96, BACK PLAB-97, FRONT PLAB-98, TEST PLAB-99 |
| PLAB-28 | [SH-10] Sesión única por usuario | Historia | PLAB-2 (E1) | SHOULD | 5 | Por hacer | BACK PLAB-100, FRONT PLAB-101, TEST PLAB-102 |
| PLAB-29 | [SH-02] Marcado de préstamos vencidos | Historia | PLAB-6 (E5) | SHOULD | 5 | Por hacer | BACK PLAB-103, FRONT PLAB-104, TEST PLAB-105 |
| PLAB-30 | [SH-03] Sanciones por retraso | Historia | PLAB-6 (E5) | SHOULD | 5 | Por hacer | DB PLAB-106, BACK PLAB-107, FRONT PLAB-108, TEST PLAB-109 |
| PLAB-31 | [SH-06] Alerta de préstamo próximo a vencer | Historia | PLAB-6 (E5) | SHOULD | 3 | Por hacer | BACK PLAB-110, FRONT PLAB-111, TEST PLAB-112 |
| PLAB-32 | [SH-07] Cancelar mi solicitud | Historia | PLAB-4 (E3) | SHOULD | 5 | Por hacer | BACK PLAB-113, FRONT PLAB-114, TEST PLAB-115 |
| PLAB-33 | [SH-01] Historial "Mis préstamos" | Historia | PLAB-4 (E3) | SHOULD | 3 | Por hacer | BACK PLAB-116, FRONT PLAB-117, TEST PLAB-118 |
| PLAB-34 | [SH-12] Cierre de la sesión de otra cuenta por el ADMIN | Historia | PLAB-8 (E7) | SHOULD | 3 | Por hacer | BACK PLAB-119, FRONT PLAB-120, TEST PLAB-121 |
| PLAB-35 | [SH-08] Baja de cuentas | Historia | PLAB-8 (E7) | SHOULD | 8 | Por hacer | DB PLAB-122, BACK PLAB-123, FRONT PLAB-124, TEST PLAB-125 |
| PLAB-36 | [SH-04] Panel de métricas | Historia | PLAB-7 (E6) | SHOULD | 5 | Por hacer | BACK PLAB-126, FRONT PLAB-127, TEST PLAB-128 |
| PLAB-37 | [SH-05] Exportación a CSV | Historia | PLAB-7 (E6) | SHOULD | 5 | Por hacer | BACK PLAB-129, FRONT PLAB-130, TEST PLAB-131 |

# Propuesta de tickets Jira · PrestaLab (paso 1 de /crear-tickets-jira)

Borrador revisado (v6.1, tras la revisión de `arquitecto-sw` de la v6 y las decisiones del usuario sobre datos de demostración). No se ha creado nada en Jira. Fuentes: `docs/historias-de-usuario.md` (23 historias; el cuerpo y los Gherkin se tomarán de ese archivo por ID al crear los tickets), `docs/adr/0001-arquitectura.md` rev. 7d (módulos `shared`, `auth`, `catalog`, `loans`, `notifications`, `reports`; DTOs `*Request`/`*Response`; controller, service, repository; `ActiveSessionInterceptor`; Anexo A de endpoints y Anexo D de datos) y la sección 3 del readme.

Convenciones:
- Puntos en escala Fibonacci (1, 2, 3, 5, 8, 13). MUST = Must y SHOULD = Should del archivo de historias. Los habilitadores técnicos (H0, H0b, H-Alertas y H-Demo) llevan prioridad MUST.
- Cada historia lleva subtareas `[DB]`, `[BACK]`, `[FRONT]` y `[TEST]` con título concreto; las omitidas se justifican.
- Migraciones: nunca se fija número. Cada una se nombra `V<siguiente>__<nombre>.sql` y el número se asigna al implementar con `/crear-migracion`. Las semillas van en `classpath:db/seed`, solo en los perfiles `dev` y `demo`, nunca en `db/migration` ni en `prod` a secas.
- Los Gherkin no se copian aquí: cada ticket referencia la historia por ID.
- Trazabilidad: HU-05a.1, HU-05a.2 y HU-05a.3 provienen de la misma historia HU-05a del archivo de historias; la clave de trazabilidad es HU-05a y cada ticket toma solo los escenarios que se le asignan.

## Definición de terminado (aplica a toda subtarea)

- Toda creación o cambio de esquema se hace con una migración Flyway `V<siguiente>__nombre.sql` (nunca con `ddl-auto`, a mano ni con `DROP`); las semillas de datos de ejemplo no son migraciones.
- Toda subtarea `[BACK]` que cambie el contrato REST regenera `docs/api/openapi.yaml` en el mismo PR; si cambia un flujo, actualiza los diagramas de `docs/diagrams/` y la sección 4 del readme.
- Toda subtarea `[TEST]` incluye `OpenApiContractIT` y `ArchitectureTest` en verde (se ejecutan en `/verificar-calidad` y en la CI) además de las pruebas propias.
- Los E2E de Playwright (headless) dejan evidencias en `docs/testing/playwright/<funcionalidad>/`.

## a) Épicas

| Épica | Tickets | Criterio |
|---|---|---|
| E0 Fundación técnica | H0b, H0, H-Demo | Piezas transversales que ninguna historia posee: primero la infraestructura (proyectos, contenedores, CI y despliegue), después el código base (`shared`, configuración, base del frontend) y, al final del ciclo, los datos de demostración del entorno de evaluación. |
| E1 Autenticación y sesión | HU-01a, HU-01b, SH-09, SH-10, SH-11 | Flujo F1: registro, inicio de sesión con sesión base, vida de la sesión, sesión única y bloqueo por intentos. Módulo `auth`. |
| E2 Catálogo | HU-02a, HU-02b | Flujo F2: alta, edición y baja lógica de equipos. Módulo `catalog`. |
| E3 Solicitud de préstamo | HU-03, HU-04, SH-01, SH-07 | Flujo F3: consultar disponibilidad, solicitar, ver y filtrar mis préstamos y cancelar. |
| E4 Ciclo del préstamo | HU-05a.1, HU-05a.2, HU-05a.3, HU-05b, HU-05c, HU-05d, HU-05e | Flujo F4: aprobar o rechazar, entregar, devolver (con y sin daños) y cerrar los no recogidos. |
| E5 Notificaciones y sanciones | H-Alertas, SH-02, SH-03, SH-06 | Alertas dentro de la aplicación, vencidos, bloqueo por retraso y aviso de próximo a vencer. Módulos `notifications` y `loans`. |
| E6 Métricas y exportación | SH-04, SH-05 | Reportes del ADMIN y del ENCARGADO. Módulo `reports`. |
| E7 Administración de cuentas | SH-08, SH-12 | Acciones del ADMIN sobre cuentas ajenas: baja y cierre de sesión. |

Ajustes: HU-03 va en E3 porque el readme la agrupa en el flujo de solicitud y su `[DB]` crea el esquema de préstamos que usa todo E3 y E4. SH-12 va en E7 porque la ejecuta el ADMIN sobre otra cuenta. H-Alertas va en E5 aunque se construye antes de HU-05a.3, porque la usan SH-02 y SH-06. E0, E2 y E7 son pequeñas, pero cada una tiene un propósito, módulo o actor distinto; ninguna queda vacía.

## b) Tickets

| ID | Título | Épica | Prioridad | Pts | Dependencias | Gherkin | Resumen |
|---|---|---|---|---|---|---|---|
| H0b | Infraestructura y despliegue | E0 | MUST | 5 | Ninguna | n/a | Proyectos, docker-compose, Dockerfile.vercel, vercel.json, CI y prueba de humo de salud. |
| H0 | Fundación técnica | E0 | MUST | 8 | H0b | n/a | Errores, trazas, configuración, contrato OpenAPI, pruebas de arquitectura y base del frontend. |
| HU-01a | Registro de cuenta de estudiante | E1 | MUST | 3 | H0, H0b | 5 | Registro con correo institucional y contraseña válida; rol ESTUDIANTE. |
| HU-01b | Inicio de sesión y acceso según rol (con sesión base) | E1 | MUST | 8 | H0, HU-01a | 6 | Inicio de sesión con "Credenciales inválidas" único, sesión con refresh token y acceso por rol. |
| HU-02a | Crear y editar equipos del catálogo | E2 | MUST | 5 | HU-01b; soft: HU-05a.1 (escenario 4) | 6 | Alta y edición con código único, unidades y estado. |
| HU-03 | Consulta de disponibilidad (con esquema de préstamos) | E3 | MUST | 8 | HU-02a | 11 | Búsqueda con unidades disponibles por rango; crea el esquema completo de préstamos. |
| HU-04 | Solicitud de préstamo | E3 | MUST | 8 | HU-03 | 16 | Solicitud (máx. 7 días, límite de 3) y vista de mis solicitudes. |
| H-Alertas | Base de alertas dentro de la aplicación | E5 | MUST | 3 | HU-04 | n/a | Tabla de alertas, evento de cambio de estado, bandeja y campana. |
| HU-05a.1 | Aprobar solicitudes | E4 | MUST | 8 | HU-04 | 14 (escenarios 1, 4 a 12, 14, 15, 17, 18 de HU-05a) | El encargado aprueba con disponibilidad, horario y plazo de recogida; crea la bandeja. |
| HU-05a.2 | Rechazar solicitudes con motivo | E4 | MUST | 3 | HU-04, HU-05a.1 (fuerte: su diálogo vive en `features/loans/inbox` y la bandeja usa `GET /api/loans`, que crea HU-05a.1; débil solo si el rechazo se prueba únicamente por API) | 3 (escenarios 2, 3, 13 de HU-05a) | Rechazo con motivo de 10 a 250 caracteres; un APROBADO no se rechaza. |
| HU-05a.3 | Rechazo automático "Sin resolver a tiempo" con tarea programada | E4 | MUST | 3 | HU-04, H-Alertas, H0b (`vercel.json`), H0 (`shared`) | 1 (escenario 16 de HU-05a) | Tarea diaria que rechaza SOLICITADO con inicio pasado; endpoint interno y Vercel Cron. |
| HU-05b | Registrar la entrega | E4 | MUST | 5 | HU-05a.1 | 12 | Entrega dentro del plazo de recogida. |
| HU-05c | Registrar la devolución | E4 | MUST | 5 | HU-05b | 9 | Devolución BUENO o CON_DESPERFECTOS; libera unidades. |
| HU-05d | Registrar la devolución con daños o pérdidas | E4 | MUST | 5 | HU-05c | 6 | DAÑADO o PERDIDO restan del total. |
| HU-02b | Dar de baja un equipo | E2 | MUST | 5 | HU-02a, HU-04; soft: HU-05a.1, HU-05b | 6 | Baja lógica y rechazo de sus SOLICITADO. |
| HU-05e | Cierre automático de préstamos no recogidos | E4 | MUST | 5 | HU-05a.1, H-Alertas, HU-05a.3 (`InternalJob`) | 12 | Vencido el plazo, APROBADO pasa a RECHAZADO "No recogido" y notifica. |
| H-Demo | Datos de demostración | E0 | MUST | 2 | HU-01b, HU-02a, HU-05d, HU-05e | n/a | Sembrador de préstamos de ejemplo (perfiles `dev` y `demo`) que cubre todos los estados del ciclo. |
| SH-09 | Duración de la sesión por rol e inactividad | E1 | SHOULD | 8 | HU-01b | 9 | Ajusta la vida máxima por rol (1 h estudiante), añade rotación por actividad con 30 min de inactividad y aviso de fin. |
| SH-11 | Bloqueo temporal por intentos fallidos | E1 | SHOULD | 5 | HU-01b | 8 | 3 fallos bloquean 15 min; 10 por origen; mensajes sin revelar datos. |
| SH-10 | Sesión única por usuario | E1 | SHOULD | 5 | HU-01b | 4 | Una sola sesión activa; el aviso permite cerrar la otra. |
| SH-02 | Marcado de préstamos vencidos | E5 | SHOULD | 5 | HU-05b, H-Alertas | 5 | A las 00:05 el ENTREGADO atrasado pasa a VENCIDO y alerta a los encargados. |
| SH-03 | Sanciones por retraso | E5 | SHOULD | 5 | HU-04, HU-05c; soft: SH-02 | 8 | La devolución con retraso bloquea nuevas solicitudes (1 día por día, máx. 15). |
| SH-06 | Alerta de préstamo próximo a vencer | E5 | SHOULD | 3 | HU-05b, H-Alertas, HU-05a.3 (job diario) | 6 | Alerta al titular el día antes de la fecha fin efectiva. |
| SH-07 | Cancelar mi solicitud | E3 | SHOULD | 5 | HU-04, HU-05a.1 | 11 | Cancelar SOLICITADO o APROBADO mientras pueda resolverse. |
| SH-01 | Historial "Mis préstamos" | E3 | SHOULD | 3 | HU-04 | 5 | Filtros por estado y fecha de inicio. |
| SH-12 | Cierre de la sesión de otra cuenta por el ADMIN | E7 | SHOULD | 3 | HU-01b | 6 | El ADMIN cierra la sesión de una cuenta con corte inmediato. |
| SH-08 | Baja de cuentas | E7 | SHOULD | 8 | HU-01b, HU-04 | 13 | El ADMIN busca y da de baja cuentas sin préstamos en curso. |
| SH-04 | Panel de métricas | E6 | SHOULD | 5 | HU-05b; soft: SH-02 | 7 | Ranking, vencidos y ocupación por rango. |
| SH-05 | Exportación a CSV | E6 | SHOULD | 5 | HU-02a, HU-04 | 5 | Descarga de inventario y préstamos con filtros opcionales. |

Totales: **29 tickets** (25 de historias y 4 habilitadores; las 23 historias del archivo se convierten en 25 tickets porque HU-05a se divide en tres), 8 épicas, **149 puntos** (tickets de historias MUST 71 en 13, SHOULD 60 en 12, habilitadores 18), 194 escenarios Gherkin (MUST 107, SHOULD 87), **94 subtareas**.

Cambios de puntos frente a la v1: HU-01b sube de 5 a 8 (absorbe la sesión base); HU-05a pasa de 13 a 14 repartidos en HU-05a.1 (8), HU-05a.2 (3) y HU-05a.3 (3); HU-05e baja de 8 a 5 (H-Alertas absorbe la infraestructura); SH-09 baja de 13 a 8 y deja de dividirse; H0, H0b, H-Alertas y H-Demo son nuevos.

Justificación breve: 3 puntos = caso simple con una pantalla pequeña o un job; 5 = caso de uso con reglas propias y pantalla; 8 = reglas de calendario o concurrencia, mucha interfaz o infraestructura transversal.

## c) Subtareas

Rutas: backend `co.prestalab.<módulo>`; frontend `features/<módulo>` y `core/`; E2E en `e2e/`.

### H0b · Infraestructura y despliegue (E0, 5 puntos, primer ticket, sin dependencias)
- [BACK] Proyecto `backend/` Spring Boot 3.5 con Java 21 y Maven, con el orden de procesadores de anotaciones Lombok, `lombok-mapstruct-binding` y MapStruct; `backend/Dockerfile.vercel` (JRE 21, usuario sin privilegios); `docker-compose.yml` con MySQL 8 (3306), API (8080) y web (4200); `.env.example` con la plantilla local (perfil `dev`), que ya incluye el nombre `SEED_PASSWORD` (vacío); documentación de las variables de Vercel del entorno de evaluación (`SPRING_PROFILES_ACTIVE=prod,demo` y el valor de `SEED_PASSWORD`, este último como secreto; ADR 2.8): el valor `prod,demo` y la contraseña no van en `.env.example`; `vercel.json` con `/api/*` hacia el backend y `/*` hacia el frontend (la entrada del cron diario se añade en HU-05a.3).
- [FRONT] Proyecto `frontend/` Angular standalone con TypeScript estricto, `proxy.conf.json` hacia `:8080` y `frontend/Dockerfile.vercel` (nginx que reenvía `/api`).
- [TEST] Proyecto `e2e/` con Playwright headless; `.github/workflows/ci.yml` que ejecuta las suites que existan (unitarias, integración y E2E; `ArchitectureTest` y `OpenApiContractIT` se suman con H0); prueba de humo de `/desplegar-vercel` solo sobre `GET /api/actuator/health`.
- Sin `[DB]`: solo levanta MySQL local; las tablas llegan con las historias.

### H0 · Fundación técnica (E0, 8 puntos, depende de H0b)
- [BACK] `shared`: `GlobalExceptionHandler`, `ProblemDetailFactory`, `ErrorCode` con los mensajes exactos de las historias, `RequestTraceFilter`, `PageResponse`, `BaseEntity`, `Clock` de `America/Bogota`, `CacheConfig` (Caffeine) y `MapperConfig`. Configuración: Flyway con `ddl-auto=validate`, pool Hikari de 5 con READ COMMITTED, actuator en `/api/actuator` solo con `health`, CORS, `ProblemDetailAuthenticationEntryPoint` y `ProblemDetailAccessDeniedHandler`; springdoc en `/api/docs` con `OpenApiCustomizer` común y primer `docs/api/openapi.yaml`; perfiles `dev`, `demo` y `prod` (ADR 2.8 y 2.6.7) con Flyway leyendo siempre `db/migration` y `classpath:db/seed` solo en `dev` y `demo`.
- [FRONT] `core/`: `ApiClient` sobre `environment.apiUrl`, `errorInterceptor`, layout base con espacio para la campana, rutas perezosas por feature y modelos `ProblemDetail` y `PageResponse<T>`.
- [TEST] `OpenApiContractIT`, `ArchitectureTest` (ArchUnit; se suman a la CI de H0b) y una prueba del `GlobalExceptionHandler`; prueba de humo de `/api/docs` y `/api/docs/v3/api-docs` y primer `@smoke`; base de evidencias en `e2e/support/evidence.ts`.
- Sin `[DB]`: no hay tablas propias; las migraciones llegan con la primera historia que las necesita.

### HU-01a · Registro de cuenta de estudiante
- [DB] `V<siguiente>__users.sql`: `users` (correo único, hash, rol, `deleted_at`) con el índice `(role, deleted_at)` ya desde la creación.
- [BACK] `auth`: `AuthController.register`, `RegisterRequest`/`UserResponse`, `AuthService` (dominio de correo, contraseña de 8 caracteres con letra y número, BCrypt, rol ESTUDIANTE), `UserRepository` y limitador de registros por IP (R-21).
- [FRONT] `features/auth/register`: formulario reactivo ("Ya existe una cuenta asociada a ese correo").
- [TEST] Unitarias de `AuthService`; integración con Testcontainers (correo duplicado, limitador); E2E `registro`.

### HU-01b · Inicio de sesión y acceso según rol, con sesión base (8 puntos)
- [DB] `V<siguiente>__refresh_tokens.sql`: tabla completa del Anexo D.1 (`BINARY(32)`, `previous_token_hash`, `revoke_reason` completo, `revoked_by`, `active_user_id` con índice único, CHECK). Las cuentas de demostración no van en SQL: las crea el `DemoAccountsSeeder` del `[BACK]` (la contraseña exige BCrypt).
- [BACK] `auth`: `POST /api/auth/login` (`LoginRequest`/`AuthResponse`, mismo "Credenciales inválidas" en todos los fallos, con hash ficticio y piso de tiempo `login-failure-min-duration` de 0,5 s, D-25), `/refresh` con rotación y detección de reutilización, `/logout`, `GET /api/auth/me`, `DemoAccountsSeeder` en `auth` (perfiles `dev` y `demo`, idempotente: `admin.demo@institucion.edu`, `encargado1.demo@` y `encargado2.demo@`, `estudiante1.demo@` a `estudiante3.demo@`, con el BCrypt de `SEED_PASSWORD` calculado al arrancar; ADR 2.8), `SecurityConfig` (resource server HS256, `@PreAuthorize`), `UserMdcFilter` (pone `userId` y `role` en el MDC y en un atributo de la petición) y `ActiveSessionInterceptor` en toda petición autenticada que falla cerrado. La vida máxima de la sesión es configurable y en esta historia vale 8 horas para todos los roles; el refresh token vence a los 30 minutos de la última rotación. ADMIN inicial en producción (ADR 2.6.8, D-26): `AdminBootstrapRunner` idempotente, solo si no hay ningún ADMIN activo y con bloqueo con nombre entre instancias, que lo crea con las variables `BOOTSTRAP_ADMIN_EMAIL`, `BOOTSTRAP_ADMIN_NAME` y `BOOTSTRAP_ADMIN_PASSWORD_HASH` (aprobado por el usuario, P-10; RN-01a.4).
- [FRONT] `core/auth`: `AuthService` con signal, `authInterceptor` con manejo genérico de `SESSION_EXPIRED`, `SESSION_REPLACED` y `SESSION_INVALIDATED` (cierra la sesión local y muestra el `detail`), renovación reactiva single-flight con reintento único, `authGuard` y `roleGuard`; `features/auth/login`.
- [TEST] Unitarias de credenciales, roles y rotación; integración (reutilización de token, corte inmediato con `ActiveSessionInterceptor`, falla cerrada: 500 si la base no responde, acceso denegado por rol); `DemoAccountsSeeder` idempotente, sin cuentas si falta `SEED_PASSWORD` o si no cumple RN-01a.3, y `prod` sin `demo` no siembra; E2E `login` y `@smoke` de inicio, renovación y cierre.

### HU-02a · Crear y editar equipos del catálogo
- [DB] `V<siguiente>__catalog.sql`: `categories` y `equipment` (código único, unidades, `status`, `version`, `deleted_at`); las categorías de referencia se insertan en la propia `V<siguiente>__catalog.sql` (se aplica también en `prod`); `R__demo_catalog.sql` en `classpath:db/seed` (solo `dev` y `demo`, no es migración) trae únicamente equipos de ejemplo.
- [BACK] `catalog`: `EquipmentController` (`GET /api/equipment/inventory`, `GET /api/equipment/{id}`, `POST`, `PUT`), `GET /api/categories` servido por `CategoryService.findAll()` con `@Cacheable("categories")` y cabecera `Cache-Control: private, max-age=300` en la respuesta (sin caché en el controlador), `EquipmentRequest`/`EquipmentResponse`, `EquipmentService` (código único, unidades >= 1, no reducir por debajo de lo comprometido), `@CacheEvict` de `equipmentSummaries`. Implementación mínima de `EquipmentUsageService` en `loans` (sin préstamos aún) para que `catalog` compile y funcione hasta HU-04.
- [FRONT] `features/catalog/inventory`: tabla y formulario de alta y edición para ENCARGADO y ADMIN.
- [TEST] Unitarias de reglas RN-02a.x; integración (código duplicado; reducción bloqueada, que gana dependencia débil con HU-05a.1); E2E `gestion-catalogo`.

### HU-03 · Consulta de disponibilidad, con esquema de préstamos (8 puntos)
- [DB] `V<siguiente>__loans.sql`: esquema completo de préstamos: `loans` con todas las columnas (hitos, `pickup_deadline`, `effective_end_date` generada, motivos) y enum de estados, más `loan_items` y `loan_status_history`, con todos los índices y CHECK de la sección 3 para las tres tablas: `idx_loan_items_equipment_loan`, `idx_loans_student_status_start`, `idx_loans_status_start`, `idx_loans_status_pickup`, `idx_loans_status_effective_end`, los índices de las cuatro columnas de actor y el CHECK de transiciones del historial.
- [BACK] `catalog`: `GET /api/equipment` paginado (búsqueda parcial, categoría, rango); rango en el DTO con `@ValidDateRange` y reloj inyectado (máx. 7 días, inicio no pasado); `EquipmentUsageService.retainedUnits` en `loans` con `RetentionRange`; un APROBADO con plazo vencido no retiene (lectura A-12); `@Cacheable` solo de `equipmentSummaries`, nunca de disponibilidad.
- [FRONT] `features/catalog/search`: buscador, selector de rango con las mismas reglas y tarjetas con "No disponible".
- [TEST] Unitarias de `RetentionRange` con `Clock.fixed`; integración (APROBADO, ENTREGADO, fin e inicio el mismo día, plazo vencido); E2E `consultar-disponibilidad`.

### HU-04 · Solicitud de préstamo
- [DB] Omitida: el esquema completo de préstamos se crea en HU-03.
- [BACK] `loans`: `POST /api/loans`, `LoanRequest`/`LoanResponse`, `LoanService.create` (`@ValidDateRange`, `FOR UPDATE` al estudiante con `UserDirectoryService.lockStudentForUpdate` y `FOR SHARE` a los equipos, límite de 3, "Unidades insuficientes"), `LoanStateMachine` y `LoanTransitionService`; `GET /api/loans/mine`, `GET /api/loans/{id}` y `GET /api/loans/mine/eligibility` (crea la respuesta con préstamos en curso y límite; SH-03 la amplía con `blockedUntil` y vencido pendiente); una SOLICITADO con inicio pasado no cuenta en el límite (lectura A-12).
- [FRONT] `features/loans/request` (carrito con cantidades) y `features/loans/my-requests` (estado y motivo de rechazo).
- [TEST] Unitarias de reglas y de la máquina de estados; integración (concurrencia, límite de 3, inicio pasado); E2E `solicitar-prestamo`.

### H-Alertas · Base de alertas dentro de la aplicación (E5, 3 puntos)
- [DB] `V<siguiente>__notifications.sql`: `notifications` con único por destinatario, préstamo y tipo (`uk_notifications_recipient_loan_type`).
- [BACK] `loans`: publica `LoanStatusChangedEvent` desde `LoanTransitionService`; `notifications`: oyente síncrono, `GET /api/notifications`, `GET /api/notifications/unread-count`, `POST /api/notifications/{id}/read` (404 `NOTIFICATION_NOT_FOUND` si es ajena).
- [FRONT] `features/notifications` y la campana con contador en `core/layout`; el contador periódico se marca con `HttpContext` como consulta en segundo plano para que no cuente como actividad del usuario.
- [TEST] Unitarias del oyente; integración (idempotencia por el único, alerta ajena responde 404); E2E `alertas` (campana y lectura).

Los tres tickets siguientes provienen de la misma historia HU-05a del archivo de historias (clave de trazabilidad: HU-05a); todos son de la épica E4 y no llevan `[DB]` porque las columnas de aprobación y rechazo ya están en el esquema de HU-03.

### HU-05a.1 · Aprobar solicitudes (8 puntos, depende de HU-04)
- [DB] Omitida: las columnas de aprobación ya están en el esquema de HU-03.
- [BACK] `loans`: `POST /api/loans/{id}/approval`, `ServiceCalendar` y `PickupDeadlinePolicy` en `domain`, `LoanService.approve` (bloquea el préstamo y luego los equipos, no `users`; disponibilidad con rango efectivo; horario de 8:00 AM a 5:00 PM; plazo de recogida) y `GET /api/loans` paginado para la bandeja de ENCARGADO y ADMIN.
- [FRONT] `features/loans/inbox`: bandeja con acción aprobar y mensajes de horario, plazo y unidades.
- [TEST] Unitarias de `PickupDeadlinePolicy` (3:00 PM, 3:01 PM, 5:00 PM, fuera de horario); integración (última unidad, rango ya iniciado, retención del plazo que cruza de día); E2E `ciclo-prestamo` (aprobar).

### HU-05a.2 · Rechazar solicitudes con motivo (3 puntos, depende de HU-04 y de HU-05a.1)
- [DB] Omitida: el motivo de rechazo ya está en el esquema de HU-03.
- [BACK] `loans`: `POST /api/loans/{id}/rejection` con `LoanRejectionRequest` (motivo de 10 a 250 caracteres) y regla de que un APROBADO no se rechaza.
- [FRONT] Diálogo de rechazo con motivo en `features/loans/inbox`.
- [TEST] Unitarias del motivo; integración (estado no pendiente); E2E `ciclo-prestamo` (rechazar).

### HU-05a.3 · Rechazo automático "Sin resolver a tiempo" con tarea programada (3 puntos, depende de H-Alertas, H0b y H0)
- [DB] Omitida: usa el esquema de HU-03 y la tabla de H-Alertas.
- [BACK] `loans`: `DailyLoanReviewJob` (00:05) que rechaza las SOLICITADO con inicio pasado con una transacción por préstamo e idempotente, y que implementa `InternalJob` con el nombre `daily-review` dentro del grupo `daily`. `shared`: `InternalJobController` e `InternalJob` (no en `loans`) con `GET /api/internal/jobs/{name}` (`daily-review`, `due-soon` y `pickup-expiration`; 404 para nombres desconocidos solo después de validar `CRON_SECRET`; 401 `INVALID_CRON_SECRET`) según el punto 2 de 2.5 del ADR. `GET /api/internal/jobs/daily` ejecuta todo lo registrado en el grupo `daily` (`due-soon` se suma cuando SH-06 lo registre) y es la única entrada de Vercel Cron, añadida al `vercel.json` creado en H0b (ADR 2.5, puntos 3 y 4, P-11). Alerta al estudiante vía H-Alertas.
- [FRONT] Omitida: el aviso al estudiante aparece en la campana de H-Alertas; no hay pantalla nueva.
- [TEST] Unitarias con `Clock.fixed`; integración de idempotencia y del secreto; si una tarea del grupo falla, la siguiente se ejecuta igual y la respuesta es 500; un nombre desconocido da 404 solo con el secreto correcto (con un `InternalJob` falso, como sugiere 5.2 del ADR); E2E `ciclo-prestamo` (aviso).

### HU-05b · Registrar la entrega (depende de HU-05a.1)
- [DB] Omitida: `delivered_by` y `delivered_at` están en el esquema de HU-03.
- [BACK] `loans`: `POST /api/loans/{id}/delivery`, `LoanService.deliver` (plazo de recogida, "Unidades insuficientes" si el total ya no cubre); `effective_end_date` es columna generada de solo lectura: no se asigna desde la aplicación.
- [FRONT] Acción "Registrar entrega" en `features/loans/inbox` (aprobados).
- [TEST] Unitarias de plazo (7:59, 9:59, 10:00, cruce de día); integración de retención tras entrega; E2E `ciclo-prestamo` (entrega).

### HU-05c · Registrar la devolución
- [DB] `V<siguiente>__loan_item_returns.sql`: `loan_item_returns` (cantidades por estado y observación).
- [BACK] `loans`: `POST /api/loans/{id}/return`, `LoanReturnRequest`/`LoanReturnResponse`, `LoanService.registerReturn` (suma igual a lo prestado, observación con CON_DESPERFECTOS, ENTREGADO o VENCIDO).
- [FRONT] Formulario de devolución en `features/loans/returns`.
- [TEST] Unitarias de validación de cantidades; integración de liberación de disponibilidad; E2E `ciclo-prestamo` (devolución).

### HU-05d · Registrar la devolución con daños o pérdidas
- [DB] Omitida: usa `loan_item_returns` y `equipment.total_units` existentes.
- [BACK] `loans`: ampliar `registerReturn` con `EquipmentCatalogService.decreaseTotalUnits`, equipo "No disponible" con total 0 y `affectedApprovedLoans` en la respuesta.
- [FRONT] Estados DAÑADO y PERDIDO y aviso de aprobados afectados en `features/loans/returns`.
- [TEST] Unitarias del total; integración (total 0, aprobado afectado); E2E `ciclo-prestamo` (daño).

### HU-02b · Dar de baja un equipo
- [DB] Omitida: la baja es `deleted_at` ya creada en HU-02a.
- [BACK] `catalog`: `DELETE /api/equipment/{id}` y `EquipmentService.retire` con `EquipmentUsageService` (`hasActiveLoans`, `lockLoansForRetirement`, `rejectPendingRequests` con "Equipo dado de baja"); `@CacheEvict` de `equipmentSummaries`.
- [FRONT] Botón y diálogo de baja en `features/catalog/inventory`.
- [TEST] Unitarias e integración (con préstamo activo, con SOLICITADO, solicitud multi-equipo); E2E `gestion-catalogo` (baja).

### HU-05e · Cierre automático de préstamos no recogidos (5 puntos)
- [DB] Omitida: la tabla de alertas se crea en H-Alertas.
- [BACK] `loans`: `PickupExpirationJob` (cada minuto) e idempotente, que implementa `InternalJob` con el nombre `pickup-expiration` y sin grupo, disparado por `@Scheduled`; tendrá cron propio en `vercel.json` solo si el plan de Vercel admite esa frecuencia (ADR 2.5, punto 4); notifica a todos los ENCARGADO y al titular con el motivo "No recogido" vía H-Alertas.
- [FRONT] Alerta "No recogido" visible en la campana (reutiliza H-Alertas); ajuste de textos en `features/notifications`.
- [TEST] Unitarias con `Clock.fixed` (10:00 exactas, 9:59, 4:00 PM, 5:00 PM, 1 día); integración de idempotencia; E2E `ciclo-prestamo` (cierre y aviso).

### H-Demo · Datos de demostración (E0, 2 puntos, después de HU-05e)
- [DB] Omitida: el esquema ya existe; los datos de ejemplo no son migraciones y se crean desde código con los perfiles `dev` y `demo` (las semillas SQL de catálogo viven en `classpath:db/seed`, en HU-02a).
- [BACK] `loans`: `DemoLoansSeeder` (perfiles `dev` y `demo`, ADR 2.8, D-28) que inserta los préstamos de ejemplo por los repositorios de `loans` y no por los servicios del dominio (estos rechazan inicios pasados y operaciones fuera de horario, y no pueden crear DEVUELTO, VENCIDO, RECHAZADO ni ENTREGADO desde ayer), con hitos, `loan_status_history` y `loan_item_returns` coherentes con los CHECK de la sección 3 y fechas relativas al `Clock`; idempotente y sin borrar nunca nada; cubre los siete estados (SOLICITADO, APROBADO, RECHAZADO, CANCELADO, ENTREGADO, VENCIDO y DEVUELTO), sin pasar de 3 préstamos en curso por estudiante y con un estudiante que tiene un VENCIDO sin devolver. Usa las cuentas de `DemoAccountsSeeder` (HU-01b) y el catálogo de HU-02a.
- [FRONT] Omitida: no añade pantallas; los datos se ven en las vistas existentes.
- [TEST] Integración con Testcontainers de los perfiles `dev` y `demo`: los datos insertados cumplen todos los CHECK de la sección 3; ejecutar el sembrador dos veces no duplica, respeta el límite de 3 en curso y deja al menos un préstamo por estado; prueba de que no se activa en `prod` a secas.

### SH-09 · Duración de la sesión por rol e inactividad (8 puntos)
- [DB] Omitida: `refresh_tokens` se crea completa en HU-01b.
- [BACK] `auth`: ajusta la vida máxima configurable de HU-01b por rol (1 h estudiante, 8 h encargado y ADMIN) en `session_expires_at`, inactividad de 30 min con rotación por actividad y textos "Tu sesión expiró" y "Tu sesión ya no es válida".
- [FRONT] `core/auth`: rotación por actividad (máx. una por minuto), cierre local a los 30 min, aviso 5 min antes del fin y serialización entre pestañas.
- [TEST] Unitarias de expiración con `Clock.fixed`; integración (inactividad 9:10 y 9:41; corte inmediato tras baja); prueba de que el contador de alertas en segundo plano no cuenta como actividad; E2E `sesion`.

### SH-11 · Bloqueo temporal por intentos fallidos
- [DB] `V<siguiente>__login_attempts.sql`: `failed_login_attempts`, `login_locked_until` y `last_failed_login_at` en `users`.
- [BACK] `auth`: contador y bloqueo de 15 minutos en `AuthService`, `LoginRateLimiter` por origen y por instancia (10 fallos en una ventana fija de 15 min desde el primer fallo de la serie) con 429 `TOO_MANY_ATTEMPTS` y respuesta "Credenciales inválidas" idéntica en todos los casos.
- [FRONT] Mensajes y nota fija del bloqueo en `features/auth/login`.
- [TEST] Unitarias del contador y del limitador con `Clock.fixed`; integración (cuenta inexistente igual que existente); prueba de equivalencia de tiempos entre los casos de fallo; E2E `login` (bloqueo).

### SH-10 · Sesión única por usuario
- [DB] Omitida: el índice único de sesión activa (`active_user_id`) se crea en HU-01b.
- [BACK] `auth`: 409 `ACTIVE_SESSION_EXISTS` en el inicio de sesión, `replaceExistingSession` y desplazamiento con `REPLACED` y 401 `SESSION_REPLACED`.
- [FRONT] Diálogo "Ya tienes una sesión activa en otro lugar" con las opciones cerrar la otra o cancelar.
- [TEST] Unitarias; integración de carrera de dos inicios de sesión; E2E `sesion` (dos contextos).

### SH-02 · Marcado de préstamos vencidos
- [DB] Omitida: usa el estado VENCIDO del esquema de HU-03 y H-Alertas.
- [BACK] `loans`: ampliar `DailyLoanReviewJob` (00:05) para pasar a VENCIDO los ENTREGADO con fecha fin efectiva anterior a hoy; alerta a los encargados con equipo, estudiante, cantidad y días de retraso vía H-Alertas; cierre al devolver.
- [FRONT] Lista de vencidos y alertas en `features/loans/inbox` y en la campana.
- [TEST] Unitarias de fecha fin efectiva; integración del job idempotente; E2E `vencidos`.

### SH-03 · Sanciones por retraso
- [DB] `V<siguiente>__sanctions.sql`: `sanctions` sin columna de estudiante, con `loan_id` único, `days_late`, `starts_on` y `ends_on`.
- [BACK] `loans`: `SanctionService` al devolver con retraso (1 día por día, máximo 15, no se suman); amplía `GET /api/loans/mine/eligibility` (creado en HU-04) con `blockedUntil` y vencido pendiente; el bloqueo y un ENTREGADO atrasado cuentan como VENCIDO (lectura A-12) en `LoanService.create`.
- [FRONT] Mensaje "Podrás volver a solicitar el <fecha>" en `features/loans/request`.
- [TEST] Unitarias del cálculo con tope de 15; integración de bloqueo y fin del bloqueo; E2E `sanciones`.

### SH-06 · Alerta de préstamo próximo a vencer
- [DB] Omitida: usa `notifications` de H-Alertas.
- [BACK] `notifications`: `DueSoonAlertJob` (00:05) con `LoanQueryService.findDeliveredDueOn`, que implementa `InternalJob` (nombre `due-soon`) y se registra en el grupo `daily` del `InternalJobController` creado en HU-05a.3 (SH-06 ya no añade cron propio ni endpoint propio; ADR 2.5, puntos 3 y 4, P-11); alerta también al entregar un préstamo de 2 días el día de inicio; cierre al devolver o vencer.
- [FRONT] Alerta de próximo a vencer en la campana del estudiante.
- [TEST] Unitarias de las reglas de antelación; integración (préstamos de 1 y 2 días); E2E `alertas-vencimiento`.

### SH-07 · Cancelar mi solicitud
- [DB] Omitida: el estado CANCELADO y el motivo ya están en el esquema de HU-03.
- [BACK] `loans`: `POST /api/loans/{id}/cancellation` con `LoanCancellationRequest` (motivo opcional, "Cancelado por usuario"), titularidad (403 si es ajeno) y ventana (SOLICITADO con inicio hoy o posterior; APROBADO antes de `pickup_deadline`).
- [FRONT] Botón "Cancelar" con motivo opcional en `features/loans/my-requests`, visible solo en la ventana válida.
- [TEST] Unitarias de las ventanas; integración (00:03 del día siguiente, ajeno responde 403); E2E `cancelar-solicitud`.

### SH-01 · Historial "Mis préstamos"
- [DB] Omitida: usa `idx_loans_student_status_start` del esquema de HU-03.
- [BACK] `loans`: parámetros de estado y rango (fecha de inicio) en `GET /api/loans/mine`, con paginación y orden de lista blanca.
- [FRONT] Filtros por estado y fechas en `features/loans/my-requests`.
- [TEST] Unitarias del filtro; integración de aislamiento entre estudiantes; E2E `mis-prestamos`.

### SH-12 · Cierre de la sesión de otra cuenta por el ADMIN
- [DB] Omitida: usa `refresh_tokens` de HU-01b (`revoked_by` y `CLOSED_BY_ADMIN` ya incluidos).
- [BACK] `auth`: `DELETE /api/users/{id}/session`, `GET /api/users/by-email` (404 `USER_NOT_FOUND` "Usuario no encontrado") y 409 `NO_ACTIVE_SESSION`.
- [FRONT] Acción "Cerrar sesión de la cuenta" en `features/admin/users`.
- [TEST] Unitarias; integración del corte inmediato también en consultas; E2E `baja-cuentas` (cierre de sesión).

### SH-08 · Baja de cuentas
- [DB] `V<siguiente>__users_deactivation.sql`: solo `users.deactivated_by` con FK, índice y CHECK (el índice `(role, deleted_at)` ya lo crea HU-01a).
- [BACK] `auth`: `UserController` y `UserAccountService`, `GET /api/users` (búsqueda por texto, rol y estado) y `GET /api/users/by-email`, `DELETE /api/users/{id}` (200 idempotente si ya está de baja; `LAST_ADMIN` antes que `CANNOT_DEACTIVATE_SELF`; 409 `USER_HAS_LOANS_IN_PROGRESS` con `UserLoanActivityService` implementado por `loans`; revoca la sesión) y ajuste de `lockStudentForUpdate` (snapshot con `active`).
- [FRONT] `features/admin/users`: buscador, lista con estado y diálogo de baja que muestra los préstamos en curso.
- [TEST] Unitarias de reglas; integración (préstamos en curso, último ADMIN, "Credenciales inválidas" al volver a entrar); concurrencia de baja contra solicitud simultánea (si gana la solicitud, la baja da 409; si gana la baja, la solicitud da 401 `SESSION_INVALIDATED`); E2E `baja-cuentas`.

### SH-04 · Panel de métricas
- [DB] Omitida: consultas agregadas sobre tablas existentes.
- [BACK] `reports`: `GET /api/reports/metrics` con `ReportService`, `LoanQueryService.rankingByDeliveredLoans`, `overdueCount`, `occupiedUnitDays` y `EquipmentCatalogService.totalActiveUnits`.
- [FRONT] `features/admin/metrics`: ranking, vencidos y ocupación con selector de rango.
- [TEST] Unitarias del porcentaje; integración con préstamo que empieza antes del rango; E2E `panel-metricas`.

### SH-05 · Exportación a CSV
- [DB] Omitida: lectura en streaming de tablas existentes.
- [BACK] `reports`: `GET /api/reports/inventory.csv` y `/loans.csv` con `StreamingResponseBody`, filtros opcionales y columnas definidas; los correos se leen con `UserDirectoryService.findSummaries` (`auth.api`).
- [FRONT] `features/admin/export`: botones de descarga y filtros.
- [TEST] Unitarias del formato CSV; integración de filtros y archivo vacío; E2E `exportar-csv`.

Conteo de subtareas: 82 en los tickets de historias (22 historias x 3 = 66, más 8 de HU-05a.1 a HU-05a.3, más 8 `[DB]`) y 12 en habilitadores (H0: 3; H0b: 3; H-Alertas: 4; H-Demo: 2) = **94**. `[DB]` omitidas con motivo: H-Demo, HU-02b, HU-04, HU-05a.1, HU-05a.2, HU-05a.3, HU-05b, HU-05d, HU-05e, SH-01, SH-02, SH-04, SH-05, SH-06, SH-07, SH-09, SH-10 y SH-12. `[FRONT]` omitidas: HU-05a.3 y H-Demo.

## d) Orden de implementación sugerido

| # | Ticket | Puntos | Motivo del lugar |
|---|---|---|---|
| 1 | H0b | 5 | Proyectos, contenedores, CI y despliegue: sin ellos no se puede ejecutar nada. |
| 2 | H0 | 8 | Fundación de errores, configuración, contrato y pruebas sobre los proyectos de H0b. |
| 3 | HU-01a | 3 | Sin cuentas no hay responsable. |
| 4 | HU-01b | 8 | Sesión base y roles para todo lo demás. |
| 5 | HU-02a | 5 | Sin equipos no hay qué prestar. |
| 6 | HU-03 | 8 | Disponibilidad y esquema completo de préstamos. |
| 7 | HU-04 | 8 | Solicitud y máquina de estados. |
| 8 | H-Alertas | 3 | Base de alertas antes de HU-05a.3 y de HU-05e. |
| 9 | HU-05a.1 | 8 | Aprobación: único punto que retiene unidades; crea la bandeja. |
| 10 | HU-05a.2 | 3 | Rechazo con motivo sobre la misma bandeja. |
| 11 | HU-05a.3 | 3 | Rechazo automático y base de tareas internas (`InternalJob`). |
| 12 | HU-05b | 5 | Entrega. |
| 13 | HU-05c | 5 | Devolución. |
| 14 | HU-05d | 5 | Devolución con daños. |
| 15 | HU-02b | 5 | Baja de equipos con SOLICITADO reales. |
| 16 | HU-05e | 5 | Cierre automático. Completa todos los estados del ciclo. |
| 17 | H-Demo | 2 | Datos de demostración: necesita cuentas, catálogo y todos los estados del ciclo. |
| 18 | SH-09 | 8 | Vida e inactividad de la sesión. |
| 19 | SH-11 | 5 | Bloqueo por intentos. |
| 20 | SH-10 | 5 | Sesión única. |
| 21 | SH-02 | 5 | Vencidos y alertas. |
| 22 | SH-03 | 5 | Sanciones (necesitan VENCIDO y devoluciones). |
| 23 | SH-06 | 3 | Próximo a vencer. |
| 24 | SH-07 | 5 | Cancelación. |
| 25 | SH-01 | 3 | Historial con filtros. |
| 26 | SH-12 | 3 | Cierre de sesión por el ADMIN. |
| 27 | SH-08 | 8 | Baja de cuentas. |
| 28 | SH-04 | 5 | Panel de métricas. |
| 29 | SH-05 | 5 | Exportación CSV. |

Hito 1 (tickets 1 a 17, 89 puntos): el sistema presta y recupera equipos de punta a punta y el entorno de evaluación tiene datos de ejemplo. Hito 2 (18 a 27, 50 puntos): seguridad de cuentas, control y comodidad. Hito 3 (28 y 29, 10 puntos): reportes. Total 149.

## Divisiones, riesgos y decisiones pendientes

- **Dividida:** HU-05a en tres tickets independientes (HU-05a.1 aprobar 8, HU-05a.2 rechazar 3, HU-05a.3 "Sin resolver a tiempo" 3), con Gherkin repartidos por número de escenario del archivo de historias: HU-05a.1 los escenarios 1, 4 a 12, 14, 15, 17 y 18 (14); HU-05a.2 los escenarios 2, 3 y 13 (3); HU-05a.3 el escenario 16 (1); suman los 18. La clave de trazabilidad es HU-05a.
- **No se divide:** SH-09 (queda en 8 puntos al mover la sesión base a HU-01b).
- **Si crece:** HU-04 (extraer "ver mis solicitudes", 3 puntos) y SH-08 (extraer búsqueda y listado de cuentas).
- **Sin decisiones pendientes del usuario.** P-10, aprobado: ADMIN inicial en producción (RN-01a.4, ADR 2.6.8 y D-26): `AdminBootstrapRunner` en HU-01b con las variables nuevas `BOOTSTRAP_ADMIN_EMAIL`, `BOOTSTRAP_ADMIN_NAME` y `BOOTSTRAP_ADMIN_PASSWORD_HASH`.
- **Cron de Vercel:** queda una única entrada de cron diario (`GET /api/internal/jobs/daily`, que ejecuta todo lo registrado en el grupo `daily`: `daily-review` y, cuando SH-06 lo registre, `due-soon`), según el ADR 2.5, puntos 2 a 4 (P-11, aprobado por el usuario). Basta confirmar que el plan de Vercel admite un cron diario. Opcional: comprobar si el plan admite además una entrada por minuto para `pickup-expiration`; si no, rigen `@Scheduled` y las lecturas que aplican la regla con el reloj (ADR 2.5, punto 4).

## Tareas relacionadas (fuera de este plan)

- `docs-writer` (`/generar-diagramas`): actualizar los diagramas `componentes` y `secuencia-tareas-programadas` por el job diario único con `InternalJobController` e `InternalJob` en `shared` (P-11).

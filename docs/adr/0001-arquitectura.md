# ADR 0001 · Arquitectura de PrestaLab

- **Estado:** Aceptado por el usuario. Revisión vigente: **7f** (2026-11-08). No queda ninguna decisión pendiente del usuario; solo las tareas de otros agentes listadas en "Decisiones del usuario" al final.
- **Historial de revisiones:**
  - 1 (2026-11-06): arquitectura base.
  - 2: refresh token, corte de acceso y contrato OpenAPI.
  - 3: sesión por rol, sesión única, límite de intentos y baja de cuentas.
  - 4: no revelación en el inicio de sesión y cancelación ajustada (SH-07).
  - 5 (2026-11-07): la baja se rechaza con préstamos en curso; lista cerrada del readme (2.6.7).
  - 6 (2026-11-07):
    - Catálogo de errores alineado con los textos de las historias.
    - `SESSION_INVALIDATED` sustituye a `ACCOUNT_DISABLED` y cubre la baja y el cierre administrativo.
    - `NO_ACTIVE_SESSION`, `INVALID_CRON_SECRET` y 404 para alertas ajenas.
    - Rotación por actividad (SH-09) y límite por origen con ventana fija (SH-11).
    - Correcciones exactas sobre los diagramas generados.
  - 7 (2026-11-07): P-9, opción B.
    - Se comprueban cuenta y sesión en **todas** las peticiones autenticadas de todos los roles, con una única consulta por llave primaria.
    - El corte por baja, cierre administrativo, desplazamiento o cierre de sesión es inmediato también en las lecturas.
    - Desaparece la ventana de 15 min 30 s y la opción O-1 queda absorbida.
  - 7f (2026-11-08): P-12 resuelta por el usuario. El sembrador de préstamos va en el habilitador H-Demo (2 puntos). La contraseña de demostración se publica en el readme (0.4) y R-23 queda como riesgo aceptado. El entorno de evaluación usa `SPRING_PROFILES_ACTIVE=prod,demo`.
  - 7e (2026-11-08):
    - P-10 aprobada (D-26).
    - Se confirma que todo cambio de base de datos va por migraciones Flyway.
    - Nuevo perfil `demo` con cuentas de prueba y datos de ejemplo (2.8, D-28, pendiente P-12).
    - Cambios para el readme 0.4 y para los tickets.
  - 7d (2026-11-07): P-11 aprobada (D-27). Registro `InternalJob` e `InternalJobController` en `shared`; una sola entrada de Vercel Cron, `GET /api/internal/jobs/daily` (`daily-review` y `due-soon`); R-1 actualizado; cambios exactos para diagramas y tickets (5.2).
  - 7c (2026-11-07):
    - Nuevo endpoint `GET /api/internal/jobs/due-soon` (`notifications`, SH-06) junto a `daily-review` y `pickup-expiration`, con `CRON_SECRET` e idempotencia (2.5 y Anexo A).
    - Una entrada de cron en `vercel.json` por endpoint y límites del plan de Vercel pendientes de verificar.
    - Alternativa recomendada: el grupo `daily` con un registro `InternalJob` en `shared` (pendiente P-11).
  - 7b (2026-11-07): referencias a historias corregidas (SH-08 a SH-12 en lugar de "HU-01c") y primer ADMIN en producción mediante un arranque idempotente desde variables de entorno (2.6.8, D-26, pendiente P-10).
- **Fecha:** 2026-11-06 (última revisión: 2026-11-07).
- **Autor:** subagente `arquitecto-sw`.
- **Fuentes respetadas:** `CLAUDE.md` (stack, estructura, convenciones, dominio), `docs/historias-de-usuario.md` (HU-01a a HU-05e, SH-01 a SH-07, PA-1 a PA-28), sección 3 de `readme.md` (modelo de datos, concurrencia y supuestos S-1 a S-11 de `database-engineer`) y los hooks de `.claude/hooks/check-conventions.sh` (sufijos de clases por paquete, `@RequestMapping("/api/...")`, sin borrado físico).
- **Alcance:** define la arquitectura de referencia del backend, el frontend, los datos y el despliegue. No contiene código de aplicación. Las secciones 2 y 4 del readme y los `.mmd` actuales son diseño previo; en el apartado 5.2 se indica qué debe cambiar en ellos.

---

## Contexto

PrestaLab es una aplicación web para prestar equipos académicos con tres roles (ESTUDIANTE, ENCARGADO, ADMIN), un ciclo de préstamo con 7 estados y reglas que dependen del reloj (horario de servicio de 8:00 AM a 5:00 PM, plazo de recogida de 2 horas de servicio, revisión diaria de las 00:05) y de la concurrencia (la aprobación es el único punto que retiene unidades). La desarrolla una sola persona con subagentes de IA, se despliega en servicios gratuitos (Vercel con contenedores y Aiven MySQL) y debe ser trazable: nada se borra físicamente y cada transición queda registrada.

Fuerzas principales:

1. **Corrección bajo concurrencia** en la aprobación, la entrega, la devolución con daños y la baja de equipos (sección 3 del readme).
2. **Reglas dependientes del tiempo** que deben poder probarse de forma determinista.
3. **Bajo acoplamiento** para que los subagentes trabajen por módulo sin romper otros.
4. **Plataforma limitada:** arranque en frío de la JVM, pocas conexiones en Aiven, instancias que pueden suspenderse o duplicarse.
5. **Mensajes de error exactos** definidos en las historias, sin filtrar detalles internos.

---

## Resumen de decisiones

| ID | Decisión | Sección |
|---|---|---|
| D-1 | Monolito modular con 6 paquetes (`shared`, `auth`, `catalog`, `loans`, `notifications`, `reports`) y dependencias acíclicas verificadas con ArchUnit. | 1 |
| D-2 | Cada módulo publica un contrato en `co.prestalab.<modulo>.api` (interfaces `*Service` y records `*View`); nadie usa repositorios, entidades ni DTO REST de otro módulo. | 1.4 |
| D-3 | Las entidades se referencian entre módulos solo por identificador (`Long studentId`, `Long equipmentId`), nunca con `@ManyToOne` cruzado. | 1.4 |
| D-4 | El ciclo `catalog` ↔ `loans` se rompe con inversión de dependencias: `catalog.api.EquipmentUsageService` lo define `catalog` y lo implementa `loans`. | 1.3 |
| D-5 | `notifications` reacciona a eventos de `loans` (`LoanStatusChangedEvent`) con oyentes síncronos dentro de la misma transacción. | 1.3 |
| D-6 | Toda transición de préstamo pasa por un único componente (`LoanStateMachine` + `LoanTransitionService`) que valida, actualiza de forma condicional, inserta en `loan_status_history` y publica el evento. No existe `AuditService` genérico ni tabla `audit_log`. | 2.4 |
| D-7 | Filtro `RequestTraceFilter` como primer filtro: `X-Request-Id`, MDC, línea de acceso por petición y cabecera en la respuesta. | 2.3 |
| D-8 | Spring Security como OAuth2 Resource Server con JWT HS256 propio (`JwtEncoder`/`JwtDecoder` de Nimbus), reglas por URL y `@PreAuthorize` por endpoint; errores 401/403 del filtro con el mismo formato `ProblemDetail`. | 2.6 |
| D-9 | Transiciones como subrecursos de acción (`POST /api/loans/{id}/approval`, `/rejection`, `/delivery`, `/return`, `/cancellation`) en lugar de `PATCH /status` genérico. | Anexo A |
| D-10 | Validación de forma en el DTO (Bean Validation, incluidas restricciones de clase con reloj inyectado); reglas de negocio en el servicio; `CHECK` y únicos de la base como última barrera. | 3 |
| D-11 | Jerarquía `BusinessException` con `ErrorCode` y mensajes exactos de las historias; `GlobalExceptionHandler` (`@RestControllerAdvice`) produce `ProblemDetail` con `code` y `requestId`; los 500 son genéricos. | 3 |
| D-12 | Caché local Caffeine solo para `categories` y `equipmentSummaries` (datos de presentación); nunca para disponibilidad, estados ni totales. | 4.1 |
| D-13 | Paginación obligatoria con `PageResponse<T>` propio, tamaño máximo 50 y ordenación por lista blanca; exportaciones CSV en streaming por lotes. | 4.2 |
| D-14 | Reloj único inyectable (`java.time.Clock`, zona `America/Bogota`, S-1) y calendario de servicio parametrizado. | 2.4 |
| D-15 | Tareas programadas idempotentes y de recuperación (procesan todo lo pendiente), disparadas por `@Scheduled` y por un endpoint interno protegido con secreto para Vercel Cron; las lecturas no dependen de que la tarea haya corrido a tiempo. | 2.5 |
| D-16 | Aislamiento READ COMMITTED en el pool, `open-in-view=false`, transacciones solo en servicios y orden de bloqueo users → loans → equipment. | 2.4 |
| D-17 | Frontend Angular standalone con `core/`, `shared/`, `features/<modulo>/`, interceptores funcionales y `environment.apiUrl = '/api'` en todos los entornos. | Anexo B |
| D-18 | Vercel enruta `/api/*` al contenedor backend; mismo origen en producción; documentación OpenAPI y actuator bajo `/api`. | Anexo C |
| D-19 | Sesión con dos tokens: access token JWT de 15 min (solo en memoria del navegador) y refresh token opaco, revocable, de un solo uso y con rotación, con 30 min de inactividad deslizante y vida máxima por rol (ESTUDIANTE 1 h, ENCARGADO 8 h, ADMIN 8 h), guardado hasheado (SHA-256 en `BINARY(32)`) en `refresh_tokens` y enviado en una cookie `HttpOnly`, `Secure`, `SameSite=Strict`, `Path=/api/auth`. Endpoints `POST /api/auth/refresh` y `POST /api/auth/logout`. Sustituye al supuesto A-8. | 2.6.2 |
| D-20 | Corte de acceso inmediato: `ActiveSessionInterceptor` comprueba cuenta y sesión en **toda** petición autenticada de cualquier rol, lecturas incluidas, con una única consulta por llave primaria (`refresh_tokens` por `sid` unida a `users`), sin caché. La baja y el cierre administrativo revocan la sesión en la misma transacción, y la renovación también verifica la cuenta. No queda ventana de acceso tras una baja, un cierre administrativo, un desplazamiento o un cierre de sesión. El access token sigue durando 15 min. Sustituye al supuesto A-9 (revisión 7, P-9 opción B). | 2.6.3 |
| D-22 | Una sola sesión activa por usuario, garantizada con un índice único en la base; un nuevo inicio de sesión con otra sesión vigente responde 409 `ACTIVE_SESSION_EXISTS` y solo la desplaza si el usuario lo confirma. | 2.6.4 |
| D-23 | Límite de 3 inicios de sesión fallidos consecutivos por cuenta con bloqueo de 15 min; contador en columnas de `users`; límite por IP en memoria de 10 intentos fallidos cada 15 min por instancia. | 2.6.5 |
| D-24 | Baja lógica de cuentas por ADMIN (`DELETE /api/users/{id}`): se rechaza con 409 `USER_HAS_LOANS_IN_PROGRESS` si el titular tiene cualquier préstamo en curso (SOLICITADO, APROBADO, ENTREGADO o VENCIDO), consultado mediante `auth.api.UserLoanActivityService` implementado por `loans`; no hay cancelación automática. Si procede, revoca la sesión. Cierre administrativo de sesión con `DELETE /api/users/{id}/session`. | 2.6.6 |
| D-25 | Regla de no revelación en el inicio de sesión: contraseña incorrecta, correo inexistente, cuenta dada de baja y cuenta bloqueada devuelven la misma respuesta (401 `INVALID_CREDENTIALS`, "Credenciales inválidas") con tiempo igualado; el motivo real solo existe en el log. | 2.6.5 |
| D-27 | Tareas internas por registro: interfaz `InternalJob` y un único `InternalJobController` en `shared`. Vercel Cron solo necesita una entrada diaria, `GET /api/internal/jobs/daily` (`daily-review` y luego `due-soon`). Los endpoints `/{name}` quedan para pruebas, ejecución manual y, si el plan lo admite, `pickup-expiration`. Todo con `CRON_SECRET` y tareas idempotentes. Decidido por el usuario (P-11). | 2.5 |
| D-26 | Primer ADMIN en producción: `AdminBootstrapRunner` idempotente que, al arrancar y solo si no hay ningún ADMIN activo, lo crea desde `BOOTSTRAP_ADMIN_EMAIL`, `BOOTSTRAP_ADMIN_NAME` y `BOOTSTRAP_ADMIN_PASSWORD_HASH` (BCrypt), sin secretos en el repositorio; en `dev` y `demo`, las cuentas de prueba de 2.8. Aprobado por el usuario (P-10). | 2.6.8 |
| D-28 | Datos de demostración: perfil `demo` (y `dev`) que, después de Flyway, crea cuentas de prueba (1 ADMIN, 2 ENCARGADO, 3 ESTUDIANTE) con la contraseña de `SEED_PASSWORD` y datos de ejemplo coherentes con el dominio. Cada módulo siembra sus propias tablas, de forma idempotente y sin borrar nunca nada. En `prod` sin `demo` no se aplica. El entorno de evaluación usa `SPRING_PROFILES_ACTIVE=prod,demo`. Los préstamos de ejemplo los crea el habilitador H-Demo. La contraseña de demostración se publica en el readme 0.4 por decisión del usuario (P-12). | 2.8 |
| D-21 | Todo contrato REST se documenta con springdoc (Swagger UI en `/api/docs`, especificación en `/api/docs/v3/api-docs`), se versiona como `docs/api/openapi.yaml` y una prueba de integración falla si el OpenAPI generado no coincide con el versionado. Todo cambio de contrato actualiza en el mismo PR el OpenAPI, la sección 4 del readme y, si cambia un flujo, los diagramas. | 2.7 |

---

## 1. Mapa de módulos del backend

### 1.1 Módulos y responsabilidades

| Módulo | Responsabilidad | Tablas que posee | Historias |
|---|---|---|---|
| `shared` | Piezas transversales sin lógica de negocio: excepciones base y `GlobalExceptionHandler`, `RequestTraceFilter`, `PageResponse`, `BaseEntity`, `AuthenticatedUser` y `Role`, configuración (`Clock`, caché, OpenAPI, Jackson, MapStruct), y la interfaz `InternalJob` con su `InternalJobController` (D-27), que solo conoce la interfaz. | ninguna | todas |
| `auth` | Registro, inicio de sesión, límite de intentos, emisión y validación de JWT, sesiones y refresh tokens, `SecurityConfig`, cuentas de usuario y su baja. | `users`, `refresh_tokens` | HU-01a, HU-01b, SH-08, SH-09, SH-10, SH-11, SH-12 |
| `catalog` | Categorías y equipos: alta, edición, baja lógica, búsqueda paginada y cálculo de disponibilidad a partir de lo que informa `loans`. | `categories`, `equipment` | HU-02a, HU-02b, HU-03 |
| `loans` | Solicitud, máquina de estados, aprobación, entrega, devolución (incluidos daños), cancelación, plazo de recogida, retención de unidades, límite de 3, sanciones, historial de estados y tareas programadas del ciclo. | `loans`, `loan_items`, `loan_item_returns`, `loan_status_history`, `sanctions` | HU-04, HU-05a a HU-05e, SH-01, SH-02, SH-03, SH-07 |
| `notifications` | Alertas dentro de la aplicación: creación a partir de eventos de `loans`, alerta diaria de próximo a vencer, bandeja, contador y lectura. | `notifications` | HU-05e (RN-05e.3), RN-05a.11, SH-02 (alertas), SH-06 |
| `reports` | Panel de métricas y exportaciones CSV. No posee tablas: orquesta consultas públicas de otros módulos. | ninguna | SH-04, SH-05 |

Las sanciones (SH-03) quedan dentro de `loans` porque se crean al devolver y se consultan al solicitar, siempre dentro de transacciones de `loans`; separarlas crearía una dependencia circular sin beneficio.

### 1.2 Estructura interna de un módulo

```text
co.prestalab.<modulo>
├── api/          # contrato público: interfaces *Service, records *View / *Snapshot, eventos
├── controller/   # *Controller con @RequestMapping("/api/...") (hook)
├── service/      # *Service / *ServiceImpl (hook): casos de uso e implementaciones de api/
├── domain/       # lógica pura sin Spring ni JPA: LoanStateMachine, PickupDeadlinePolicy, ServiceCalendar, RetentionRange
├── repository/   # *Repository (Spring Data JPA, consultas nativas parametrizadas)
├── entity/       # entidades JPA (Lombok), nunca salen del módulo
├── dto/          # *Request / *Response (records) del contrato REST (hook)
├── mapper/       # *Mapper de MapStruct
├── exception/    # excepciones de negocio del módulo (extienden las de shared)
├── event/        # oyentes de eventos de otros módulos (solo notifications)
└── job/          # tareas programadas (solo loans y notifications)
```

Reglas: `domain/` no depende de Spring ni de JPA y concentra las reglas de calendario y transiciones para probarlas con pruebas unitarias puras. Los records de `api/` no se llaman `*Request`/`*Response` para distinguir el contrato entre módulos del contrato REST: un cambio en la API pública no obliga a cambiar otros módulos y viceversa. Los subpaquetes `api/`, `domain/`, `exception/`, `event/` y `job/` amplían la estructura base de `CLAUDE.md` (supuesto A-2).

### 1.3 Dependencias permitidas

Lectura: la fila puede depender de la columna. Solo se permite depender del paquete `api` de otro módulo y de `shared`.

| Depende de → | `shared` | `auth.api` | `catalog.api` | `loans.api` | `notifications.api` |
|---|---|---|---|---|---|
| `auth` | sí | (propio) | no | no | no |
| `catalog` | sí | no | (propio) | no | no |
| `loans` | sí | sí, e implementa `UserLoanActivityService` | sí, e implementa `EquipmentUsageService` | (propio) | no |
| `notifications` | sí | sí | no | sí (consultas y eventos) | (propio) |
| `reports` | sí | sí | sí | sí | no |
| `shared` | (propio) | no | no | no | no |

Grafo resultante (acíclico): `shared` ← `auth`, `catalog` ← `loans` ← `notifications`; `reports` → `auth`, `catalog`, `loans`.

**Inversión `catalog` ↔ `loans` (D-4).** `catalog` necesita saber, para un equipo, las unidades retenidas en un rango (HU-03), las unidades comprometidas (RN-02a.6), si tiene préstamos activos (RN-02b.2) y rechazar las solicitudes pendientes al darlo de baja (RN-02b.3). `loans` necesita bloquear y leer equipos (RN-05a.3, RN-05b.6, RN-05d.2). Para no crear un ciclo, `catalog` declara en su `api` la interfaz `EquipmentUsageService` y `loans` la implementa (`loans.service.EquipmentUsageServiceImpl`). En compilación solo existe `loans → catalog`; Spring inyecta la implementación en tiempo de ejecución.

**Eventos `loans` → `notifications` (D-5).** `notifications` necesita leer préstamos para armar las alertas (el contenido no se copia, sección 3 del readme), así que depende de `loans`. Para que `loans` no dependa de vuelta, `loans` publica `LoanStatusChangedEvent(loanId, studentId, fromStatus, toStatus, closureReason, actorId, changedAt, effectiveEndDate)` con `ApplicationEventPublisher` y `notifications` lo atiende con un `@EventListener` síncrono que corre en la misma transacción: si la alerta falla, la transición se revierte (las alertas son parte de RN-05e.3 y RN-SH02.4), y la unicidad `uk_notifications_recipient_loan_type` hace idempotente la repetición.

### 1.4 Contratos entre módulos

| Interfaz (`api`) | Implementa | Usada por | Operaciones (propósito) |
|---|---|---|---|
| `auth.api.UserDirectoryService` | `auth` | `loans`, `notifications`, `reports` | `findSummaries(ids)` (nombre, correo), `findActiveIdsByRoles(roles)` (destinatarios), `lockStudentForUpdate(id)` (propagación `MANDATORY`, RN-04.8 y SH-03), que devuelve un snapshot con `active` para que la solicitud se rechace si la cuenta se dio de baja mientras esperaba el bloqueo (2.6.6). |
| `auth.api.UserLoanActivityService` | `loans` (`UserLoanActivityServiceImpl`) | `auth` | `findLoansInProgress(userId)` con propagación `MANDATORY`: devuelve `LoanInProgressView(loanId, status, startDate, endDate)` de los préstamos SOLICITADO, APROBADO, ENTREGADO o VENCIDO del titular, sin bloquear ni modificar nada (2.6.6). Inversión de dependencias para no crear el ciclo `auth` ↔ `loans`. |
| `catalog.api.EquipmentCatalogService` | `catalog` | `loans`, `reports`, `notifications` | `lockForUpdate(ids)` y `lockForShare(ids)` en orden de `id` (propagación `MANDATORY`) que devuelven `EquipmentSnapshot(id, name, totalUnits, status, retired)`; `decreaseTotalUnits(id, n)` (`MANDATORY`, RN-05d.2); `findSummaries(ids)` (cacheable, solo nombre, código y categoría); `streamInventory()` y `totalActiveUnits()` (SH-04, SH-05). |
| `catalog.api.EquipmentUsageService` | `loans` | `catalog` | `retainedUnits(ids, from, to)` en una consulta (HU-03); `committedUnits(id)` (RN-02a.5); `lockLoansForRetirement(id)`, `hasActiveLoans(id)` y `rejectPendingRequests(id, actorId)` (HU-02b). |
| `loans.api.LoanQueryService` | `loans` | `notifications`, `reports` | `findNotificationViews(loanIds)`, `findDeliveredDueOn(date)` (SH-06), `rankingByDeliveredLoans`, `overdueCount`, `occupiedUnitDays` (SH-04), `streamLoansForExport(filter)` (SH-05). |
| `loans.api.event.LoanStatusChangedEvent` | `loans` (publica) | `notifications` | Ver 1.3. |

Reglas del contrato: los métodos que bloquean filas usan `Propagation.MANDATORY` para obligar a que el llamador ya tenga la transacción abierta; los records de `api` son inmutables y nunca contienen entidades; las entidades de un módulo se refieren a las de otro solo por `Long` (D-3), lo que además evita que `@SQLRestriction` u otros filtros escondan referencias históricas (riesgo R-7).

### 1.5 Reglas verificadas automáticamente (ArchUnit)

Una prueba `ArchitectureTest` en `backend/src/test` (se ejecuta con `./mvnw test`) falla si:

1. Hay ciclos entre los paquetes `co.prestalab.<modulo>`.
2. Una clase accede a `..<otro>.repository..`, `..<otro>.entity..`, `..<otro>.service..`, `..<otro>.dto..` o `..<otro>.domain..` de otro módulo (solo se admite `..<otro>.api..` y `shared`).
3. Un `controller` depende de `repository` o `entity`, o devuelve tipos que no sean `*Response`, `PageResponse`, `ResponseEntity<...Response>` o `StreamingResponseBody`.
4. Un `repository` es usado fuera del `service` de su módulo.
5. `domain` depende de `org.springframework..` o `jakarta.persistence..`.
6. Un método público de un `controller` no tiene `@PreAuthorize` (o la clase no lo tiene), salvo la lista blanca: registro, inicio de sesión, renovación, cierre de sesión y el controlador de tareas internas.
7. Se invoca `delete*` de un repositorio, `LocalDate.now()`/`LocalDateTime.now()` sin `Clock`, o se inyecta por campo.
8. Una clase en `dto` no es `record` o no termina en `Request`/`Response`.
9. Un método público de un `controller` no tiene `@Operation`, o una clase de controlador no tiene `@Tag` (contrato OpenAPI, 2.7).

### 1.6 Alternativas descartadas y consecuencias

- **Microservicios:** descartados por el costo operativo (despliegues, red, consistencia distribuida) frente a un dominio acotado y una sola persona (coincide con 2.1 del readme).
- **Paquetes por capa** (`controller/`, `service/` globales): descartado; dispersa una historia en todo el árbol y no permite fronteras.
- **Spring Modulith:** descartado por ahora. Aporta verificación de módulos y eventos persistentes, pero exige convenciones de paquetes `internal` y una tabla de publicación de eventos; ArchUnit cubre la verificación con menos piezas. Si los módulos se extraen, es la evolución natural.
- **Llamadas directas `loans → notifications`:** descartadas porque crean ciclo con las lecturas de `notifications`.
- **`reports` con su propio repositorio de consultas sobre tablas ajenas:** descartado para respetar la regla de no acceder a datos ajenos sin contrato; el costo es que `loans` expone consultas agregadas en `LoanQueryService`.
- **Consecuencias:** más interfaces y records de contrato; a cambio, cada subagente puede trabajar en un módulo con fronteras verificadas por pruebas.

---

## 2. Flujo de una petición de extremo a extremo

### 2.1 Camino feliz

```text
Navegador → Vercel (/api/*) → [1] RequestTraceFilter → [2] SecurityFilterChain
→ [3] DispatcherServlet → [4] Controller (Bean Validation + @PreAuthorize)
→ [5] Service (@Transactional, reglas de negocio, bloqueos, api de otros módulos)
→ [6] Repository (JPA / SQL nativo parametrizado) → [7] Mapper (MapStruct, dentro de la transacción)
→ commit → [8] Controller devuelve *Response → [1] RequestTraceFilter registra y limpia MDC
```

| Paso | Componente | Qué hace | Qué no hace |
|---|---|---|---|
| 0 | Vercel | Termina TLS y enruta `/api/*` al contenedor backend; añade `x-vercel-id`. | No aplica reglas. |
| 1 | `shared.web.RequestTraceFilter` (`OncePerRequestFilter`, `Ordered.HIGHEST_PRECEDENCE`, antes de Spring Security) | Toma `X-Request-Id` si cumple `^[A-Za-z0-9-]{8,64}$`, si no genera un UUID; lo pone en MDC (`requestId`) y en la cabecera de respuesta; guarda `x-vercel-id` en MDC (`edgeId`); mide la duración. En `finally` escribe la línea de acceso (2.3) y limpia el MDC. | No lee cuerpos ni registra la cadena de consulta. |
| 2 | `SecurityFilterChain` (`auth.security.SecurityConfig`) | `CorsFilter` (lista restringida) → `BearerTokenAuthenticationFilter` valida firma HS256, `exp` e `iss` → `JwtAuthenticationConverter` crea el principal `AuthenticatedUser(id, role)` con autoridad `ROLE_<rol>` → `UserMdcFilter` pone `userId` y `role` en MDC y en un atributo de la petición → `AuthorizationFilter` aplica las reglas por URL (públicas, `authenticated()`, secreto en `/api/internal/**`). | No decide sobre la sesión: toda petición autenticada pasa después por `ActiveSessionInterceptor` (2.6.3), que consulta la base una vez. |
| 3 | `DispatcherServlet` | Resuelve el handler y la ruta patrón (`/api/loans/{id}/approval`). | |
| 4 | `*Controller` | Recibe `@Valid @RequestBody *Request`, parámetros validados (`@Validated`) y `@AuthenticationPrincipal AuthenticatedUser`; `@PreAuthorize("hasAnyRole(...)")` por método. Llama a un solo método del servicio y arma `ResponseEntity` (201 con `Location` al crear). | Sin `@Transactional`, sin reglas de negocio, sin repositorios, sin entidades. |
| 5 | `*Service` | Abre la transacción, aplica reglas de negocio (sección 3), bloquea filas en el orden fijo (2.4), llama a `api` de otros módulos, invoca `LoanTransitionService` para cualquier cambio de estado y llama al mapper antes de salir. Devuelve un `*Response`. | No conoce HTTP (`HttpServletRequest`, códigos de estado). |
| 6 | `*Repository` | Consultas derivadas, JPQL o SQL nativo con parámetros, proyecciones a records, `@Lock` y `jakarta.persistence.lock.timeout`. | No concatena SQL; no borra. |
| 7 | `*Mapper` | Entidad → `*Response` y `*Request` → entidad (ignora `id`, auditoría y `version`). `unmappedTargetPolicy = ERROR`. Convierte `LocalDateTime` local a `OffsetDateTime` con la zona de la institución. | No consulta la base ni aplica reglas. |
| 8 | Jackson | Serializa el record. | |

### 2.2 Flujo de error

| Origen | Quién lo convierte | Respuesta | Registro |
|---|---|---|---|
| Access token ausente, inválido o vencido (filtro) | `ProblemDetailAuthenticationEntryPoint` | 401, `code = UNAUTHENTICATED`, "Debes iniciar sesión"; el frontend intenta una renovación (2.6.2) | INFO en la línea de acceso |
| Refresh token ausente, vencido, revocado, reutilizado o de una cuenta dada de baja | `GlobalExceptionHandler` (`InvalidSessionException`) | 401, `SESSION_EXPIRED` (o `SESSION_REPLACED` si la sesión fue desplazada o cerrada por un ADMIN); borra la cookie | INFO; WARN con `reason=REUSE_DETECTED` si hubo reutilización |
| Cualquier petición autenticada (lectura o escritura, de cualquier rol) con la cuenta dada de baja o la sesión revocada, aunque el access token siga vigente | `ActiveSessionInterceptor` → `GlobalExceptionHandler` | 401, `SESSION_INVALIDATED` (baja o cierre por ADMIN), `SESSION_REPLACED` (desplazada) o `SESSION_EXPIRED` (cerrada por el usuario o vencida) | WARN con el motivo real |
| Secreto ausente o incorrecto en `/api/internal/jobs/{job}` | `InternalJobAuthFilter` → `ProblemDetailFactory` | 401, `INVALID_CRON_SECRET`, "No autorizado", sin otros detalles ni `WWW-Authenticate` | WARN con IP de origen |
| Inicio de sesión con otra sesión vigente | `GlobalExceptionHandler` (`ActiveSessionExistsException`) | 409, `ACTIVE_SESSION_EXISTS` con `activeSession` | INFO |
| Inicio de sesión fallido: contraseña incorrecta, correo inexistente, cuenta dada de baja o bloqueada | `GlobalExceptionHandler` (`InvalidCredentialsException`) | 401, `INVALID_CREDENTIALS`, "Credenciales inválidas", idéntico en todos los casos y entregado no antes del piso de tiempo (D-25) | WARN `login_failed` con el motivo real |
| Exceso de intentos fallidos desde una IP | `LoginRateLimiter` → `GlobalExceptionHandler` | 429, `TOO_MANY_ATTEMPTS`, cabecera `Retry-After` | WARN |
| `Origin` ajeno en `/api/auth/refresh` o `/api/auth/logout` | `GlobalExceptionHandler` | 403, `ACCESS_DENIED` | WARN |
| Regla por URL denegada (filtro) | `ProblemDetailAccessDeniedHandler` | 403, `ACCESS_DENIED`, "Acceso denegado" | INFO |
| `@PreAuthorize` denegado (método) | `GlobalExceptionHandler` (`AccessDeniedException`) | 403, "Acceso denegado" | INFO |
| Bean Validation del DTO o de parámetros | `GlobalExceptionHandler` (`MethodArgumentNotValidException`, `HandlerMethodValidationException`, `ConstraintViolationException`) | 400, `VALIDATION_ERROR`, `errors: [{field, message}]` con los mensajes de las historias | INFO sin valores |
| Cuerpo ilegible, tipo de parámetro inválido, parámetro faltante | `GlobalExceptionHandler` | 400, "La solicitud no tiene un formato válido" (sin detalle de Jackson) | INFO |
| Regla de negocio (`BusinessException`) | `GlobalExceptionHandler` | 400, 403, 404 o 409 según la subclase, `code` y `detail` exactos del catálogo (3.3) y extensiones propias (por ejemplo `items` en unidades insuficientes) | WARN sin traza de pila |
| Bloqueo optimista, espera de bloqueo agotada o interbloqueo | `GlobalExceptionHandler` (`OptimisticLockingFailureException`, `PessimisticLockingFailureException`, `CannotAcquireLockException`) | 409, `CONCURRENT_MODIFICATION` | WARN |
| Violación de integridad no traducida por el servicio | `GlobalExceptionHandler` (`DataIntegrityViolationException`) | 409, `DATA_CONFLICT`, mensaje genérico (nunca el texto de MySQL) | WARN con el nombre de la restricción |
| Ruta inexistente o método no permitido | `GlobalExceptionHandler` | 404 / 405 | INFO |
| Cualquier otra excepción | `GlobalExceptionHandler` (`Exception`) | 500, `INTERNAL_ERROR`, "Ocurrió un error inesperado. Código de referencia: `<requestId>`" | ERROR con traza de pila y `requestId` |

Detalles obligatorios:

- Toda excepción de tiempo de ejecución que sale del servicio revierte la transacción (comportamiento por defecto de `@Transactional` con `RuntimeException`; `BusinessException` lo es).
- El advice extiende `ResponseEntityExceptionHandler` para que las excepciones estándar de Spring MVC tengan el mismo formato. El entry point, el access denied handler y el advice usan el mismo `ProblemDetailFactory` de `shared`, porque los errores producidos en filtros no llegan al `@RestControllerAdvice`.
- `server.error.include-stacktrace=never`, `include-message=never`, `include-binding-errors=never`.
- El frontend (`errorInterceptor`) muestra `detail` (ya en español), redirige a inicio de sesión ante 401 y, ante 500, muestra el código de referencia.

### 2.3 Trazabilidad

**Línea de acceso** (una por petición, nivel INFO, logger `prestalab.access`), escrita por `RequestTraceFilter` en `finally`:

```text
http_request method=POST path=/api/loans/154/approval route=/api/loans/{id}/approval status=200 durationMs=87 userId=15 role=ENCARGADO requestId=9f1c... edgeId=iad1::abc...
```

- `userId` y `role` los pone `UserMdcFilter` también como atributo de la petición, porque Spring Security limpia el contexto antes de que el filtro externo termine. Sin sesión: `userId=-`.
- Nunca se registran contraseñas, tokens, cuerpos, correos ni la cadena de consulta.
- Formato: texto con `[%X{requestId}]` en `dev`; JSON estructurado (`logging.structured.format.console`) en `prod` hacia la salida estándar, que recogen los registros de Vercel.
- El `requestId` viaja en la cabecera `X-Request-Id` de la respuesta y en la propiedad `requestId` de todo `ProblemDetail`.
- Tareas programadas: cada ejecución abre su propio MDC con `requestId=job-<nombre>-<uuid>` y `userId=SYSTEM`, y registra inicio, cantidades procesadas y duración.

**Trazabilidad de negocio:** cada transición de préstamo inserta una fila en `loan_status_history` (D-6) y registra una línea INFO `loan_transition loanId=.. from=.. to=.. actor=..`. Los hitos (`approved_by`, `delivered_by`, etc.) se guardan en `loans` en la misma transacción, como define la sección 3 del readme.

**Alternativa descartada:** Micrometer Tracing con exportador OTLP. Aporta trazas distribuidas que aquí no existen (un solo servicio) y requiere un colector; el `requestId` en MDC cubre la necesidad. Si se añade, el `traceId` puede reemplazar al `requestId` sin cambiar el contrato de la cabecera.

### 2.4 Transacciones, concurrencia y reloj

- **Límites:** `@Transactional` solo en servicios; lecturas con `readOnly = true`; `spring.jpa.open-in-view=false`; el mapeo a `*Response` ocurre dentro de la transacción.
- **Aislamiento:** READ COMMITTED configurado en el pool (`spring.datasource.hikari.transaction-isolation=TRANSACTION_READ_COMMITTED`), como exige el punto 7 de la sección 3 del readme para que la suma de retenidas vea las aprobaciones confirmadas tras obtener el bloqueo. Se aplica a todo el sistema para no depender de anotarlo en cada método.
- **Orden de bloqueo:** users → loans → equipment, cada grupo por `id` ascendente (punto 6 de la sección 3). La tabla `refresh_tokens` (D-19) va al final: users → loans → refresh_tokens. El inicio de sesión bloquea `users` y luego `refresh_tokens`; la baja de una cuenta bloquea `users`, lee sin bloqueo los préstamos del titular y por último bloquea `refresh_tokens`; la renovación bloquea solo su fila de `refresh_tokens` y lee `users` sin bloquear, así que no puede interbloquearse con las anteriores. La baja de un equipo (HU-02b) lo respeta: `EquipmentUsageService.lockLoansForRetirement` bloquea primero los préstamos SOLICITADO y activos del equipo y después `catalog` bloquea el equipo.
- **Espera de bloqueo:** 5 s (`jakarta.persistence.lock.timeout`); al agotarse, 409 `CONCURRENT_MODIFICATION`. Un interbloqueo detectado por InnoDB se reintenta una vez en el servicio de aplicación y, si persiste, responde 409.
- **Transiciones (D-6):** `LoanStateMachine` (en `domain`) define las transiciones válidas del diagrama de estados de la sección 3; `LoanTransitionService.transition(loan, to, actorId, at, reason)` es el único que cambia `loans.status`: ejecuta `UPDATE ... WHERE id = ? AND status = <esperado>` (si afecta 0 filas lanza `CONCURRENT_MODIFICATION`), inserta `loan_status_history` con `changed_at` tomado del `Clock` y `changed_by` (`NULL` si es el sistema) y publica `LoanStatusChangedEvent`. Esto sustituye al `AuditService` del diseño previo.
- **Reloj (D-14):** un bean `Clock` con zona `prestalab.time-zone=America/Bogota` (S-1); la conexión JDBC fija la misma zona de sesión. `ServiceCalendar` (8:00 a 17:00, parametrizable) y `PickupDeadlinePolicy` (2 horas de servicio, excepción de 1 día después de las 3:00 PM, PA-26) viven en `loans.domain` y reciben el instante como parámetro. Las pruebas usan `Clock.fixed(...)`.

### 2.5 Tareas programadas

| Tarea | Módulo | Frecuencia | Qué hace | Regla |
|---|---|---|---|---|
| `PickupExpirationJob` | `loans` | cada minuto | APROBADO con `pickup_deadline <= ahora` → RECHAZADO `NO_RECOGIDO`. | HU-05e |
| `DailyLoanReviewJob` | `loans` | 00:05 | SOLICITADO con `start_date < hoy` → RECHAZADO `SIN_RESOLVER_A_TIEMPO`; ENTREGADO con `effective_end_date < hoy` → VENCIDO. | RN-05a.11, SH-02 |
| `DueSoonAlertJob` | `notifications` | 00:05 | Alerta PROXIMO_A_VENCER para ENTREGADO con `effective_end_date = mañana` (consulta vía `LoanQueryService`). | SH-06 |

Diseño (D-15):

1. **Idempotentes y de recuperación:** cada ejecución procesa todo lo pendiente hasta "ahora", no solo lo del último intervalo, y cada préstamo se cierra con su propia transacción corta usando la transición condicional. Dos instancias que corran a la vez no duplican nada (una actualiza 0 filas y no inserta historial ni evento; las alertas tienen único). Por eso no se usa bloqueo distribuido.
2. **Registro de tareas internas (D-27, decidido por el usuario: P-11):**
   - `shared` define la interfaz `InternalJob` (`name()`, `group()`, `run(Instant now)`). Cada tarea la implementa en su módulo:

     | Tarea | Nombre | Grupo | Módulo |
     |---|---|---|---|
     | `DailyLoanReviewJob` | `daily-review` | `daily` | `loans` |
     | `DueSoonAlertJob` | `due-soon` | `daily` | `notifications` |
     | `PickupExpirationJob` | `pickup-expiration` | ninguno | `loans` |

   - Un único `InternalJobController` en `shared` (`co.prestalab.shared.controller`, `@RequestMapping("/api/internal/jobs")`) recibe la lista de beans `InternalJob` por inyección.
   - `shared` no depende de ningún módulo, porque solo conoce la interfaz, y `loans` sigue sin depender de `notifications` (D-5). ArchUnit sigue exigiendo el grafo de 1.3.
3. **Disparadores:**
   - `@Scheduled` en proceso (zona de la institución) mientras el contenedor esté activo: cada tarea se programa por su cuenta en su módulo.
   - Como red de seguridad, Vercel Cron, que invoca con GET.

   | Endpoint | Qué ejecuta | Uso |
   |---|---|---|
   | `GET /api/internal/jobs/daily` | Todas las tareas del grupo `daily`, en este orden: `daily-review` y luego `due-soon` | **Única entrada de cron diaria** (00:05 en `America/Bogota` = 05:05 UTC). |
   | `GET /api/internal/jobs/{name}` (`daily-review`, `due-soon`, `pickup-expiration`) | Una sola tarea | Pruebas, ejecución manual y, si el plan de Vercel lo admite, una entrada para `pickup-expiration`. |

   - **Protección:** todos exigen `Authorization: Bearer ${CRON_SECRET}`, comparado en tiempo constante, y responden 401 `INVALID_CRON_SECRET` "No autorizado" si falta o no coincide. Un nombre o grupo desconocido responde 404, y solo después de validar el secreto.
   - **Idempotencia:**
     - `daily-review` y `pickup-expiration`, por la transición condicional.
     - `due-soon`, por el único `uk_notifications_recipient_loan_type`.
     - Repetir `daily` el mismo día no duplica nada. Cada tarea procesa todo lo pendiente hasta "ahora", con una transacción por préstamo.
   - **Ejecución del grupo:** cada tarea corre en su propia transacción y con su propio MDC (`requestId=job-<nombre>-<uuid>`). El fallo de una se registra con ERROR y no impide la siguiente. La respuesta es 204 si todas terminaron y 500 `INTERNAL_ERROR` si alguna falló; el detalle va al log, nunca a la respuesta.
4. **Entradas de cron en `vercel.json`:**
   - Solo una obligatoria, `daily` a las 05:05 UTC. Añadir otra tarea diaria no toca `vercel.json`: basta con implementar `InternalJob` con el grupo `daily`.
   - `pickup-expiration` solo lleva entrada propia si el plan lo admite, porque su frecuencia es de un minuto.
   - El número de tareas de cron y la frecuencia mínima del plan de Vercel del proyecto **deben verificarse antes de desplegar**: verificación pendiente, este ADR no fija esos límites.
   - Si el plan no admite la entrada de `pickup-expiration`, rigen `@Scheduled` en proceso y las lecturas que aplican la regla con el reloj (punto 5), así que la corrección no depende de Vercel Cron (R-1).
   - **Alternativas descartadas:**
     - Un endpoint y una entrada de cron por tarea diaria: consume más entradas del plan y obliga a tocar `vercel.json` con cada tarea nueva.
     - Que `daily-review` llame a `DueSoonAlertJob`: crea la dependencia `loans → notifications`.
     - Disparar `due-soon` con un evento publicado por `daily-review`: oculta el disparo y mezcla dos tareas en una transacción de eventos.
5. **Lecturas que no dependen del momento en que corre la tarea** (aceptadas, A-12; riesgo R-1): la consulta de retenidas y el conteo de préstamos en curso ignoran un APROBADO con `pickup_deadline <= ahora` (equivale a lo que RN-05e.1 ya dice: deja de retener al vencer el plazo); la entrega exige `ahora < pickup_deadline` (ya lo garantiza `chk_loans_timeline`) y responde "Solo se entregan préstamos aprobados"; el límite de 3 no cuenta una SOLICITADO con `start_date < hoy`; la regla de RN-SH03.5 trata como vencido un ENTREGADO con `effective_end_date < hoy`.

**Alternativas descartadas:** ShedLock (añade una tabla y no aporta sobre la idempotencia ya garantizada); depender solo de Vercel Cron (en el plan Hobby la frecuencia y la precisión son limitadas); GitHub Actions programado (retrasos de varios minutos y dependencia de otra plataforma).

### 2.6 Seguridad

#### 2.6.1 Autenticación y autorización

- **Access token sin estado (D-8):** `spring-boot-starter-oauth2-resource-server`. `auth` emite el access token con `NimbusJwtEncoder` (HS256, clave de `JWT_SECRET` con al menos 256 bits; el arranque falla si es más corta) y lo valida con `NimbusJwtDecoder` con tolerancia de reloj de 30 s. Claims: `sub` (id del usuario), `role`, `sid` (id de la sesión de refresh, para trazas), `iss=prestalab`, `iat`, `exp` (15 min, ver 2.6.2). Contraseñas con BCrypt. En el inicio de sesión, si el correo no existe se compara contra un hash ficticio para que el tiempo de respuesta no revele qué dato falló (RN-01b.2).
- **Autorización:** reglas por URL (públicas: `POST /api/auth/register`, `/login`, `/refresh`, `/logout`, `GET /api/actuator/health`, `/api/docs/**`; `/api/internal/**` con secreto; todo lo demás `authenticated()`) más `@PreAuthorize` por método con la matriz del Anexo A (`@EnableMethodSecurity`). La titularidad (cancelar, ver detalle, leer alertas propias) se valida en el servicio porque requiere datos.
- **CORS restringido:** `CorsConfigurationSource` con orígenes de `CORS_ALLOWED_ORIGINS` (vacío en producción: mismo origen; `http://localhost:4200` solo en `dev` si no se usa el proxy).
- **CSRF:** desactivado de forma global porque el access token viaja en la cabecera `Authorization`. Los dos únicos endpoints que usan la cookie (`/api/auth/refresh` y `/api/auth/logout`) quedan protegidos por `SameSite=Strict` y, además, rechazan con 403 toda petición cuyo `Origin` (o `Sec-Fetch-Site`) no sea el propio sitio.
- **Secretos solo por variables de entorno:** `DB_URL`, `DB_USER`, `DB_PASSWORD`, `JWT_SECRET`, `CRON_SECRET`, `CORS_ALLOWED_ORIGINS`, `SPRING_PROFILES_ACTIVE`, `SEED_PASSWORD` (solo con los perfiles `dev` o `demo`, 2.8), `BOOTSTRAP_ADMIN_EMAIL`, `BOOTSTRAP_ADMIN_NAME` y `BOOTSTRAP_ADMIN_PASSWORD_HASH` (primer ADMIN, 2.6.8). Ninguno tiene valor por defecto en `application-prod.yml`. El refresh token no usa secreto propio (es aleatorio y se guarda hasheado).
- **Alternativa descartada:** filtro JWT propio (`JwtAuthenticationFilter`) con jjwt. Funciona, pero reimplementa validaciones que el resource server ya trae probadas.

#### 2.6.2 Sesión con access token y refresh token (D-19)

**Duraciones (decididas por el usuario, P-1)**

| Parámetro | Valor | Propiedad |
|---|---|---|
| Access token | 15 min, recortado a `session_expires_at` si este llega antes | `prestalab.auth.access-token-ttl=PT15M` |
| Refresh token (inactividad) | 30 min deslizantes desde la última rotación, que ocurre como mucho 1 min después de cada actividad (ver "Rotación por actividad") | `prestalab.auth.refresh-token-ttl=PT30M` |
| Intervalo mínimo entre rotaciones por actividad | 1 min | `prestalab.auth.activity-rotation-interval=PT1M` (lo aplica el cliente) |
| Vida máxima de la sesión, ESTUDIANTE | 1 h desde el inicio de sesión | `prestalab.auth.session-max-lifetime.estudiante=PT1H` |
| Vida máxima de la sesión, ENCARGADO | 8 h | `prestalab.auth.session-max-lifetime.encargado=PT8H` |
| Vida máxima de la sesión, ADMIN | 8 h (confirmado, P-1b) | `prestalab.auth.session-max-lifetime.admin=PT8H` |
| Tolerancia de reloj al validar el JWT | 30 s | `prestalab.auth.clock-skew=PT30S` |

Consecuencias: una sesión termina por lo primero que ocurra: 30 min sin actividad (RN-SH09.2), la vida máxima de su rol (RN-SH09.1) o el cierre de sesión (RN-SH09.5). Un ESTUDIANTE vuelve a iniciar sesión como mínimo cada hora. Un usuario activo renueva como mucho una vez por minuto. La vida máxima se fija al iniciar sesión según el rol de ese momento y se guarda en `session_expires_at`.

**Tokens y dónde viven**

| Token | Formato | Dónde lo guarda el servidor | Dónde lo guarda el navegador |
|---|---|---|---|
| Access token | JWT HS256 con `sub`, `role`, `sid`, `exp` | No se guarda (sin estado) | Solo en memoria: un signal de `AuthService`. Nunca en `localStorage`, `sessionStorage` ni cookies. Se pierde al recargar y se recupera con una renovación silenciosa. |
| Refresh token | 32 bytes aleatorios (`SecureRandom`) en Base64URL, opaco | Solo su SHA-256 en `refresh_tokens` (una fila por sesión, Anexo D) | Cookie `prestalab_rt`: `HttpOnly`, `Secure` (desactivable solo en `dev`), `SameSite=Strict`, `Path=/api/auth`, `Max-Age` igual a su expiración. JavaScript no puede leerla y solo viaja a `/api/auth/*`. |

SHA-256 es suficiente para el refresh token porque tiene 256 bits de entropía (no es una contraseña) y permite buscarlo por índice; BCrypt no permitiría la búsqueda.

**Flujo**

1. **Inicio de sesión** (`POST /api/auth/login`): aplica el límite de intentos (2.6.5), valida credenciales, aplica la regla de sesión única (2.6.4), crea la sesión en `refresh_tokens` con `session_expires_at` según el rol, devuelve `AuthResponse` y fija la cookie.
2. **Uso normal:** el frontend envía `Authorization: Bearer <access>` en cada petición.
3. **Renovación** (`POST /api/auth/refresh`, sin cuerpo, con la cookie), en una transacción:
   1. Calcula el SHA-256 de la cookie y bloquea la fila con `token_hash = ?` (`FOR UPDATE`).
   2. Si no la encuentra, busca `previous_token_hash = ?`: si existe, es **reutilización** de un token ya rotado (posible robo): revoca la sesión (`REUSE_DETECTED`), registra WARN y responde 401 `SESSION_EXPIRED`.
   3. Según el estado de la sesión:
      - Desplazada por otro inicio de sesión (`REPLACED`): 401 `SESSION_REPLACED` (RN-SH10.3).
      - Cerrada por un ADMIN (`CLOSED_BY_ADMIN`), revocada por baja (`ACCOUNT_DISABLED`) o cuenta con `deleted_at` aunque la sesión no estuviera revocada: 401 `SESSION_INVALIDATED` (RN-SH09.4, RN-SH12.3); en el último caso revoca con `ACCOUNT_DISABLED`.
      - Vencida por inactividad o vida máxima, cerrada con `LOGOUT`, `EXPIRED` o `REUSE_DETECTED`: 401 `SESSION_EXPIRED` (RN-SH09.3); si estaba vencida y sin revocar, la revoca con `EXPIRED`.
   4. Si es válida, **rota**: genera un token nuevo, mueve el hash actual a `previous_token_hash`, guarda el nuevo en `token_hash`, incrementa `rotation_count`, fija `expires_at = MIN(ahora + 30 min, session_expires_at)` y emite un access token nuevo con `exp = MIN(ahora + 15 min, session_expires_at)` y el rol leído de `users`.
   5. Responde 200 con `AuthResponse` y la cookie nueva. Cada refresh token sirve una sola vez.
4. **Cierre de sesión** (`POST /api/auth/logout`, con la cookie): revoca la sesión (`LOGOUT`), borra la cookie (`Max-Age=0`) y responde 204. Es idempotente: sin cookie o con una cookie inválida también responde 204. Como la sesión queda revocada, `ActiveSessionInterceptor` rechaza de inmediato cualquier petición con el access token anterior (401 `SESSION_EXPIRED`).
5. **Recarga de página:** al arrancar, la aplicación Angular (`provideAppInitializer`) llama a `/api/auth/refresh`; si responde 200 restaura la sesión, si responde 401 queda sin sesión y muestra el inicio de sesión.

**Entradas, salidas y errores**

| Endpoint | Entrada | 2xx | Errores |
|---|---|---|---|
| `POST /api/auth/login` | `LoginRequest {email, password, replaceExistingSession}` (el último es opcional, `false` por defecto) | 200 `AuthResponse {accessToken, tokenType: "Bearer", expiresAt, sessionExpiresAt, user: {id, fullName, role}}` + `Set-Cookie: prestalab_rt` | 400 `VALIDATION_ERROR` (solo campos vacíos o demasiado largos); 401 `INVALID_CREDENTIALS` "Credenciales inválidas", idéntico para contraseña incorrecta, correo inexistente, cuenta dada de baja y cuenta bloqueada (D-25); 409 `ACTIVE_SESSION_EXISTS` (solo con credenciales correctas, 2.6.4); 429 `TOO_MANY_ATTEMPTS` (por IP, 2.6.5) |
| `POST /api/auth/refresh` | Cookie `prestalab_rt`; sin cuerpo | 200 `AuthResponse` + `Set-Cookie` con el token rotado | 401 `SESSION_EXPIRED` "Tu sesión expiró. Inicia sesión de nuevo" (ausente, desconocido, vencido por inactividad o vida máxima, cerrado por el usuario o reutilizado; el motivo real solo va al log); 401 `SESSION_REPLACED` (desplazada por otro inicio de sesión); 401 `SESSION_INVALIDATED` (cerrada por un ADMIN o cuenta dada de baja); en todos los casos la cookie se borra; 403 `ACCESS_DENIED` por `Origin` ajeno |
| `POST /api/auth/logout` | Cookie `prestalab_rt` (opcional) | 204 + cookie borrada | 403 `ACCESS_DENIED` por `Origin` ajeno |

**Frontend (interceptores y tiempos)**

- Orden: `provideHttpClient(withInterceptors([errorInterceptor, authInterceptor]))`. `authInterceptor` es el interno: ve primero la respuesta, así que puede renovar y reintentar antes de que `errorInterceptor` traduzca el error para la interfaz.
- `authInterceptor` añade `Authorization` a toda petición a `environment.apiUrl` excepto `/auth/login`, `/auth/register`, `/auth/refresh` y `/auth/logout`, y registra la actividad en `AuthService`.
- **Renovación reactiva:** ante un 401 `UNAUTHENTICATED` en una petición que llevaba token, lanza una única renovación compartida (si ya hay una en curso, espera la misma; patrón single-flight con `shareReplay(1)`) y reintenta la petición original una sola vez. Si la renovación responde `SESSION_EXPIRED`, `SESSION_REPLACED` o `SESSION_INVALIDATED`, limpia la sesión y navega a `/login?returnUrl=...` con el texto de ese código. No renueva ante `INVALID_CREDENTIALS`, `SESSION_INVALIDATED`, `SESSION_REPLACED` ni ante errores de los propios endpoints `/auth/*`.
- **Rotación por actividad (exigida por RN-SH09.2):** la inactividad de 30 min se cuenta desde la última actividad, no desde la última renovación.
  - Actividad es una interacción del usuario (teclado, ratón o toque) o una petición que él inicia. Las consultas automáticas en segundo plano, como el contador de alertas, se marcan con un `HttpContext` y no cuentan.
  - Ante cada actividad, si la última rotación fue hace 1 min o más, `AuthService` llama a `/api/auth/refresh` en segundo plano. Así la última rotación queda siempre como mucho 1 min antes de la última actividad, y el servidor, que vence el refresh token 30 min después de la última rotación, cierra la sesión entre 29 y 30 min después de la última actividad, sin guardar la actividad en cada petición.
  - El cliente además cierra la sesión localmente a los 30 min exactos sin actividad y muestra "Tu sesión expiró. Inicia sesión de nuevo".
  - Cumple los escenarios de SH-09: con actividad a las 9:10 y acción a las 9:41, la sesión expiró; con actividad a las 9:20 y acción a las 9:45, sigue activa.
  - Costo: como mucho una renovación por minuto por usuario activo. Cada rotación también renueva el access token, así que un 401 por access token vencido solo ocurre tras 15 min sin actividad.
- **Fin de la vida máxima:** con `sessionExpiresAt` de la respuesta, el layout muestra un aviso 5 min antes ("Tu sesión terminará a las HH:MM. Guarda tus cambios"; para un ESTUDIANTE, a los 55 min) y al llegar la hora limpia la sesión y lleva al inicio de sesión con "Tu sesión expiró. Inicia sesión de nuevo".
- **Varias pestañas:** la renovación se serializa con la Web Locks API (`navigator.locks.request('prestalab-refresh', ...)`). Como la cookie es compartida, la segunda pestaña renueva con la cookie ya rotada y no dispara la detección de reutilización. Todas las pestañas comparten una sola sesión (2.6.4).
- Ante `SESSION_INVALIDATED` o `SESSION_REPLACED` en cualquier respuesta, cierra la sesión local, llama a `/auth/logout` y muestra el `detail` recibido: "Tu sesión ya no es válida. Inicia sesión de nuevo" o "Tu sesión fue cerrada porque iniciaste sesión en otro lugar".

**Alternativas descartadas:** JWT de larga duración sin renovación (no permite revocar ni cortar el acceso); refresh token en `localStorage` o `sessionStorage` (legible por cualquier script inyectado); access token en cookie (obligaría a protección CSRF en todos los endpoints); una fila por cada token emitido (la tabla crecería con cada renovación y el borrado físico está prohibido; una fila por sesión con `previous_token_hash` conserva la detección de reutilización del token inmediatamente anterior, que es el caso que importa: un token más antiguo no existe y se rechaza); refresh token JWT (no es revocable sin estado); renovación proactiva por temporizador sin condición de actividad (mantendría viva, hasta la vida máxima, una pestaña olvidada en un equipo compartido); renovación proactiva 60 s antes del vencimiento del access token condicionada a la actividad (revisiones anteriores: corría la ventana de inactividad hasta 15 min y no cumplía el escenario 2 de SH-09); guardar `last_activity_at` en el servidor en cada petición (una escritura por petición).

#### 2.6.3 Corte de acceso al dar de baja una cuenta (D-20)

Objetivo (P-9, opción B elegida por el usuario): una cuenta dada de baja, o una sesión cerrada por un ADMIN, desplazada o cerrada por el usuario, deja de tener acceso **en la petición siguiente**, sea lectura o escritura y sea cual sea el rol (RN-SH09.4, RN-SH12.3).

| Mecanismo | Qué hace | Costo |
|---|---|---|
| Access token de 15 min (se mantiene) | Transporta la identidad (`sub`), el rol y la sesión (`sid`) sin consultar la base para autenticar ni autorizar por rol. Ya no determina cuánto dura el acceso tras una revocación. | Ninguno adicional: las rotaciones por actividad (2.6.2) lo renuevan. |
| Verificación en cada renovación | `/api/auth/refresh` lee `users.deleted_at` y el estado de la sesión, y rechaza la renovación de una cuenta dada de baja o de una sesión revocada. Funciona aunque la baja se haga fuera de la aplicación (por ejemplo, con un script del administrador). | Ya incluida en la renovación. |
| Revocación inmediata de la sesión | La baja (2.6.6) y el cierre administrativo revocan la sesión en la misma transacción (motivos internos `ACCOUNT_DISABLED` y `CLOSED_BY_ADMIN`). | Un `UPDATE` por operación. |
| Comprobación de cuenta y sesión en **toda** petición autenticada | `ActiveSessionInterceptor` (ver "Implementación") en todas las peticiones autenticadas de todos los roles, lecturas incluidas. Responde 401 `SESSION_INVALIDATED` (cuenta dada de baja o sesión cerrada por un ADMIN), `SESSION_REPLACED` (sesión desplazada) o `SESSION_EXPIRED` (sesión cerrada por el usuario, vencida o inexistente). | Una lectura por llave primaria por petición autenticada. |

**Implementación (un solo punto de control):**
- **Componente:** un único `HandlerInterceptor` de `auth` (`ActiveSessionInterceptor`) registrado para `/api/**`. Excluye solo lo público: `/api/auth/register`, `/login`, `/refresh`, `/logout`, `/api/actuator/health`, `/api/docs/**` y `/api/internal/**`, que va con su secreto. `/api/auth/me` sí pasa por él.
- **Por qué un interceptor y no un filtro:** las excepciones de `preHandle` las resuelve el `GlobalExceptionHandler` con el mismo formato que el resto, y se ejecuta después de `UserMdcFilter`, así que el rechazo queda registrado con el usuario. Las rutas que no llegan a un controlador responden 404 sin datos, así que dejarlas fuera no abre ningún acceso. Alternativa válida y descartada: un filtro de Spring Security tras `BearerTokenAuthenticationFilter`, que obligaría a escribir la respuesta con `ProblemDetailFactory` fuera del advice.
- **Una sola consulta:** con JdbcTemplate (o una proyección de Spring Data), solo lectura, fuera de transacción. La conexión se toma y se devuelve en milisegundos, antes de que empiece la transacción del servicio.

  ```sql
  SELECT rt.revoked_at, rt.revoke_reason, rt.expires_at, rt.session_expires_at, u.deleted_at
  FROM refresh_tokens rt
  JOIN users u ON u.id = rt.user_id
  WHERE rt.id = :sid AND rt.user_id = :sub
  ```

  Usa la llave primaria de `refresh_tokens` (`sid` del token) y la de `users`, y el `user_id = :sub` evita usar un `sid` ajeno. No hacen falta índices nuevos.
- **Resultado, en este orden:**
  1. Fila inexistente: `SESSION_EXPIRED`.
  2. `deleted_at` no nulo, o `revoke_reason` `ACCOUNT_DISABLED` o `CLOSED_BY_ADMIN`: `SESSION_INVALIDATED`.
  3. `REPLACED`: `SESSION_REPLACED`.
  4. `LOGOUT`, `EXPIRED`, `REUSE_DETECTED`, o `session_expires_at` ≤ ahora: `SESSION_EXPIRED`.
  5. En otro caso continúa.
  - `expires_at` (inactividad del refresh) no se usa aquí, porque el access token siempre vence antes (15 < 30 min).
- **Falla cerrada:** si la consulta falla (base no disponible, tiempo agotado), la petición no continúa y responde 500 `INTERNAL_ERROR` con su `requestId`. Nunca se deja pasar por defecto.
- **Sin caché (regla de 4.1):** el resultado no se guarda en Caffeine ni en ninguna caché entre peticiones, porque es una decisión de acceso que depende de cambios concurrentes (una baja o un cierre en otra instancia). Una caché reintroduciría la ventana y la inconsistencia entre instancias. Solo se reutiliza dentro de la misma petición, como atributo de la petición.
- **Consultas de sesión por petición:** todas las de usuarios autenticados las hace este interceptor; ningún servicio repite la comprobación. Las operaciones que necesitan bloquear al usuario (`lockStudentForUpdate`) siguen comprobando `deleted_at` bajo el bloqueo, para cubrir la carrera con una baja simultánea (2.6.6).

**Rendimiento:**
- **Costo por petición:** una consulta por llave primaria con una unión de dos filas: microsegundos en MySQL más un viaje de red a Aiven, de unos pocos milisegundos si Vercel y Aiven están en la misma región (requisito de despliegue, Anexo C). Para el volumen esperado del proyecto (decenas de usuarios simultáneos), el aumento de latencia es pequeño frente al resto de la petición.
- **Pool de conexiones:** la consulta ocupa una conexión del pool (5 por instancia) durante milisegundos y la libera antes de la transacción del servicio, así que no se retienen dos conexiones a la vez (R-4).
- **Arranque en frío:** añade una consulta a la primera petición; es despreciable frente al arranque de la JVM (R-3).
- Si el volumen creciera mucho, la evolución sería mover el estado de sesión a un almacén compartido (por ejemplo Redis) con invalidación explícita, no una caché local.

**Un solo código para baja y cierre administrativo.** La sesión de una cuenta dada de baja y la cerrada por un ADMIN reciben el mismo 401 `SESSION_INVALIDATED` con el texto "Tu sesión ya no es válida. Inicia sesión de nuevo", que ambas historias exigen (RN-SH09.4, RN-SH12.3). No se usan dos códigos (ni el antiguo `ACCOUNT_DISABLED`) porque el `code` es visible para el cliente y uno distinto le revelaría que su cuenta fue dada de baja, lo que RN-SH08.2 prohíbe. El motivo real (`ACCOUNT_DISABLED` o `CLOSED_BY_ADMIN`) queda en `refresh_tokens.revoke_reason` y en el log.

**Corte real (revisión 7):** la cuenta dada de baja, la sesión cerrada por un ADMIN, la desplazada y la cerrada por el usuario reciben 401 en **la siguiente petición autenticada**, sea lectura o escritura, de cualquier rol. Ya no existe la ventana de 15 min 30 s de las revisiones anteriores ni la diferencia entre personal y estudiantes, y se cumple literalmente RN-SH12.3 ("inmediato") y, con margen, RN-SH09.4 ("a más tardar 15 minutos").

**Cliente manipulado:** un cliente que no renueve o que conserve un access token de 15 min no obtiene ventaja. El token sigue siendo criptográficamente válido, pero cada uso pasa por la comprobación de sesión y recibe 401 en cuanto la sesión o la cuenta dejan de estar activas. El único riesgo residual de un access token robado es usarlo mientras la sesión legítima siga activa, el mismo de cualquier token portador; se corta con el cierre de sesión, el cierre administrativo o la baja (R-10).

**Alternativas descartadas:**
- Comprobar solo escrituras y peticiones de personal (O-1, revisión 6): dejaba hasta 15 min 30 s de lecturas a un estudiante con un cliente manipulado y no cumplía RN-SH12.3.
- Verificación cacheada 60 s por instancia o lista de cuentas bloqueadas en caché local: reintroducen una ventana y son inconsistentes entre instancias.
- Acortar el access token: contradice la decisión del usuario y no daría un corte inmediato.
- Introspección del token contra un servicio externo: no hay tal servicio y añade otra dependencia.

#### 2.6.4 Una sola sesión activa por usuario (D-22)

- **Invariante:** cada usuario tiene como máximo una fila de `refresh_tokens` con `revoked_at IS NULL`. Se garantiza en la base con un índice único sobre una columna generada (Anexo D) y en el servicio bloqueando la fila de `users` (`FOR UPDATE`) durante el inicio de sesión. Todas las pestañas de un mismo navegador comparten esa sesión porque comparten la cookie.
- **Inicio de sesión con otra sesión existente:**
  1. Tras validar el límite de intentos y las credenciales, bloquea `users` y busca la sesión no revocada del usuario.
  2. Si existe pero está vencida (`expires_at` o `session_expires_at` ≤ ahora), la revoca con `EXPIRED` y continúa.
  3. Si existe, es vigente y `replaceExistingSession` es `false`, responde 409 `ACTIVE_SESSION_EXISTS` "Ya tienes una sesión activa en otro lugar" (RN-SH10.2) con la extensión `activeSession: {startedAt, lastActivityAt}`. No incluye IP ni dispositivo. Es compatible con la regla de no revelación (2.6.5): solo se llega aquí con correo y contraseña correctos de una cuenta activa y no bloqueada, así que no da información a quien no conoce las credenciales. Reinicia el contador de intentos fallidos.
  4. El frontend muestra el aviso con dos opciones: cerrar la otra sesión e ingresar, o cancelar el ingreso (que deja la otra sesión activa, escenario 3 de SH-10). Si confirma, repite `POST /api/auth/login` con las mismas credenciales (que solo viven en el formulario) y `replaceExistingSession: true`.
  5. El servidor revoca la sesión anterior (`REPLACED`), crea la nueva y responde 200.
- **Qué le pasa a la sesión desplazada:** no puede renovar ni escribir (401 `SESSION_REPLACED`, "Tu sesión fue cerrada porque iniciaste sesión en otro lugar", RN-SH10.3). Con la comprobación en toda petición (2.6.3), pierde también las lecturas de inmediato, sea cual sea el rol. `SESSION_REPLACED` se usa **solo** para este caso; la sesión cerrada por un ADMIN recibe `SESSION_INVALIDATED`.
- **Qué significa "cerrar otras sesiones" en este ADR (cerrado):** hay exactamente dos mecanismos y **no existe cierre de otras sesiones desde dentro de una sesión activa**.
  1. **Reemplazo confirmado al iniciar sesión:** 409 `ACTIVE_SESSION_EXISTS` y nuevo `POST /api/auth/login` con `replaceExistingSession: true`. Es lo que RN-SH10.2 llama "cerrar la otra sesión", y cubre las demás sesiones de la cuenta porque por la invariante solo puede haber una.
  2. **Cierre administrativo** (SH-12): `DELETE /api/users/{id}/session`, solo ADMIN. Revoca la sesión vigente con `CLOSED_BY_ADMIN` y la persona recibe `SESSION_INVALIDATED`. Es también la vía urgente para cortar una cuenta comprometida que no se puede dar de baja porque tiene préstamos en curso (2.6.6).

  Desde una sesión activa el usuario solo puede cerrar la propia (`POST /api/auth/logout`, RN-SH09.5).
- **Concurrencia:** dos inicios de sesión simultáneos del mismo usuario se serializan por el bloqueo de `users`; si aun así chocan, el índice único lo impide y la violación se traduce a 409 `ACTIVE_SESSION_EXISTS`.
- **Alternativas descartadas:** varias sesiones con un tope (el usuario pidió una sola); que el último inicio de sesión desplace al anterior sin avisar (el usuario pidió informar y ofrecer el cierre); un token de "toma de sesión" en la respuesta 409 para no reenviar la contraseña (añade otro secreto con su ciclo de vida; reenviar las credenciales desde el formulario es más simple).

#### 2.6.5 Límite de intentos de inicio de sesión (D-23)

- **Regla (aceptada, P-4b):** tras 3 fallos consecutivos de una misma cuenta, la cuenta queda bloqueada para iniciar sesión 15 min contados desde el tercer fallo. Los intentos durante el bloqueo no cuentan ni lo alargan, para que nadie pueda mantener bloqueada una cuenta indefinidamente con pocos intentos. Un inicio de sesión correcto reinicia el contador; al vencer el bloqueo, el contador vuelve a 0 (RN-SH11.1, RN-SH11.4, RN-SH11.5).
- **Correo inexistente (RN-SH11.6):** "cuenta intentos y se bloquea igual". No hace falta guardar nada: un correo sin cuenta nunca puede iniciar sesión y su respuesta es siempre la misma que la de una cuenta bloqueada, así que el comportamiento observable ya es idéntico. Si ese correo se registra después, la cuenta nueva empieza con el contador en 0.
- **Regla de no revelación (decisión del usuario, D-25):** ningún mensaje, código ni tiempo de respuesta del inicio de sesión revela si un correo existe ni qué dato es incorrecto.
  - Contraseña incorrecta, correo inexistente, cuenta dada de baja y cuenta bloqueada (incluso con la contraseña correcta) devuelven exactamente la misma respuesta: 401, `code = INVALID_CREDENTIALS`, "Credenciales inválidas" (texto de RN-01b.2), sin extensiones.
  - El motivo real (`UNKNOWN_EMAIL`, `BAD_PASSWORD`, `ACCOUNT_DISABLED`, `ACCOUNT_LOCKED`) solo existe dentro del servidor, en la propiedad interna `reason` de `InvalidCredentialsException`, y solo se escribe en el log (`login_failed reason=...`, con el correo resumido por hash, nunca en claro). Nunca llega al `ProblemDetail`.
  - `LoginRequest` solo valida presencia y longitud máxima: no valida el formato ni el dominio del correo en el inicio de sesión (eso es del registro), para que una respuesta 400 no indique qué dato está mal. Un correo mal formado termina en el mismo 401.
  - **Tiempo igualado:** correo inexistente o cuenta dada de baja se comparan contra un hash BCrypt ficticio; con la cuenta bloqueada se ejecuta igualmente la comparación BCrypt y se descarta el resultado. Además, toda respuesta fallida del inicio de sesión se entrega no antes de un piso fijo (`prestalab.auth.login-failure-min-duration=PT0.5S`, mayor que BCrypt más la escritura del contador), para que la actualización del contador, que solo ocurre con cuentas existentes, no se note en el tiempo.
  - Las únicas otras respuestas del inicio de sesión no dependen de la cuenta o exigen conocer las credenciales: 429 `TOO_MANY_ATTEMPTS` se decide por IP antes de buscar la cuenta y es idéntico para cualquier correo; 409 `ACTIVE_SESSION_EXISTS` solo se alcanza con credenciales correctas de una cuenta activa (2.6.4); 400 `VALIDATION_ERROR` solo por campos vacíos o demasiado largos.
  - El formulario muestra siempre la nota fija "Después de 3 intentos fallidos, el acceso se bloquea durante 15 minutos" y, ante cualquier 401 del inicio de sesión, el mismo mensaje "Credenciales inválidas", sin lógica distinta según el caso.
  - Fuera del inicio de sesión: `SESSION_INVALIDATED`, `SESSION_EXPIRED` y `SESSION_REPLACED` solo los recibe quien ya tiene una sesión de esa cuenta (no permiten enumerar correos), y ninguno distingue una cuenta dada de baja de una sesión cerrada (RN-SH08.2); `USER_NOT_FOUND` solo lo recibe un ADMIN autenticado en `/api/users/**`. El texto "Tu sesión ya no es válida..." nunca aparece en el inicio de sesión (RN-SH09.4).
  - **Excepción aceptada: el registro.** El usuario decidió que el registro sí puede indicar que ya existe una cuenta con el correo ("Ya existe una cuenta asociada a ese correo", RN-01a.2, PA-34). La regla de no revelación aplica al inicio de sesión, al bloqueo y a sus errores. El limitador por IP se aplica también a `POST /api/auth/register` (R-21).
- **Almacenamiento: columnas en `users`** (`failed_login_attempts`, `login_locked_until`, `last_failed_login_at`; Anexo D). Motivos: la regla es por cuenta y por fallos consecutivos, así que basta un estado, no un historial; se actualiza de forma atómica bajo el mismo bloqueo de `users` que ya toma el inicio de sesión (2.6.4); no crece con cada intento (el borrado físico está prohibido); y no requiere consultas por ventana de tiempo. Se descarta una tabla `login_attempts`: una fila por intento sin poder borrarla, índices por correo, IP y tiempo, y consultas por ventana, solo para auditoría; esa auditoría va al log (`login_failed reason=BAD_PASSWORD|UNKNOWN_EMAIL|ACCOUNT_DISABLED|ACCOUNT_LOCKED`, con el correo resumido por hash, nunca en claro). Si más adelante se exige auditoría en base, se añade una tabla de solo inserción.
- **Detalle transaccional:** el incremento del contador debe confirmarse aunque la respuesta sea un error, por eso se ejecuta en una transacción propia (`REQUIRES_NEW`) que bloquea la fila de `users`.
- **Límite por origen (aceptado, P-4c; RN-SH11.8, PA-35):** un limitador en memoria por instancia (Caffeine) usa una **ventana fija por IP que empieza en el primer intento fallido de la serie**. Funciona así:
  - Cuenta los inicios de sesión fallidos, sea cual sea el correo.
  - Al décimo fallo, el origen queda bloqueado hasta que se cumplan 15 min desde ese primer fallo. Al terminar la ventana, el contador del origen vuelve a 0.
  - Mientras dura el bloqueo, todo intento de ese origen, incluso con credenciales correctas (escenario 7 de SH-11), recibe 429 `TOO_MANY_ATTEMPTS` "Demasiados intentos. Inténtalo de nuevo más tarde", con `Retry-After`. Se responde antes de buscar la cuenta, así que no depende del correo.
  - Un inicio de sesión correcto desde el origen no reinicia su serie.
  - El registro usa un limitador aparte con la misma forma, contando todos sus intentos.
  - Mitiga el rociado de contraseñas sobre muchas cuentas y el bloqueo masivo de cuentas ajenas. La IP se toma del primer valor de `X-Forwarded-For` que añade Vercel, solo en los perfiles desplegados detrás de Vercel. Al ser por instancia es un límite aproximado (riesgo R-18).

#### 2.6.6 Baja de cuentas (D-24)

Alcance decidido (P-2): solo dar de baja cuentas, sin cambio de roles ni reactivación. Historias: SH-08 (baja de cuentas, RN-SH08.3 con PA-29 y PA-36 para los préstamos en curso) y SH-12 (cierre de la sesión de otra cuenta, PA-33). Este apartado fija su contrato técnico.

- **Endpoints (solo ADMIN, contrato en el Anexo A):**
  - `GET /api/users`: busca por nombre o correo (`q`), rol y estado, y lista las cuentas con su estado, activa o dada de baja (RN-SH08.7).
  - `GET /api/users/by-email?email=`: localiza una cuenta por su correo exacto; 404 `USER_NOT_FOUND` "Usuario no encontrado" si no existe (RN-SH08.7, RN-SH12.2).
  - `DELETE /api/users/{id}`: baja lógica.
  - `DELETE /api/users/{id}/session`: cierre administrativo de la sesión (SH-12).
- **Reglas de la baja, en este orden** (RN-SH08.1 fija que, si se cumplen las dos primeras a la vez, gana `LAST_ADMIN`):
  1. 404 `USER_NOT_FOUND` si la cuenta no existe.
  2. Si la cuenta ya está dada de baja, responde 200 con su `deactivatedAt` original y `sessionRevoked: false`: la operación es idempotente y no necesita un mensaje que las historias no definen.
  3. 409 `LAST_ADMIN` "Debe existir al menos un administrador activo" si la cuenta es el último ADMIN activo (RN-01a.4). Para que dos ADMIN no se den de baja mutuamente a la vez, cuando el objetivo es ADMIN se bloquean todas las filas de ADMIN activos en orden de `id`.
  4. 409 `CANNOT_DEACTIVATE_SELF` "No puedes darte de baja a ti mismo".
  5. 409 `USER_HAS_LOANS_IN_PROGRESS` "La cuenta tiene préstamos en curso" (confirmado, RN-SH08.3, PA-36) si el titular tiene cualquier préstamo SOLICITADO, APROBADO, ENTREGADO o VENCIDO. Incluye la extensión `loans: [{loanId, status, startDate, endDate}]` para que el ADMIN sepa qué falta por cerrar. No se modifica nada: **la baja nunca cancela, rechaza ni modifica préstamos** (RN-SH08.4).
  - El correo sigue reservado (el único de `users.email` incluye las bajas): no puede volver a registrarse, porque no hay reactivación (RN-SH08.5).
- **Reglas del cierre administrativo de sesión (SH-12):**
  - 404 `USER_NOT_FOUND` si la cuenta no existe.
  - 409 `NO_ACTIVE_SESSION` "La cuenta no tiene sesión activa" (RN-SH12.4) si no hay una sesión no revocada y vigente. Una sesión vencida pero aún no revocada se revoca con `EXPIRED` y también responde 409. Se elige 409 y no 204 porque el ADMIN debe ver el mensaje de la historia y la petición no pudo cumplir su efecto por el estado del recurso.
  - Si hay sesión, la revoca con `CLOSED_BY_ADMIN` y `revoked_by` igual al ADMIN, y responde 204. La persona recibe 401 `SESSION_INVALIDATED` al usar la sesión (RN-SH12.3) y puede volver a iniciar sesión (RN-SH12.5).
  - Un ADMIN puede cerrar su propia sesión por esta vía; equivale a cerrar sesión.
- **Transacción** (orden users → refresh_tokens; los préstamos solo se leen):
  1. Bloquea la fila del usuario (`FOR UPDATE`) y, si el objetivo es ADMIN, las de los ADMIN activos, y valida las reglas que dependen solo de `users`.
  2. Llama a `auth.api.UserLoanActivityService`, implementado por `loans` (inversión de dependencias como la de `catalog`, 1.3: `auth` no puede depender de `loans`). Devuelve los préstamos en curso del titular con una lectura sin bloqueo (READ COMMITTED, posterior al bloqueo de `users`). Si la lista no está vacía, lanza `USER_HAS_LOANS_IN_PROGRESS` y no cambia nada.
  3. Fija `deleted_at` y `deactivated_by` (Anexo D).
  4. Revoca la sesión vigente con el motivo interno `ACCOUNT_DISABLED`; la persona recibe `SESSION_INVALIDATED` al usarla.
  5. Responde 200 `UserDeactivationResponse {userId, deactivatedAt, sessionRevoked}`.
- **Cómo queda una cuenta sin préstamos en curso** antes de darla de baja, con los flujos que ya existen:
  - SOLICITADO: el titular la cancela (SH-07), un ENCARGADO la rechaza con motivo (HU-05a) o se rechaza sola al pasar su día de inicio (RN-05a.11).
  - APROBADO: el titular lo cancela antes de su plazo de recogida (SH-07) o se cierra solo como "No recogido" (HU-05e); un APROBADO no se rechaza manualmente.
  - ENTREGADO o VENCIDO: el encargado registra la devolución (HU-05c, HU-05d).
- **Concurrencia con una solicitud simultánea:** crear una solicitud es la única operación que hace aparecer un préstamo en curso, y ya bloquea la fila del estudiante (`UserDirectoryService.lockStudentForUpdate`, sección 3, punto 5). Por eso la baja y la solicitud se serializan sobre `users`:
  - Si la solicitud confirma primero, la baja, al obtener el bloqueo, ve la SOLICITADO y responde 409 `USER_HAS_LOANS_IN_PROGRESS`.
  - Si la baja confirma primero, la solicitud, al obtener el bloqueo, recibe la cuenta con `deleted_at` (el snapshot de `lockStudentForUpdate` incluye si está activa) y responde 401 `SESSION_INVALIDATED` "Tu sesión ya no es válida. Inicia sesión de nuevo" sin crear nada (escenario 5 de SH-09). Esto cubre la carrera en que `ActiveSessionInterceptor` validó la sesión justo antes de la baja.
  - Las demás transiciones (aprobar, entregar, devolver, cancelar, cierres automáticos) solo mueven préstamos entre estados en curso o los sacan de ese conjunto. Si una de ellas confirma durante la baja, el peor caso es un 409 conservador que el ADMIN resuelve reintentando. Por eso la baja no necesita bloquear préstamos.
- **Urgencia:** si hay que cortar ya el acceso de una cuenta con préstamos en curso (por ejemplo, una cuenta comprometida), el ADMIN cierra su sesión con `DELETE /api/users/{id}/session`. La persona puede volver a iniciar sesión con sus credenciales; el cambio de credenciales queda fuera del alcance actual (riesgo R-20).
- Las sanciones y el historial se conservan.
- **Baja de un ENCARGADO o ADMIN:** sus acciones pasadas siguen referenciadas por id (sin `@SQLRestriction` en `users`, R-7); deja de recibir alertas porque `findActiveIdsByRoles` excluye las bajas.

**OpenAPI y autorización:** ver el Anexo A (tabla y fragmento YAML).

#### 2.6.7 Lista cerrada de cambios de texto para el readme

Es la única lista de cambios de texto del readme derivados de este ADR. La aplica `docs-writer` (`/actualizar-documentacion`) y no debe ampliarse sin una nueva revisión del ADR. Los diagramas se rigen por 5.1 y 5.2. "Actual" cita el texto vigente del readme; "Nuevo" es el texto que lo sustituye (puede ajustarse la redacción, no el contenido).

**Sección 0.4 (URL del proyecto), revisión 7e**

| # | Actual | Nuevo |
|---|---|---|
| 0.4-1 | (no existe) | Subapartado "Cuentas de prueba" con la tabla de correos y roles de 2.8 (`admin.demo@institucion.edu`, `encargado1.demo@institucion.edu`, `encargado2.demo@institucion.edu`, `estudiante1.demo@institucion.edu`, `estudiante2.demo@institucion.edu` y `estudiante3.demo@institucion.edu`), el uso sugerido de cada una, **la contraseña común de demostración** (decisión del usuario, P-12; el valor lo proporciona el usuario y debe coincidir con `SEED_PASSWORD` del entorno de evaluación en Vercel) y estas notas: "Contraseña exclusiva de demostración, válida solo en el entorno de evaluación. Cada evaluador debe usar una cuenta distinta, porque cada cuenta admite una sola sesión activa (iniciar sesión con la misma cuenta cierra la otra). Tras 3 intentos fallidos la cuenta se bloquea 15 minutos. Los datos son ficticios." |

**Sección 1.4 (instalación)**

| # | Actual | Nuevo |
|---|---|---|
| 1.4-1 | `# Documentación interactiva: http://localhost:8080/swagger-ui.html` | `# Documentación interactiva: http://localhost:8080/api/docs (especificación en /api/docs/v3/api-docs)` |
| 1.4-2 | `cp .env.example .env            # completa los valores locales` | Igual, y añadir debajo: "`.env.example` incluye `DB_*`, `JWT_SECRET`, `CRON_SECRET`, `CORS_ALLOWED_ORIGINS`, `SPRING_PROFILES_ACTIVE` y `SEED_PASSWORD`." |
| 1.4-3 | `./mvnw verify -Pintegration  # integración (Testcontainers, requiere Docker)` | `./mvnw verify -Pintegration  # integración y contrato OpenAPI (Testcontainers, requiere Docker)` |
| 1.4-4 | "El perfil `dev` carga `R__seed_dev.sql` con categorías, equipos y un usuario por rol (correos en el script; contraseña definida en `.env` como `SEED_PASSWORD`)." | "Los perfiles `dev` y `demo` crean las cuentas de prueba de la sección 0.4 y datos de ejemplo (equipos y préstamos en distintos estados) al arrancar, con la contraseña de `SEED_PASSWORD` del `.env`. El esquema siempre lo crean las migraciones Flyway; en `prod` sin `demo` no se siembra nada." |

**Sección 2.1 (arquitectura)**

| # | Actual | Nuevo |
|---|---|---|
| 2.1-1 | "(un paquete por módulo de negocio: `auth`, `catalog`, `loans`, `reports`)" | "(un paquete por módulo: `shared`, `auth`, `catalog`, `loans` (incluye sanciones), `notifications` y `reports`; definición en `docs/adr/0001-arquitectura.md`)" |
| 2.1-2 | "Vercel enruta `/api/*` al backend, así no hay CORS ni configuración de URLs por entorno." | "Vercel enruta `/api/*` al backend: mismo origen, CORS cerrado en producción (`CORS_ALLOWED_ORIGINS` vacío) y sin URLs por entorno." |

**Sección 2.2 (componentes), tabla**

| # | Actual | Nuevo |
|---|---|---|
| 2.2-1 | API REST: "... errores en formato `ProblemDetail`, documentación OpenAPI." | "... errores en formato `ProblemDetail` con `code` y `requestId`, documentación OpenAPI en `/api/docs` con contrato versionado en `docs/api/openapi.yaml`." |
| 2.2-2 | Seguridad: "Spring Security, JWT, BCrypt" / "Autenticación sin estado, autorización por rol con `@PreAuthorize`." | "Spring Security (OAuth2 Resource Server), JWT, refresh token, BCrypt" / "Access token de 15 min, refresh token rotativo de 30 min deslizantes en cookie `HttpOnly`, una sesión por usuario, límite de intentos, `@PreAuthorize` en cada endpoint y comprobación de cuenta y sesión." |
| 2.2-3 | Persistencia: "Entidades con borrado lógico (`@SQLDelete`, `@SQLRestriction`), mapeo entidad ↔ DTO." | "Entidades con borrado lógico por método de dominio (sin `@SQLRestriction` en `users` ni `equipment`), referencias entre módulos por id, mapeo entidad ↔ DTO con MapStruct." |
| 2.2-4 | Tareas programadas: "Spring `@Scheduled`" / "Marcar préstamos vencidos (SH-02)." | "Spring `@Scheduled` y Vercel Cron (`/api/internal/jobs/*` con `CRON_SECRET`)" / "Cierre de no recogidos, rechazo de solicitudes sin resolver, marcado de vencidos y alertas de próximo a vencer; tareas idempotentes." |
| 2.2-5 | (no existe) | Filas nuevas: "Caché / Caffeine / Solo categorías y resúmenes de equipos; nunca disponibilidad." · "Trazabilidad / `RequestTraceFilter`, MDC, SLF4J / `X-Request-Id`, línea de acceso por petición y `loan_status_history`." |
| 2.2-6 | Pruebas: "JUnit 5, Mockito, Testcontainers, ..." | Añadir "ArchUnit" a la tecnología y "fronteras de módulos y contrato OpenAPI" a la responsabilidad. |

**Sección 2.3 (estructura)**

| # | Actual | Nuevo |
|---|---|---|
| 2.3-1 | `│   │       ├── auth/        # controller, service, dto, security (JWT)` | `auth/ # cuentas, JWT, refresh token, sesiones, límite de intentos` |
| 2.3-2 | `│   │       ├── loans/       # solicitudes, ciclo del préstamo, disponibilidad` | `loans/ # solicitudes, ciclo del préstamo, disponibilidad, sanciones, tareas programadas` |
| 2.3-3 | (no existe) | Línea nueva: `notifications/ # alertas dentro de la aplicación` |
| 2.3-4 | `│   │       ├── reports/     # métricas y exportación CSV` | `reports/ # métricas y exportación CSV (vía api de otros módulos)` |
| 2.3-5 | `│   │       └── shared/      # errores (ProblemDetail), auditoría, configuración` | `shared/ # errores (ProblemDetail), trazabilidad, paginación, configuración` |
| 2.3-6 | (no existe) | Nota bajo el árbol: "Cada módulo: controller, service, repository, dto, mapper, entity, api, domain, exception y, si aplica, event y job." |
| 2.3-7 | `docs/` sin `api/` ni `adr/` | Añadir `api/ # openapi.yaml (contrato versionado)` y `adr/ # decisiones de arquitectura`. |
| 2.3-8 | `vercel.json              # servicios y enrutamiento en Vercel` | `vercel.json # servicios, enrutamiento y Vercel Cron` |

**Sección 2.4 (infraestructura y despliegue)**

| # | Actual | Nuevo |
|---|---|---|
| 2.4-1 | Paso 2: "GitHub Actions ejecuta pruebas unitarias, de integración y E2E" | "... pruebas unitarias, de arquitectura (ArchUnit), de integración, de contrato OpenAPI y E2E" |
| 2.4-2 | Paso 4: "(`DB_URL`, `DB_USER`, `DB_PASSWORD`, `JWT_SECRET`, `SPRING_PROFILES_ACTIVE=prod`)" | "(`DB_URL`, `DB_USER`, `DB_PASSWORD`, `JWT_SECRET`, `CRON_SECRET`, `CORS_ALLOWED_ORIGINS` vacío en producción, `SPRING_PROFILES_ACTIVE=prod`)" |
| 2.4-3 | (no existe) | Paso nuevo: "Vercel Cron invoca una sola vez al día `GET /api/internal/jobs/daily` (00:05 hora de la institución, 05:05 UTC) con `Authorization: Bearer ${CRON_SECRET}`; ejecuta la revisión diaria de préstamos y las alertas de próximo a vencer. El backend también ejecuta las tareas con `@Scheduled`. Antes de desplegar hay que verificar el límite de tareas de cron del plan de Vercel." |
| 2.4-4 | Paso 6: "pruebas de humo: `GET /api/actuator/health` y el flujo principal..." | "... `GET /api/actuator/health`, `/api/docs` y el flujo principal con Playwright (`@smoke`), que incluye inicio de sesión, renovación y cierre de sesión" |

**Sección 2.5 (seguridad), tabla y ejemplo**

| # | Actual | Nuevo |
|---|---|---|
| 2.5-1 | "Autenticación sin estado / JWT firmado (HS256) con expiración de 120 min; el secreto llega por `JWT_SECRET`." | "Sesión / Access token JWT HS256 de **15 min** (secreto `JWT_SECRET`) solo en memoria del navegador; refresh token opaco, de un solo uso y rotativo, de 30 min deslizantes, en cookie `HttpOnly`, `Secure`, `SameSite=Strict`, guardado como SHA-256; vida máxima de la sesión 1 h ESTUDIANTE y 8 h ENCARGADO y ADMIN." |
| 2.5-2 | "Autorización por rol / `@PreAuthorize` en cada endpoint de gestión ..." | "`@PreAuthorize` en cada endpoint; además, **toda** petición autenticada, de cualquier rol y también las consultas, comprueba que la cuenta siga activa y la sesión vigente con una consulta por llave primaria, sin caché ..." |
| 2.5-3 | "Errores / `ProblemDetail` sin trazas internas ni mensajes de la base de datos." | "... con `code` estable y `requestId`; los errores inesperados son genéricos y se registran con su `requestId`." |
| 2.5-4 | "Secretos / Variables de entorno en Vercel; ..." | Añadir "(`DB_*`, `JWT_SECRET`, `CRON_SECRET`)". |
| 2.5-5 | "Integridad y trazabilidad / Borrado lógico (`deleted_at`) y tabla `audit_log`; ..." | "Borrado lógico (`deleted_at`), `loan_status_history` en cada transición y línea de acceso con `X-Request-Id`; ..." (sin `audit_log`, que no existe). |
| 2.5-6 | "Mismo origen / El frontend y la API se sirven desde el mismo dominio, por lo que no se abre CORS." | "... mismo dominio; CORS restringido a `CORS_ALLOWED_ORIGINS` (vacío en producción)." |
| 2.5-7 | (no existe) | Filas nuevas: "Sesión única / una sesión activa por usuario; un nuevo inicio de sesión pide confirmar el cierre de la otra; el ADMIN puede cerrar la sesión de una cuenta." · "Cierre de sesión / `POST /api/auth/logout` revoca la sesión en el servidor." · "Límite de intentos / 3 fallos consecutivos bloquean la cuenta 15 min; máximo 10 intentos fallidos por origen cada 15 min." · "No revelación / contraseña incorrecta, correo inexistente, cuenta dada de baja o bloqueada reciben el mismo 'Credenciales inválidas' con tiempo igualado; el registro sí indica si el correo ya tiene cuenta (decisión aceptada)." · "Baja de cuenta / solo ADMIN, nunca la propia ni la del último ADMIN, y solo sin préstamos en curso; revoca la sesión y la persona pierde el acceso en su siguiente petición, sea consulta o acción ('Tu sesión ya no es válida. Inicia sesión de nuevo')." · "Cierre de sesión por el ADMIN / corta de inmediato la sesión de otra cuenta, con el mismo mensaje." · "CSRF / la API usa Bearer; los endpoints de la cookie exigen `SameSite=Strict` y `Origin` propio." |
| 2.5-8 | Ejemplo `@PatchMapping("/{id}/status")` con `changeStatus(id, LoanStatusRequest)` | `@PostMapping("/{id}/approval")` con `@PreAuthorize("hasAnyRole('ENCARGADO','ADMIN')")` y `approve(@PathVariable Long id, @AuthenticationPrincipal AuthenticatedUser user)` (sin `PATCH /status`). |

**Sección 2.6 (tests)**

| # | Actual | Nuevo |
|---|---|---|
| 2.6-1 | (no existe) | Filas nuevas: `ArchitectureTest` (fronteras de módulos y reglas de 1.5); `OpenApiContractIT` (el OpenAPI generado coincide con `docs/api/openapi.yaml`); IT de concurrencia de la aprobación (dos aprobaciones por la última unidad); pruebas de sesión (rotación, reutilización, vencimiento por inactividad y por vida máxima según el rol, sesión única, bloqueo tras 3 fallos con respuesta idéntica, cierre de sesión, baja rechazada con préstamos en curso); `ActiveSessionInterceptorIT` (tras una baja, un cierre administrativo, un desplazamiento o un cierre de sesión, la **consulta** siguiente de un ESTUDIANTE con su access token aún vigente recibe 401 con el código correcto; la comprobación falla cerrada si la base no responde). |

**Sección 4 (API)**

| # | Actual | Nuevo |
|---|---|---|
| 4-1 | "Documentación completa en `/swagger-ui.html` (springdoc)." | "Documentación completa en `/api/docs` (springdoc). Contrato versionado en `docs/api/openapi.yaml`, generado desde el código y verificado por `OpenApiContractIT`; aquí se muestra un extracto." |
| 4-2 | `servers: - url: https://<proyecto>.vercel.app/api` con rutas `/equipment`, `/loans` | `servers: - url: https://<proyecto>.vercel.app` con rutas completas `/api/equipment`, `/api/loans`, ... |
| 4-3 | `PATCH /loans/{id}/status` y `LoanStatusRequest` | `POST /api/loans/{id}/approval`, `/rejection`, `/delivery`, `/return` y `/cancellation` con sus DTO (Anexo A); sin `PATCH /status`. |
| 4-4 | `LoanResponse.status` sin CANCELADO | Enum con los 7 estados, incluido CANCELADO. |
| 4-5 | `condition: [BUENO, DANADO, INCOMPLETO]` | Líneas `{condition: [BUENO, CON_DESPERFECTOS, DANADO, PERDIDO], quantity, notes}` por equipo. |
| 4-6 | `status: [DISPONIBLE, MANTENIMIENTO, RETIRADO]` | `[DISPONIBLE, MANTENIMIENTO]` (la baja es `deleted_at`). |
| 4-7 | `reason: maxLength 255` | Rechazo: 10 a 250; cancelación: hasta 250, opcional. |
| 4-8 | `endDate`: "Máximo 7 días después de startDate" | "Rango de máximo 7 días contando ambos extremos (fin hasta 6 días después del inicio)." |
| 4-9 | `q`: "Texto en nombre o código" | "Texto en el nombre" (RN-03.1). |
| 4-10 | `EquipmentPage {content, page, size, totalElements}` | `PageResponse` genérico con `totalPages`; tamaño máximo 50. |
| 4-11 | `ProblemDetail {type, title, status, detail, instance}` | Añadir `code`, `requestId`, `timestamp` y extensiones (`errors`, `items`, `blockedUntil`, `activeSession`, `loans`). |
| 4-12 | Respuestas de `/loans` sin 401 ni 409 de concurrencia | Añadir 401 `UNAUTHENTICATED`, 403 y 409 `CONCURRENT_MODIFICATION` donde aplique. |
| 4-13 | Ejemplo 409 con `detail` por equipo y sin `code` | El ejemplo de 3.4 de este ADR (`code`, `requestId`, `timestamp`, `items[]`). |
| 4-14 | `"createdAt": "2026-11-03T14:22:05Z"` | `"createdAt": "2026-11-03T14:22:05-05:00"` |
| 4-15 | (no existe) | `POST /api/auth/login` (con `replaceExistingSession`), `/api/auth/refresh`, `/api/auth/logout`, `AuthResponse` con `accessToken`, `tokenType`, `expiresAt`, `sessionExpiresAt` y `user`; esquemas `bearerAuth` y `refreshCookie`; códigos `INVALID_CREDENTIALS`, `SESSION_EXPIRED`, `SESSION_REPLACED`, `SESSION_INVALIDATED`, `ACTIVE_SESSION_EXISTS` y `TOO_MANY_ATTEMPTS`, con los textos del catálogo 3.3. |
| 4-16 | (no existe) | `GET /api/users`, `GET /api/users/by-email`, `DELETE /api/users/{id}` (409 `LAST_ADMIN`, `CANNOT_DEACTIVATE_SELF`, `USER_HAS_LOANS_IN_PROGRESS`) y `DELETE /api/users/{id}/session` (204, 409 `NO_ACTIVE_SESSION`), de SH-08 y SH-12. |
| 4-17 | Diagramas de secuencia: login, solicitar, ciclo con `PATCH /status` | Los de 5.1: login, sesión y renovación, sesión única, solicitar, aprobar, entrega y devolución, cancelar, baja de cuenta y tareas programadas. |

#### 2.6.8 Primer ADMIN en producción (D-26, revisión 7b)

RN-01a.4 exige al menos un ADMIN desde el inicio, y el registro solo crea cuentas ESTUDIANTE. En `dev` lo cubren las semillas de `classpath:db/seed`. En vista previa y producción no puede haber contraseñas ni hashes en el repositorio.

- **Mecanismo:** un `AdminBootstrapRunner` (`ApplicationRunner` de `auth`, activo en los perfiles distintos de `dev`) se ejecuta al arrancar, después de Flyway.
  - Si **no existe ningún ADMIN activo** (`role = 'ADMIN' AND deleted_at IS NULL`), crea uno con `BOOTSTRAP_ADMIN_EMAIL` (en minúsculas), `BOOTSTRAP_ADMIN_NAME` y `BOOTSTRAP_ADMIN_PASSWORD_HASH`. El hash es BCrypt generado fuera del sistema, nunca la contraseña en claro.
  - Si ya existe algún ADMIN activo, no hace nada: el proceso es idempotente.
- **Concurrencia entre instancias:** la comprobación y la inserción van en una transacción que toma un bloqueo con nombre (`SELECT GET_LOCK('prestalab_admin_bootstrap', 10)`). Así dos instancias que arrancan a la vez no crean dos ADMIN. Además, el único `uk_users_email` impide duplicar el correo.
- **Validación:**
  - Si faltan variables o el hash no tiene formato BCrypt, el arranque **no falla**: registra WARN, porque un ADMIN puede existir ya, y el health check informa `adminBootstrap: MISSING` mientras no haya ningún ADMIN activo.
  - Si el correo ya existe con otro rol o dado de baja, no modifica esa cuenta (no cambia roles ni reactiva) y registra ERROR para que se corrija la variable.
  - Nunca registra el hash ni la contraseña.
- **Después del primer arranque:** las variables pueden quedar en Vercel sin efecto. Se recomienda vaciar `BOOTSTRAP_ADMIN_PASSWORD_HASH` una vez creado el ADMIN; el ADMIN puede cambiar su contraseña cuando exista esa función (fuera del alcance actual). El ADMIN inicial cuenta para la regla `LAST_ADMIN` como cualquier otro.
- **Por qué así:** no pone secretos en git, funciona igual en Vercel (variables por entorno) y en Docker local, es idempotente y no depende de un paso manual sobre la base de Aiven. Solo actúa cuando el sistema quedaría sin cumplir RN-01a.4, así que nunca crea un ADMIN si ya hay uno.
- **Alternativas descartadas:**
  - Migración Flyway con el hash: queda en el repositorio, es distinta por entorno y las migraciones aplicadas no se editan.
  - Placeholder de Flyway con el hash: deja el dato en el historial de `flyway_schema_history` y obliga a que el valor exista en cada despliegue posterior.
  - `INSERT` manual en Aiven: no es reproducible, sin trazabilidad y requiere acceso directo a producción.
  - Endpoint público de "primer ADMIN": abre una vía de toma de control del sistema.
  - Contraseña en claro por variable: expone el secreto en el panel y en los logs de despliegue.
- **Variables nuevas para `.env.example`** (no se edita aquí): `BOOTSTRAP_ADMIN_EMAIL=`, `BOOTSTRAP_ADMIN_NAME=` y `BOOTSTRAP_ADMIN_PASSWORD_HASH=` (hash BCrypt, por ejemplo `$2a$10$...`).
- **Aprobado por el usuario (P-10, revisión 7e).** Las variables ya figuran en `.env.example`. Si el perfil `demo` (2.8) está activo, su ADMIN de prueba también cuenta como ADMIN activo, así que este arranque no crea otro.

### 2.7 Contrato REST documentado con OpenAPI (D-21)

- **Herramienta:** `springdoc-openapi-starter-webmvc-ui`, enfoque *code-first*: el contrato sale de los controladores y DTO anotados.
- **Rutas bajo `/api`** (Vercel solo enruta `/api/*` al backend): Swagger UI en `/api/docs` (`springdoc.swagger-ui.path`), especificación en `/api/docs/v3/api-docs` y `/api/docs/v3/api-docs.yaml` (`springdoc.api-docs.path`). Los recursos estáticos que sirve springdoc también deben quedar bajo `/api/docs/`; la prueba de humo de `/desplegar-vercel` comprueba que la UI y el JSON responden en la URL pública. Acceso público (el contrato no contiene secretos), en todos los perfiles.
- **Contenido obligatorio:** `@Tag` por controlador; `@Operation` (resumen y descripción en español, con las reglas RN que aplica) por método; `@ApiResponse` por cada estado posible con esquema `ProblemDetail` (`code`, `requestId`, `timestamp` y extensiones como `errors`, `items`, `blockedUntil`); `@Schema` con ejemplo en cada record; `@ParameterObject` para filtros y paginación. Un `OpenApiCustomizer` de `shared` añade a toda operación protegida las respuestas 401, 403 y 500 comunes y el esquema `bearerAuth`; los endpoints de renovación y cierre de sesión declaran el esquema `refreshCookie` (apiKey en cookie `prestalab_rt`). `servers: [{url: "/"}]` porque las rutas ya incluyen `/api`. Salida determinista con `springdoc.writer-with-order-by-keys=true`.
- **Versionado del contrato:** `docs/api/openapi.yaml` es la copia versionada en git (junto a la documentación, fuera de `backend/` porque la consumen también el frontend, las pruebas E2E y la sección 4 del readme). `info.version` sigue versionado semántico: mayor ante cambios incompatibles, menor ante endpoints o campos nuevos.
- **Prueba de contrato:** `OpenApiContractIT` (perfil `integration`, con el mismo contexto Testcontainers del resto de pruebas de integración) pide `/api/docs/v3/api-docs.yaml`, lo compara como árbol YAML con `docs/api/openapi.yaml` y falla mostrando la diferencia; deja el generado en `target/openapi/openapi.generated.yaml`. Para regenerar a propósito: `./mvnw verify -Pintegration -Dopenapi.update=true`, que sobrescribe el archivo versionado. Es viable sin herramientas extra porque reutiliza Testcontainers; la alternativa con `springdoc-openapi-maven-plugin` exige levantar la aplicación con base de datos durante el build y se descarta.
- **Regla de cambio de contrato:** todo cambio de endpoint, DTO, código de estado o `code` de error incluye en el mismo PR: anotaciones actualizadas, `docs/api/openapi.yaml` regenerado, la sección 4 del readme actualizada (`/actualizar-documentacion 4`) y, si cambia un flujo, los diagramas (`/generar-diagramas`). `code-reviewer` lo verifica y la CI lo hace cumplir con `OpenApiContractIT` y la regla 9 de ArchUnit.
- **Criterios de calidad:** `OpenApiContractIT` en verde; regla 9 de ArchUnit en verde; opcionalmente, `openapi-diff` en la CI contra la rama base para marcar cambios incompatibles en el PR (propuesto, no obligatorio).
- **Alternativa descartada:** enfoque *design-first* con `openapi-generator` (interfaces generadas a partir del YAML): más herramientas y fricción con records, MapStruct y los subagentes, para un único consumidor propio.

---

### 2.8 Datos de demostración y cuentas de prueba (D-28, revisión 7e)

Objetivo: que quien evalúe el proyecto pueda entrar con cada rol y recorrer el ciclo del préstamo sin preparar datos, sin guardar secretos en el repositorio y sin tocar el esquema fuera de Flyway.

**Perfiles**

| Perfil | Dónde | Esquema (Flyway `db/migration`) | Datos de demostración | Primer ADMIN (2.6.8) |
|---|---|---|---|---|
| `dev` | Local (`docker compose`, `mvnw`) | Sí | Sí | No hace falta: lo cubre la cuenta ADMIN de prueba |
| `prod` | Vercel y Aiven | Sí | **No** | `AdminBootstrapRunner` |
| `prod,demo` | Despliegue usado para la evaluación | Sí | Sí | No crea otro: la cuenta ADMIN de prueba ya cuenta como ADMIN activo |

Se activa poniendo `SPRING_PROFILES_ACTIVE=prod,demo` y `SEED_PASSWORD` en las variables de entorno de Vercel del entorno de evaluación. Lo recomendado es que ese entorno use una base de Aiven propia y desechable, no la de producción. Sin `demo`, ni la ubicación `classpath:db/seed` ni los sembradores se cargan.

**Por qué no se aplican por defecto en producción:** las cuentas de prueba comparten una contraseña conocida por terceros y los datos son ficticios. Mezclados con datos reales, permitirían acceso indebido (sobre todo con la cuenta ADMIN: baja de cuentas, exportación de correos) y falsearían las métricas. Por eso son una decisión explícita por entorno, no un comportamiento por defecto.

**Cómo se crean**
- **Datos que no dependen de cuentas** (categorías adicionales de ejemplo y equipos): script SQL repetible en `classpath:db/seed`, por ejemplo `R__demo_catalog.sql`. No va en `db/migration`, porque el hook solo admite allí archivos `V<n>__`.
  - Flyway solo añade esa ubicación con los perfiles `dev` o `demo` (`spring.flyway.locations` por perfil).
  - El script solo inserta lo que falta (`INSERT ... SELECT ... WHERE NOT EXISTS`, por `inventory_code` o nombre); nunca usa `DELETE`, `TRUNCATE` ni `DROP`.
  - Las categorías de referencia que necesita también producción no son de demostración: van en una migración `V<n>__` (S-3).
- **Cuentas de prueba:** `DemoAccountsSeeder` (`ApplicationRunner` de `auth`, solo con `dev` o `demo`, se ejecuta después de Flyway).
  - Crea las cuentas que falten, buscándolas por correo, con BCrypt de `SEED_PASSWORD` calculado al arrancar. SQL no puede calcular BCrypt, y un hash como marcador de Flyway quedaría registrado en el historial de migraciones.
  - Si `SEED_PASSWORD` falta o no cumple RN-01a.3 (8 caracteres, letra y número), no crea cuentas y registra WARN.
  - Nunca modifica cuentas existentes: no cambia contraseñas, no reactiva bajas y no cambia roles.
- **Préstamos de ejemplo:** `DemoLoansSeeder` (`ApplicationRunner` de `loans`, solo con `dev` o `demo`, ordenado después de `DemoAccountsSeeder`).
  - Localiza a los titulares por correo con `UserDirectoryService` y los equipos por código con `EquipmentCatalogService`, así que respeta las fronteras de módulos: cada módulo siembra solo sus tablas.
  - Solo siembra si los estudiantes de prueba aún no tienen préstamos, para ser idempotente.
  - Inserta los préstamos con sus hitos y su `loan_status_history` coherentes con los `CHECK` de la sección 3, con fechas relativas al `Clock`. No pasa por los casos de uso, porque estos impiden crear préstamos en el pasado.

**Cuentas** (correos `@institucion.edu`, nombres ficticios)

| Correo | Rol | Uso sugerido |
|---|---|---|
| `admin.demo@institucion.edu` | ADMIN | Métricas, baja de cuentas y cierre de sesión de otra cuenta. |
| `encargado1.demo@institucion.edu` | ENCARGADO | Bandeja: aprobar, rechazar, entregar y recibir. |
| `encargado2.demo@institucion.edu` | ENCARGADO | Segundo evaluador o prueba de concurrencia en la aprobación. |
| `estudiante1.demo@institucion.edu` | ESTUDIANTE | Tiene una SOLICITADO y un APROBADO: puede solicitar uno más (límite de 3). |
| `estudiante2.demo@institucion.edu` | ESTUDIANTE | Tiene un ENTREGADO en curso y en su historial un DEVUELTO, un RECHAZADO (motivo manual) y un CANCELADO ("Cancelado por usuario"). |
| `estudiante3.demo@institucion.edu` | ESTUDIANTE | Tiene un VENCIDO sin devolver: muestra la alerta de vencido y el bloqueo de nuevas solicitudes (RN-SH03.5). |

**Datos de ejemplo**
- **Catálogo:** 3 categorías (Cómputo, Audiovisual, Laboratorio) y unos 8 equipos con unidades entre 1 y 5. Uno está en MANTENIMIENTO ("No disponible") y otro tiene una sola unidad, para ver la competencia por la última unidad.
- **Préstamos:** los de la tabla de cuentas, con fechas relativas a hoy:
  - SOLICITADO con inicio mañana.
  - APROBADO con inicio mañana; su `pickup_deadline` se calcula con `PickupDeadlinePolicy`.
  - ENTREGADO desde ayer y con fin pasado mañana.
  - VENCIDO con fin anterior a hoy.
  - DEVUELTO, RECHAZADO y CANCELADO en el pasado.
  - Ningún estudiante supera 3 préstamos en curso y las unidades retenidas nunca superan el total.
- **Alertas:** las que corresponden (PRESTAMO_VENCIDO para el personal) las crea el mismo sembrador mediante el evento de estado, o la primera ejecución de `daily`.

**Contraseña de demostración (decisión del usuario, P-12):**
- El valor sigue entrando a la aplicación solo por la variable `SEED_PASSWORD`; el código y los scripts no lo contienen.
- El readme (sección 0.4) **publica** esa contraseña junto a los correos y roles, para que cualquier evaluador pueda entrar sin pedirla.
- Es una contraseña exclusiva de demostración, no un secreto de producción: no debe reutilizarse en ninguna otra cuenta ni en `BOOTSTRAP_ADMIN_PASSWORD_HASH`.
- El valor publicado y el configurado en Vercel deben coincidir; si se cambia uno, se cambia el otro en el mismo momento.
- Ni `SEED_PASSWORD` ni la contraseña se escriben en `.env.example`, que solo muestra el nombre de la variable.
- Si algún hook de detección de secretos bloquea la escritura en el readme, la añade el usuario a mano.

**Configuración del entorno de evaluación (Vercel):**
- `SPRING_PROFILES_ACTIVE=prod,demo`.
- `SEED_PASSWORD` con la contraseña publicada.
- `DB_URL`, `DB_USER` y `DB_PASSWORD` de una base de Aiven exclusiva para la evaluación y desechable (recomendado).
- El resto de variables de `prod` (`JWT_SECRET`, `CRON_SECRET`, `CORS_ALLOWED_ORIGINS`).
- `BOOTSTRAP_ADMIN_*` no hace falta, porque la cuenta ADMIN de prueba cumple RN-01a.4.
- En local, `.env` usa `SPRING_PROFILES_ACTIVE=dev`.

**Riesgos:** R-23 y R-24.

**Cambios en los tickets (`docs/plans/tickets-jira-propuesta.md`)**
- **H0 [BACK]:** perfiles `dev`, `demo` y `prod`; `spring.flyway.locations` con `classpath:db/seed` solo en `dev` y `demo`; la clase base de los sembradores, activa por perfil; `.env.example` con `SEED_PASSWORD` documentado para `dev` y `demo`.
- **H0b [BACK]:** documentar las variables del entorno de evaluación en Vercel (`SPRING_PROFILES_ACTIVE=prod,demo`, `SEED_PASSWORD`, la base de Aiven del entorno). La CI no usa `demo`.
- **HU-01a:** sin cambios de alcance. Las cuentas de prueba usan el dominio `@institucion.edu` y cumplen RN-01a.1 y RN-01a.3.
- **HU-01b [DB] y [BACK]:** "Semilla de un usuario por rol en `classpath:db/seed`" pasa a ser `DemoAccountsSeeder` en `auth` (1 ADMIN, 2 ENCARGADO y 3 ESTUDIANTE con `SEED_PASSWORD`), idempotente y sin modificar cuentas existentes. **[TEST]:** idempotencia, que no haya cuentas sin `SEED_PASSWORD` y que el perfil `prod` sin `demo` no siembre.
- **HU-02a [DB]:** `R__demo_catalog.sql` en `classpath:db/seed` con equipos de ejemplo. Las categorías de referencia siguen en su migración `V<n>__`.
- **Préstamos de ejemplo (decidido, P-12):** habilitador **H-Demo** (2 puntos), justo después de HU-05e, con el `DemoLoansSeeder` en `loans` para los perfiles `dev` y `demo`.
  - Necesita el esquema de HU-03, las devoluciones de HU-05c y HU-05d, los estados de HU-05e y las cuentas y el catálogo de HU-01b y HU-02a.
  - Inserta por los repositorios de `loans`, con hitos y `loan_status_history` coherentes con los `CHECK` de la sección 3. No usa los casos de uso, porque estos impiden crear préstamos en el pasado.
- **H0b:** documentar el entorno de evaluación (`SPRING_PROFILES_ACTIVE=prod,demo` y `SEED_PASSWORD`) como variables de Vercel. `.env.example` no lleva `prod,demo` como valor por defecto.
- **Readme:** filas 0.4-1 y 1.4-4 de la lista 2.6.7.

## 3. Validaciones y excepciones

### 3.1 Dónde va cada validación

| Tipo de validación | Dónde | Mecanismo | Ejemplos (regla) |
|---|---|---|---|
| Obligatoriedad, formato, longitud, rangos numéricos | Controller, sobre el `*Request` | `@NotNull`, `@NotBlank`, `@Size`, `@Email`, `@Min`, `@Pattern` | Cantidad ≥ 1 (RN-04.1); unidades ≥ 1 al crear o editar (RN-02a.3); motivo de rechazo 10 a 250 (RN-05a.2); motivo de cancelación ≤ 250 (RN-SH07.5); contraseña (RN-01a.3). |
| Formato con configuración | Controller | Restricción propia `@InstitutionalEmail` (dominio de `prestalab.auth.institutional-domain`) | "Usa tu correo institucional" (RN-01a.1). |
| Coherencia entre campos del mismo DTO | Controller | Restricción de clase sobre el record | `@ValidDateRange(maxDays = 7, notBeforeToday = true)` en solicitud y disponibilidad (RN-03.5, RN-04.2); `notBeforeToday = false` en filtros de SH-01, SH-04 y SH-05; equipos sin repetir; observación obligatoria en líneas CON_DESPERFECTOS, DANADO o PERDIDO (RN-05c.3, RN-05d.1). |
| Dependiente del reloj sin datos persistidos | Controller | El validador recibe el `Clock` inyectado (validadores administrados por Spring) | "La fecha de inicio no puede ser anterior a hoy". |
| Paginación y ordenación | Controller | `@PageableDefault`, tamaño máximo global, lista blanca de ordenación | 4.2. |
| Rol | Controller | `@PreAuthorize` | "Acceso denegado" (RN-01b.4 y permisos de cada historia). |
| Unicidad, existencia, titularidad | Service | Consultas; la unicidad se confirma traduciendo la violación del índice único | Correo ya registrado (RN-01a.2); código de inventario (RN-02a.2); cancelar solicitud ajena (RN-SH07.1). |
| Estado y transiciones | Service + `LoanStateMachine` | Transición condicional | "Solo se resuelven solicitudes pendientes", "Solo se entregan préstamos aprobados", "El préstamo no ha sido entregado". |
| Disponibilidad, comprometidas, límite de 3, sanciones, vencido sin devolver | Service, bajo bloqueo | Consultas de la sección 3 del readme dentro de la transacción | RN-04.3, RN-02a.6, RN-04.8, RN-SH03.2, RN-SH03.5, RN-05a.3, RN-05b.6. |
| Horario y plazos | Service + `ServiceCalendar` / `PickupDeadlinePolicy` | Instante del `Clock` | RN-05a.10, RN-05b.3, RN-05a.8. |
| Consistencia con el recurso cargado | Service | Comparación con los ítems del préstamo | Suma de la devolución igual a lo prestado (RN-05c.2). |
| Invariantes de una fila | Base de datos | `CHECK`, únicos, llaves foráneas (sección 3) | Última barrera; su violación nunca llega al usuario con el texto de MySQL. |

Regla práctica: si la validación se puede decidir solo con el cuerpo de la petición y el reloj, va en el DTO; si necesita leer la base, el estado de otro registro o bloquear, va en el servicio. Los mensajes de Bean Validation viven en `ValidationMessages.properties` (UTF-8) con el texto exacto de las historias.

### 3.2 Jerarquía de excepciones

```text
RuntimeException
└── shared.exception.BusinessException (abstracta: ErrorCode code, Object[] args, Map<String,Object> properties)
    ├── BadRequestException           → 400  (consistencia con el recurso: RETURN_QUANTITIES_MISMATCH)
    ├── UnauthorizedException         → 401
    │   ├── InvalidCredentialsException       (INVALID_CREDENTIALS para todo fallo de inicio de sesión; propiedad
    │   │                                       interna reason = UNKNOWN_EMAIL | BAD_PASSWORD | ACCOUNT_DISABLED |
    │   │                                       ACCOUNT_LOCKED, solo para el log, nunca en el ProblemDetail)
    │   ├── InvalidSessionException           (SESSION_EXPIRED, SESSION_REPLACED, SESSION_INVALIDATED; propiedad
    │   │                                       interna reason = revoke_reason, solo para el log)
    │   └── InvalidCronSecretException        (INVALID_CRON_SECRET, endpoint interno de tareas)
    ├── ForbiddenOperationException   → 403  (titularidad y Origin ajeno: ACCESS_DENIED)
    ├── ResourceNotFoundException     → 404  (LOAN_NOT_FOUND, EQUIPMENT_NOT_FOUND, NOTIFICATION_NOT_FOUND, USER_NOT_FOUND)
    ├── TooManyRequestsException      → 429  (TOO_MANY_ATTEMPTS, propiedad retryAfterSeconds)
    └── ConflictException             → 409  (reglas de negocio y estado)
        ├── ActiveSessionExistsException      (propiedad activeSession)
        ├── AccountDeactivationException      (CANNOT_DEACTIVATE_SELF, LAST_ADMIN, USER_HAS_LOANS_IN_PROGRESS con loans[])
        ├── NoActiveSessionException          (NO_ACTIVE_SESSION)
        ├── InsufficientUnitsException        (propiedad items[])
        ├── InvalidLoanTransitionException
        ├── LoanLimitReachedException
        ├── StudentBlockedException           (propiedad blockedUntil)
        ├── OutsideServiceHoursException
        ├── DuplicateResourceException
        ├── CommittedUnitsException
        ├── EquipmentUnavailableException
        └── ConcurrentModificationException
```

- Las clases base viven en `shared.exception`; las concretas en `<modulo>.exception`. Cada una fija su `ErrorCode`; el estado HTTP lo deriva el advice de la clase base, no la excepción (el servicio no conoce HTTP).
- Una `BusinessException` nunca envuelve una causa técnica que se muestre: si un servicio traduce una excepción técnica (por ejemplo, la violación de `uk_users_email` por una carrera), registra la causa en el log y lanza la de negocio sin exponerla.
- Las excepciones de negocio se crean sin traza de pila (`writableStackTrace = false`): son flujo esperado y abaratan su costo.
- Un equipo inexistente o dado de baja al solicitar responde "Equipo no disponible" (409), no 404, porque así lo piden HU-02b (escenarios 4 y 5) y HU-04 (escenario 8).

### 3.3 Catálogo de códigos

Los textos de `docs/historias-de-usuario.md` mandan: si una historia cambia un mensaje, este catálogo y `ValidationMessages.properties` / `messages_es.properties` se ajustan a ella. Los textos sin historia (por ejemplo `CONCURRENT_MODIFICATION`, `INVALID_CRON_SECRET` o `INTERNAL_ERROR`) los confirmó el usuario o no son mensajes de usuario final.

| `code` | HTTP | `detail` (texto exacto) | Origen |
|---|---|---|---|
| `VALIDATION_ERROR` | 400 | "La solicitud tiene datos inválidos" + `errors[]` con los mensajes de cada campo | DTO |
| `MALFORMED_REQUEST` | 400 | "La solicitud no tiene un formato válido" | Framework |
| `RETURN_QUANTITIES_MISMATCH` | 400 | "Las unidades indicadas no coinciden con las prestadas" | RN-05c.2 |
| `UNAUTHENTICATED` | 401 | "Debes iniciar sesión" | RN-01b.3 |
| `INVALID_CREDENTIALS` | 401 | "Credenciales inválidas" | RN-01b.2. Único código de fallo del inicio de sesión: contraseña incorrecta, correo inexistente, cuenta dada de baja y cuenta bloqueada (D-25). El motivo real solo va al log. |
| `SESSION_EXPIRED` | 401 | "Tu sesión expiró. Inicia sesión de nuevo" | RN-SH09.3. Inactividad, vida máxima, sesión cerrada por el usuario o token reutilizado. |
| `SESSION_REPLACED` | 401 | "Tu sesión fue cerrada porque iniciaste sesión en otro lugar" | RN-SH10.3. Solo para la sesión desplazada por un nuevo inicio de sesión. |
| `SESSION_INVALIDATED` | 401 | "Tu sesión ya no es válida. Inicia sesión de nuevo" | RN-SH09.4, RN-SH12.3, PA-33. Cuenta dada de baja o sesión cerrada por un ADMIN: un solo código para no revelar la baja (RN-SH08.2). Sustituye a `ACCOUNT_DISABLED`. Nunca en el inicio de sesión. |
| `USER_NOT_FOUND` | 404 | "Usuario no encontrado" | RN-SH08.7, RN-SH12.2. Solo para un ADMIN autenticado en `/api/users/**`. |
| `NO_ACTIVE_SESSION` | 409 | "La cuenta no tiene sesión activa" | RN-SH12.4 |
| `ACTIVE_SESSION_EXISTS` | 409 | "Ya tienes una sesión activa en otro lugar" + `activeSession` | RN-SH10.2. Solo con credenciales correctas. |
| `CANNOT_DEACTIVATE_SELF` | 409 | "No puedes darte de baja a ti mismo" | RN-SH08.1 |
| `LAST_ADMIN` | 409 | "Debe existir al menos un administrador activo" | RN-SH08.1, RN-01a.4. Prevalece sobre `CANNOT_DEACTIVATE_SELF`. |
| `TOO_MANY_ATTEMPTS` | 429 | "Demasiados intentos. Inténtalo de nuevo más tarde" | RN-SH11.8, PA-35. Se decide por origen, igual para cualquier correo. |
| `INVALID_CRON_SECRET` | 401 | "No autorizado" | Solo `/api/internal/jobs/{job}` (2.5). Sin detalles ni `WWW-Authenticate`; no es un mensaje de usuario. |
| `ACCESS_DENIED` | 403 | "Acceso denegado" | RN-01b.4, RN-SH07.1 |
| `LOAN_NOT_FOUND`, `EQUIPMENT_NOT_FOUND`, `NOTIFICATION_NOT_FOUND` | 404 | "Préstamo no encontrado", "Equipo no encontrado", "Alerta no encontrada" | Lecturas por id. `NOTIFICATION_NOT_FOUND` también al leer o marcar como leída una alerta ajena: no revela que existe (A-7, misma regla que el detalle de un préstamo ajeno). |
| `EMAIL_ALREADY_REGISTERED` | 409 | "Ya existe una cuenta asociada a ese correo" | RN-01a.2, PA-34 |
| `INVENTORY_CODE_EXISTS` | 409 | "El código de inventario ya existe" | RN-02a.2 |
| `COMMITTED_UNITS` | 409 | "Hay {n} unidades comprometidas" | RN-02a.6 |
| `EQUIPMENT_HAS_ACTIVE_LOANS` | 409 | "El equipo tiene préstamos activos" | RN-02b.2 |
| `EQUIPMENT_UNAVAILABLE` | 409 | "Equipo no disponible" | RN-02b.4, RN-04.6, RN-05a.7 |
| `INSUFFICIENT_UNITS` | 409 | "Unidades insuficientes" + `items[]` `{equipmentId, name, requested, available}` | RN-04.3, RN-05a.3, RN-05b.6 |
| `LOAN_LIMIT_REACHED` | 409 | "Ya tienes 3 préstamos en curso" | RN-04.8 |
| `STUDENT_BLOCKED` | 409 | "Podrás volver a solicitar el {fecha}" | RN-SH03.2, RN-SH03.4 |
| `OVERDUE_LOAN_PENDING` | 409 | "Tienes un préstamo vencido pendiente de devolución" | RN-SH03.5 |
| `LOAN_NOT_PENDING` | 409 | "Solo se resuelven solicitudes pendientes" | RN-05a.1 |
| `LOAN_ALREADY_ENDED` | 409 | "La solicitud ya terminó" | RN-05a.8 |
| `LOAN_ALREADY_STARTED` | 409 | "La solicitud ya inició" | RN-05a.8 |
| `OUTSIDE_APPROVAL_HOURS` | 409 | "Las aprobaciones se hacen de 8:00 AM a 5:00 PM" | RN-05a.10 |
| `LOAN_NOT_APPROVED` | 409 | "Solo se entregan préstamos aprobados" | RN-05b.1 |
| `LOAN_NOT_STARTED` | 409 | "El préstamo aún no inicia" | RN-05b.3 |
| `SERVICE_NOT_STARTED` | 409 | "El servicio inicia a las 8:00 AM" | RN-05b.3 |
| `LOAN_NOT_DELIVERED` | 409 | "El préstamo no ha sido entregado" | RN-05c.1 |
| `LOAN_ALREADY_DELIVERED` | 409 | "El préstamo ya fue entregado" | RN-SH07.3 |
| `LOAN_NOT_CANCELLABLE` | 409 | "El préstamo ya no se puede cancelar" | RN-SH07.2, RN-SH07.3; también SOLICITADO con el día de inicio pasado (incluso entre las 00:00 y las 00:05) y APROBADO con el plazo de recogida vencido |
| `USER_HAS_LOANS_IN_PROGRESS` | 409 | "La cuenta tiene préstamos en curso" + `loans[]` (SOLICITADO, APROBADO, ENTREGADO o VENCIDO) | RN-SH08.3, PA-36 (confirmado) |
| `CONCURRENT_MODIFICATION` | 409 | "Otra operación modificó este registro. Actualiza e intenta de nuevo" | 2.4 (confirmado, P-6) |
| `DATA_CONFLICT` | 409 | "No se pudo guardar por un conflicto de datos" | Integridad no traducida |
| `INTERNAL_ERROR` | 500 | "Ocurrió un error inesperado. Código de referencia: {requestId}" | Cualquier otra |

### 3.4 Formato de `ProblemDetail`

```json
{
  "type": "https://prestalab/errors/insufficient-units",
  "title": "Unidades insuficientes",
  "status": 409,
  "detail": "Unidades insuficientes",
  "instance": "/api/loans",
  "code": "INSUFFICIENT_UNITS",
  "requestId": "9f1c2a7e-0b4d-4c55-9d0e-3f8a1b2c3d4e",
  "timestamp": "2026-11-03T14:22:05-05:00",
  "items": [ { "equipmentId": 12, "name": "Trípode Manfrotto", "requested": 2, "available": 1 } ]
}
```

`type` sigue el patrón ya usado en la sección 4 del readme (`https://prestalab/errors/<code-en-kebab>`); `code` es estable y es lo que usa el frontend para decidir comportamiento; `detail` es el texto para el usuario.

---

## 4. Política de caché y paginación

### 4.1 Caché

| Caché | Contenido | Clave | Expiración | Invalidación explícita | Motivo |
|---|---|---|---|---|---|
| `categories` | Lista de `CategoryView` (id, nombre) | constante | 60 min | `@CacheEvict(allEntries = true)` en cualquier escritura de categorías (hoy solo semillas, S-3) | Se lee en cada búsqueda y formulario; casi nunca cambia. |
| `equipmentSummaries` | `EquipmentSummaryView` (id, nombre, código, nombre de categoría) | id del equipo | 10 min, máximo 2 000 entradas | `@CacheEvict(key = #id)` al editar o dar de baja | Enriquecer préstamos, alertas, métricas y CSV sin repetir consultas. |

Reglas:

1. **Nunca se cachea** el estado de la cuenta ni de la sesión que consulta `ActiveSessionInterceptor` en cada petición (2.6.3), disponibilidad, unidades retenidas o comprometidas, `total_units`, `status` del equipo, estado de préstamos, límite de 3, sanciones, alertas ni nada que participe en una decisión. Los records cacheados no incluyen esos campos para que no se usen por error.
2. `@Cacheable` y `@CacheEvict` solo en métodos públicos de servicios (`api` o `service`), nunca en controladores ni repositorios, y nunca con llamadas internas a la propia clase (el proxy no intercepta).
3. Se cachean records inmutables, nunca entidades JPA.
4. Proveedor: Caffeine en memoria (`spring-boot-starter-cache`), nombres en `shared.config.CacheNames`. En pruebas de integración se usa `spring.cache.type=none` salvo en la prueba de la propia caché.
5. HTTP: `GET /api/categories` responde `Cache-Control: private, max-age=300`; el resto de respuestas autenticadas `no-store`. En el frontend las categorías se comparten durante la sesión con `shareReplay(1)`; la disponibilidad se pide siempre.

**Alternativas descartadas:** Redis (sin infraestructura gratuita estable en el plan actual y con más latencia que el beneficio); cachear la página de búsqueda del catálogo (incluye disponibilidad); cachear métricas de SH-04 (se reevaluará si se mide lentitud). **Consecuencia:** con varias instancias, cada una tiene su caché; un cambio de nombre puede tardar hasta 10 min en verse en otra instancia, aceptable porque son datos de presentación (riesgo R-2).

### 4.2 Paginación

- Todo listado recibe `Pageable` y devuelve `PageResponse<T>(List<T> content, int page, int size, long totalElements, int totalPages)` de `shared.dto`. No se serializa `Page`/`PageImpl` de Spring (su JSON no es estable).
- Índice de página desde 0. Tamaño por defecto 20, máximo global 50 (`spring.data.web.pageable.max-page-size=50`; un tamaño mayor se recorta).
- Ordenación por lista blanca por endpoint; una propiedad no permitida responde 400 `VALIDATION_ERROR`.
- Las consultas paginadas no producen N+1: la disponibilidad se calcula en una consulta para toda la página (sección 3 del readme) y los ítems de préstamos se cargan por lote.

| Listado | Endpoint | Tamaño por defecto | Orden permitido (por defecto primero) |
|---|---|---|---|
| Catálogo con disponibilidad | `GET /api/equipment` | 12 | `name` |
| Inventario del encargado | `GET /api/equipment/inventory` | 20 | `name`, `inventoryCode` |
| Mis préstamos | `GET /api/loans/mine` | 20 | `startDate,desc`, `createdAt` |
| Bandeja y préstamos del encargado | `GET /api/loans` | 20 | `startDate,asc`, `createdAt` |
| Alertas | `GET /api/notifications` | 20 | `createdAt,desc` |

Excepciones justificadas, sin paginar: `GET /api/categories` (lista pequeña y cacheada), `GET /api/notifications/unread-count`, `GET /api/reports/metrics` (ranking fijo de 10) y los CSV de SH-05, que se generan en streaming (`StreamingResponseBody`) leyendo en lotes de 500 para no cargar todo en memoria.

---

## 5. Diagramas

### 5.1 Diagramas que debe producir `/generar-diagramas`

Todos con el título marcado "(diseño)" mientras no exista código, en `docs/diagrams/<archivo>`. Los nuevos deben añadirse a la tabla de `.claude/skills/generar-diagramas/SKILL.md`.

| # | Archivo | Tipo | Estado | Sección del readme | Debe mostrar |
|---|---|---|---|---|---|
| 1 | `arquitectura.mmd` | `flowchart LR` | Actualizar | 2.1 | Navegador → Vercel (`/*` al frontend nginx, `/api/*` al backend); Vercel Cron → `/api/internal/jobs/*`; dentro del backend la cadena `RequestTraceFilter → SecurityFilterChain → Controller → Service → Repository` con el `Mapper` y el `GlobalExceptionHandler`; caché Caffeine junto a los servicios; tareas programadas; MySQL Aiven con TLS y Flyway al arrancar. |
| 2 | `modulos-backend.mmd` | `flowchart LR` | Nuevo | 2.2 | Los 6 módulos con su paquete `api`; flechas sólidas solo para las dependencias de la tabla 1.3; flecha punteada "implementa" de `loans` a `catalog.api.EquipmentUsageService`; flecha punteada "evento `LoanStatusChangedEvent`" de `loans` a `notifications`; nota con lo prohibido (repositorios, entidades y DTO ajenos; ciclos). |
| 3 | `componentes.mmd` | `flowchart TB` | Actualizar | 2.2 | Ver 5.2. Frontend (`core/`, `shared/`, `features/`) y backend por módulo con sus componentes principales, `shared` y la base. |
| 4 | `secuencia-peticion.mmd` | `sequenceDiagram` | Nuevo | 2.2 | Petición genérica: Vercel, `RequestTraceFilter` (requestId y MDC), `SecurityFilterChain` (token, `UserMdcFilter`), `ActiveSessionInterceptor` en toda petición autenticada (una consulta por llave primaria a `refresh_tokens` y `users`, sin caché, falla cerrada), Controller (`@Valid`, `@PreAuthorize`), Service (transacción), Repository, Mapper, respuesta con `X-Request-Id`, línea de acceso. Bloques `alt`: 401 desde el entry point, 400 de validación, 409 de negocio y 500 genérico con registro ERROR. |
| 5 | `secuencia-login.mmd` | `sequenceDiagram` | Actualizar | 4 | Ver 5.2. Inicio de sesión con límite por IP, regla de no revelación (un solo `alt` de fallo que agrupa contraseña incorrecta, correo inexistente, cuenta dada de baja y cuenta bloqueada, con el mismo 401, el piso de tiempo y el motivo solo en el log), contador de intentos y sesión única; la renovación y el cierre van en el diagrama 14. |
| 6 | `secuencia-solicitar-prestamo.mmd` | `sequenceDiagram` | Actualizar | 4 | Ver 5.2. |
| 7 | `secuencia-aprobar-prestamo.mmd` | `sequenceDiagram` | Nuevo | 4 | `POST /api/loans/{id}/approval`: `@PreAuthorize`, horario de servicio con `Clock`, `SELECT loans FOR UPDATE` (SOLICITADO), comprobación de fechas (RN-05a.8), `EquipmentCatalogService.lockForUpdate` en orden de id (READ COMMITTED), cálculo de `pickup_deadline`, suma de retenidas con el rango efectivo, `LoanTransitionService` (UPDATE condicional + `loan_status_history` + evento), mapper, 200; `alt` con "Unidades insuficientes", "Equipo no disponible", "Las aprobaciones se hacen de 8:00 AM a 5:00 PM" y un segundo encargado esperando el bloqueo. |
| 8 | `secuencia-ciclo-prestamo.mmd` | `sequenceDiagram` | Reescribir | 4 | Entrega y devolución: `POST .../delivery` (bloqueo de préstamo y equipo, plazo de recogida, total ≥ cantidad, alerta de próximo a vencer en préstamos de 2 días) y `POST .../return` (ENTREGADO o VENCIDO, líneas por estado, `loan_item_returns`, `decreaseTotalUnits` para DANADO/PERDIDO, sanción si hay retraso, cierre de alertas por evento, aviso de APROBADO afectados en la respuesta). |
| 9 | `secuencia-cancelar-prestamo.mmd` | `sequenceDiagram` | Nuevo | 4 | `POST /api/loans/{id}/cancellation` del ESTUDIANTE: titularidad en el servicio (403 "Acceso denegado"); ventana de cancelación con el `Clock` (SOLICITADO con inicio hoy o posterior; APROBADO antes de `pickup_deadline`); motivo opcional ("Cancelado por usuario"); transición condicional frente a una entrega o una tarea programada simultáneas; historial; 200. `alt` con "El préstamo ya fue entregado" y "El préstamo ya no se puede cancelar" (incluidos SOLICITADO con inicio pasado y APROBADO con plazo vencido). |
| 10 | `secuencia-tareas-programadas.mmd` | `sequenceDiagram` | Nuevo | 2.4 o 4 | Disparadores (`@Scheduled` y Vercel Cron con `CRON_SECRET`), MDC de la tarea, selección de pendientes, transacción por préstamo con UPDATE condicional, evento y alertas (NO_RECOGIDO a todos los ENCARGADO y al titular; SIN_RESOLVER_A_TIEMPO al titular; PRESTAMO_VENCIDO a ENCARGADO y ADMIN), segunda instancia que actualiza 0 filas sin duplicar. |
| 11 | `infraestructura.mmd` | `flowchart TB` | Actualizar | 2.4 | Ver 5.2. |
| 12 | `estados-prestamo.mmd` | `stateDiagram-v2` | Sin cambios | 3.1 | Es de `database-engineer` y ya es coherente con este ADR. |
| 13 | `modelo-datos.mmd` | `erDiagram` | Actualizar cuando `database-engineer` aplique el Anexo D | 3.1 | Entidad `REFRESH_TOKENS` con `active_user_id` único y relación `USERS ||--o{ REFRESH_TOKENS : "abre sesión"`; nuevas columnas de `USERS` (`failed_login_attempts`, `login_locked_until`, `last_failed_login_at`, `deactivated_by`) y relación reflexiva "da de baja"; `LOANS.closure_reason` sin cambios. Lo regenera `/generar-diagramas modelo-datos` después del cambio del modelo, no antes. |
| 14 | `secuencia-sesion-refresh.mmd` | `sequenceDiagram` | Nuevo | 4 | Participantes: Usuario, Angular (`AuthService`, `authInterceptor`, Web Locks), `AuthController`, `RefreshTokenService`, MySQL (`users`, `refresh_tokens`). Pasos: petición con access token de 15 min vencido → 401 `UNAUTHENTICATED` → renovación única compartida → `FOR UPDATE` por `token_hash` → comprobación de cuenta, inactividad de 30 min y vida máxima por rol → rotación (`previous_token_hash`) → 200 con cookie nueva → reintento de la petición original. Notas de tiempo: rotación por actividad (como mucho una por minuto) y cierre local a los 30 min sin actividad; aviso 5 min antes de `sessionExpiresAt` (ESTUDIANTE a los 55 min). Bloques `alt`: reutilización de un token rotado (revoca la sesión, 401 `SESSION_EXPIRED`); sesión vencida por inactividad o por vida máxima (401 `SESSION_EXPIRED`); sesión desplazada (401 `SESSION_REPLACED`); sesión cerrada por un ADMIN o cuenta dada de baja (401 `SESSION_INVALIDATED`); dos pestañas serializadas por Web Locks; recarga de página con renovación silenciosa; cierre de sesión (`POST /api/auth/logout`, revocación, cookie borrada, 204). |
| 15 | `secuencia-baja-cuenta.mmd` | `sequenceDiagram` | Nuevo | 2.5 del readme (seguridad) y 4 | `DELETE /api/users/{id}` por un ADMIN: `@PreAuthorize`; reglas en el orden de 2.6.6 (404, 200 idempotente si ya está dada de baja, `LAST_ADMIN` antes que `CANNOT_DEACTIVATE_SELF`, con bloqueo de los ADMIN activos); bloqueo de la fila del usuario; `UserLoanActivityService` de `loans` que lee sus préstamos en curso; `alt` con algún SOLICITADO, APROBADO, ENTREGADO o VENCIDO → 409 `USER_HAS_LOANS_IN_PROGRESS` con `loans[]` sin cambiar nada; si no hay ninguno, `deleted_at` y `deactivated_by`, revocación de la sesión y 200. Sin cancelación automática de préstamos. Bloque `par` con una solicitud simultánea del estudiante serializada en la fila de `users` (si la solicitud gana, 409 en la baja; si gana la baja, 401 `SESSION_INVALIDATED` en la solicitud). Después, el corte: cualquier petición siguiente del estudiante, consulta o acción, con el access token aún vigente, la rechaza `ActiveSessionInterceptor` con 401 `SESSION_INVALIDATED`; la renovación también responde 401 `SESSION_INVALIDATED` (escenario 5b de SH-09); un nuevo inicio de sesión de la cuenta recibe el 401 genérico `INVALID_CREDENTIALS`; nota "corte inmediato en toda petición, sin ventana". Variante: baja hecha fuera de la aplicación, detectada en la renovación. |
| 16 | `secuencia-sesion-unica.mmd` | `sequenceDiagram` | Nuevo | 4 | Dispositivo A con sesión vigente; dispositivo B inicia sesión con credenciales correctas → bloqueo de `users` → 409 `ACTIVE_SESSION_EXISTS` con `activeSession` → diálogo → nuevo `POST /api/auth/login` con `replaceExistingSession: true` → revocación `REPLACED` de A y sesión nueva de B → 200. Después, A: escritura rechazada con 401 `SESSION_REPLACED`, renovación rechazada con 401 `SESSION_REPLACED`, mensaje y vuelta al inicio de sesión. `alt`: sesión anterior ya vencida (se revoca con `EXPIRED` sin 409); cancelar el ingreso (la sesión de A sigue activa). Cierre administrativo `DELETE /api/users/{id}/session` por `UserController`: 204 y revocación `CLOSED_BY_ADMIN` (A recibe 401 `SESSION_INVALIDATED`), 409 `NO_ACTIVE_SESSION` o 404 `USER_NOT_FOUND`. |

**Estado de los diagramas (revisión 6).** Los 16 `.mmd` ya existen en `docs/diagrams/`. Para la revisión 6 solo hay que aplicar a 7 de ellos las correcciones exactas de 5.2 ("Correcciones de la revisión 6"), en este orden: `modulos-backend`, `componentes`, `secuencia-login`, `secuencia-sesion-refresh`, `secuencia-sesion-unica`, `secuencia-baja-cuenta` y `secuencia-tareas-programadas`. Después hay que volver a renderizar sus PNG. `modelo-datos.mmd` sigue dependiendo de que `database-engineer` aplique el Anexo D. La tabla de `.claude/skills/generar-diagramas/SKILL.md` debe registrar los 8 diagramas añadidos por este ADR (`modulos-backend`, `secuencia-peticion`, `secuencia-sesion-refresh`, `secuencia-sesion-unica`, `secuencia-baja-cuenta`, `secuencia-aprobar-prestamo`, `secuencia-cancelar-prestamo` y `secuencia-tareas-programadas`) con su sección del readme.

### 5.2 Cambios requeridos en los diagramas y secciones existentes

No se editan aquí; los aplica `docs-writer` con `/generar-diagramas` y `/actualizar-documentacion`.

**Correcciones de la revisión 6 sobre los `.mmd` ya generados (lista exacta)**

| Archivo | Línea actual | Cambio |
|---|---|---|
| `modulos-backend.mmd` | `AAPI["auth.api<br/>UserDirectoryService<br/>UserDeactivationHandler"]` | `AAPI["auth.api<br/>UserDirectoryService<br/>UserLoanActivityService"]` |
| `modulos-backend.mmd` | `LAPI -.->\|"implementa UserDeactivationHandler"\| AAPI` | `LAPI -.->\|"implementa UserLoanActivityService"\| AAPI` |
| `componentes.mmd` | Nodo `LSV`: `...EquipmentUsageServiceImpl<br/>LoanAccountDeactivationServiceImpl` | `...EquipmentUsageServiceImpl<br/>UserLoanActivityServiceImpl` |
| `componentes.mmd` | `LSV -.->\|"implementa UserDeactivationHandler"\| ASV` | `LSV -.->\|"implementa auth.api.UserLoanActivityService"\| ASV` |
| `secuencia-login.mmd` | `alt IP con 10 fallos en 15 min` | `alt origen bloqueado: 10 fallos, hasta 15 min desde el primer fallo de la serie` |
| `secuencia-login.mmd` | `C-->>FE: 429 TOO_MANY_ATTEMPTS con Retry-After` | `C-->>FE: 429 TOO_MANY_ATTEMPTS "Demasiados intentos. Inténtalo de nuevo más tarde" con Retry-After, sin mirar correo ni contraseña` |
| `secuencia-login.mmd` | `FE-->>U: Diálogo cerrar la otra sesión y continuar (ver secuencia-sesion-unica)` | `FE-->>U: Aviso "Ya tienes una sesión activa en otro lugar": cerrar la otra o cancelar (ver secuencia-sesion-unica)` |
| `secuencia-login.mmd` | `FE->>FE: Guarda el access token solo en memoria y programa la renovación` | `FE->>FE: Guarda el access token solo en memoria; activa la rotación por actividad y el aviso de fin de sesión` |
| `secuencia-sesion-refresh.mmd` | `else sesión desplazada o cerrada por un ADMIN` / `C-->>FE: 401 SESSION_REPLACED y borra la cookie` | Dos ramas: `else sesión desplazada (REPLACED)` → `401 SESSION_REPLACED`; `else cerrada por un ADMIN o cuenta con deleted_at` → `RT->>DB: revoca con ACCOUNT_DISABLED si hace falta` y `C-->>FE: 401 SESSION_INVALIDATED y borra la cookie` |
| `secuencia-sesion-refresh.mmd` | `else vencida por 30 min de inactividad, vida máxima por rol o cuenta con deleted_at` / `RT->>DB: revoca con EXPIRED o ACCOUNT_DISABLED` | `else vencida por 30 min de inactividad o vida máxima, o cerrada con LOGOUT` / `RT->>DB: revoca con EXPIRED si hace falta` (sigue `401 SESSION_EXPIRED`) |
| `secuencia-sesion-refresh.mmd` | `Note over FE: Renovación proactiva 60 s antes de expiresAt solo si hubo actividad` | `Note over FE: Rotación por actividad (como mucho una por minuto) y cierre local a los 30 min sin actividad` |
| `secuencia-sesion-unica.mmd` | `C-->>B: 409 ACTIVE_SESSION_EXISTS con activeSession startedAt y lastActivityAt` | `C-->>B: 409 ACTIVE_SESSION_EXISTS "Ya tienes una sesión activa en otro lugar" con activeSession` |
| `secuencia-sesion-unica.mmd` | `B->>B: diálogo "Cerrar la otra sesión y continuar"` | `B->>B: aviso con dos opciones: cerrar la otra sesión e ingresar, o cancelar (A sigue activa)` |
| `secuencia-sesion-unica.mmd` | `A->>A: mensaje "Tu sesión se cerró porque se inició sesión en otro dispositivo" ...` | `A->>A: mensaje "Tu sesión fue cerrada porque iniciaste sesión en otro lugar" y vuelve al inicio de sesión` |
| `secuencia-sesion-unica.mmd` | Bloque `opt cierre administrativo` con `C-->>C: 204, idempotente` | Participante `UserController`; `alt` con sesión vigente → revoca `CLOSED_BY_ADMIN` → 204, y A al usarla → `401 SESSION_INVALIDATED "Tu sesión ya no es válida. Inicia sesión de nuevo"`; sin sesión activa → `409 NO_ACTIVE_SESSION "La cuenta no tiene sesión activa"`; correo inexistente → `404 USER_NOT_FOUND` |
| `secuencia-baja-cuenta.mmd` | `alt cuenta inexistente o ya dada de baja` → `404 USER_NOT_FOUND`, luego `else es la propia cuenta`, luego `else último ADMIN activo` | Orden nuevo: `alt cuenta inexistente` → `404 USER_NOT_FOUND`; `else ya dada de baja` → `200 idempotente`; `else último ADMIN activo` → `409 LAST_ADMIN "Debe existir al menos un administrador activo"`; `else es la propia cuenta` → `409 CANNOT_DEACTIVATE_SELF "No puedes darte de baja a ti mismo"` |
| `secuencia-baja-cuenta.mmd` | `UA->>DB: revoca la sesión con ACCOUNT_DISABLED` | `UA->>DB: revoca la sesión (motivo interno ACCOUNT_DISABLED)` |
| `secuencia-baja-cuenta.mmd` | `LS-->>ST: 401 ACCOUNT_DISABLED sin crear nada` | `LS-->>ST: 401 SESSION_INVALIDATED "Tu sesión ya no es válida. Inicia sesión de nuevo" sin crear nada` |
| `secuencia-baja-cuenta.mmd` | `AI-->>ST: 200, sin consulta a la base (hasta 15 min 30 s)` | Ver revisión 7 (más abajo): esa lectura ya no responde 200. |
| `secuencia-baja-cuenta.mmd` | `AI-->>ST: 401 ACCOUNT_DISABLED` | `AI-->>ST: 401 SESSION_INVALIDATED` |
| `secuencia-baja-cuenta.mmd` | `ST->>C: POST /api/auth/refresh al vencer el access token` / `C-->>ST: 401 SESSION_EXPIRED` | `ST->>C: POST /api/auth/refresh (rotación por actividad o access token vencido)` / `C-->>ST: 401 SESSION_INVALIDATED` |
| `secuencia-tareas-programadas.mmd` | `IJ-->>VC: 401` | `IJ-->>VC: 401 INVALID_CRON_SECRET "No autorizado" (comparación en tiempo constante)` |

`modelo-datos.mmd` no cambia por la revisión 6: `ACCOUNT_DISABLED` sigue siendo un valor interno válido de `revoke_reason`.

**Correcciones de la revisión 7 (comprobación en toda petición, P-9 opción B)**

| Archivo | Línea actual | Cambio |
|---|---|---|
| `secuencia-peticion.mmd` | `SF->>AI: escritura o petición de ENCARGADO y ADMIN` | `SF->>AI: toda petición autenticada, de cualquier rol` |
| `secuencia-peticion.mmd` | `AI->>DB: lee sesión y cuenta por llave primaria` | `AI->>DB: una consulta por llave primaria a refresh_tokens (sid) unida a users, sin caché` |
| `secuencia-peticion.mmd` | (no existe; justo después de la consulta) | Bloque nuevo: `alt cuenta dada de baja o sesión revocada o vencida` → `AI-->>U: 401 SESSION_INVALIDATED, SESSION_REPLACED o SESSION_EXPIRED por GlobalExceptionHandler`; `else la base no responde` → `AI-->>U: 500 INTERNAL_ERROR (falla cerrada)`; `else sesión activa` → `AI->>C: continúa`. El resto del flujo (Bean Validation, servicio, respuesta) queda dentro de esta última rama. |
| `secuencia-baja-cuenta.mmd` | `ST->>AI: lectura de ESTUDIANTE con access token vigente` / `AI-->>ST: 200, sin consulta a la base (hasta 15 min 30 s)` | `ST->>AI: consulta de ESTUDIANTE con access token aún vigente` / `AI->>DB: consulta de sesión y cuenta` / `AI-->>ST: 401 SESSION_INVALIDATED "Tu sesión ya no es válida. Inicia sesión de nuevo"` |
| `secuencia-baja-cuenta.mmd` | `ST->>AI: escritura, o cualquier petición de personal` | `ST->>AI: acción que modifica datos` (sigue `401 SESSION_INVALIDATED`, con la corrección de la revisión 6) |
| `secuencia-baja-cuenta.mmd` | `Note over ST,AI: Línea de tiempo del corte` | `Note over ST,AI: Corte inmediato en toda petición autenticada, sin ventana` |
| `componentes.mmd` | `ASI -.->\|"escrituras y personal"\| AREPO` | `ASI -.->\|"toda petición autenticada, consulta por PK, sin caché"\| AREPO` |
| `secuencia-sesion-unica.mmd` | `A->>I: escritura con access token aún vigente` | `A->>I: cualquier petición con access token aún vigente` |

Fuera de estos tres archivos solo cambia esa línea de `secuencia-sesion-unica.mmd`. No hay renombres: el componente sigue llamándose `ActiveSessionInterceptor`.

**Correcciones de la revisión 7d (registro de tareas internas, D-27)**

| Archivo | Línea actual | Cambio |
|---|---|---|
| `componentes.mmd` | `LJOB["PickupExpirationJob · DailyLoanReviewJob<br/>InternalJobController"]` | `LJOB["PickupExpirationJob · DailyLoanReviewJob<br/>implementan InternalJob"]` |
| `componentes.mmd` | `NJOB["DueSoonAlertJob"]` | `NJOB["DueSoonAlertJob<br/>implementa InternalJob"]` |
| `componentes.mmd` | Subgrafo `SHB["shared"]` (sin nodo de tareas) | Nodo nuevo dentro de `SHB`: `IJC["InternalJobController · InternalJob<br/>/api/internal/jobs/daily y /{name}"]` |
| `componentes.mmd` | (no existen) | Flechas nuevas: `IJC -.->\|"ejecuta por nombre o grupo"\| LJOB` y `IJC -.->\|"ejecuta por nombre o grupo"\| NJOB`. Son punteadas porque `shared` solo conoce la interfaz y la lista de beans se inyecta; no es una dependencia de paquete. Si el diagrama tiene un nodo de Vercel Cron o del exterior, añadir `CRON -->\|"GET /api/internal/jobs/daily (05:05 UTC)"\| IJC`. |
| `secuencia-tareas-programadas.mmd` | `participant IJ as InternalJobController` | `participant IJ as InternalJobController (shared)` |
| `secuencia-tareas-programadas.mmd` | `participant J as Job (PickupExpiration, DailyLoanReview, DueSoonAlert)` | Dos participantes: `participant LJ as Tareas de loans (DailyLoanReview, PickupExpiration)` y `participant NJ as DueSoonAlertJob (notifications)` |
| `secuencia-tareas-programadas.mmd` | `VC->>IJ: GET /api/internal/jobs/{job} con Bearer CRON_SECRET` | `VC->>IJ: GET /api/internal/jobs/daily con Bearer CRON_SECRET (única entrada de cron, 05:05 UTC)` |
| `secuencia-tareas-programadas.mmd` | `IJ->>J: ejecuta` / `IJ-->>VC: 204` | `IJ->>LJ: daily-review (su propia transacción y MDC)`, luego `IJ->>NJ: due-soon (su propia transacción y MDC)`, luego `alt todas terminaron` → `IJ-->>VC: 204`; `else alguna falló` → `IJ-->>VC: 500 INTERNAL_ERROR, detalle en el log` |
| `secuencia-tareas-programadas.mmd` | `SCH->>J: ejecuta en la zona de la institución` | `SCH->>LJ: ejecuta en la zona de la institución` y `SCH->>NJ: ejecuta a las 00:05` (cada tarea se programa en su módulo) |
| `secuencia-tareas-programadas.mmd` | Mensajes que nombran `J` (`J->>J`, `J->>DB`, `J->>TS`, `TS-->>J`) | Nombran `LJ` |
| `secuencia-tareas-programadas.mmd` | `opt DueSoonAlertJob 00:05` / `J->>DB: ENTREGADO con fin efectivo mañana, alerta PROXIMO_A_VENCER` | `NJ->>DB: ENTREGADO con fin efectivo mañana, alerta PROXIMO_A_VENCER (único por destinatario, préstamo y tipo)`, fuera del `opt` porque ya va dentro del grupo `daily` |
| `secuencia-tareas-programadas.mmd` | (no existe) | `Note over IJ: /{name} (daily-review, due-soon, pickup-expiration) para pruebas y ejecución manual; pickup-expiration solo con cron propio si el plan lo admite` |

**Cambios exactos en los tickets (`docs/plans/tickets-jira-propuesta.md`)**
- **H0 [BACK]** (lo transversal va en el habilitador): añadir la interfaz `InternalJob` (`name()`, `group()`, `run(Instant now)`) y el `InternalJobController` en `shared` (`/api/internal/jobs/{name}` y `/api/internal/jobs/daily`), con la validación de `CRON_SECRET` en tiempo constante y 401 `INVALID_CRON_SECRET`. **H0 [TEST]**: pruebas del controlador con un `InternalJob` falso (secreto correcto e incorrecto, nombre desconocido 404 tras validar el secreto, grupo con una tarea que falla: 500 y la otra se ejecuta).
- **H0b [BACK]**: `vercel.json` con una sola entrada `crons`, `{"path": "/api/internal/jobs/daily", "schedule": "5 5 * * *"}`, y la tarea de verificar el límite de tareas de cron del plan antes del primer despliegue. Desaparece la frase "los crons se añaden en HU-05a parte 3 y SH-06".
- **HU-05a, parte 3 [BACK]**, nuevo texto: "`DailyLoanReviewJob` implementa `InternalJob` (nombre `daily-review`, grupo `daily`) y se programa con `@Scheduled` a las 00:05; rechaza las SOLICITADO con inicio pasado con una transacción por préstamo e idempotente; alerta al estudiante vía H-Alertas. Se dispara por `GET /api/internal/jobs/daily` (cron de H0b) o `/daily-review` (manual)." Se quita "`GET /api/internal/jobs/daily-review` con `CRON_SECRET` ... y su entrada de Vercel Cron". **[TEST]**: integración de idempotencia ejecutando la tarea dos veces y por el grupo `daily`. La dependencia "H0b (`vercel.json`)" pasa a "H0 (`InternalJob`)".
- **SH-06 [BACK]**, nuevo texto: "`DueSoonAlertJob` implementa `InternalJob` (nombre `due-soon`, grupo `daily`), con `@Scheduled` a las 00:05 y `LoanQueryService.findDeliveredDueOn`; se ejecuta dentro de `GET /api/internal/jobs/daily`, sin entrada de cron propia." Se quitan la mención a otro cron en `vercel.json` y la nota "el ADR se actualizará aparte". **[TEST]**: idempotencia por el único al ejecutar el grupo dos veces. La dependencia "H0b (`vercel.json`)" pasa a "H0 (`InternalJob`)".
- **HU-05e [BACK]**: "`PickupExpirationJob` implementa `InternalJob` (nombre `pickup-expiration`, sin grupo)"; se dispara por `@Scheduled` cada minuto y por `/pickup-expiration`; tiene entrada de cron propia solo si el plan la admite.
- **Riesgos del plan:** el punto "A verificar" pasa a "verificar que el plan de Vercel admite al menos una tarea de cron diaria y si admite una por minuto para `pickup-expiration` (ADR 2.5, punto 4; R-1)".

**`arquitectura.mmd` (2.1)**
- El subgrafo "Backend por capas" omite el filtro de trazabilidad, el mapper, el manejador de errores y la caché: añadirlos en el orden de 2.1 de este ADR.
- Falta el disparo de tareas (Vercel Cron → `/api/internal/jobs/*` y `@Scheduled`).

**`componentes.mmd` (2.2)**
1. Quitar `AuditService` de `shared`: el historial lo escribe `LoanTransitionService` (con `LoanStateMachine`) dentro de `loans`, en la misma transacción que el cambio de estado.
2. Mover `OverdueLoanJob` de `shared` a `loans` como `PickupExpirationJob` y `DailyLoanReviewJob`; añadir `DueSoonAlertJob` en `notifications`; `InternalJobController` e `InternalJob` en `shared` (D-27; ver correcciones de la revisión 7d).
3. Sustituir `JwtAuthenticationFilter` por `BearerTokenAuthenticationFilter` (resource server) + `UserMdcFilter`; añadir `ProblemDetailAuthenticationEntryPoint` y `ProblemDetailAccessDeniedHandler`. `@PreAuthorize` está en los controladores, no en `SecurityConfig`: la flecha `SECC → módulos` debe representar reglas por URL, no autorización por método.
4. Añadir el módulo `notifications` (controller, servicio, oyente de eventos).
5. Corregir dependencias: `MLOAN → MCAT` pasa por `catalog.api`; añadir `loans → auth.api`; `loans` implementa `catalog.api.EquipmentUsageService` (punteada); `notifications → loans.api` y `auth.api`; evento punteado `loans ⇢ notifications`; eliminar `MREP → DB` (reports no accede a tablas, usa `api`).
6. Precisar el nodo de caché: Caffeine con `categories` y `equipmentSummaries`; "sin caché de disponibilidad"; `PageResponse` con máximo 50.
7. Representar que `GlobalExceptionHandler` atiende lo que sale de los controladores y que los 401/403 del filtro los atiende el entry point y el access denied handler.
8. Desglosar `shared` del backend: `exception`, `web` (`RequestTraceFilter`, `PageResponse`), `persistence` (`BaseEntity`), `config` (`Clock`, caché, OpenAPI, `MapperConfig`).
9. Frontend: añadir `errorInterceptor`, `authGuard`, la feature `notifications` y la nota `environment.apiUrl = '/api'`; renombrar `JwtInterceptor` a `authInterceptor` (funcional, archivo `auth.interceptor.ts`) y mostrar que renueva el token ante 401 y reintenta; `AuthService` con el access token en memoria y la renovación al arrancar.
10. Backend `auth`: añadir `RefreshTokenService` (rotación, reutilización, sesión única, revocación), `LoginAttemptService` y `LoginRateLimiter` (límite de intentos), `UserAccountService` y `UserController` (baja de cuentas y cierre administrativo de sesión), `ActiveSessionInterceptor` (toda petición autenticada), la tabla `refresh_tokens` y la flecha punteada "implementa `UserLoanActivityService`" de `loans` a `auth.api`.

**`secuencia-login.mmd` (4)**
- Añadir `RequestTraceFilter` y la cabecera `X-Request-Id` en la respuesta.
- Añadir el camino 400 por Bean Validation y que el 401 lo produce `GlobalExceptionHandler` con `code = INVALID_CREDENTIALS`.
- Correo normalizado a minúsculas; solo usuarios con `deleted_at IS NULL`; comparación con hash ficticio si el correo no existe.
- Límite de intentos y no revelación: límite por IP (429) antes de buscar la cuenta; contador de la cuenta en transacción propia; un único `alt` de fallo (contraseña incorrecta, correo inexistente, cuenta dada de baja o bloqueada) con el mismo 401 `INVALID_CREDENTIALS`, hash ficticio, piso de tiempo y motivo solo en el log (2.6.5, D-25). Quitar del diagrama actual el texto "sin revelar si el correo existe" como caso aparte: ahora es la regla general.
- Sesión única: bloqueo de `users`, `alt` con 409 `ACTIVE_SESSION_EXISTS` y reintento con `replaceExistingSession: true` (detalle en el diagrama 16).
- Emisión del access token con `JwtEncoder` (`sub`, `role`, `sid`, `exp` 15 min, no 120 min) y creación de la sesión en `refresh_tokens` (solo el hash, `session_expires_at` según el rol).
- Respuesta `{accessToken, tokenType, expiresAt, sessionExpiresAt, user: {id, fullName, role}}` más `Set-Cookie: prestalab_rt` (`HttpOnly`, `Secure`, `SameSite=Strict`, `Path=/api/auth`).
- El frontend guarda el access token solo en memoria (no en `sessionStorage` ni `localStorage`), activa la rotación por actividad y el aviso de fin de sesión.

**`secuencia-solicitar-prestamo.mmd` (4)**
- "fechas futuras" es incorrecto: el inicio puede ser hoy (PA-4). Las reglas de rango (máximo 7 días incluidos, fin no anterior a inicio, inicio no anterior a hoy) y los equipos sin repetir son validación del DTO en el controller, no del servicio.
- El bloqueo no es `PESSIMISTIC_WRITE` sobre equipos: según el punto 5 de la sección 3 del readme se bloquea la fila del estudiante (`FOR UPDATE`, vía `UserDirectoryService.lockStudentForUpdate`) y los equipos se leen con `FOR SHARE` (vía `EquipmentCatalogService.lockForShare`).
- Faltan las reglas de negocio: límite de 3 con SOLICITADO incluidas, bloqueo por sanción, préstamo vencido sin devolver, equipo en mantenimiento o dado de baja ("Equipo no disponible").
- La suma "APROBADO o ENTREGADO que se cruzan" está desactualizada: usar el rango efectivo de retención (APROBADO hasta `GREATEST(end_date, DATE(pickup_deadline))`; ENTREGADO y VENCIDO hasta la devolución).
- Añadir el mapper, la fila de `loan_status_history` (`NULL → SOLICITADO`) escrita por `LoanTransitionService` y los `alt` de error (400, 409 por límite, bloqueo y unidades) con `ProblemDetail` que incluye `code` y `requestId`.

**`secuencia-ciclo-prestamo.mmd` (4)**
- `PATCH /api/loans/{id}/status` con `action` se reemplaza por los subrecursos del Anexo A (D-9); el diagrama se reescribe como entrega y devolución y la aprobación pasa a `secuencia-aprobar-prestamo.mmd`.
- Faltan: orden de bloqueo y READ COMMITTED en la aprobación; horario de servicio; cálculo de `pickup_deadline`; UPDATE condicional y `@Version`; VENCIDO → DEVUELTO; estados de devolución correctos (BUENO, CON_DESPERFECTOS, DANADO, PERDIDO por cantidad); resta de unidades; sanción; eventos y alertas; aviso de APROBADO afectados (RN-05d.4); mensajes exactos de cada rechazo en lugar de un genérico `InvalidLoanTransitionException`.

**`infraestructura.mmd` (2.4)**
- Añadir Vercel Cron → backend (`/api/internal/jobs/*` con `CRON_SECRET`).
- Añadir un subgrafo "Local" (`docker compose`: MySQL 8.4 :3306, API :8080, web :4200 con nginx que reenvía `/api`).
- Mostrar las variables de entorno en Vercel (`DB_URL`, `DB_USER`, `DB_PASSWORD`, `JWT_SECRET`, `CRON_SECRET`, `CORS_ALLOWED_ORIGINS`, `SPRING_PROFILES_ACTIVE`), los registros a salida estándar y la prueba de humo `GET /api/actuator/health`.
- En CI, nombrar la prueba de arquitectura (ArchUnit) junto a las unitarias, de integración y E2E.

**Texto de las secciones 1.4, 2 y 4 del readme**

Los cambios de texto del readme están consolidados en la lista cerrada del apartado 2.6.7, que es la única referencia para `docs-writer`. Este apartado 5.2 solo cubre los diagramas. Fuera del readme, la skill `actualizar-documentacion` debe cambiar `http://localhost:8080/v3/api-docs` por `http://localhost:8080/api/docs/v3/api-docs`.

**Modelo de datos (sección 3, responsabilidad de `database-engineer`)**
- Aplicar los cambios del Anexo D con sus migraciones Flyway, su reflejo en el diagrama ER y su descripción: tabla `refresh_tokens` (`BINARY(32)`) con sesión activa única y columnas de intentos y de baja en `users`; sin cambios en `loans.closure_reason`. Ajustar además las consultas de la sección 3 según el supuesto A-12 (aceptado).

---

## 6. Supuestos y riesgos

### Supuestos

| ID | Supuesto | Estado |
|---|---|---|
| A-1 | Zona horaria única `America/Bogota` (S-1 del readme), configurable por `prestalab.time-zone`. | Aceptado |
| A-2 | Los subpaquetes `api/`, `domain/`, `exception/`, `event/` y `job/` amplían la estructura de `CLAUDE.md` (controller, service, repository, dto, mapper, entity) sin contradecirla. El usuario lo refleja en `CLAUDE.md` y en `backend-developer.md`. | Aceptado |
| A-3 | `notifications` es un módulo nuevo frente a los cuatro del readme (auth, catalog, loans, reports). | Aceptado |
| A-4 | Spring Boot 3.5.x sobre Java 21 (necesario para `ProblemDetail`, salida de logs estructurada y validación de métodos en Spring MVC). | Aceptado |
| A-5 | Las categorías solo se cargan por semillas (S-3); no hay endpoint de gestión, pero la invalidación de caché queda prevista. | Aceptado |
| A-6 | La búsqueda con disponibilidad (`GET /api/equipment`) la usan los tres roles; el inventario de gestión (`GET /api/equipment/inventory`) solo ENCARGADO y ADMIN. | Aceptado |
| A-7 | El detalle de un préstamo ajeno responde 404 a un ESTUDIANTE (no revela existencia); la cancelación de uno ajeno responde 403 "Acceso denegado", como pide SH-07. | Aceptado |
| A-8 | (Eliminado.) Se suponía guardar el token en `sessionStorage` sin refresh token. Lo sustituye D-19 (2.6.2). | Eliminado |
| A-9 | (Reemplazado.) Se aceptaba que una cuenta dada de baja conservara acceso hasta expirar su token de 120 min. Lo sustituye D-20 (2.6.3): desde la revisión 7, corte inmediato en toda petición autenticada. | Reemplazado |
| A-10 | `.env.example` debe añadir `CRON_SECRET` y `CORS_ALLOWED_ORIGINS` (no se edita aquí). | Aceptado |
| A-19 | `.env.example` incluye `BOOTSTRAP_ADMIN_EMAIL`, `BOOTSTRAP_ADMIN_NAME` y `BOOTSTRAP_ADMIN_PASSWORD_HASH` para el primer ADMIN (2.6.8). | Aceptado (P-10; ya aplicado) |
| A-20 | Las cuentas y los datos de demostración son ficticios. La contraseña común de demostración se publica en el readme 0.4 por decisión del usuario; la aplicación la recibe solo por `SEED_PASSWORD` (2.8). | Aceptado (P-12) |
| A-11 | La plataforma de Vercel con contenedores puede ejecutar más de una instancia y suspenderlas sin tráfico. | Aceptado |
| A-12 | Las lecturas del apartado 2.5, punto 5 (ignorar APROBADO con plazo vencido y SOLICITADO con inicio pasado; tratar ENTREGADO atrasado como vencido para RN-SH03.5) se adoptan. `database-engineer` ajustará las consultas de la sección 3. | Aceptado |
| A-13 | Se dan de baja cuentas pero no se cambian roles ni se reactivan cuentas (decisión del usuario, P-2). Las historias son SH-08 y SH-12 (redactadas por `product-owner`); este ADR fija su contrato (2.6.6, Anexo A). | Aceptado |
| A-14 | Los navegadores admitidos soportan la Web Locks API y cookies `SameSite=Strict` (Chromium, Firefox y Safari actuales). | Nuevo |
| A-15 | La vida máxima de la sesión se fija con el rol vigente al iniciar sesión; como no hay cambio de roles, no hace falta recalcularla. | Nuevo |
| A-16 | Vercel añade `X-Forwarded-For` con la IP del cliente y el backend solo confía en esa cabecera en los perfiles desplegados detrás de Vercel. | Nuevo, pendiente de verificar al desplegar |
| A-17 | No se da de baja una cuenta con préstamos en curso de cualquier tipo (SOLICITADO, APROBADO, ENTREGADO o VENCIDO); la baja nunca cancela préstamos. Sustituye las versiones anteriores de este supuesto. | Aceptado (decisión del usuario, 2026-11-07) |
| A-18 | La cancelación del titular (SH-07) solo procede mientras la solicitud pueda resolverse: SOLICITADO hasta su día de inicio incluido y APROBADO antes de su plazo de recogida. Así coincide con el rechazo automático "Sin resolver a tiempo" y el cierre "No recogido". | Aceptado (historias ajustadas por `product-owner`) |

### Riesgos

| ID | Riesgo | Impacto | Mitigación |
|---|---|---|---|
| R-1 | Las tareas no corren a tiempo: contenedor suspendido o límites de Vercel Cron del plan (número de entradas, frecuencia mínima y precisión de la hora), **pendientes de verificar antes de desplegar**. | Un APROBADO vencido seguiría reteniendo unidades o contando en el límite; alertas diarias tardías o, si la entrada `daily` no corre, ausentes ese día. | Tareas de recuperación e idempotentes; doble disparador (`@Scheduled` y Vercel Cron); una sola entrada de cron obligatoria (`daily`, D-27), que minimiza lo que se necesita del plan; `pickup-expiration` no depende de Vercel Cron, gracias a las lecturas que aplican la regla con el reloj (2.5, A-12). Si el plan no admitiera ni siquiera una entrada diaria, el disparo quedaría solo en `@Scheduled` y habría que buscar un disparador externo. |
| R-2 | Caché local inconsistente entre instancias. | Nombres desactualizados hasta 10 min. | Solo datos de presentación, expiración corta; si se escala de verdad, pasar a Redis o quitar la caché de equipos. |
| R-3 | Arranque en frío de la JVM. | Primera petición lenta; posible tiempo de espera en la prueba de humo. | Class Data Sharing en la imagen, `spring.jpa.open-in-view=false`, arranque sin inicialización diferida para no penalizar la primera petición de negocio; reintentos en la prueba de humo. |
| R-4 | Límite de conexiones de Aiven Free, esperas de bloqueo que retienen conexiones y, desde la revisión 7, una consulta de sesión en cada petición autenticada. | Agotamiento del pool. | Pool máximo de 5 por instancia; transacciones cortas sin llamadas externas; espera de bloqueo de 5 s; la consulta de sesión se hace fuera de transacción y libera la conexión antes de que el servicio abra la suya (nunca dos conexiones por petición a la vez); tiempo de espera del pool corto (`connection-timeout` de 2 s) para fallar rápido. |
| R-5 | Interbloqueo entre la baja de un equipo y una aprobación simultánea. | 409 inesperado. | Orden fijo de bloqueo (2.4), un reintento ante interbloqueo, prueba de integración específica. |
| R-6 | El hook prohíbe `DROP`: el esquema solo puede crecer. | Columnas o índices obsoletos permanecen. | Migraciones aditivas (expand) y columnas obsoletas documentadas como en desuso. |
| R-7 | `@SQLRestriction("deleted_at IS NULL")` en `users` o `equipment` ocultaría referencias históricas (un préstamo de un equipo dado de baja perdería su nombre). | Datos incompletos en historial, CSV y alertas. | No usar `@SQLRestriction` en esas entidades; referencias por id (D-3); repositorios con métodos `findActive...` explícitos; pruebas de integración del historial de equipos dados de baja. |
| R-8 | Reglas dependientes del reloj difíciles de probar. | Pruebas frágiles. | `Clock` inyectado en todo; ArchUnit prohíbe `now()` sin reloj; `domain` probado con pruebas unitarias puras con los escenarios exactos de HU-05a, HU-05b y HU-05e. |
| R-9 | `LIKE '%texto%'` recorre la tabla de equipos (riesgo ya anotado en la sección 3). | Lentitud con catálogos grandes. | Aceptable con cientos o pocos miles de equipos; evolución a índice FULLTEXT si crece. |
| R-10 | El access token (15 min) es criptográficamente válido hasta que expira; un token robado sirve mientras la sesión legítima siga activa. | Uso indebido de un token robado (por ejemplo, por XSS) durante la sesión de su dueño. Ya **no** hay ventana tras una baja, un cierre administrativo, un desplazamiento o un cierre de sesión (revisión 7). | Comprobación de cuenta y sesión en toda petición autenticada (2.6.3), así que el corte es inmediato en lecturas y escrituras de todos los roles. Access token solo en memoria; refresh token en cookie `HttpOnly`; cierre de sesión y cierre administrativo cortan cualquier token emitido para esa sesión. |
| R-11 | Fronteras de módulos solo verificadas por pruebas. | Erosión si se omite `./mvnw test`. | `ArchitectureTest` en `/verificar-calidad` y en CI; revisión de `code-reviewer`. |
| R-12 | Fuerza bruta y bloqueo malicioso de cuentas: 3 intentos con bloqueo de 15 min frenan la fuerza bruta, pero permiten que un tercero bloquee una cuenta ajena (incluida la de un ADMIN) a voluntad. Como el bloqueo no se revela (D-25), el usuario legítimo bloqueado solo ve "Credenciales inválidas". | Denegación de servicio del inicio de sesión de una cuenta durante 15 min por cada 3 intentos; confusión del usuario bloqueado. | Los intentos durante el bloqueo no lo alargan; límite por IP (2.6.5) para frenar el bloqueo masivo; nota fija del formulario sobre el bloqueo; registro WARN de `login_failed`; ninguna sesión vigente se ve afectada por el bloqueo. |
| R-13 | Una alerta que falla revierte la transición (oyente en la misma transacción). | Una falla en `notifications` bloquearía el ciclo del préstamo. | Es intencional para no perder alertas obligatorias; el oyente es simple, idempotente y cubierto por pruebas de integración. |
| R-14 | Falsa detección de reutilización del refresh token: dos pestañas que renuevan a la vez, o una respuesta de renovación que se pierde en la red (el navegador conserva la cookie anterior). | El usuario debe volver a iniciar sesión. | Web Locks entre pestañas, renovación única compartida dentro de la pestaña y rotación por actividad; la pérdida de una respuesta es rara y su efecto es solo un nuevo inicio de sesión, preferible a aceptar tokens reutilizados. |
| R-15 | Sesiones cortas (1 h para ESTUDIANTE, 30 min de inactividad), rotación por actividad (hasta una renovación por minuto por usuario activo), una consulta de sesión en **cada** petición autenticada (revisión 7) y arranque en frío. | Inicios de sesión frecuentes; más escrituras en `refresh_tokens`; unos pocos milisegundos más por petición (un viaje de red a Aiven); posible pérdida de lo escrito en un formulario si la sesión vence. | La consulta de sesión usa dos llaves primarias y no hace falta índice nuevo; Vercel y Aiven deben estar en la misma región; si la latencia medida molesta, la evolución es un almacén de sesión compartido con invalidación (Redis), nunca una caché local (4.1). Aviso 5 min antes del fin de la vida máxima; la escritura de teclado cuenta como actividad, así que rellenar un formulario mantiene la sesión; la rotación es una actualización por llave única, barata para el volumen esperado; `returnUrl` al volver a iniciar sesión; formularios largos (solicitud, devolución) conservan su estado en memoria del componente hasta la recarga. |
| R-18 | El límite por IP es por instancia y la IP puede ser compartida (red de la institución). | Límite aproximado con varias instancias; muchos estudiantes detrás de una misma IP podrían alcanzar el límite. | El límite solo cuenta intentos fallidos y es holgado (10 cada 15 min); se ajusta por configuración; si molesta, se desactiva y queda solo el bloqueo por cuenta. |
| R-20 | Una cuenta comprometida con cualquier préstamo en curso no se puede dar de baja y no existe cambio de contraseña. Vaciar sus préstamos puede tardar: una SOLICITADO se rechaza enseguida, pero un APROBADO no se rechaza manualmente y hay que esperar su cierre "No recogido" (hasta el día siguiente) o su entrega y devolución. Mientras tanto, quien tenga las credenciales puede volver a iniciar sesión y crear solicitudes. | Acceso indebido sostenido durante horas o días; nuevas solicitudes que vuelven a bloquear la baja. | El ADMIN cierra la sesión (`DELETE /api/users/{id}/session`) cada vez que haga falta; el ENCARGADO rechaza las SOLICITADO nuevas; el límite de 3 en curso acota el daño. Un bloqueo administrativo del inicio de sesión o el restablecimiento de contraseña quedan como mejora futura fuera del alcance actual. |
| R-21 | El registro indica si un correo ya tiene cuenta ("Ya existe una cuenta asociada a ese correo", RN-01a.2, PA-34). Es una excepción a D-25 **aceptada por el usuario**. | Enumeración de correos institucionales por el formulario de registro. | Riesgo residual aceptado; el limitador por IP se aplica también a `POST /api/auth/register`. |
| R-22 | El piso de tiempo de los inicios de sesión fallidos retiene un hilo unos 500 ms por intento. | Más carga ante ataques de fuerza bruta. | El limitador por IP corta antes del piso; el piso se aplica sin bloquear conexiones de base (después de confirmar la transacción). |
| R-23 | **Riesgo aceptado por el usuario (P-12):** la contraseña de demostración es pública (readme 0.4) y da acceso a todas las cuentas de prueba del entorno de evaluación, incluida la ADMIN. | Cualquiera que lea el readme puede ver los datos de demostración, exportar correos ficticios, dar de baja cuentas de prueba (sin reactivación, lo que puede estropear la evaluación), cerrar sesiones ajenas o bloquear cuentas con 3 intentos fallidos. | Recomendaciones: `demo` solo en el entorno de evaluación y nunca junto a datos reales; base de Aiven exclusiva y desechable; contraseña exclusiva de demostración, no reutilizada en ningún otro sitio; cambiarla (en Vercel y en el readme) y desactivar `demo` al terminar la evaluación. Si el entorno se estropea, se recrea la base y se vuelve a desplegar: las semillas son idempotentes. La regla `LAST_ADMIN` impide quedarse sin ADMIN. |
| R-24 | Varios evaluadores con la misma cuenta de prueba. | Por la sesión única (SH-10), cada inicio de sesión desplaza al anterior ("Tu sesión fue cerrada porque iniciaste sesión en otro lugar"). | Hay 6 cuentas y el readme pide usar una por evaluador; si hace falta, se añaden más cuentas al sembrador. |
| R-19 | Falso 409 `ACTIVE_SESSION_EXISTS` cuando el usuario cerró la pestaña sin cerrar sesión en otro equipo (por ejemplo, un equipo de laboratorio). | Paso adicional al iniciar sesión. | El diálogo permite cerrar la otra sesión en un clic; la sesión olvidada vence sola por inactividad en 30 min. |
| R-16 | La cookie `Secure` no se envía por HTTP en entornos locales que no sean `localhost`. | Sesión que no se renueva en desarrollo. | `prestalab.auth.cookie-secure=false` solo en el perfil `dev`; siempre `true` en vista previa y producción. |
| R-17 | El OpenAPI versionado se desincroniza del código. Con la revisión 7, en particular, que alguna operación autenticada no documente los 401 de sesión, que ahora puede devolver cualquiera de ellas (también las consultas). | Contrato documentado incorrecto para el frontend y la evaluación. | `OpenApiContractIT` en la CI y en `/verificar-calidad`; el `OpenApiCustomizer` común añade `SESSION_INVALIDATED`, `SESSION_REPLACED` y `SESSION_EXPIRED` a **toda** operación autenticada (no solo a las escrituras); regla 9 de ArchUnit; revisión de `code-reviewer`. |

---

## Anexo A · Superficie de la API y autorización

Normativo para `backend-developer`, `frontend-developer` y la sección 4 del readme. Todas las rutas con `@RequestMapping("/api/...")`.

| Método y ruta | Roles | Historia | Entrada | Salida |
|---|---|---|---|---|
| `POST /api/auth/register` | público | HU-01a | `RegisterRequest` (fullName, email, password) | 201 `UserResponse` |
| `POST /api/auth/login` | público | HU-01b, D-22, D-23 | `LoginRequest` (email, password, replaceExistingSession) | 200 `AuthResponse` (accessToken, tokenType, expiresAt, sessionExpiresAt, user) + cookie `prestalab_rt`; 401 `INVALID_CREDENTIALS`; 409 `ACTIVE_SESSION_EXISTS`; 429 `TOO_MANY_ATTEMPTS` |
| `POST /api/auth/refresh` | público con cookie `prestalab_rt` y `Origin` propio | D-19 | sin cuerpo | 200 `AuthResponse` + cookie rotada; 401 `SESSION_EXPIRED` o `SESSION_REPLACED`; 403 `ACCESS_DENIED` |
| `POST /api/auth/logout` | público con cookie opcional y `Origin` propio | D-19 | sin cuerpo | 204 + cookie borrada (idempotente); 403 `ACCESS_DENIED` |
| `GET /api/auth/me` | autenticado | HU-01b | — | `UserResponse` |
| `GET /api/users` | ADMIN | SH-08 (RN-SH08.7) | `q` (nombre o correo), `role`, `status` (`ACTIVA`, `DADA_DE_BAJA`), `page`, `size` (orden `fullName`, `createdAt`) | `PageResponse<UserAdminResponse>` (id, fullName, email, role, status, createdAt, deactivatedAt, hasActiveSession); incluye cuentas dadas de baja |
| `GET /api/users/by-email` | ADMIN | SH-08 (RN-SH08.7), SH-12 (RN-SH12.2) | `email` (exacto) | `UserAdminResponse`; 404 `USER_NOT_FOUND` "Usuario no encontrado" |
| `DELETE /api/users/{id}` | ADMIN | SH-08, D-24 | — | 200 `UserDeactivationResponse` (userId, deactivatedAt, sessionRevoked); 404 `USER_NOT_FOUND`; 409 `CANNOT_DEACTIVATE_SELF`, `LAST_ADMIN` o `USER_HAS_LOANS_IN_PROGRESS` (con `loans[]`) — baja lógica, sin tocar préstamos |
| `DELETE /api/users/{id}/session` | ADMIN | SH-12 | — | 204 (sesión revocada con `CLOSED_BY_ADMIN`; la persona recibe `SESSION_INVALIDATED`); 409 `NO_ACTIVE_SESSION` "La cuenta no tiene sesión activa"; 404 `USER_NOT_FOUND` |
| `GET /api/categories` | autenticado | HU-02a, HU-03 | — | `List<CategoryResponse>` (cacheada) |
| `GET /api/equipment` | ESTUDIANTE, ENCARGADO, ADMIN | HU-03 | `q`, `categoryId`, `from`, `to`, `page`, `size` | `PageResponse<EquipmentAvailabilityResponse>` |
| `GET /api/equipment/inventory` | ENCARGADO, ADMIN | HU-02a, HU-02b | `q`, `categoryId`, `status`, `page`, `size` | `PageResponse<EquipmentResponse>` |
| `GET /api/equipment/{id}` | ENCARGADO, ADMIN | HU-02a | — | `EquipmentResponse` (incluye unidades comprometidas y `version`) |
| `POST /api/equipment` | ENCARGADO, ADMIN | HU-02a | `EquipmentRequest` | 201 `EquipmentResponse` + `Location` |
| `PUT /api/equipment/{id}` | ENCARGADO, ADMIN | HU-02a | `EquipmentRequest` con `version` | `EquipmentResponse` |
| `DELETE /api/equipment/{id}` | ENCARGADO, ADMIN | HU-02b | — | `EquipmentRetirementResponse` (id, solicitudes rechazadas) — baja lógica |
| `POST /api/loans` | ESTUDIANTE | HU-04 | `LoanRequest` (startDate, endDate, items) | 201 `LoanResponse` + `Location` |
| `GET /api/loans/mine` | ESTUDIANTE | HU-04, SH-01 | `status`, `from`, `to`, `page`, `size` | `PageResponse<LoanSummaryResponse>` |
| `GET /api/loans/mine/eligibility` | ESTUDIANTE | RN-04.8, SH-03 | — | `LoanEligibilityResponse` (en curso, límite, bloqueado hasta, vencido pendiente) |
| `GET /api/loans` | ENCARGADO, ADMIN | HU-05a a HU-05c | `status`, `from`, `to`, `page`, `size` | `PageResponse<LoanSummaryResponse>` |
| `GET /api/loans/{id}` | titular, ENCARGADO, ADMIN | HU-04 (RN-04.7) | — | `LoanResponse` (ítems, motivo, historial de estados) |
| `POST /api/loans/{id}/approval` | ENCARGADO, ADMIN | HU-05a | — | `LoanResponse` (incluye `pickupDeadline`) |
| `POST /api/loans/{id}/rejection` | ENCARGADO, ADMIN | HU-05a | `LoanRejectionRequest` (reason 10 a 250) | `LoanResponse` |
| `POST /api/loans/{id}/delivery` | ENCARGADO, ADMIN | HU-05b | — | `LoanResponse` |
| `POST /api/loans/{id}/return` | ENCARGADO, ADMIN | HU-05c, HU-05d | `LoanReturnRequest` (por equipo: líneas `{condition, quantity, notes}`) | `LoanReturnResponse` (préstamo y `affectedApprovedLoans`) |
| `POST /api/loans/{id}/cancellation` | ESTUDIANTE (titular) | SH-07 | `LoanCancellationRequest` (reason opcional, hasta 250) | `LoanResponse`. Solo mientras la solicitud aún puede resolverse: SOLICITADO con `start_date >= hoy` (hasta el día de inicio incluido) o APROBADO con `ahora < pickup_deadline`. Fuera de eso, 409 `LOAN_ALREADY_DELIVERED` (ENTREGADO) o `LOAN_NOT_CANCELLABLE` (resto, incluidos SOLICITADO con inicio pasado y APROBADO con plazo vencido aunque la tarea programada aún no los haya cerrado); 403 `ACCESS_DENIED` si no es el titular |
| `GET /api/notifications` | autenticado (propias) | HU-05e, SH-02, SH-06 | `unreadOnly`, `page`, `size` | `PageResponse<NotificationResponse>` |
| `GET /api/notifications/unread-count` | autenticado | ídem | — | `UnreadCountResponse` |
| `POST /api/notifications/{id}/read` | destinatario | ídem | — | 204; 404 `NOTIFICATION_NOT_FOUND` si no existe **o es de otro usuario** (no se revela su existencia) |
| `GET /api/reports/metrics` | ADMIN | SH-04 | `from`, `to` | `MetricsResponse` |
| `GET /api/reports/inventory.csv` | ENCARGADO, ADMIN | SH-05 | — | `text/csv` en streaming |
| `GET /api/reports/loans.csv` | ENCARGADO, ADMIN | SH-05 | `status`, `from`, `to` | `text/csv` en streaming |
| `GET /api/internal/jobs/daily` | secreto `CRON_SECRET` (`Authorization: Bearer`) | RN-05a.11, SH-02, SH-06 | — | Ejecuta `daily-review` y luego `due-soon`. **Única entrada de Vercel Cron** (05:05 UTC). 204 si todas las tareas terminan; 500 `INTERNAL_ERROR` si alguna falla, con el detalle en el log; 401 `INVALID_CRON_SECRET` "No autorizado" (comparación en tiempo constante, sin más detalle). Idempotente. |
| `GET /api/internal/jobs/daily-review` | secreto `CRON_SECRET` | RN-05a.11, SH-02 | — | Una sola tarea (`loans`), para pruebas y ejecución manual. 204; 401 `INVALID_CRON_SECRET`. Idempotente. |
| `GET /api/internal/jobs/due-soon` | secreto `CRON_SECRET` | SH-06 | — | Una sola tarea (`notifications`), para pruebas y ejecución manual. 204; 401 `INVALID_CRON_SECRET`. Idempotente por el único de `notifications`. |
| `GET /api/internal/jobs/pickup-expiration` | secreto `CRON_SECRET` | HU-05e | — | Una sola tarea (`loans`). Entrada de cron propia solo si el plan admite su frecuencia. 204; 401 `INVALID_CRON_SECRET`. Idempotente. |

Todos los atiende el `InternalJobController` de `shared` (D-27). Cualquier otro nombre o grupo bajo `/api/internal/jobs/` responde 404, y solo después de validar el secreto. El límite de tareas de cron y la frecuencia del plan de Vercel quedan pendientes de verificar antes de desplegar (2.5, punto 4).
| `GET /api/actuator/health` | público | despliegue | — | estado |
| `GET /api/docs`, `GET /api/docs/v3/api-docs[.yaml]` | público | D-21 | — | Swagger UI y especificación OpenAPI |

Todas las operaciones autenticadas pueden responder además 401 `UNAUTHENTICATED` (access token ausente o vencido), y, desde la revisión 7, cualquier operación autenticada (consultas incluidas) 401 `SESSION_INVALIDATED`, `SESSION_REPLACED` o `SESSION_EXPIRED`; los documenta el `OpenApiCustomizer` común (2.7).

**Fragmento OpenAPI de los endpoints nuevos de cuentas y sesión** (referencia para SH-08, SH-10, SH-12 y para `docs/api/openapi.yaml`; el archivo real lo genera springdoc desde el código):

```yaml
paths:
  /api/auth/login:
    post:
      tags: [Autenticación]
      summary: Inicia sesión (límite de 3 intentos, una sola sesión activa)
      security: []
      requestBody:
        required: true
        content:
          application/json:
            schema: { $ref: '#/components/schemas/LoginRequest' }
      responses:
        '200':
          description: Sesión iniciada; fija la cookie prestalab_rt
          headers:
            Set-Cookie: { schema: { type: string }, description: 'prestalab_rt; HttpOnly; Secure; SameSite=Strict; Path=/api/auth' }
          content:
            application/json:
              schema: { $ref: '#/components/schemas/AuthResponse' }
        '400': { $ref: '#/components/responses/Problem' }
        '401': { $ref: '#/components/responses/Problem' }   # INVALID_CREDENTIALS
        '409': { $ref: '#/components/responses/Problem' }   # ACTIVE_SESSION_EXISTS
        '429': { $ref: '#/components/responses/Problem' }   # TOO_MANY_ATTEMPTS
  /api/users:
    get:
      tags: [Cuentas]
      summary: Busca y lista cuentas con su estado (rol ADMIN, RN-SH08.7)
      parameters:
        - { name: q, in: query, schema: { type: string, maxLength: 150 }, description: Nombre o correo }
        - { name: role, in: query, schema: { type: string, enum: [ESTUDIANTE, ENCARGADO, ADMIN] } }
        - { name: status, in: query, schema: { type: string, enum: [ACTIVA, DADA_DE_BAJA] } }
        - { name: page, in: query, schema: { type: integer, minimum: 0, default: 0 } }
        - { name: size, in: query, schema: { type: integer, minimum: 1, maximum: 50, default: 20 } }
      responses:
        '200':
          description: Página de cuentas
          content:
            application/json:
              schema: { $ref: '#/components/schemas/UserAdminPage' }
        '401': { $ref: '#/components/responses/Problem' }
        '403': { $ref: '#/components/responses/Problem' }
  /api/users/by-email:
    get:
      tags: [Cuentas]
      summary: Localiza una cuenta por su correo exacto (rol ADMIN, RN-SH08.7, RN-SH12.2)
      parameters:
        - { name: email, in: query, required: true, schema: { type: string, maxLength: 150 } }
      responses:
        '200':
          description: Cuenta encontrada, activa o dada de baja
          content:
            application/json:
              schema: { $ref: '#/components/schemas/UserAdminResponse' }
        '401': { $ref: '#/components/responses/Problem' }
        '403': { $ref: '#/components/responses/Problem' }
        '404': { $ref: '#/components/responses/Problem' }   # USER_NOT_FOUND "Usuario no encontrado"
  /api/users/{id}:
    delete:
      tags: [Cuentas]
      summary: Da de baja una cuenta (baja lógica, rol ADMIN)
      description: Se rechaza si el titular tiene algún préstamo en curso (SOLICITADO, APROBADO, ENTREGADO o VENCIDO). Si no, marca la baja lógica y revoca su sesión. No modifica préstamos.
      parameters:
        - { name: id, in: path, required: true, schema: { type: integer, format: int64 } }
      responses:
        '200':
          description: Cuenta dada de baja (o ya lo estaba; idempotente)
          content:
            application/json:
              schema: { $ref: '#/components/schemas/UserDeactivationResponse' }
        '401': { $ref: '#/components/responses/Problem' }
        '403': { $ref: '#/components/responses/Problem' }
        '404': { $ref: '#/components/responses/Problem' }   # USER_NOT_FOUND
        '409': { $ref: '#/components/responses/Problem' }   # LAST_ADMIN (prevalece), CANNOT_DEACTIVATE_SELF, USER_HAS_LOANS_IN_PROGRESS (loans[])
  /api/users/{id}/session:
    delete:
      tags: [Cuentas]
      summary: Cierra la sesión activa de una cuenta (rol ADMIN, SH-12)
      description: La sesión cerrada recibe 401 SESSION_INVALIDATED "Tu sesión ya no es válida. Inicia sesión de nuevo" al usarse.
      parameters:
        - { name: id, in: path, required: true, schema: { type: integer, format: int64 } }
      responses:
        '204': { description: Sesión cerrada }
        '401': { $ref: '#/components/responses/Problem' }
        '403': { $ref: '#/components/responses/Problem' }
        '404': { $ref: '#/components/responses/Problem' }   # USER_NOT_FOUND
        '409': { $ref: '#/components/responses/Problem' }   # NO_ACTIVE_SESSION "La cuenta no tiene sesión activa"
components:
  schemas:
    LoginRequest:
      type: object
      required: [email, password]
      properties:
        email: { type: string, minLength: 1, maxLength: 150, description: 'Sin validación de formato ni dominio en el inicio de sesión (D-25)' }
        password: { type: string, minLength: 1, maxLength: 72 }
        replaceExistingSession: { type: boolean, default: false }
    AuthResponse:
      type: object
      properties:
        accessToken: { type: string }
        tokenType: { type: string, enum: [Bearer] }
        expiresAt: { type: string, format: date-time }
        sessionExpiresAt: { type: string, format: date-time }
        user:
          type: object
          properties:
            id: { type: integer, format: int64 }
            fullName: { type: string }
            role: { type: string, enum: [ESTUDIANTE, ENCARGADO, ADMIN] }
    UserAdminResponse:
      type: object
      properties:
        id: { type: integer, format: int64 }
        fullName: { type: string }
        email: { type: string }
        role: { type: string, enum: [ESTUDIANTE, ENCARGADO, ADMIN] }
        status: { type: string, enum: [ACTIVA, DADA_DE_BAJA] }
        createdAt: { type: string, format: date-time }
        deactivatedAt: { type: string, format: date-time, nullable: true }
        hasActiveSession: { type: boolean }
    UserAdminPage:
      allOf:
        - $ref: '#/components/schemas/PageResponse'
        - type: object
          properties:
            content: { type: array, items: { $ref: '#/components/schemas/UserAdminResponse' } }
    UserDeactivationResponse:
      type: object
      properties:
        userId: { type: integer, format: int64 }
        deactivatedAt: { type: string, format: date-time }
        sessionRevoked: { type: boolean }
    LoansInProgressProblem:
      description: Extensión del ProblemDetail de USER_HAS_LOANS_IN_PROGRESS
      type: object
      properties:
        loans:
          type: array
          items:
            type: object
            properties:
              loanId: { type: integer, format: int64 }
              status: { type: string, enum: [SOLICITADO, APROBADO, ENTREGADO, VENCIDO] }
              startDate: { type: string, format: date }
              endDate: { type: string, format: date }
```

**Matriz de autorización de cuentas y sesión**

| Operación | ESTUDIANTE | ENCARGADO | ADMIN | Sin sesión |
|---|---|---|---|---|
| Iniciar sesión, renovar, cerrar sesión | sí | sí | sí | sí (son la entrada) |
| Ver su propia cuenta (`/api/auth/me`) | sí | sí | sí | no (401) |
| Listar cuentas | no (403) | no (403) | sí | no (401) |
| Dar de baja una cuenta | no (403) | no (403) | sí, excepto la propia y el último ADMIN (409) | no (401) |
| Cerrar la sesión de otra cuenta | no (403) | no (403) | sí | no (401) |

Justificación de D-9: cada acción tiene su DTO con validación propia (el motivo es obligatorio solo al rechazar; las líneas solo al devolver), su rol (cancelar es del ESTUDIANTE; el resto del ENCARGADO) y su `@PreAuthorize`, algo imposible con un `PATCH /status` polimórfico sin validaciones condicionales. Alternativa descartada: `PATCH /api/loans/{id}` con `{status}`, que mezcla roles y obliga a validar en el servicio lo que es de forma.

## Anexo B · Frontend

- **Sesión:** access token de 15 min solo en memoria (signal de `AuthService`); refresh token en cookie `HttpOnly` que el código nunca lee. Renovación silenciosa al arrancar (`provideAppInitializer`), rotación por actividad (como mucho una por minuto) y renovación reactiva ante 401 con reintento único, todo serializado entre pestañas con Web Locks. Cierre local tras 30 min sin actividad y aviso 5 min antes de `sessionExpiresAt` (vida máxima por rol). Aviso "Ya tienes una sesión activa en otro lugar" con las opciones cerrar la otra o cancelar ante 409 `ACTIVE_SESSION_EXISTS`. Los textos de sesión se muestran tal como llegan en `detail`. Revisión 7: no cambia el código del cliente, porque `authInterceptor` ya trata `SESSION_INVALIDATED`, `SESSION_REPLACED` y `SESSION_EXPIRED` en cualquier respuesta. El efecto visible es que también una consulta (por ejemplo, abrir el catálogo) puede devolverlos y llevar al inicio de sesión con su mensaje, sin renovar. Las pruebas E2E deben cubrir ese caso. Nota fija en el formulario de inicio de sesión sobre el bloqueo tras 3 intentos. Detalle en 2.6.2 a 2.6.5.
- **Inicio de sesión (D-25):** el componente no distingue casos. Ante cualquier 401 del inicio de sesión muestra solo "Credenciales inválidas", no marca un campo concreto ni sugiere registrarse, y conserva visible la nota fija del bloqueo. El 429 muestra "Demasiados intentos. Inténtalo de nuevo más tarde" y el 409 `ACTIVE_SESSION_EXISTS` abre el aviso de sesión única. El formulario de inicio de sesión no valida el formato ni el dominio del correo (solo que no esté vacío).
- **Administración de cuentas (ADMIN):** pantalla en `features/admin/users` con la lista paginada de cuentas, la baja con confirmación (ante 409 `USER_HAS_LOANS_IN_PROGRESS` muestra los préstamos en curso de `loans[]` y qué hace falta para cerrar cada uno, según 2.6.6) y el cierre de sesión de una cuenta.
- **Cancelación (SH-07):** el botón "Cancelar" solo aparece en SOLICITADO con inicio hoy o posterior y en APROBADO antes de `pickupDeadline`; el backend lo vuelve a validar.
- **Estructura:** `core/` (autenticación con `AuthService` basado en signals, `errorInterceptor` y `authInterceptor` funcionales registrados en ese orden con `provideHttpClient(withInterceptors([errorInterceptor, authInterceptor]))`, `authGuard` y `roleGuard(roles)`, `ApiClient` que antepone `environment.apiUrl`, layout con la campana de alertas); `shared/` (paginador, selector de rango con las mismas reglas que el backend, estados de carga, vacío y error, pipes de etiquetas como "DAÑADO" y "No disponible", modelos `ProblemDetail` y `PageResponse<T>`); `features/` (`auth`, `catalog`, `loans`, `admin`, `notifications`) con rutas perezosas por feature y componentes `OnPush`.
- **HTTP:** solo `${environment.apiUrl}/...` con `apiUrl = '/api'` en todos los entornos; en desarrollo `proxy.conf.json` reenvía `/api` a `:8080` y en contenedor local lo hace nginx. Las interfaces TypeScript reflejan los `*Response` del Anexo A.
- **Errores:** `errorInterceptor` usa `code` para decidir (401: cerrar sesión y llevar a inicio de sesión; 403: "Acceso denegado"; 409 `INSUFFICIENT_UNITS`: marcar los ítems de `items[]`), muestra `detail` tal cual y, en 500, el código de referencia.
- **Validación:** los formularios reactivos replican las reglas de forma para dar respuesta inmediata; el backend sigue siendo la barrera.
- **Alternativa descartada:** NgRx; signals y servicios por feature bastan para el tamaño del estado.

## Anexo C · Datos, configuración y despliegue

- **Flyway (regla confirmada en la revisión 7e):** todo cambio de base de datos (tablas, columnas, índices, restricciones y datos de referencia como las categorías) se hace con migraciones Flyway versionadas en `backend/src/main/resources/db/migration/V<n>__<descripcion>.sql` (validado por hook). Las migraciones aplicadas nunca se editan, `spring.jpa.hibernate.ddl-auto=validate` impide cambios no versionados y no se ejecuta SQL manual contra Aiven. Los datos de demostración no son esquema: van por la ubicación adicional `classpath:db/seed` y los sembradores del perfil `demo` o `dev` (2.8), y nunca se aplican en `prod` sin `demo`.
- **Borrado lógico:** ninguna llamada a `delete*`; la baja es un método de dominio que fija `deleted_at` con el `Clock`; los repositorios filtran explícitamente (R-7).
- **Entidades:** `BaseEntity` (`@MappedSuperclass`) con `id`, `createdAt`, `updatedAt`, `deletedAt`; Lombok con `@Getter`, `@NoArgsConstructor(access = PROTECTED)` y setters solo donde el dominio lo requiere (sin `@Data` en entidades); `@Version` en `equipment` y `loans`; `effective_end_date` de solo lectura; enumeraciones con `EnumType.STRING`.
- **MapStruct y Lombok:** `MapperConfig` común (`componentModel = "spring"`, `unmappedTargetPolicy = ERROR`), procesadores de anotaciones en orden Lombok → `lombok-mapstruct-binding` → MapStruct.
- **Conexión:** `sslMode=REQUIRED` en Aiven, zona de sesión de la institución, pool Hikari de 5, READ COMMITTED.
- **Despliegue:** `Dockerfile.vercel` en `frontend/` (nginx) y `backend/` (JRE 21, usuario sin privilegios); `vercel.json` enruta `/api/*` al backend y `/*` al frontend, y declara la tarea de Vercel Cron; `management.endpoints.web.base-path=/api/actuator` con solo `health` expuesto; springdoc en `/api/docs` y `/api/docs/v3/api-docs` (2.7). Local: `docker compose` con MySQL 8 (3306), API (8080) y web (4200).
- **Calidad:** `/verificar-calidad` y la CI incluyen `ArchitectureTest` y `OpenApiContractIT`; la prueba de humo de `/desplegar-vercel` usa `GET /api/actuator/health`, comprueba que `/api/docs` y `/api/docs/v3/api-docs` responden y ejecuta el flujo `@smoke` de Playwright, que incluye inicio de sesión, renovación y cierre de sesión.

## Anexo D · Cambios requeridos en el modelo de datos

Los implementa `database-engineer` con migraciones Flyway y los documenta en la sección 3 del readme; aquí solo se especifican. Nombres y tipos finales quedan a su criterio siempre que se conserven las garantías. Todo pertenece al módulo `auth`, salvo D.4 (`loans`).

### D.1 Tabla `refresh_tokens` (D-19, D-22)

Una fila por **sesión**: el token vigente se rota dentro de la misma fila, así la tabla crece con los inicios de sesión y no con cada renovación (el borrado físico está prohibido).

| Columna | Tipo | Restricciones | Descripción |
|---|---|---|---|
| `id` | BIGINT | PK, AUTO_INCREMENT | Identificador de la sesión (claim `sid` del access token). |
| `user_id` | BIGINT | NOT NULL, FK `fk_refresh_tokens_user` → users.id (RESTRICT) | Dueño de la sesión. |
| `token_hash` | BINARY(32) | NOT NULL, UNIQUE `uk_refresh_tokens_token_hash` | SHA-256 en bruto (32 bytes) del refresh token vigente; índice más compacto que el hexadecimal. Nunca se guarda el token en claro. |
| `previous_token_hash` | BINARY(32) | NULL, UNIQUE `uk_refresh_tokens_previous_hash` | Hash del token rotado inmediatamente antes; si se vuelve a presentar, es reutilización. |
| `rotation_count` | INT | NOT NULL, DEFAULT 0, CHECK ≥ 0 | Número de rotaciones. |
| `expires_at` | DATETIME | NOT NULL | Vencimiento del token vigente: 30 min desde la última rotación, sin superar `session_expires_at`. |
| `session_expires_at` | DATETIME | NOT NULL | Vida máxima de la sesión, fijada al iniciar sesión según el rol: ESTUDIANTE 1 h, ENCARGADO 8 h, ADMIN 8 h. Los valores viven en configuración, no en la base; la columna guarda el instante resultante. |
| `last_rotated_at` | DATETIME | NULL | Instante de la última rotación (se muestra como `lastActivityAt` en el 409 de sesión única). |
| `revoked_at` | DATETIME | NULL | Instante de la revocación; NULL = no revocada. |
| `revoke_reason` | ENUM('LOGOUT','REUSE_DETECTED','ACCOUNT_DISABLED','REPLACED','EXPIRED','CLOSED_BY_ADMIN') | NULL | Motivo de la revocación. `EXPIRED` se usa al revocar una sesión vencida antes de abrir otra. |
| `revoked_by` | BIGINT | NULL, FK `fk_refresh_tokens_revoked_by` → users.id | ADMIN que la cerró (`CLOSED_BY_ADMIN`, `ACCOUNT_DISABLED`); NULL en los demás casos. |
| `active_user_id` | BIGINT | GENERATED ALWAYS AS (CASE WHEN `revoked_at` IS NULL THEN `user_id` END) STORED, UNIQUE `uk_refresh_tokens_active_user` | **Unicidad de sesión activa por usuario.** MySQL no tiene índices únicos parciales; el único sobre esta columna admite muchas filas con NULL (sesiones revocadas) y una sola no revocada por usuario. |
| `created_at`, `updated_at`, `deleted_at` | DATETIME | convenciones de la sección 3 | `created_at` es el inicio de sesión. `deleted_at` no se usa en los flujos: una sesión termina por `revoked_at` o por vencimiento. |

Restricciones `CHECK`: `expires_at <= session_expires_at`; `session_expires_at > created_at`; `revoked_at` y `revoke_reason` ambos NULL o ambos NOT NULL; `rotation_count = 0` si y solo si `previous_token_hash` es NULL; `revoked_by` NOT NULL solo con `CLOSED_BY_ADMIN` o `ACCOUNT_DISABLED`.

Nota: una sesión vencida pero no revocada sigue ocupando `active_user_id`, porque la unicidad no puede depender de la hora. El inicio de sesión la revoca con `EXPIRED` dentro de la misma transacción antes de crear la nueva (2.6.4), así que nunca bloquea al usuario.

Índices: `uk_refresh_tokens_token_hash` (renovación); `uk_refresh_tokens_previous_hash` (detección de reutilización); `uk_refresh_tokens_active_user` (sesión única y búsqueda de la sesión vigente de un usuario); `idx_refresh_tokens_user_revoked (user_id, revoked_at)` (índice de la FK e historial de sesiones); índice de la FK `revoked_by`; `idx_refresh_tokens_expires (expires_at)` (consultas de sesiones vigentes y mantenimiento).

Retención: las filas vencidas o revocadas se conservan como historial de sesiones (sin borrado físico). Con una fila por inicio de sesión, el volumen es del orden de los inicios de sesión diarios, compatible con el plan gratuito de Aiven.

### D.2 Columnas nuevas en `users` para el límite de intentos (D-23)

| Columna | Tipo | Restricciones | Descripción |
|---|---|---|---|
| `failed_login_attempts` | INT | NOT NULL, DEFAULT 0, CHECK entre 0 y 3 | Fallos consecutivos desde el último inicio de sesión correcto o desde el fin del último bloqueo. |
| `login_locked_until` | DATETIME | NULL | Fin del bloqueo (tercer fallo + 15 min); NULL = sin bloqueo. |
| `last_failed_login_at` | DATETIME | NULL | Último fallo, para diagnóstico. |

Justificación de columnas frente a una tabla `login_attempts` en 2.6.5: la regla necesita un estado por cuenta, no un historial; se actualiza bajo el bloqueo de `users` que ya toma el inicio de sesión; no crece. No requieren índice: siempre se leen por la llave primaria de la cuenta encontrada por `uk_users_email`. El límite por IP no se guarda en la base (memoria por instancia).

### D.3 Columna nueva en `users` para la baja de cuentas (D-24)

| Columna | Tipo | Restricciones | Descripción |
|---|---|---|---|
| `deactivated_by` | BIGINT | NULL, FK `fk_users_deactivated_by` → users.id, con índice | ADMIN que dio de baja la cuenta. CHECK: NOT NULL solo si `deleted_at` es NOT NULL (puede quedar NULL si la baja se hizo fuera de la aplicación). |

`deleted_at` ya existe y es la baja lógica. El índice `idx_users_role` debería pasar a `(role, deleted_at)` para que la búsqueda de destinatarios activos y el conteo de ADMIN activos (`LAST_ADMIN`) no lean cuentas dadas de baja; decisión de `database-engineer`.

### D.4 Sin cambios en `loans` por la baja de cuentas

La baja no modifica préstamos (D-24): `loans.closure_reason` **no** gana ningún valor nuevo y `chk_loans_closure_reason` no cambia. Se retira la propuesta anterior de `CUENTA_DADA_DE_BAJA`. La consulta de préstamos en curso de un titular usa el índice existente `idx_loans_student_status_start`.

### D.5 Consultas de la sección 3 (A-12, aceptado)

Ajustar las consultas de retenidas y de préstamos en curso según el apartado 2.5, punto 5, de este ADR.

---

## Decisiones del usuario

**Resueltas (2026-11-06)**

| ID | Resolución |
|---|---|
| P-1 / P-1b | Access token de 15 min; refresh de 30 min deslizantes; vida máxima ESTUDIANTE 1 h, ENCARGADO 8 h, ADMIN 8 h. |
| P-2 / P-2b | Solo baja de cuentas. No se da de baja una cuenta con cualquier préstamo en curso (SOLICITADO, APROBADO, ENTREGADO o VENCIDO): 409 `USER_HAS_LOANS_IN_PROGRESS`. Sin cancelación automática (revisión 5, 2026-11-07). |
| Registro | El registro puede indicar que ya existe una cuenta con ese correo (RN-01a.2): excepción aceptada a D-25, con el limitador por IP (R-21). |
| P-2c | `product-owner` redactó o ajustó las historias: SH-07, SH-08 (baja, PA-29 y PA-36), SH-09, SH-10, SH-11 y SH-12. |
| P-3 / P-3b | Una sesión activa por usuario con desplazamiento confirmado; cierre administrativo con `DELETE /api/users/{id}/session`. |
| P-4 / P-4b / P-4c | 3 fallos consecutivos bloquean 15 min; límite por origen de 10 intentos fallidos con ventana de 15 min desde el primer fallo de la serie, por instancia (RN-SH11.8, PA-35). |
| P-5 | Contrato versionado en `docs/api/openapi.yaml`. |
| P-6 / P-8 / X-2 | Textos: los de `docs/historias-de-usuario.md` mandan (catálogo 3.3, revisión 6). `USER_HAS_LOANS_IN_PROGRESS` "La cuenta tiene préstamos en curso" confirmado (PA-36). |
| P-7 | Opción O-1 (comprobar todas las peticiones de ENCARGADO y ADMIN). Superada por P-9. |
| P-10 | Primer ADMIN en producción con `AdminBootstrapRunner` y las variables `BOOTSTRAP_ADMIN_*` (D-26, revisión 7e). |
| P-12 | Datos de demostración (revisión 7f): el sembrador de préstamos va en el habilitador H-Demo (2 puntos); la contraseña de demostración se publica en el readme 0.4; el entorno de evaluación usa `SPRING_PROFILES_ACTIVE=prod,demo`; R-23 es un riesgo aceptado. |
| P-11 | Grupo `GET /api/internal/jobs/daily` con el registro `InternalJob` y el `InternalJobController` en `shared`: una sola entrada de cron para `daily-review` y `due-soon` (D-27, revisión 7d). |
| P-9 | Opción B (revisión 7): comprobar cuenta y sesión en **todas** las peticiones autenticadas de todos los roles, con una consulta por llave primaria, sin caché y fallando cerrado. Corte inmediato real. |
| Regla nueva | No revelación en el inicio de sesión (D-25). |
| SH-07 | Cancelación solo mientras la solicitud puede resolverse (A-18). |
| Tokens | Hash del refresh token en `BINARY(32)`. |
| Revisión 6 | `SESSION_INVALIDATED` para baja y cierre administrativo; `SESSION_REPLACED` solo para el desplazamiento; `NO_ACTIVE_SESSION` (409); `INVALID_CRON_SECRET` (401); alerta ajena con 404; "cerrar otras sesiones" = reemplazo confirmado al iniciar sesión y cierre administrativo, sin cierre desde dentro. |

**Pendiente del usuario:** ninguna decisión.

**Abiertas (corresponden a otros agentes, no bloquean la aceptación)**

| ID | Tema | Responsable | Nota |
|---|---|---|---|
| X-3 | Aplicar el Anexo D (`refresh_tokens` con `BINARY(32)` y sesión activa única, columnas de `users`, consultas de A-12; sin cambios en `loans.closure_reason`). | `database-engineer` | Después se regenera `modelo-datos.mmd`. |
| X-4 | Aplicar al readme la lista cerrada de 2.6.7. | `docs-writer` (`/actualizar-documentacion`, `/generar-diagramas`) | Las secciones 1.4, 2.1 a 2.6 y 4. |
| X-5 | Aplicar a los `.mmd` las correcciones exactas de las revisiones 6 y 7 (5.2) y volver a renderizar sus PNG. | `docs-writer` (`/generar-diagramas`) | Revisión 6: `modulos-backend`, `componentes`, `secuencia-login`, `secuencia-sesion-refresh`, `secuencia-sesion-unica`, `secuencia-baja-cuenta`, `secuencia-tareas-programadas`. Revisión 7: `secuencia-peticion`, `secuencia-baja-cuenta`, `componentes` y una línea de `secuencia-sesion-unica`. |

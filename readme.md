# PrestaLab

Sistema web de préstamo de equipos y recursos académicos. Proyecto final del curso de Ingeniería de Software con IA.

## Índice

0. [Ficha del proyecto](#0-ficha-del-proyecto)
1. [Descripción general del producto](#1-descripción-general-del-producto)
2. [Arquitectura del sistema](#2-arquitectura-del-sistema)
3. [Modelo de datos](#3-modelo-de-datos)
4. [Especificación de la API](#4-especificación-de-la-api)
5. [Historias de usuario](#5-historias-de-usuario)
6. [Tickets de trabajo](#6-tickets-de-trabajo)
7. [Pull requests](#7-pull-requests)

---

## 0. Ficha del proyecto

### **0.1. Tu nombre completo:**

<!-- COMPLETAR: nombre completo -->
_Nombre completo del autor_ (AFRC)

### **0.2. Nombre del proyecto:**

PrestaLab

### **0.3. Descripción breve del proyecto:**

PrestaLab es una aplicación web para que los estudiantes de una institución educativa consulten la disponibilidad de equipos (portátiles, cámaras, kits de laboratorio, libros) y los soliciten en préstamo, y para que los encargados controlen el inventario y el ciclo completo del préstamo: aprobación, entrega, devolución y vencimiento. Está construida con Angular, Java Spring Boot y MySQL, desplegada en Vercel como contenedores, y desarrollada con asistencia de IA (Claude Code) en todas las fases.

### **0.4. URL del proyecto:**

<!-- COMPLETAR URL del proyecto desplegado (Entrega 3) -->

#### Cuentas de prueba

Las seis cuentas son ficticias y solo existen en el entorno de evaluación. Todas usan la misma contraseña de demostración: `Demo-UfAlodoVFTVV-26`.

| Correo | Rol | Qué puede probar | Datos de ejemplo |
|---|---|---|---|
| `admin.demo@institucion.edu` | ADMIN | Métricas, baja de cuentas y cierre de la sesión de otra cuenta. | Ve todo el catálogo y todos los préstamos de ejemplo. |
| `encargado1.demo@institucion.edu` | ENCARGADO | Bandeja: aprobar, rechazar, entregar y recibir. | Préstamos SOLICITADO, APROBADO, ENTREGADO y VENCIDO de los estudiantes de prueba. |
| `encargado2.demo@institucion.edu` | ENCARGADO | Segundo evaluador o prueba de concurrencia en la aprobación. | Los mismos préstamos que `encargado1`. |
| `estudiante1.demo@institucion.edu` | ESTUDIANTE | Solicitar un préstamo más (límite de 3 en curso) y cancelar. | Un préstamo SOLICITADO y uno APROBADO. |
| `estudiante2.demo@institucion.edu` | ESTUDIANTE | Consultar el historial y devolver un préstamo. | Un ENTREGADO en curso y, en el historial, un DEVUELTO, un RECHAZADO (motivo manual) y un CANCELADO ("Cancelado por usuario"). |
| `estudiante3.demo@institucion.edu` | ESTUDIANTE | Ver la alerta de vencido y el bloqueo de nuevas solicitudes. | Un préstamo VENCIDO sin devolver. |

El catálogo de ejemplo tiene 3 categorías (Cómputo, Audiovisual, Laboratorio) y unos 8 equipos. Uno está en MANTENIMIENTO ("No disponible") y otro tiene una sola unidad.

**Avisos**

- Son cuentas solo de demostración y la contraseña es válida únicamente en el entorno de evaluación. No la uses en otro sitio.
- Cada cuenta admite una sola sesión activa. Si dos evaluadores usan la misma cuenta se desplazan mutuamente: usa una cuenta distinta cada uno.
- Tras 3 intentos fallidos la cuenta se bloquea 15 minutos.
- Los datos son ficticios y pueden reiniciarse.

**Cómo se activan**

- **Local:** los perfiles `dev` y `demo` crean las cuentas y los datos de ejemplo al arrancar, con la contraseña de `SEED_PASSWORD` del `.env` (ver 1.4).
- **Despliegue de evaluación:** en las variables de entorno de Vercel se define `SPRING_PROFILES_ACTIVE=prod,demo` y `SEED_PASSWORD`. Debe usarse una base de Aiven propia y desechable, nunca la de producción real.
- Sin el perfil `demo` (por ejemplo, `prod` solo) no se crea ninguna cuenta ni dato de ejemplo.

### 0.5. URL o archivo comprimido del repositorio

<!-- COMPLETAR -->
`https://github.com/<usuario>/prestalab`

Ramas de entrega: `feature/entrega-1-AFRC`, `feature/entrega-2-AFRC`, `final-project-AFRC`.

---

## 1. Descripción general del producto

### **1.1. Objetivo:**

**Problema.** En muchas instituciones los préstamos de equipos se gestionan con hojas de cálculo, formularios en papel o mensajes. El estudiante no sabe qué hay disponible hasta que va al laboratorio; el encargado no tiene visibilidad de qué equipos están fuera, cuáles vencieron o en qué estado volvieron; y la institución pierde equipos y no tiene datos para decidir compras.

**Propósito.** PrestaLab centraliza el inventario y el ciclo del préstamo en una sola aplicación web:

- **Estudiantes:** consultan disponibilidad real por fechas y solicitan equipos sin desplazarse.
- **Encargados** (laboratorios, audiovisuales, biblioteca): aprueban, entregan y reciben devoluciones con trazabilidad, y mantienen el inventario al día.
- **Administración:** obtiene métricas de uso y vencimientos para tomar decisiones.

**Valor.** Menos tiempo de gestión, menos pérdidas (cada préstamo tiene responsable y fechas), historial auditable (nada se borra físicamente) y datos de uso del inventario.

### **1.2. Características y funcionalidades principales:**

Alcance según `docs/historias-de-usuario.md`: 23 historias, 11 Must y 12 Should.

**MUST-HAVE (11 historias)**

| ID | Funcionalidad | Flujo | Descripción |
|---|---|---|---|
| HU-01a | Registro de cuenta de estudiante | Autenticación y sesión | Registro con correo institucional; el registro siempre crea un ESTUDIANTE. |
| HU-01b | Inicio de sesión y acceso según rol | Autenticación y sesión | Inicio de sesión con access token y refresh token; menús y rutas según el rol (ESTUDIANTE, ENCARGADO, ADMIN). |
| HU-02a | Crear y editar equipos del catálogo | Catálogo | El encargado gestiona equipos con categoría, código de inventario único, unidades y estado. |
| HU-02b | Dar de baja un equipo | Catálogo | Baja lógica: el equipo deja de ofrecerse y se conserva el historial. |
| HU-03 | Consulta de disponibilidad | Solicitud | Búsqueda por nombre o categoría con las unidades disponibles para un rango de fechas. |
| HU-04 | Solicitud de préstamo | Solicitud | Uno o varios equipos para un rango de hasta 7 días, con máximo 3 préstamos en curso; la solicitud no retiene unidades. |
| HU-05a | Aprobar o rechazar solicitudes | Ciclo del préstamo | El encargado aprueba (retiene unidades, de 8:00 AM a 5:00 PM) o rechaza con motivo. |
| HU-05b | Registrar la entrega | Ciclo del préstamo | Deja constancia de quién tiene cada equipo y desde cuándo. |
| HU-05c | Registrar la devolución | Ciclo del préstamo | Cierra el ciclo y libera las unidades. |
| HU-05d | Registrar la devolución con daños o pérdidas | Ciclo del préstamo | Las unidades dañadas o perdidas se restan del total del equipo. |
| HU-05e | Cierre automático de préstamos no recogidos | Ciclo del préstamo | Un APROBADO no recogido en su plazo pasa a RECHAZADO ("No recogido") y libera las unidades. |

**SHOULD-HAVE (12 historias)**

| ID | Funcionalidad | Flujo |
|---|---|---|
| SH-01 | Historial "Mis préstamos" | Solicitud |
| SH-07 | Cancelar mi solicitud | Solicitud |
| SH-02 | Marcado de préstamos vencidos | Notificaciones y sanciones |
| SH-03 | Sanciones por retraso | Notificaciones y sanciones |
| SH-06 | Alerta de préstamo próximo a vencer | Notificaciones y sanciones |
| SH-04 | Panel de métricas | Métricas y exportación |
| SH-05 | Exportación a CSV | Métricas y exportación |
| SH-11 | Bloqueo temporal por intentos fallidos | Autenticación y sesión |
| SH-09 | Duración y expiración de la sesión | Autenticación y sesión |
| SH-10 | Sesión única por usuario | Autenticación y sesión |
| SH-08 | Baja de cuentas | Administración de cuentas |
| SH-12 | Cierre de la sesión de otra cuenta por el ADMIN | Administración de cuentas |

### **1.3. Diseño y experiencia de usuario:**

<!-- COMPLETAR con el enlace al video -->

Recorrido principal (video de demostración: `<enlace al video>`). Las capturas las generan las pruebas E2E de Playwright (headless) en `docs/testing/playwright/<funcionalidad>/`; el índice está en [`docs/testing/playwright/README.md`](docs/testing/playwright/README.md).

| Paso | Pantalla | Evidencia |
|---|---|---|
| 1 | **Inicio de sesión:** formulario con validación y mensajes de error claros. | [`login/`](docs/testing/playwright/login/RESULTADO.md) |
| 2 | **Catálogo:** búsqueda, filtro por categoría y selector de fechas; cada tarjeta muestra unidades disponibles. | [`consultar-disponibilidad/`](docs/testing/playwright/consultar-disponibilidad/RESULTADO.md) |
| 3 | **Solicitud:** carrito de equipos con cantidades, resumen y confirmación. | [`solicitar-prestamo/`](docs/testing/playwright/solicitar-prestamo/RESULTADO.md) |
| 4 | **Bandeja del encargado:** solicitudes pendientes con acciones aprobar / rechazar. | [`ciclo-prestamo/`](docs/testing/playwright/ciclo-prestamo/RESULTADO.md) |
| 5 | **Entrega y devolución:** registro del estado del equipo al recibirlo. | [`ciclo-prestamo/`](docs/testing/playwright/ciclo-prestamo/RESULTADO.md) |
| 6 | **Gestión de inventario:** tabla con creación, edición y baja lógica. | [`gestion-catalogo/`](docs/testing/playwright/gestion-catalogo/RESULTADO.md) |

Principios de diseño: interfaz en español, estados de carga / vacío / error en cada vista, diseño responsivo y etiquetas accesibles en formularios.

### **1.4. Instrucciones de instalación:**

**Requisitos:** Git, Docker Desktop, Java 21, Node.js 22 y npm. Para trabajar con IA: Claude Code y `jq` (`brew install jq`).

**Opción A: todo con Docker (recomendada para evaluar)**

```bash
git clone https://github.com/<usuario>/prestalab.git && cd prestalab
cp .env.example .env            # completa los valores locales
docker compose up -d --build    # MySQL :3306, API :8080, web :4200
```

`.env.example` incluye `DB_*`, `JWT_SECRET`, `CRON_SECRET`, `CORS_ALLOWED_ORIGINS`, `SPRING_PROFILES_ACTIVE` y `SEED_PASSWORD`.

Abre `http://localhost:4200`.

**Opción B: desarrollo (backend y frontend por separado)**

```bash
# 1. Base de datos
docker compose up -d mysql

# 2. Backend (Flyway aplica migraciones y, en el perfil dev, los datos de demostración)
cd backend
./mvnw spring-boot:run -Dspring-boot.run.profiles=dev     # http://localhost:8080
# Documentación interactiva: http://localhost:8080/api/docs (especificación en /api/docs/v3/api-docs)

# 3. Frontend (proxy de /api hacia :8080 en proxy.conf.json)
cd ../frontend
npm ci
npm start                                                 # http://localhost:4200
```

**Migraciones y semillas:** las migraciones viven en `backend/src/main/resources/db/migration` (`V<n>__*.sql`) y se aplican al arrancar. Los perfiles `dev` y `demo` crean las cuentas de prueba de la sección 0.4 y datos de ejemplo (equipos y préstamos en distintos estados) al arrancar, con la contraseña de `SEED_PASSWORD` del `.env`. El esquema siempre lo crean las migraciones Flyway; en `prod` sin `demo` no se siembra nada.

**Pruebas**

```bash
cd backend && ./mvnw test                  # unitarias
cd backend && ./mvnw verify -Pintegration  # integración y contrato OpenAPI (Testcontainers, requiere Docker)
cd frontend && npm run test -- --watch=false
cd e2e && npm ci && npx playwright install chromium && npx playwright test   # headless; evidencias en docs/testing/playwright/
bash .claude/hooks/tests/run-hook-tests.sh # pruebas de los hooks de IA
```

**Entorno de IA (Claude Code)**

```bash
chmod +x .claude/hooks/*.sh
claude          # luego /mcp para autenticar Atlassian; /hooks y /agents para verificar
```

---

## 2. Arquitectura del Sistema

### **2.1. Diagrama de arquitectura:**

```mermaid
---
title: Arquitectura (diseño)
---
flowchart LR
    U["Usuario<br/>(navegador)"] -->|HTTPS| V["Vercel<br/>enrutamiento vercel.json"]
    V -->|"/*"| FE["Servicio frontend<br/>Angular + nginx<br/>(contenedor)"]
    V -->|"/api/*"| BE["Servicio backend<br/>Spring Boot API REST<br/>(contenedor)"]
    CRON["Vercel Cron"] -->|"GET /api/internal/jobs/*<br/>Bearer CRON_SECRET"| BE
    subgraph BEI["Backend por capas"]
        direction LR
        TRACE["RequestTraceFilter<br/>X-Request-Id y MDC"] --> SEC["SecurityFilterChain<br/>Resource Server JWT"]
        SEC --> C["Controller /api<br/>Bean Validation y @PreAuthorize"]
        C --> S["Service<br/>transacción y reglas"]
        S --> R["Repository JPA"]
        S --> M["Mapper MapStruct"]
        S --- CA["Caché Caffeine<br/>categories, equipmentSummaries"]
        EH["GlobalExceptionHandler<br/>ProblemDetail"] -.-> C
        JOBS["Tareas programadas<br/>@Scheduled"] --> S
    end
    BE --- BEI
    R -->|"JDBC + TLS"| DB[("MySQL 8<br/>Aiven")]
    BE -.->|"Flyway al arrancar"| DB
```

> Fuente: [`docs/diagrams/arquitectura.mmd`](docs/diagrams/arquitectura.mmd) · Imagen: [`docs/diagrams/arquitectura.png`](docs/diagrams/arquitectura.png).

**Patrón.** Cliente-servidor con una SPA (Angular) y una API REST monolítica, organizada como **monolito modular** (un paquete por módulo: `shared`, `auth`, `catalog`, `loans` (incluye sanciones), `notifications` y `reports`; definición en `docs/adr/0001-arquitectura.md`) y **arquitectura en capas** dentro de cada módulo (controller → service → repository). Frontend y backend se empaquetan como contenedores independientes en un **monorepo**.

**Justificación.** El dominio es acotado y lo desarrolla una sola persona en pocas semanas: un monolito modular ofrece la separación necesaria sin el costo operativo de microservicios. Las capas facilitan pruebas unitarias del servicio y que los subagentes de IA trabajen con reglas claras por capa.

**Beneficios**
- Un solo dominio público: Vercel enruta `/api/*` al backend: mismo origen, CORS cerrado en producción (`CORS_ALLOWED_ORIGINS` vacío) y sin URLs por entorno.
- Contenedores reproducibles: el mismo `Dockerfile.vercel` corre en local (`docker compose`) y en producción.
- Monorepo: un PR puede incluir migración, backend, frontend y pruebas de una historia; Claude Code ve todo el contexto.
- Los módulos pueden extraerse a servicios más adelante si el sistema crece.

**Sacrificios y déficits**
- Escala como una unidad: no se puede escalar solo el módulo de préstamos.
- El backend en un contenedor de Vercel tiene **arranque en frío** (la JVM tarda unos segundos en la primera petición).
- Cada instancia abre su propio pool de conexiones y el plan gratuito de Aiven las limita, por lo que el pool se mantiene pequeño.
- Dependencia de servicios gratuitos (Vercel Hobby, Aiven Free) con límites de recursos.

### **2.2. Descripción de componentes principales:**

```mermaid
---
title: Componentes (diseño)
---
flowchart TB
    subgraph FE["Frontend Angular (contenedor nginx), environment.apiUrl = /api"]
        direction TB
        subgraph CORE["core/"]
            AUTHS["AuthService<br/>access token en memoria<br/>renovación al arrancar"]
            AINT["authInterceptor<br/>agrega Bearer, renueva ante 401 y reintenta"]
            EINT["errorInterceptor<br/>muestra detail y requestId"]
            AG["authGuard"]
            GUARD["roleGuard<br/>rutas por rol"]
        end
        subgraph FEAT["features/"]
            FAUTH["auth<br/>login, registro"]
            FCAT["catalog<br/>búsqueda y disponibilidad"]
            FLOAN["loans<br/>carrito, solicitud, mis préstamos"]
            FADM["admin<br/>bandeja, inventario, métricas, cuentas"]
            FNOT["notifications<br/>alertas"]
        end
        SHARED["shared/<br/>componentes y pipes"]
    end

    subgraph BE["Backend Spring Boot (contenedor)"]
        direction TB
        subgraph SEC["Filtros y seguridad"]
            TRACE["RequestTraceFilter<br/>requestId en MDC"]
            BEARER["BearerTokenAuthenticationFilter<br/>resource server"]
            UMDC["UserMdcFilter"]
            SECC["SecurityConfig<br/>reglas por URL"]
            ENTRY["ProblemDetailAuthenticationEntryPoint<br/>401"]
            DENIED["ProblemDetailAccessDeniedHandler<br/>403"]
        end
        subgraph MODS["Módulos"]
            subgraph MAUTH["auth"]
                AC["AuthController · UserController"]
                ASV["AuthService · RefreshTokenService<br/>LoginAttemptService · LoginRateLimiter<br/>UserAccountService"]
                ASI["ActiveSessionInterceptor"]
                AREPO["UserRepository · RefreshTokenRepository"]
            end
            subgraph MCAT["catalog"]
                CC["EquipmentController · CategoryController"]
                CSV["EquipmentService · EquipmentCatalogService"]
                CREPO["EquipmentRepository · CategoryRepository"]
            end
            subgraph MLOAN["loans"]
                LC["LoanController"]
                LSV["LoanService · LoanTransitionService<br/>LoanStateMachine · EquipmentUsageServiceImpl<br/>UserLoanActivityServiceImpl"]
                LJOB["PickupExpirationJob · DailyLoanReviewJob<br/>InternalJobController"]
                LREPO["LoanRepository · LoanStatusHistoryRepository"]
            end
            subgraph MNOT["notifications"]
                NC["NotificationController"]
                NSV["NotificationService<br/>oyente LoanStatusChangedEvent"]
                NJOB["DueSoonAlertJob"]
            end
            subgraph MREP["reports"]
                RC["ReportController"]
                RSV["ReportService"]
            end
        end
        subgraph SHB["shared"]
            SEXC["exception<br/>GlobalExceptionHandler, BusinessException"]
            SWEB["web<br/>RequestTraceFilter, PageResponse"]
            SPER["persistence<br/>BaseEntity"]
            SCFG["config<br/>Clock, caché, OpenAPI, MapperConfig"]
        end
        CACHE["Caffeine<br/>categories, equipmentSummaries<br/>sin caché de disponibilidad"]
        MAP["DTO Request/Response y MapStruct<br/>no se exponen entidades"]
    end

    DB[("MySQL 8<br/>Flyway")]

    FAUTH --> AUTHS
    FCAT --> AINT
    FLOAN --> AINT
    FADM --> AINT
    FNOT --> AINT
    AUTHS --> AINT
    AINT --> EINT
    GUARD -.-> FEAT
    AG -.-> FEAT
    EINT -->|"HTTPS /api/*"| TRACE
    TRACE --> BEARER
    BEARER --> UMDC
    UMDC --> SECC
    BEARER -.->|"401"| ENTRY
    SECC -.->|"403"| DENIED
    SECC -->|"reglas por URL"| MODS
    ASI -.->|"toda petición autenticada, consulta por PK, sin caché"| AREPO
    AC --> ASV --> AREPO
    CC --> CSV --> CREPO
    LC --> LSV --> LREPO
    LJOB --> LSV
    NC --> NSV
    NJOB --> NSV
    RC --> RSV
    LSV -->|"catalog.api"| CSV
    LSV -->|"auth.api"| ASV
    LSV -.->|"implementa EquipmentUsageService"| CSV
    LSV -.->|"implementa auth.api.UserLoanActivityService"| ASV
    LSV -.->|"evento LoanStatusChangedEvent"| NSV
    NSV -->|"loans.api y auth.api"| LSV
    RSV -->|"api de auth, catalog y loans"| LSV
    CSV --> CACHE
    MODS --> MAP
    AREPO --> DB
    CREPO --> DB
    LREPO --> DB
    SEXC -.->|"errores de controllers"| MODS
    MODS --> SHB
```

> Fuente: [`docs/diagrams/componentes.mmd`](docs/diagrams/componentes.mmd) · Imagen: [`docs/diagrams/componentes.png`](docs/diagrams/componentes.png).

**Módulos del backend y sus dependencias permitidas**

```mermaid
---
title: Módulos del backend (diseño)
---
flowchart LR
    subgraph SH["shared"]
        SHX["excepciones, web, persistence, config"]
    end
    subgraph AUTH["auth"]
        AAPI["auth.api<br/>UserDirectoryService<br/>UserLoanActivityService"]
    end
    subgraph CAT["catalog"]
        CAPI["catalog.api<br/>EquipmentCatalogService<br/>EquipmentUsageService"]
    end
    subgraph LOANS["loans"]
        LAPI["loans.api<br/>LoanQueryService<br/>LoanStatusChangedEvent"]
    end
    subgraph NOT["notifications"]
        NAPI["notifications.api"]
    end
    subgraph REP["reports"]
        RAPI["reports sin tablas propias"]
    end
    LOANS --> AAPI
    LOANS --> CAPI
    NOT --> AAPI
    NOT --> LAPI
    REP --> AAPI
    REP --> CAPI
    REP --> LAPI
    AUTH --> SHX
    CAT --> SHX
    LOANS --> SHX
    NOT --> SHX
    REP --> SHX
    LAPI -.->|"implementa EquipmentUsageService"| CAPI
    LAPI -.->|"implementa UserLoanActivityService"| AAPI
    LAPI -.->|"evento LoanStatusChangedEvent"| NAPI
    PROH["Prohibido: repositorios, entidades, servicios y DTO de otro módulo, y ciclos<br/>Solo se depende de api y shared (ArchUnit)"]
    LOANS ~~~ PROH
```

> Fuente: [`docs/diagrams/modulos-backend.mmd`](docs/diagrams/modulos-backend.mmd) · Imagen: [`docs/diagrams/modulos-backend.png`](docs/diagrams/modulos-backend.png).

**Flujo de una petición de extremo a extremo**

```mermaid
---
title: Petición genérica a la API (diseño)
---
sequenceDiagram
    autonumber
    actor U as Navegador
    participant V as Vercel
    participant T as RequestTraceFilter
    participant SF as SecurityFilterChain
    participant AI as ActiveSessionInterceptor
    participant C as Controller
    participant S as Service
    participant R as Repository
    participant M as Mapper
    participant DB as MySQL
    U->>V: /api/... con Authorization Bearer
    V->>T: reenvía y añade x-vercel-id
    T->>T: toma o genera X-Request-Id, pone requestId y edgeId en MDC
    T->>SF: continúa la cadena
    alt token ausente, inválido o vencido
        SF-->>U: 401 UNAUTHENTICATED por ProblemDetailAuthenticationEntryPoint
    else token válido
        SF->>SF: valida firma, exp e iss, crea AuthenticatedUser, UserMdcFilter pone userId y role
        SF->>AI: toda petición autenticada, de cualquier rol
        AI->>DB: una consulta por llave primaria a refresh_tokens (sid) unida a users, sin caché
        alt cuenta dada de baja o sesión revocada o vencida
            AI-->>U: 401 SESSION_INVALIDATED, SESSION_REPLACED o SESSION_EXPIRED por GlobalExceptionHandler
        else la base no responde
            AI-->>U: 500 INTERNAL_ERROR (falla cerrada)
        else sesión activa
            AI->>C: continúa
            C->>C: Bean Validation y @PreAuthorize
            alt datos inválidos
                C-->>U: 400 VALIDATION_ERROR por GlobalExceptionHandler
            else acceso denegado
                C-->>U: 403 Acceso denegado
            else datos válidos
                C->>S: caso de uso
                activate S
                Note over S,DB: Una transacción
                S->>R: consultas y bloqueos
                R->>DB: SQL parametrizado
                DB-->>R: filas
                S->>M: entidad a Response
                M-->>S: Response
                deactivate S
                alt regla de negocio incumplida
                    S-->>U: 409 con code y detail exactos, WARN sin traza
                else error inesperado
                    S-->>U: 500 INTERNAL_ERROR con requestId, registro ERROR
                else éxito
                    S-->>C: Response
                    C-->>U: 2xx con cabecera X-Request-Id
                end
            end
        end
    end
    T->>T: escribe la línea de acceso http_request y limpia el MDC
```

> Fuente: [`docs/diagrams/secuencia-peticion.mmd`](docs/diagrams/secuencia-peticion.mmd) · Imagen: [`docs/diagrams/secuencia-peticion.png`](docs/diagrams/secuencia-peticion.png).

| Componente | Tecnología | Responsabilidad |
|---|---|---|
| Frontend SPA | Angular (componentes standalone, signals, formularios reactivos), TypeScript estricto, nginx | Interfaz por rol, validación de formularios, manejo del JWT con interceptor, guards de ruta. |
| API REST | Java 21, Spring Boot, Spring Web, Bean Validation, springdoc-openapi | Endpoints bajo `/api`, validación de entrada, errores en formato `ProblemDetail` con `code` y `requestId`, documentación OpenAPI en `/api/docs` con contrato versionado en `docs/api/openapi.yaml`. |
| Seguridad | Spring Security (OAuth2 Resource Server), JWT, refresh token, BCrypt | Access token de 15 min, refresh token rotativo de 30 min deslizantes en cookie `HttpOnly`, una sesión por usuario, límite de intentos, `@PreAuthorize` en cada endpoint y comprobación de cuenta y sesión. |
| Persistencia | Spring Data JPA (Hibernate), MapStruct | Entidades con borrado lógico por método de dominio (sin `@SQLRestriction` en `users` ni `equipment`), referencias entre módulos por id, mapeo entidad ↔ DTO con MapStruct. |
| Migraciones | Flyway | Versionado del esquema y datos semilla por perfil. |
| Base de datos | MySQL 8 (Docker en local, Aiven en producción) | Almacenamiento transaccional con InnoDB, `utf8mb4` y TLS. |
| Tareas programadas | Spring `@Scheduled` y Vercel Cron (`/api/internal/jobs/*` con `CRON_SECRET`) | Cierre de no recogidos, rechazo de solicitudes sin resolver, marcado de vencidos y alertas de próximo a vencer; tareas idempotentes. |
| Caché | Caffeine | Solo categorías y resúmenes de equipos; nunca disponibilidad. |
| Trazabilidad | `RequestTraceFilter`, MDC, SLF4J | `X-Request-Id`, línea de acceso por petición y `loan_status_history`. |
| Plataforma | Vercel (servicios con contenedores), Vercel Container Registry | Build de imágenes, enrutamiento, HTTPS, despliegues de vista previa por rama. |
| Pruebas | JUnit 5, Mockito, Testcontainers, ArchUnit, Vitest/Jasmine, Playwright (headless) | Unitarias, fronteras de módulos y contrato OpenAPI, integración contra MySQL real y E2E con capturas como evidencia en `docs/testing/playwright/<funcionalidad>/`. |
| Desarrollo con IA | Claude Code: CLAUDE.md, hooks, skills, 6 subagentes (front, back, database, qa-tester, code-reviewer, docs-writer), MCP Atlassian, Playwright y Mermaid | Implementación guiada por tickets, verificación automática y reglas obligatorias (lint, convenciones, sin `DELETE FROM`, sin `.env`). |

**Stack resumido:** Angular · Java 21 + Spring Boot · MySQL 8 · Flyway · Docker · Vercel · Aiven · Playwright · Claude Code.

### **2.3. Descripción de alto nivel del proyecto y estructura de ficheros**

```text
prestalab/
├── CLAUDE.md                # contexto y reglas para Claude Code
├── README.md                # esta documentación
├── PROMPTS.md               # registro de uso de IA
├── vercel.json              # servicios, enrutamiento y Vercel Cron
├── docker-compose.yml       # entorno local completo
├── .mcp.json                # MCP de Atlassian (Jira), Playwright y Mermaid
├── .env.example             # plantilla de variables (el .env real no se versiona)
├── .claude/
│   ├── settings.json        # permisos y registro de hooks
│   ├── hooks/               # lint, convenciones, bloqueo de DELETE FROM y .env (+ tests/)
│   ├── skills/              # implementar-historia, verificar-calidad, desplegar-vercel, ...
│   └── agents/              # frontend, backend, database, qa-tester, code-reviewer, docs-writer
├── backend/
│   ├── Dockerfile.vercel
│   ├── pom.xml
│   └── src/
│       ├── main/java/co/prestalab/
│       │   ├── auth/        # cuentas, JWT, refresh token, sesiones, límite de intentos
│       │   ├── catalog/     # categorías y equipos
│       │   ├── loans/       # solicitudes, ciclo del préstamo, disponibilidad, sanciones, tareas programadas
│       │   ├── notifications/ # alertas dentro de la aplicación
│       │   ├── reports/     # métricas y exportación CSV (vía api de otros módulos)
│       │   └── shared/      # errores (ProblemDetail), trazabilidad, paginación, configuración
│       ├── main/resources/  # application*.yml, db/migration (Flyway)
│       └── test/            # unitarias (*Test) e integración (*IT)
├── frontend/
│   ├── Dockerfile.vercel, nginx.conf, nginx.local.conf
│   └── src/app/
│       ├── core/            # auth, interceptores, guards, layout
│       ├── shared/          # componentes y pipes reutilizables
│       └── features/        # auth, catalog, loans, admin (una carpeta por módulo)
├── e2e/                     # Playwright headless: tests/, pages/ (Page Objects), support/ (evidencias)
└── docs/
    ├── adr/                 # decisiones de arquitectura
    ├── api/                 # openapi.yaml (contrato versionado)
    ├── diagrams/            # fuentes .mmd e imágenes de arquitectura, componentes, secuencia, ER e infraestructura
    ├── testing/playwright/  # evidencias E2E por funcionalidad (capturas + RESULTADO.md)
    ├── plans/               # plan de implementación por ticket
    └── ai-log/              # prompts.jsonl (registro automático de prompts)
```

- **Módulos del backend:** cada módulo tiene controller, service, repository, dto, mapper, entity, api, domain, exception y, si aplica, event y job.
- **Backend:** *package-by-feature* (un paquete por módulo) con capas dentro de cada uno. Facilita ubicar el código de una historia y mantener los módulos desacoplados.
- **Frontend:** estructura `core / shared / features` recomendada por la guía de estilo de Angular, con rutas perezosas por módulo.
- **`.claude/`:** configuración versionada del asistente; cualquier persona que clone el repositorio trabaja con las mismas reglas.

### **2.4. Infraestructura y despliegue**

```mermaid
---
title: Infraestructura y despliegue (diseño)
---
flowchart TB
    DEV["Desarrollador + Claude Code<br/>(hooks y skills)"] -->|"git push rama"| GH["GitHub<br/>monorepo"]
    GH -->|"PR"| CI["GitHub Actions ci.yml"]
    subgraph CIJ["CI"]
        direction LR
        T1["Unitarias back y front"] --> T2["ArchitectureTest ArchUnit"] --> T3["Integración Testcontainers<br/>y OpenApiContractIT"] --> T4["E2E Playwright"]
    end
    CI --> CIJ
    GH -->|"webhook"| VB["Vercel Build<br/>Dockerfile.vercel x2"]
    VB --> VCR["Vercel Container Registry"]
    VCR --> FEP["frontend<br/>(nginx :80)"]
    VCR --> BEP["backend<br/>(Spring Boot :80)"]
    CRON["Vercel Cron"] -->|"/api/internal/jobs/* con CRON_SECRET"| BEP
    ENV["Variables en Vercel<br/>DB_URL, DB_USER, DB_PASSWORD, JWT_SECRET,<br/>CRON_SECRET, CORS_ALLOWED_ORIGINS,<br/>SPRING_PROFILES_ACTIVE"] -.-> BEP
    BEP -->|"TLS"| AIV[("Aiven MySQL Free")]
    BEP -.->|"logs a salida estándar"| LOGS["Registros de Vercel"]
    SMOKE["Prueba de humo<br/>GET /api/actuator/health y @smoke"] -.-> BEP
    subgraph Vercel
        VB
        VCR
        FEP
        BEP
        CRON
        LOGS
    end
    subgraph LOCAL["Local (docker compose)"]
        LDB[("MySQL 8.4 :3306")]
        LAPI["API :8080"]
        LWEB["web :4200<br/>nginx reenvía /api"]
        LWEB --> LAPI --> LDB
    end
    DEV -.->|"docker compose up"| LOCAL
```

> Fuente: [`docs/diagrams/infraestructura.mmd`](docs/diagrams/infraestructura.mmd) · Imagen: [`docs/diagrams/infraestructura.png`](docs/diagrams/infraestructura.png).

**Entornos**

| Entorno | Dónde | Base de datos | Rama |
|---|---|---|---|
| Local | `docker compose` | MySQL 8.4 en contenedor | cualquiera |
| Vista previa | Vercel Preview (URL por despliegue) | Aiven (esquema de pruebas) | `feature/*` |
| Producción | Vercel Production | Aiven | `final-project-AFRC` |

**Proceso de despliegue**

1. Cada historia se desarrolla en `feature/PLAB-<n>-<slug>` y entra por PR a la rama de la entrega activa.
2. En cada PR, GitHub Actions ejecuta pruebas unitarias, de arquitectura (ArchUnit), de integración, de contrato OpenAPI y E2E (`.github/workflows/ci.yml`).
3. Vercel construye las dos imágenes a partir de los `Dockerfile.vercel`, las publica en su registro y genera una URL de vista previa por despliegue.
4. Al integrar en `final-project-AFRC`, Vercel despliega en producción. Las variables (`DB_URL`, `DB_USER`, `DB_PASSWORD`, `JWT_SECRET`, `CRON_SECRET`, `CORS_ALLOWED_ORIGINS` vacío en producción, `SPRING_PROFILES_ACTIVE=prod`) se definen en Vercel, nunca en el repositorio.
5. Al arrancar, Flyway aplica las migraciones pendientes sobre Aiven (`ddl-auto: validate` impide cambios no versionados).
6. Vercel Cron invoca `GET /api/internal/jobs/daily-review` a las 00:05 hora de la institución con `Authorization: Bearer ${CRON_SECRET}`; el backend también ejecuta las tareas con `@Scheduled`.
7. La skill `/desplegar-vercel` ejecuta pruebas de humo: `GET /api/actuator/health`, `/api/docs` y el flujo principal con Playwright (`@smoke`), que incluye inicio de sesión, renovación y cierre de sesión, sobre la URL pública.

**Plan B:** si los contenedores no están disponibles en la cuenta de Vercel, el frontend se publica como sitio estático en Vercel y el backend en Render o Railway con el mismo Dockerfile.

### **2.5. Seguridad**

| Práctica | Implementación |
|---|---|
| Sesión | Access token JWT HS256 de **15 min** (secreto `JWT_SECRET`) solo en memoria del navegador; refresh token opaco, de un solo uso y rotativo, de 30 min deslizantes, en cookie `HttpOnly`, `Secure`, `SameSite=Strict`, guardado como SHA-256; vida máxima de la sesión 1 h ESTUDIANTE y 8 h ENCARGADO y ADMIN. |
| Contraseñas | Hash con BCrypt; nunca se devuelven en las respuestas. |
| Autorización por rol | `@PreAuthorize` en cada endpoint; además, **toda** petición autenticada, de cualquier rol y también las consultas, comprueba que la cuenta siga activa y la sesión vigente con una consulta por llave primaria, sin caché y fallando cerrado. Guards en Angular (la UI no es la barrera: el backend siempre valida). |
| Validación de entrada | Bean Validation en los DTO (`@NotNull`, `@Future`, `@Size`, `@Email`) y reglas de negocio en el servicio. |
| Inyección SQL | Consultas JPA parametrizadas; prohibido concatenar SQL. |
| Errores | `ProblemDetail` con `code` estable y `requestId`, sin trazas internas ni mensajes de la base de datos; los errores inesperados son genéricos y se registran con su `requestId`. |
| Secretos | Variables de entorno en Vercel (`DB_*`, `JWT_SECRET`, `CRON_SECRET`); `.env` ignorado por git y bloqueado para la IA por hook (`protect-sensitive-files.sh`) y reglas `permissions.deny`. Un hook impide pegar contraseñas en los prompts. |
| Transporte | HTTPS en Vercel y TLS obligatorio hacia Aiven (`sslMode=REQUIRED`). |
| Integridad y trazabilidad | Borrado lógico (`deleted_at`), `loan_status_history` en cada transición y línea de acceso con `X-Request-Id`; un hook bloquea `DELETE FROM`, `TRUNCATE` y `DROP`. |
| Mismo origen | El frontend y la API se sirven desde el mismo dominio; CORS restringido a `CORS_ALLOWED_ORIGINS` (vacío en producción). |
| Sesión única | Una sesión activa por usuario; un nuevo inicio de sesión pide confirmar el cierre de la otra; el ADMIN puede cerrar la sesión de una cuenta. |
| Cierre de sesión | `POST /api/auth/logout` revoca la sesión en el servidor. |
| Límite de intentos | 3 fallos consecutivos bloquean la cuenta 15 min; máximo 10 intentos fallidos por origen cada 15 min. |
| No revelación | Contraseña incorrecta, correo inexistente, cuenta dada de baja o bloqueada reciben el mismo "Credenciales inválidas" con tiempo igualado; el registro sí indica si el correo ya tiene cuenta (decisión aceptada). |
| Baja de cuenta | Solo ADMIN, nunca la propia ni la del último ADMIN, y solo sin préstamos en curso; revoca la sesión y la persona pierde el acceso en su siguiente petición, sea consulta o acción ("Tu sesión ya no es válida. Inicia sesión de nuevo"). |
| Cierre de sesión por el ADMIN | Corta de inmediato la sesión de otra cuenta (`DELETE /api/users/{id}/session`), con el mismo mensaje. |
| CSRF | La API usa Bearer; los endpoints de la cookie exigen `SameSite=Strict` y `Origin` propio. |
| Dependencias | Dependabot y `npm audit` / `mvn dependency-check` en CI. |

Ejemplo de autorización por rol:

```java
@PostMapping("/{id}/approval")
@PreAuthorize("hasAnyRole('ENCARGADO','ADMIN')")
public LoanResponse approve(@PathVariable Long id, @AuthenticationPrincipal AuthenticatedUser user) {
    return loanService.approve(id, user.id());
}
```

### **2.6. Tests**

| Tipo | Ejemplo | Qué verifica |
|---|---|---|
| Unitaria (backend) | `LoanServiceTest#deberiaRechazarSolicitudCuandoNoHayUnidadesDisponibles` | Que la solicitud falla con 409 si la cantidad pedida supera la disponibilidad del rango. |
| Unitaria (backend) | `LoanServiceTest#noDeberiaPermitirDevolverUnPrestamoNoEntregado` | Que solo se aceptan transiciones de estado válidas. |
| Integración | `LoanControllerIT` (MockMvc + Testcontainers MySQL 8) | `POST /api/loans` crea el préstamo y sus ítems en una transacción, responde 201 y devuelve 403 si el usuario no es estudiante. |
| Unitaria (frontend) | `loan.service.spec.ts` | Que el servicio llama a `/api/loans` con el cuerpo correcto y maneja el error 409. |
| E2E (Playwright, headless) | `e2e/tests/ciclo-prestamo.spec.ts` `@smoke` | Estudiante solicita → encargado aprueba y entrega → registra devolución → la disponibilidad vuelve a su valor. Capturas por paso en `docs/testing/playwright/ciclo-prestamo/`. |
| Arquitectura | `ArchitectureTest` | Fronteras de módulos y reglas de 1.5 del ADR. |
| Contrato | `OpenApiContractIT` | Que el OpenAPI generado coincide con `docs/api/openapi.yaml`. |
| Integración (concurrencia) | IT de concurrencia de la aprobación | Dos aprobaciones por la última unidad: solo una gana. |
| Integración (sesión) | Pruebas de sesión | Rotación, reutilización, vencimiento por inactividad y por vida máxima según el rol, sesión única, bloqueo tras 3 fallos con respuesta idéntica, cierre de sesión, baja rechazada con préstamos en curso. |
| Integración (sesión) | `ActiveSessionInterceptorIT` | Tras una baja, un cierre administrativo, un desplazamiento o un cierre de sesión, la **consulta** siguiente de un ESTUDIANTE con su access token aún vigente recibe 401 con el código correcto; la comprobación falla cerrada si la base no responde. |
| Hooks de IA | `.claude/hooks/tests/run-hook-tests.sh` | 31 casos: bloqueo de `.env`, `DELETE FROM`, ramas y commits fuera de convención, Playwright con ventana y specs sin evidencias. |

Cobertura objetivo: ≥ 80 % de líneas en la capa de servicios (JaCoCo). Reportes: `backend/target/site/jacoco/` y `e2e/playwright-report/`.

**Evidencias E2E.** Todas las pruebas corren en Chromium **headless** (configuración en `e2e/playwright.config.ts`; un hook bloquea `--headed`, `--ui` y `codegen`). Cada spec declara su funcionalidad con `test.use({ funcionalidad: '...' })` y registra capturas con `await evidence('<paso>')`; además se guarda una captura final con el resultado de cada prueba. El reporter genera por funcionalidad:

```text
docs/testing/playwright/
├── README.md                          # índice: funcionalidad | en verde | última ejecución
└── solicitar-prestamo/
    ├── RESULTADO.md                   # tabla de pruebas y capturas por paso
    ├── resultados.json
    ├── ca1-solicitud-exitosa-...--01-catalogo-filtrado.png
    ├── ca1-solicitud-exitosa-...--02-formulario-diligenciado.png
    ├── ca1-solicitud-exitosa-...--03-prestamo-en-estado-solicitado.png
    └── ca1-solicitud-exitosa-...--04-final-passed.png
```

---

## 3. Modelo de Datos

### **3.1. Diagrama del modelo de datos:**

Modelo relacional para MySQL 8 (InnoDB, `utf8mb4`). Cubre las historias HU-01a a HU-05e y SH-01 a SH-07 de [`docs/historias-de-usuario.md`](docs/historias-de-usuario.md), con las decisiones PA-1 a PA-28, y la sesión del [ADR 0001](docs/adr/0001-arquitectura.md) (refresh token D-19, corte de acceso D-20, Anexo D) con los cambios aceptados por el usuario: una sola sesión abierta por usuario, vida máxima de la sesión según el rol, bloqueo temporal tras intentos fallidos de inicio de sesión y baja de cuentas por un ADMIN (D-22 a D-25, Anexo D, revisión 4), que solo procede si el titular no tiene préstamos en curso. Las lecturas aplican las reglas de tiempo con el reloj, sin esperar a las tareas programadas (supuesto A-12 del ADR).

```mermaid
erDiagram
    USERS {
        bigint id PK "AUTO_INCREMENT"
        varchar(120) full_name "NOT NULL"
        varchar(150) email UK "NOT NULL, uk_users_email, incluye bajas"
        varchar(100) password_hash "NOT NULL, BCrypt"
        enum role "NOT NULL, ESTUDIANTE ENCARGADO ADMIN, default ESTUDIANTE"
        int failed_login_attempts "NOT NULL, default 0, fallos consecutivos, CHECK 0 a 3"
        datetime login_locked_until "NULL, fin del bloqueo del inicio de sesión"
        datetime last_failed_login_at "NULL, último fallo contado"
        bigint deactivated_by FK "NULL, ADMIN que dio de baja, solo con deleted_at"
        datetime created_at "NOT NULL, default CURRENT_TIMESTAMP"
        datetime updated_at "NULL, ON UPDATE CURRENT_TIMESTAMP"
        datetime deleted_at "NULL, borrado lógico"
    }
    REFRESH_TOKENS {
        bigint id PK "AUTO_INCREMENT, una fila por sesión, claim sid"
        bigint user_id FK "NOT NULL, dueño de la sesión"
        binary(32) token_hash UK "NOT NULL, SHA-256 binario del token vigente"
        binary(32) previous_token_hash UK "NULL, token rotado anterior, detecta reutilización"
        int rotation_count "NOT NULL, default 0, 0 si y solo si sin rotación"
        datetime expires_at "NOT NULL, deslizante, CHECK no mayor que session_expires_at"
        datetime session_expires_at "NOT NULL, vida máxima fijada al iniciar según el rol"
        datetime last_rotated_at "NULL hasta la primera rotación"
        datetime revoked_at "NULL, sesión sin cerrar"
        enum revoke_reason "NULL, LOGOUT REUSE_DETECTED ACCOUNT_DISABLED REPLACED EXPIRED CLOSED_BY_ADMIN"
        bigint revoked_by FK "NULL, ADMIN que la cerró, solo CLOSED_BY_ADMIN o ACCOUNT_DISABLED"
        bigint active_user_id UK "GENERATED STORED, user_id si no está cerrada, una por usuario"
        datetime created_at "NOT NULL, inicio de sesión"
        datetime updated_at "NULL"
        datetime deleted_at "NULL, no se usa en flujos"
    }
    CATEGORIES {
        bigint id PK "AUTO_INCREMENT"
        varchar(80) name UK "NOT NULL, uk_categories_name"
        varchar(255) description "NULL"
        datetime created_at "NOT NULL"
        datetime updated_at "NULL"
        datetime deleted_at "NULL, borrado lógico"
    }
    EQUIPMENT {
        bigint id PK "AUTO_INCREMENT"
        varchar(30) inventory_code UK "NOT NULL, único incluso dados de baja"
        varchar(120) name "NOT NULL"
        varchar(500) description "NULL"
        bigint category_id FK "NOT NULL"
        int total_units "NOT NULL, CHECK mayor o igual a 0"
        enum status "NOT NULL, DISPONIBLE MANTENIMIENTO, default DISPONIBLE"
        bigint version "NOT NULL, bloqueo optimista"
        datetime created_at "NOT NULL"
        datetime updated_at "NULL"
        datetime deleted_at "NULL, fecha de baja"
    }
    LOANS {
        bigint id PK "AUTO_INCREMENT"
        bigint student_id FK "NOT NULL, titular"
        enum status "NOT NULL, 7 estados, default SOLICITADO"
        date start_date "NOT NULL"
        date end_date "NOT NULL, CHECK 0 a 6 días desde start_date"
        datetime approved_at "NULL"
        bigint approved_by FK "NULL, encargado o admin"
        datetime pickup_deadline "NULL, plazo de recogida fijado al aprobar"
        datetime delivered_at "NULL, CHECK menor que pickup_deadline"
        bigint delivered_by FK "NULL"
        date effective_end_date "GENERATED STORED, fecha fin efectiva"
        datetime returned_at "NULL"
        bigint returned_by FK "NULL"
        datetime closed_at "NULL, rechazo o cancelación"
        bigint closed_by FK "NULL, NULL si cerró el sistema"
        enum closure_reason "NULL, RECHAZO_MANUAL NO_RECOGIDO SIN_RESOLVER_A_TIEMPO EQUIPO_DADO_DE_BAJA CANCELACION_USUARIO"
        varchar(250) closure_note "NULL, 10 a 250 si RECHAZO_MANUAL"
        bigint version "NOT NULL, bloqueo optimista"
        datetime created_at "NOT NULL, fecha de solicitud"
        datetime updated_at "NULL"
        datetime deleted_at "NULL, no se usa en flujos"
    }
    LOAN_ITEMS {
        bigint id PK "AUTO_INCREMENT"
        bigint loan_id FK, UK "NOT NULL, uk compuesto con equipment_id"
        bigint equipment_id FK, UK "NOT NULL"
        int quantity "NOT NULL, CHECK mayor o igual a 1"
        datetime created_at "NOT NULL"
        datetime updated_at "NULL"
        datetime deleted_at "NULL"
    }
    LOAN_ITEM_RETURNS {
        bigint id PK "AUTO_INCREMENT"
        bigint loan_item_id FK, UK "NOT NULL, uk compuesto con item_condition"
        enum item_condition UK "NOT NULL, BUENO CON_DESPERFECTOS DANADO PERDIDO"
        int quantity "NOT NULL, CHECK mayor o igual a 1"
        varchar(500) notes "obligatoria si no es BUENO"
        datetime created_at "NOT NULL"
        datetime updated_at "NULL"
        datetime deleted_at "NULL"
    }
    LOAN_STATUS_HISTORY {
        bigint id PK "AUTO_INCREMENT"
        bigint loan_id FK "NOT NULL"
        enum from_status "NULL solo al crear"
        enum to_status "NOT NULL, CHECK transición válida"
        bigint changed_by FK "NULL, NULL si fue el sistema"
        datetime changed_at "NOT NULL, instante de negocio"
        datetime created_at "NOT NULL"
        datetime updated_at "NULL"
        datetime deleted_at "NULL"
    }
    SANCTIONS {
        bigint id PK "AUTO_INCREMENT"
        bigint loan_id FK, UK "NOT NULL, un bloqueo por préstamo"
        int days_late "NOT NULL, CHECK mayor o igual a 1"
        date starts_on "NOT NULL, día siguiente a la devolución"
        date ends_on "NOT NULL, CHECK duración igual a LEAST de days_late y 15"
        datetime created_at "NOT NULL"
        datetime updated_at "NULL"
        datetime deleted_at "NULL, anulación"
    }
    NOTIFICATIONS {
        bigint id PK "AUTO_INCREMENT"
        bigint recipient_id FK, UK "NOT NULL, uk con loan_id y tipo"
        bigint loan_id FK, UK "NOT NULL"
        enum notification_type UK "NOT NULL, PRESTAMO_VENCIDO PROXIMO_A_VENCER NO_RECOGIDO SIN_RESOLVER_A_TIEMPO"
        datetime read_at "NULL, no leída"
        datetime closed_at "NULL, abierta"
        datetime created_at "NOT NULL, fecha de la alerta"
        datetime updated_at "NULL"
        datetime deleted_at "NULL"
    }

    USERS ||--o{ REFRESH_TOKENS : "inicia sesiones"
    USERS |o--o{ REFRESH_TOKENS : "cierra como ADMIN"
    USERS |o--o{ USERS : "da de baja"
    CATEGORIES ||--o{ EQUIPMENT : "clasifica"
    USERS ||--o{ LOANS : "solicita como titular"
    USERS |o--o{ LOANS : "aprueba"
    USERS |o--o{ LOANS : "entrega"
    USERS |o--o{ LOANS : "recibe devolución"
    USERS |o--o{ LOANS : "rechaza o cancela"
    LOANS ||--|{ LOAN_ITEMS : "contiene"
    EQUIPMENT ||--o{ LOAN_ITEMS : "se presta en"
    LOAN_ITEMS ||--o{ LOAN_ITEM_RETURNS : "se devuelve como"
    LOANS ||--|{ LOAN_STATUS_HISTORY : "registra transiciones"
    USERS |o--o{ LOAN_STATUS_HISTORY : "ejecuta"
    LOANS ||--o| SANCTIONS : "origina bloqueo"
    USERS ||--o{ NOTIFICATIONS : "recibe"
    LOANS ||--o{ NOTIFICATIONS : "genera"
```

> Fuente: [`docs/diagrams/modelo-datos.mmd`](docs/diagrams/modelo-datos.mmd) · Imagen: [`docs/diagrams/modelo-datos.png`](docs/diagrams/modelo-datos.png). Diagrama de diseño: aún no hay migraciones Flyway en el repositorio.

**Ciclo de vida del préstamo** (columna `loans.status`; las transiciones válidas también se exigen con un CHECK en `loan_status_history`):

```mermaid
stateDiagram-v2
    [*] --> SOLICITADO : estudiante solicita
    SOLICITADO --> APROBADO : encargado aprueba en horario de servicio
    SOLICITADO --> RECHAZADO : rechazo manual, sin resolver a tiempo o equipo dado de baja
    SOLICITADO --> CANCELADO : estudiante cancela
    APROBADO --> ENTREGADO : encargado entrega dentro del plazo de recogida
    APROBADO --> RECHAZADO : sistema cierra como no recogido
    APROBADO --> CANCELADO : estudiante cancela
    ENTREGADO --> VENCIDO : revisión diaria, fecha fin efectiva anterior a hoy
    ENTREGADO --> DEVUELTO : encargado registra devolución
    VENCIDO --> DEVUELTO : encargado registra devolución
    RECHAZADO --> [*]
    CANCELADO --> [*]
    DEVUELTO --> [*]
```

> Fuente: [`docs/diagrams/estados-prestamo.mmd`](docs/diagrams/estados-prestamo.mmd).

### **3.2. Descripción de entidades principales:**

**Convenciones comunes**

- Motor InnoDB, juego de caracteres `utf8mb4` con colación `utf8mb4_0900_ai_ci`: las comparaciones no distinguen mayúsculas ni tildes, así que "cámara" encuentra "Cámara Canon EOS R10" (RN-03.1) y los únicos de correo y código no admiten variantes como `LAB-001` y `lab-001`.
- Llave primaria subrogada `id BIGINT AUTO_INCREMENT` en todas las tablas (Aiven exige llave primaria con `sql_require_primary_key`).
- Auditoría en todas las tablas: `created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP`, `updated_at DATETIME NULL ON UPDATE CURRENT_TIMESTAMP` y `deleted_at DATETIME NULL` (NULL = vigente). En las tablas de solo inserción (`loan_status_history`, `loan_item_returns`) `updated_at` y `deleted_at` quedan en NULL; se conservan para usar una sola entidad base en JPA.
- Borrado lógico siempre: ninguna fila se borra físicamente. Todas las llaves foráneas son `ON DELETE RESTRICT ON UPDATE RESTRICT`: las llaves subrogadas no cambian, y un borrado físico accidental falla en lugar de propagarse. No se usa `CASCADE` ni `SET NULL`.
- Enumeraciones con `ENUM` de MySQL y valores del dominio en español sin tildes (`DANADO`; la interfaz muestra "DAÑADO"). Añadir un valor al final de un `ENUM` es un `ALTER TABLE ... MODIFY` que MySQL aplica sin copiar la tabla y sin eliminar restricciones; con `VARCHAR` + `CHECK` habría que eliminar y volver a crear la restricción. En JPA se mapean con `@Enumerated(EnumType.STRING)`.
- `DATE` para fechas de negocio (rangos de préstamo, bloqueos) y `DATETIME` para instantes, en hora local de la institución (supuesto S-1).
- Nombres en inglés y `snake_case`; restricciones `fk_<tabla>_<ref>`, `uk_<tabla>_<col>`, `idx_<tabla>_<col>` y `chk_<tabla>_<regla>`.
- Los `CHECK` (MySQL 8.0.16+) cubren las reglas de una sola fila. Lo que depende de "hoy" (`CURDATE()` no se admite en un `CHECK`) o de otras filas (límite de 3, disponibilidad, suma de la devolución) lo valida el servicio dentro de la transacción. Los `CHECK` están escritos para no dar nunca UNKNOWN, porque MySQL acepta como válida una condición que evalúa NULL.

**users**: cuentas de las personas que usan el sistema (HU-01a, HU-01b).

| Columna | Tipo | Restricciones | Descripción |
|---|---|---|---|
| id | BIGINT | PK, AUTO_INCREMENT | Identificador. |
| full_name | VARCHAR(120) | NOT NULL | Nombre completo (supuesto S-2). |
| email | VARCHAR(150) | NOT NULL, UNIQUE `uk_users_email` | Correo institucional y usuario de acceso, guardado en minúsculas. El único incluye las cuentas con baja lógica (RN-01a.2). El dominio `@institucion.edu` (RN-01a.1) se valida en el registro. |
| password_hash | VARCHAR(100) | NOT NULL | Hash BCrypt. La política de RN-01a.3 se valida antes de cifrar. |
| role | ENUM('ESTUDIANTE','ENCARGADO','ADMIN') | NOT NULL, DEFAULT 'ESTUDIANTE', INDEX `idx_users_role_deleted_at (role, deleted_at)` | Un rol por cuenta. El registro siempre crea ESTUDIANTE (RN-01a.4); ENCARGADO y ADMIN se cargan con datos semilla. No hay cambio de roles. |
| failed_login_attempts | INT | NOT NULL, DEFAULT 0, CHECK `chk_users_failed_login_attempts` (BETWEEN 0 AND 3) | Fallos consecutivos de inicio de sesión desde el último acierto o desde el fin del último bloqueo (D-23). Llega a 3 con el fallo que bloquea y se queda en 3 durante el bloqueo. El `CHECK` repite el máximo de la regla: si el máximo cambia, hace falta una migración. |
| login_locked_until | DATETIME | NULL | Fin del bloqueo del inicio de sesión (instante del tercer fallo + 15 min); NULL = sin bloqueo. Un valor pasado ya no bloquea y se limpia con el siguiente intento. Se levanta solo por fecha, sin proceso programado. |
| last_failed_login_at | DATETIME | NULL | Instante del último fallo contado, para diagnóstico. Los intentos durante el bloqueo no se cuentan ni lo cambian (van al log). |
| deactivated_by | BIGINT | NULL, FK `fk_users_deactivated_by` → users.id, INDEX `idx_users_deactivated_by` | ADMIN que dio de baja la cuenta (D-24). NULL si la cuenta está activa o si la baja se hizo fuera de la aplicación. |
| created_at, updated_at | DATETIME | ver convenciones | Auditoría. |
| deleted_at | DATETIME | NULL | Baja lógica de la cuenta (no hay reactivación). En la misma transacción se revoca su sesión abierta en `refresh_tokens` (`ACCOUNT_DISABLED`, D-20). Una cuenta con baja no inicia sesión ni renueva; en el inicio de sesión se trata igual que un correo inexistente. |

Restricciones `CHECK` de `users`:

| Restricción | Regla |
|---|---|
| `chk_users_failed_login_attempts` | `failed_login_attempts BETWEEN 0 AND 3`. |
| `chk_users_login_lock` | Con fallos (`failed_login_attempts > 0`) hay `last_failed_login_at`; con bloqueo, `last_failed_login_at` NOT NULL y `login_locked_until > last_failed_login_at`. |
| `chk_users_deactivated_by` | `deactivated_by IS NULL OR deleted_at IS NOT NULL`. Que un ADMIN no se dé de baja a sí mismo lo valida el servicio: MySQL no admite en un `CHECK` la columna `AUTO_INCREMENT` `id`. |

**Bloqueo por intentos fallidos (D-23).** Tras 3 fallos consecutivos el inicio de sesión de la cuenta queda bloqueado 15 minutos desde el tercer fallo (parámetros, supuesto S-15). Los intentos durante el bloqueo no cuentan ni lo alargan. Si `login_locked_until > ahora` rechaza el intento aunque la contraseña sea correcta. Correo inexistente, cuenta dada de baja, contraseña incorrecta y cuenta bloqueada producen **la misma respuesta** (401 "Credenciales inválidas", RN-01b.2, D-25) y el mismo trabajo: siempre se ejecuta una comparación BCrypt (contra el hash ficticio si no hay cuenta), y toda respuesta fallida respeta un tiempo mínimo, así que ni el mensaje ni el tiempo distinguen los casos. Ninguna columna obliga a distinguirlos ante quien inicia sesión: `login_locked_until`, `failed_login_attempts` y `last_failed_login_at` solo se usan dentro del servicio y en el log. El fallo se registra en una transacción propia que bloquea la fila del usuario (`REQUIRES_NEW`, para que se confirme aunque la respuesta sea un error) y, así, los intentos simultáneos contra la misma cuenta se cuentan uno a uno. Una sola sentencia (MySQL evalúa las asignaciones de izquierda a derecha, así que la segunda ve el contador ya actualizado):

```sql
UPDATE users
SET failed_login_attempts = CASE WHEN login_locked_until IS NOT NULL AND login_locked_until <= :now
                                 THEN 1 ELSE failed_login_attempts + 1 END,   -- bloqueo vencido: empieza de nuevo
    login_locked_until    = CASE WHEN failed_login_attempts >= :maxAttempts THEN :lockedUntil ELSE NULL END,
    last_failed_login_at  = :now
WHERE id = :userId
  AND (login_locked_until IS NULL OR login_locked_until <= :now);             -- durante el bloqueo: 0 filas
-- :lockedUntil = :now + duración del bloqueo; ambos los calcula el servicio con el Clock
```

Un acierto pone `failed_login_attempts = 0` y `login_locked_until = NULL`. Probado en MySQL 8: dos fallos dejan 2; el tercero deja 3 y el bloqueo; un intento durante el bloqueo afecta 0 filas; el primer fallo después del bloqueo deja 1 sin bloqueo. No se usa una tabla `login_attempts` con una fila por intento: crecería con cada intento (también con ataques) sin poder borrarse, y la regla solo necesita el estado actual de la cuenta. Los intentos se registran en el log con el motivo real y el correo resumido por hash, no en la base. Un correo inexistente no tiene fila y no acumula intentos por cuenta; lo frena el límite por origen de conexión (supuesto S-17), que no se guarda en la base.

**Baja de una cuenta (D-24, decisión del usuario).** Solo un ADMIN, nunca sobre sí mismo ni sobre el último ADMIN activo, y **solo si el titular no tiene préstamos en curso de ningún tipo** (SOLICITADO, APROBADO, ENTREGADO o VENCIDO). No se cancela ni se cierra ningún préstamo por la baja. "En curso" usa las mismas condiciones de reloj que el límite de 3 (A-12): una SOLICITADO con el inicio pasado o un APROBADO con el plazo de recogida vencido no impiden la baja, y la tarea programada los cierra después con su motivo (supuesto S-18). Transacción, con el orden users → loans → refresh_tokens:

1. Bloquea la fila del usuario (`FOR UPDATE`). Si es ADMIN, bloquea antes todas las filas de ADMIN activos en orden de `id` (`role = 'ADMIN' AND deleted_at IS NULL`, por `idx_users_role_deleted_at`) y comprueba que no sea el último.
2. Comprueba que no tenga préstamos en curso con la misma condición del conteo de RN-04.8 (`EXISTS`, por `idx_loans_student_status_start`). No hace falta bloquear los préstamos: el único camino que crea un préstamo en curso es crear una solicitud, que bloquea la misma fila del usuario (punto 5 de "Disponibilidad y concurrencia") y comprueba allí que la cuenta siga activa. Las transiciones posteriores solo sacan préstamos de "en curso".
3. Fija `deleted_at` y `deactivated_by`.
4. Revoca la sesión abierta: `UPDATE refresh_tokens SET revoked_at = :now, revoke_reason = 'ACCOUNT_DISABLED', revoked_by = :adminId WHERE active_user_id = :userId`.

Para cortar el acceso de una cuenta que no se puede dar de baja (por ejemplo, con préstamos en mano), el ADMIN cierra su sesión (`CLOSED_BY_ADMIN`, ver `refresh_tokens`).

**refresh_tokens**: sesiones de inicio de sesión con su refresh token rotativo (ADR 0001: D-19, D-20, Anexo D; módulo `auth`). Una fila por **sesión**: el token vigente se rota dentro de la misma fila, así la tabla crece con los inicios de sesión y no con cada renovación.

| Columna | Tipo | Restricciones | Descripción |
|---|---|---|---|
| id | BIGINT | PK, AUTO_INCREMENT | Identificador de la sesión (claim `sid` del access token). |
| user_id | BIGINT | NOT NULL, FK `fk_refresh_tokens_user` → users.id | Dueño de la sesión. |
| token_hash | BINARY(32) | NOT NULL, UNIQUE `uk_refresh_tokens_token_hash` | SHA-256 del refresh token vigente, en binario (los 32 bytes del resumen, sin pasar a hexadecimal). El token en claro nunca se guarda. En JPA se mapea como `byte[]` con `@JdbcTypeCode(SqlTypes.BINARY)` y `@Column(length = 32)` (o `columnDefinition = "binary(32)"`) para que `ddl-auto=validate` lo acepte; las búsquedas pasan el `byte[]` de `MessageDigest` como parámetro. |
| previous_token_hash | BINARY(32) | NULL, UNIQUE `uk_refresh_tokens_previous_hash` | Hash del token rotado inmediatamente antes. Si se vuelve a presentar, es reutilización (posible robo) y se cierra la sesión. |
| rotation_count | INT | NOT NULL, DEFAULT 0 | Número de rotaciones. |
| expires_at | DATETIME | NOT NULL | Vencimiento del token vigente: `MIN(ahora + vida del refresh token, session_expires_at)`, recalculado en cada rotación (expiración deslizante). |
| session_expires_at | DATETIME | NOT NULL | Vida máxima de la sesión, fijada al iniciar sesión según el rol de ese momento. No cambia con las rotaciones. |
| last_rotated_at | DATETIME | NULL | Instante de la última rotación; NULL si nunca rotó. |
| revoked_at | DATETIME | NULL | Instante del cierre de la sesión; NULL = sin cerrar. |
| revoke_reason | ENUM('LOGOUT','REUSE_DETECTED','ACCOUNT_DISABLED','REPLACED','EXPIRED','CLOSED_BY_ADMIN') | NULL | Motivo del cierre: cierre de sesión, reutilización detectada, baja de la cuenta, reemplazada por un nuevo inicio de sesión que el usuario confirmó, vencida y cerrada al iniciar una nueva (o al intentar renovarla), o cerrada por un ADMIN (pérdida o robo del dispositivo). |
| revoked_by | BIGINT | NULL, FK `fk_refresh_tokens_revoked_by` → users.id, INDEX `idx_refresh_tokens_revoked_by` | ADMIN que cerró la sesión: obligatorio con `CLOSED_BY_ADMIN`; con `ACCOUNT_DISABLED` es el ADMIN de la baja, o NULL si la detectó la renovación (baja hecha fuera de la aplicación); NULL con los demás motivos. |
| active_user_id | BIGINT | GENERATED ALWAYS AS (CASE WHEN revoked_at IS NULL THEN user_id END) STORED, UNIQUE `uk_refresh_tokens_active_user` | `user_id` mientras la sesión no está cerrada; NULL al cerrarla. El único garantiza **una sola sesión sin cerrar por usuario**. En JPA no se mapea (o se mapea de solo lectura). |
| created_at | DATETIME | NOT NULL | Inicio de sesión. Se fija con el mismo `Clock` que `session_expires_at` (ver `chk_refresh_tokens_expiry`). |
| updated_at | DATETIME | ver convenciones | Auditoría. |
| deleted_at | DATETIME | NULL | No se usa en los flujos: una sesión termina por `revoked_at` o por vencimiento. |

Restricciones `CHECK` de `refresh_tokens`:

| Restricción | Regla |
|---|---|
| `chk_refresh_tokens_hash_distinct` | `previous_token_hash IS NULL OR previous_token_hash <> token_hash`. La longitud la fija el tipo `BINARY(32)`; MySQL rellena con `0x00` un valor más corto, así que el servicio siempre escribe el resumen completo de 32 bytes. |
| `chk_refresh_tokens_rotation` | Sin rotar: `rotation_count = 0`, `previous_token_hash` y `last_rotated_at` NULL. Rotada: `rotation_count > 0`, ambos NOT NULL y `last_rotated_at < expires_at`. |
| `chk_refresh_tokens_expiry` | `expires_at <= session_expires_at` y `session_expires_at > created_at`. |
| `chk_refresh_tokens_revocation` | `revoked_at` y `revoke_reason` ambos NULL o ambos NOT NULL; sin revocar, `revoked_by` NULL; EXPIRED solo con `revoked_at >= expires_at`; CLOSED_BY_ADMIN con `revoked_by` NOT NULL; `revoked_by` NOT NULL solo con CLOSED_BY_ADMIN o ACCOUNT_DISABLED. |

Las duraciones son parámetros de configuración, no constantes del esquema: access token 15 min (no se guarda), refresh token 30 min deslizantes, vida máxima de la sesión 1 h para ESTUDIANTE y 8 h para ENCARGADO y ADMIN. El servicio calcula `session_expires_at` con el rol al iniciar sesión, y `expires_at` en cada rotación. `last_rotated_at` (o `created_at` si nunca rotó) se muestra como última actividad de la sesión vigente cuando otro inicio de sesión choca con ella.

**Una sola sesión por usuario.** MySQL no tiene índices parciales (`WHERE revoked_at IS NULL`), así que el único se pone sobre la columna generada `active_user_id`, que vale NULL en las sesiones cerradas (un `UNIQUE` admite varios NULL). Un único no puede depender de la hora, así que una sesión vencida pero sin cerrar sigue ocupando el lugar: el inicio de sesión la cierra primero. Flujo del inicio de sesión, en una transacción y con el orden de bloqueo users → refresh_tokens:

1. Bloquea la fila del usuario (`FOR UPDATE`) y aplica el bloqueo por intentos (arriba).
2. Si la contraseña es correcta, busca su sesión sin cerrar: `SELECT ... FROM refresh_tokens WHERE active_user_id = ? FOR UPDATE` (a lo sumo una fila).
3. Si está vencida (`expires_at <= ahora`), la cierra con `EXPIRED`. Si está vigente, no la reemplaza sin confirmación: el usuario puede cerrarla desde el nuevo inicio de sesión (`REPLACED`) o cancelar (supuesto S-14). Un ADMIN puede cerrar la sesión de cualquier usuario (`CLOSED_BY_ADMIN`, `revoked_by` = el ADMIN) con `UPDATE ... WHERE active_user_id = ?`.
4. Inserta la sesión nueva. Si dos inicios de sesión simultáneos llegaran a insertar, el segundo falla con `1062 Duplicate entry` en `uk_refresh_tokens_active_user`: la garantía es del motor, no solo del bloqueo.

**Corte de acceso (D-20).** La baja de la cuenta (ver `users`) revoca su sesión en la misma transacción (a lo sumo una fila, por `uk_refresh_tokens_active_user`). La renovación busca por `token_hash`, rechaza la sesión cerrada o vencida y además lee `users.deleted_at` por llave primaria, lo que cubre bajas hechas fuera de la aplicación (entonces revoca con `ACCOUNT_DISABLED` y `revoked_by` NULL). Toda petición autenticada, de cualquier rol y también las consultas, comprueba la cuenta y la sesión con una lectura de `refresh_tokens` por llave primaria (`id` = claim `sid`) unida a `users` por llave primaria, sin caché y sin índice adicional. Por eso la petición siguiente a una baja, un cierre administrativo (`CLOSED_BY_ADMIN`) o un desplazamiento por otro inicio de sesión (`REPLACED`) recibe 401 de inmediato, aunque el access token aún no haya expirado. Tampoco se puede renovar.

**Retención.** Ninguna fila se borra: las sesiones cerradas o vencidas quedan como historial. Volumen medido en MySQL 8 con 200.000 sesiones y hash `BINARY(32)`: unos 70 MB entre datos e índices y 80 MB de archivo (alrededor de 0,4 KB por sesión; con `CHAR(64)` eran 108 MB, así que el binario ahorra cerca del 25 %). Los índices de hash aleatorio siguen ocupando más que los datos. Con sesiones de 1 h, un estudiante puede abrir varias por día, así que el volumen depende de los inicios de sesión diarios (ver riesgos de Aiven en los supuestos).

**categories**: clasificación del catálogo, usada para el filtro por categoría exacta (RN-03.1) y en el CSV de inventario (RN-SH05.1).

| Columna | Tipo | Restricciones | Descripción |
|---|---|---|---|
| id | BIGINT | PK, AUTO_INCREMENT | Identificador. |
| name | VARCHAR(80) | NOT NULL, UNIQUE `uk_categories_name` | Nombre visible ("Cómputo", "Audiovisual"). |
| description | VARCHAR(255) | NULL | Descripción opcional. |
| created_at, updated_at, deleted_at | DATETIME | ver convenciones | Auditoría y borrado lógico. |

**equipment**: tipo de equipo del catálogo con su número de unidades (HU-02a, HU-02b, HU-03, HU-05d).

| Columna | Tipo | Restricciones | Descripción |
|---|---|---|---|
| id | BIGINT | PK, AUTO_INCREMENT | Identificador. |
| inventory_code | VARCHAR(30) | NOT NULL, UNIQUE `uk_equipment_inventory_code` | Código de inventario. El único incluye los equipos dados de baja (RN-02a.2). |
| name | VARCHAR(120) | NOT NULL, INDEX | Nombre buscable por coincidencia parcial. |
| description | VARCHAR(500) | NULL | Detalle opcional. |
| category_id | BIGINT | NOT NULL, FK `fk_equipment_category` → categories.id | Categoría. |
| total_units | INT | NOT NULL, CHECK `chk_equipment_total_units` (total_units >= 0) | Unidades físicas vigentes. El mínimo de 1 al crear o editar (RN-02a.3) lo valida el servicio, porque una devolución DAÑADO o PERDIDO puede dejarlo en 0 (RN-05d.3). |
| status | ENUM('DISPONIBLE','MANTENIMIENTO') | NOT NULL, DEFAULT 'DISPONIBLE' | MANTENIMIENTO se muestra "No disponible" y no admite solicitudes (RN-02a.4). La baja no es un estado: es `deleted_at`. |
| version | BIGINT | NOT NULL, DEFAULT 0 | Bloqueo optimista (`@Version`) para ediciones concurrentes desde la interfaz. |
| created_at, updated_at | DATETIME | ver convenciones | Auditoría. |
| deleted_at | DATETIME | NULL | Fecha de baja lógica (RN-02b.1). El equipo y sus préstamos se conservan. |

**loans**: solicitud de préstamo de un estudiante y su ciclo de vida completo (HU-04, HU-05a a HU-05e, SH-01 a SH-07).

| Columna | Tipo | Restricciones | Descripción |
|---|---|---|---|
| id | BIGINT | PK, AUTO_INCREMENT | Identificador (columna "identificador" del CSV). |
| student_id | BIGINT | NOT NULL, FK `fk_loans_student` → users.id | Estudiante titular. |
| status | ENUM('SOLICITADO','APROBADO','RECHAZADO','CANCELADO','ENTREGADO','VENCIDO','DEVUELTO') | NOT NULL, DEFAULT 'SOLICITADO' | Estado actual (RN-04.5). |
| start_date | DATE | NOT NULL | Fecha de inicio (incluida). |
| end_date | DATE | NOT NULL, CHECK `chk_loans_date_range` | Fecha fin (incluida); `end_date >= start_date` y `DATEDIFF(end_date, start_date) <= 6`, es decir, máximo 7 días. "Inicio no anterior a hoy" lo valida el servicio. |
| approved_at | DATETIME | NULL | Instante de aprobación (RN-05a.4). |
| approved_by | BIGINT | NULL, FK `fk_loans_approved_by` → users.id | ENCARGADO o ADMIN que aprobó. |
| pickup_deadline | DATETIME | NULL | Plazo de recogida, calculado por el servicio al aprobar (convenciones, RN-05e.2, PA-26). |
| delivered_at | DATETIME | NULL | Instante de entrega (RN-05b.2). |
| delivered_by | BIGINT | NULL, FK `fk_loans_delivered_by` → users.id | Encargado que entregó. |
| effective_end_date | DATE | GENERATED ALWAYS AS (GREATEST(end_date, DATE(delivered_at))) STORED, NULL hasta la entrega | Fecha fin efectiva (PA-25). La calcula el motor. |
| returned_at | DATETIME | NULL | Instante de devolución (RN-05c.5). |
| returned_by | BIGINT | NULL, FK `fk_loans_returned_by` → users.id | Encargado que recibió. |
| closed_at | DATETIME | NULL | Instante del rechazo o la cancelación. |
| closed_by | BIGINT | NULL, FK `fk_loans_closed_by` → users.id | Quien rechazó o canceló; NULL cuando cerró el sistema. |
| closure_reason | ENUM('RECHAZO_MANUAL','NO_RECOGIDO','SIN_RESOLVER_A_TIEMPO','EQUIPO_DADO_DE_BAJA','CANCELACION_USUARIO') | NULL | Tipo de cierre. Los motivos del sistema tienen texto fijo ("No recogido", "Sin resolver a tiempo", "Equipo dado de baja"). |
| closure_note | VARCHAR(250) | NULL | Texto libre: motivo del rechazo manual (10 a 250 caracteres, RN-05a.2) o motivo opcional de la cancelación (RN-SH07.5). Una cancelación sin nota se muestra "Cancelado por usuario". |
| version | BIGINT | NOT NULL, DEFAULT 0 | Bloqueo optimista de las transiciones. |
| created_at | DATETIME | NOT NULL | Fecha y hora de la solicitud. |
| updated_at, deleted_at | DATETIME | ver convenciones | Ningún flujo borra préstamos (supuesto S-9). |

Restricciones `CHECK` de `loans` (coherencia del estado con sus hitos dentro de la fila):

| Restricción | Regla |
|---|---|
| `chk_loans_date_range` | `end_date >= start_date` y `DATEDIFF(end_date, start_date) <= 6`. |
| `chk_loans_approval_fields` | `approved_at`, `approved_by` y `pickup_deadline` son todos NULL o todos NOT NULL. |
| `chk_loans_approval_status` | SOLICITADO no tiene aprobación; APROBADO, ENTREGADO, VENCIDO y DEVUELTO sí. RECHAZADO y CANCELADO pueden tenerla o no. |
| `chk_loans_delivery` | `delivered_at` (y `delivered_by`) NOT NULL si y solo si el estado es ENTREGADO, VENCIDO o DEVUELTO. |
| `chk_loans_return` | `returned_at` (y `returned_by`) NOT NULL si y solo si el estado es DEVUELTO. |
| `chk_loans_closure` | `closed_at` y `closure_reason` NOT NULL si y solo si el estado es RECHAZADO o CANCELADO. |
| `chk_loans_closure_reason` | CANCELACION_USUARIO solo con CANCELADO y `closed_by` NOT NULL. RECHAZO_MANUAL: RECHAZADO sin aprobación previa, con `closed_by` y nota de 10 a 250 caracteres. EQUIPO_DADO_DE_BAJA: sin aprobación, con `closed_by`, sin nota. SIN_RESOLVER_A_TIEMPO: sin aprobación, `closed_by` NULL, sin nota. NO_RECOGIDO: con aprobación, `closed_by` NULL, sin nota. |
| `chk_loans_timeline` | `pickup_deadline >= approved_at`; `DATE(pickup_deadline) >= start_date`; `DATE(approved_at) <= start_date` (una SOLICITADO con el inicio pasado ya no se aprueba, RN-05a.11); `approved_at <= delivered_at < pickup_deadline` (entrega dentro del plazo, RN-05b.3); `DATE(delivered_at) >= start_date`; `returned_at >= delivered_at`. |
| `chk_loans_closure_timing` | Cada cierre ocurre en su ventana de tiempo (A-12): NO_RECOGIDO con `closed_at >= pickup_deadline` (RN-05e.5); SIN_RESOLVER_A_TIEMPO con `DATE(closed_at) > start_date`; RECHAZO_MANUAL, EQUIPO_DADO_DE_BAJA y la cancelación de una SOLICITADO con `DATE(closed_at) <= start_date`; la cancelación de un APROBADO con `closed_at < pickup_deadline`. Así el estado que escriben las acciones coincide con el que ya muestran las lecturas: lo que las lecturas tratan como cerrado no puede cerrarse con otro motivo. |

El horario de servicio (8:00 AM a 5:00 PM) no se fija con `CHECK` sobre `TIME(approved_at)` porque es un parámetro de negocio; lo valida el servicio (RN-05a.10, RN-05b.3).

**loan_items**: equipos y cantidades de cada solicitud. Resuelve la relación N:M entre `loans` y `equipment` (RN-04.1).

| Columna | Tipo | Restricciones | Descripción |
|---|---|---|---|
| id | BIGINT | PK, AUTO_INCREMENT | Identificador. |
| loan_id | BIGINT | NOT NULL, FK `fk_loan_items_loan` → loans.id | Préstamo. |
| equipment_id | BIGINT | NOT NULL, FK `fk_loan_items_equipment` → equipment.id | Equipo. |
| quantity | INT | NOT NULL, CHECK `chk_loan_items_quantity` (quantity >= 1) | Unidades pedidas (RN-04.1). |
| created_at, updated_at, deleted_at | DATETIME | ver convenciones | Auditoría. |

UNIQUE `uk_loan_items_loan_equipment (loan_id, equipment_id)`: un equipo aparece una sola vez por solicitud. Los ítems no cambian después de crear la solicitud: no hay aprobaciones ni cancelaciones parciales (RN-SH07.6).

**loan_item_returns**: resultado de la devolución por equipo y estado (HU-05c, HU-05d). Una fila por cada estado con al menos una unidad.

| Columna | Tipo | Restricciones | Descripción |
|---|---|---|---|
| id | BIGINT | PK, AUTO_INCREMENT | Identificador. |
| loan_item_id | BIGINT | NOT NULL, FK `fk_loan_item_returns_loan_item` → loan_items.id | Ítem devuelto. |
| item_condition | ENUM('BUENO','CON_DESPERFECTOS','DANADO','PERDIDO') | NOT NULL | Estado de las unidades (PA-6). `condition` es palabra reservada en MySQL; por eso el prefijo. |
| quantity | INT | NOT NULL, CHECK `chk_loan_item_returns_quantity` (quantity >= 1) | Unidades en ese estado. |
| notes | VARCHAR(500) | CHECK `chk_loan_item_returns_notes`: obligatoria y no vacía si el estado no es BUENO | Observación (RN-05c.3, RN-05d.1; supuesto S-5). |
| created_at, updated_at, deleted_at | DATETIME | ver convenciones | Solo inserción. |

UNIQUE `uk_loan_item_returns_item_condition (loan_item_id, item_condition)`. Que la suma de las filas de un ítem sea igual a `loan_items.quantity` (RN-05c.2) lo valida el servicio en la misma transacción que pasa el préstamo a DEVUELTO, porque un `CHECK` no puede sumar filas. DANADO y PERDIDO restan esas unidades de `equipment.total_units` en esa transacción (RN-05d.2).

**loan_status_history**: bitácora de solo inserción con cada transición de estado, su actor y su instante.

| Columna | Tipo | Restricciones | Descripción |
|---|---|---|---|
| id | BIGINT | PK, AUTO_INCREMENT | Identificador. |
| loan_id | BIGINT | NOT NULL, FK `fk_loan_status_history_loan` → loans.id | Préstamo. |
| from_status | ENUM(estados del préstamo) | NULL | Estado anterior; NULL solo en la fila de creación. |
| to_status | ENUM(estados del préstamo) | NOT NULL, CHECK `chk_loan_status_history_transition` | Estado nuevo. El `CHECK` solo admite las transiciones del diagrama de estados. |
| changed_by | BIGINT | NULL, FK `fk_loan_status_history_changed_by` → users.id | Actor; NULL = sistema (revisión de las 00:05, cierre de no recogidos). |
| changed_at | DATETIME | NOT NULL | Instante de negocio, tomado del mismo reloj que `approved_at`, `delivered_at`, etc. (`created_at` es el instante técnico de inserción). |
| created_at, updated_at, deleted_at | DATETIME | ver convenciones | Solo inserción. |

**sanctions**: bloqueo para solicitar generado por una devolución con retraso (SH-03).

| Columna | Tipo | Restricciones | Descripción |
|---|---|---|---|
| id | BIGINT | PK, AUTO_INCREMENT | Identificador. |
| loan_id | BIGINT | NOT NULL, UNIQUE `uk_sanctions_loan`, FK `fk_sanctions_loan` → loans.id | Préstamo devuelto con retraso; el estudiante sancionado es su titular. |
| days_late | INT | NOT NULL, CHECK `chk_sanctions_days_late` (days_late >= 1) | Días de retraso = fecha de devolución - fecha fin efectiva (RN-SH03.1). |
| starts_on | DATE | NOT NULL | Primer día bloqueado: el día siguiente a la devolución. |
| ends_on | DATE | NOT NULL, CHECK `chk_sanctions_range` | Último día bloqueado; `ends_on >= starts_on` y `DATEDIFF(ends_on, starts_on) + 1 = LEAST(days_late, 15)`. |
| created_at, updated_at | DATETIME | ver convenciones | Auditoría. |
| deleted_at | DATETIME | NULL | Anulación administrativa del bloqueo, si se requiere. |

Un estudiante está bloqueado hoy si tiene una sanción con `starts_on <= hoy <= ends_on`. La fecha en que puede volver a solicitar (RN-SH03.4) es `MAX(ends_on) + 1` de sus sanciones con `ends_on >= hoy`. Los bloqueos no se suman (RN-SH03.6). El bloqueo se levanta solo por fecha (RN-SH03.3), sin proceso programado. El bloqueo por préstamo VENCIDO sin devolver (RN-SH03.5) no se guarda: se consulta en `loans` y cuenta también un ENTREGADO atrasado (`effective_end_date < hoy`) aunque la revisión de las 00:05 aún no lo haya marcado VENCIDO (ver "Lecturas que no dependen de las tareas programadas"). Una devolución atrasada genera su sanción por fechas (RN-SH03.1) aunque el préstamo pase de ENTREGADO a DEVUELTO sin haber estado en VENCIDO.

**notifications**: alertas dentro de la aplicación, una fila por destinatario (HU-05e, RN-05a.11, SH-02, SH-06).

| Columna | Tipo | Restricciones | Descripción |
|---|---|---|---|
| id | BIGINT | PK, AUTO_INCREMENT | Identificador. |
| recipient_id | BIGINT | NOT NULL, FK `fk_notifications_recipient` → users.id | Destinatario: el titular (PROXIMO_A_VENCER, SIN_RESOLVER_A_TIEMPO, NO_RECOGIDO) o cada ENCARGADO y ADMIN (PRESTAMO_VENCIDO; NO_RECOGIDO a todos los ENCARGADO). |
| loan_id | BIGINT | NOT NULL, FK `fk_notifications_loan` → loans.id | Préstamo que origina la alerta. El equipo, las fechas, la cantidad, el motivo y los días de retraso se leen del préstamo; no se copian. |
| notification_type | ENUM('PRESTAMO_VENCIDO','PROXIMO_A_VENCER','NO_RECOGIDO','SIN_RESOLVER_A_TIEMPO') | NOT NULL | Tipo de alerta. |
| read_at | DATETIME | NULL | NULL = no leída. |
| closed_at | DATETIME | NULL | Cierre automático al devolver o al vencer (RN-SH02.5, RN-SH06.5); NULL = abierta. |
| created_at | DATETIME | NOT NULL | Instante en que se generó la alerta. |
| updated_at, deleted_at | DATETIME | ver convenciones | Auditoría. |

UNIQUE `uk_notifications_recipient_loan_type (recipient_id, loan_id, notification_type)`: cada evento ocurre a lo sumo una vez por préstamo, así que repetir la revisión diaria no duplica alertas (se inserta con `INSERT IGNORE` o `ON DUPLICATE KEY UPDATE`).

**Relaciones**

| Relación | Tipo | Llave foránea | Acciones |
|---|---|---|---|
| categories → equipment | 1:N obligatoria | `equipment.category_id` | ON DELETE RESTRICT, ON UPDATE RESTRICT |
| users → refresh_tokens | 1:N (historial de sesiones); a lo sumo una sin cerrar por usuario (UNIQUE `active_user_id`) | `refresh_tokens.user_id` | RESTRICT / RESTRICT |
| users → refresh_tokens (ADMIN que cierra) | 1:N opcional | `refresh_tokens.revoked_by` | RESTRICT / RESTRICT |
| users → users (ADMIN que da de baja) | 1:N opcional, autorrelación | `users.deactivated_by` | RESTRICT / RESTRICT |
| users → loans (titular) | 1:N obligatoria | `loans.student_id` | RESTRICT / RESTRICT |
| users → loans (aprueba, entrega, recibe, rechaza o cancela) | 4 relaciones 1:N opcionales (0..1 por préstamo) | `approved_by`, `delivered_by`, `returned_by`, `closed_by` | RESTRICT / RESTRICT |
| loans ↔ equipment | N:M, resuelta por `loan_items` | `loan_items.loan_id`, `loan_items.equipment_id` | RESTRICT / RESTRICT |
| loans → loan_items | 1:N (1..N; la solicitud se crea con al menos un ítem) | `loan_items.loan_id` | RESTRICT / RESTRICT |
| loan_items → loan_item_returns | 1:N (0..4, una por estado) | `loan_item_returns.loan_item_id` | RESTRICT / RESTRICT |
| loans → loan_status_history | 1:N (1..N; al menos la creación) | `loan_status_history.loan_id` | RESTRICT / RESTRICT |
| users → loan_status_history | 1:N opcional (NULL = sistema) | `loan_status_history.changed_by` | RESTRICT / RESTRICT |
| loans → sanctions | 1:0..1 (UNIQUE `loan_id`) | `sanctions.loan_id` | RESTRICT / RESTRICT |
| users → notifications | 1:N | `notifications.recipient_id` | RESTRICT / RESTRICT |
| loans → notifications | 1:N | `notifications.loan_id` | RESTRICT / RESTRICT |

**Índices**

Cada llave foránea tiene un índice cuya primera columna es la de la llave (InnoDB lo exige). Los compuestos ponen primero las columnas de igualdad (`status`, `student_id`, `equipment_id`) y al final la de rango u orden.

| Índice | Columnas | Consulta que acelera | Historias |
|---|---|---|---|
| `uk_users_email` | users (email) | Inicio de sesión por correo; correo ya registrado (el registro puede decir que el correo ya tiene cuenta, RN-01a.2). Los intentos y el bloqueo se leen y escriben en la misma fila por llave primaria, sin índice adicional. | HU-01a, HU-01b |
| `uk_refresh_tokens_token_hash` | refresh_tokens (token_hash) | Renovación y cierre de sesión: `token_hash = ? FOR UPDATE` (acceso `const`). | D-19 |
| `uk_refresh_tokens_previous_hash` | refresh_tokens (previous_token_hash) | Detección de reutilización: `previous_token_hash = ?` cuando el hash no está en `token_hash`. | D-19 |
| `uk_refresh_tokens_active_user` | refresh_tokens (active_user_id) | Una sola sesión sin cerrar por usuario; sesión abierta del usuario al iniciar sesión y al darlo de baja: `active_user_id = ?` (a lo sumo una fila). | D-19, D-20 |
| `idx_refresh_tokens_user_created` | refresh_tokens (user_id, created_at) | Índice de la FK; historial de sesiones de un usuario ordenado por inicio (`user_id = ? ORDER BY created_at DESC`). No incluye `expires_at`, así la rotación (cada 30 min) solo actualiza los dos únicos de hash. | D-19 |
| `idx_users_role_deleted_at` | users (role, deleted_at) | Destinatarios activos de "todos los ENCARGADO y ADMIN" al generar alertas (`role IN (...) AND deleted_at IS NULL`, cubriente porque el índice incluye `id`); ADMIN activos que se bloquean y cuentan para no dar de baja al último (`role = 'ADMIN' AND deleted_at IS NULL ORDER BY id FOR UPDATE`). Sustituye a `idx_users_role (role)`. | HU-05e, SH-02, D-24 |
| `idx_users_deactivated_by` | users (deactivated_by) | Índice de la FK; bajas hechas por un ADMIN. | D-24 |
| `idx_refresh_tokens_revoked_by` | refresh_tokens (revoked_by) | Índice de la FK; sesiones cerradas por un ADMIN. | D-22, D-24 |
| `uk_categories_name` | categories (name) | Lista de categorías ordenada; nombre único. | HU-02a, HU-03 |
| `uk_equipment_inventory_code` | equipment (inventory_code) | Código duplicado al crear o editar; búsqueda por código. | HU-02a |
| `idx_equipment_category_name` | equipment (category_id, name) | Filtro por categoría exacta ordenado por nombre y paginado; índice de la FK. | HU-03, SH-05 |
| `idx_equipment_name` | equipment (name) | Catálogo sin filtro ordenado por nombre, de 12 en 12. La búsqueda parcial `LIKE '%texto%'` no usa B-tree y recorre la tabla; es aceptable para un catálogo de cientos o pocos miles de equipos (ver riesgos). | HU-03 |
| `idx_loans_student_status_start` | loans (student_id, status, start_date) | "Mis solicitudes" con filtro de estado y de fecha de inicio; conteo de préstamos en curso con las condiciones de reloj (rango por `student_id` y cada estado; en SOLICITADO también `start_date >= hoy`; `pickup_deadline` de los APROBADO se lee de la fila); bloqueo por VENCIDO o ENTREGADO atrasado (`effective_end_date` se lee de la fila); préstamos del estudiante para buscar sus sanciones; índice de la FK. Por estudiante son pocas filas, así que no se añade `pickup_deadline` ni `effective_end_date` al índice. | HU-04, SH-01, SH-03 |
| `idx_loans_status_start` | loans (status, start_date) | Cola de solicitudes por resolver (`status = 'SOLICITADO' AND start_date >= hoy ORDER BY start_date`); cierre "Sin resolver a tiempo" (`status = 'SOLICITADO' AND start_date < hoy`); ranking, vencidos (`status IN ('VENCIDO','ENTREGADO')`, con `effective_end_date < hoy` para ENTREGADO) y ocupación por fecha de inicio; CSV filtrado por estado y fechas. | HU-05a, SH-04, SH-05 |
| `idx_loans_status_pickup` | loans (status, pickup_deadline) | Cierre de no recogidos: `status = 'APROBADO' AND pickup_deadline <= ahora`. Las lecturas no lo necesitan: la disponibilidad llega a `loans` por llave primaria desde `loan_items` y evalúa `pickup_deadline > ahora` en la fila. | HU-05e |
| `idx_loans_status_effective_end` | loans (status, effective_end_date) | Marcado de vencidos (`status = 'ENTREGADO' AND effective_end_date < hoy`) y alerta de próximo a vencer (`= mañana`). | SH-02, SH-06 |
| `idx_loans_approved_by`, `idx_loans_delivered_by`, `idx_loans_returned_by`, `idx_loans_closed_by` | loans (columna de actor) | Índices de FK; trazabilidad de lo que hizo cada encargado. | HU-05a a HU-05c |
| `uk_loan_items_loan_equipment` | loan_items (loan_id, equipment_id) | Ítems de un préstamo (detalle, devolución, CSV); un equipo por solicitud; índice de la FK `loan_id`. | HU-04, HU-05c, SH-05 |
| `idx_loan_items_equipment_loan` | loan_items (equipment_id, loan_id, quantity) | Disponibilidad: para cada equipo de la página se leen sus ítems solo desde el índice (cubriente) y se une con `loans` por llave primaria. También préstamos activos al dar de baja, unidades comprometidas y ranking. Índice de la FK `equipment_id`. | HU-02a, HU-02b, HU-03, HU-05a, SH-04 |
| `uk_loan_item_returns_item_condition` | loan_item_returns (loan_item_id, item_condition) | Detalle de la devolución por ítem; un registro por estado; índice de la FK. | HU-05c, HU-05d |
| `idx_loan_status_history_loan_changed` | loan_status_history (loan_id, changed_at) | Línea de tiempo de un préstamo en orden; índice de la FK. | HU-05a a SH-07 |
| `idx_loan_status_history_changed_by` | loan_status_history (changed_by) | Índice de la FK; acciones de un usuario. | Trazabilidad |
| `uk_sanctions_loan` | sanctions (loan_id) | Bloqueo vigente: préstamos del estudiante (por `idx_loans_student_status_start`) unidos con sus sanciones; impide sancionar dos veces la misma devolución. | SH-03 |
| `uk_notifications_recipient_loan_type` | notifications (recipient_id, loan_id, notification_type) | Idempotencia de la revisión diaria y del cierre de no recogidos; índice de la FK `recipient_id`. | HU-05e, SH-02, SH-06 |
| `idx_notifications_recipient_open` | notifications (recipient_id, closed_at, read_at, created_at) | Bandeja y contador de no leídas: `recipient_id = ? AND closed_at IS NULL AND read_at IS NULL ORDER BY created_at DESC` (MySQL resuelve `IS NULL` como igualdad dentro del índice). | HU-05e, SH-02, SH-06 |
| `idx_notifications_loan_type` | notifications (loan_id, notification_type) | Cierre automático de alertas al devolver o al vencer: `loan_id = ? AND notification_type IN (...) AND closed_at IS NULL`; índice de la FK `loan_id`. | SH-02, SH-06 |

**Atributos derivados: cuáles se guardan y cuáles se calculan**

| Atributo | Decisión | Motivo |
|---|---|---|
| Plazo de recogida (`pickup_deadline`) | Se guarda; lo calcula el servicio al aprobar. | Depende del calendario de servicio (8:00 AM a 5:00 PM, 2 horas, excepción de 1 día, PA-26), que no conviene replicar en SQL. Se fija una vez y no cambia. Lo usan el cierre de no recogidos (indexado), la ventana de entrega (`CHECK delivered_at < pickup_deadline`) y el rango de retención. Si la política cambia, los préstamos ya aprobados conservan su plazo. |
| Fecha fin efectiva (`effective_end_date`) | Columna generada `STORED`. | Depende solo de `end_date` y `delivered_at` de la misma fila. La mantiene el motor (sin anomalías de actualización) y se indexa para la revisión diaria. En JPA se mapea de solo lectura (`insertable = false, updatable = false`). |
| Rango efectivo de retención | Se calcula en la consulta. | APROBADO con `pickup_deadline > ahora`: de `start_date` a `GREATEST(end_date, DATE(pickup_deadline))`; con el plazo vencido ya no retiene, aunque el cierre aún no haya corrido (RN-05e.1, A-12). ENTREGADO o VENCIDO: su rango y, si `end_date` ya pasó, cada día desde hoy hasta la devolución. DEVUELTO (métricas): de `start_date` a `DATE(returned_at)`. Depende de "hoy", así que no puede guardarse. |
| Disponibilidad y unidades comprometidas | Se calculan. | Dependen del rango consultado y de hoy. Guardar contadores por día obligaría a mantenerlos en cada transición, con riesgo de desincronización. |
| Días de retraso de la alerta de vencido | Se calcula: hoy - `effective_end_date`. | Cambia cada día. |
| Bloqueo por retraso (`sanctions`) | Se guarda al registrar la devolución. | Es un hecho emitido con la política vigente (1 día por día de retraso, máximo 15). Su fin se consulta con índice y se levanta solo por fecha. |
| Bloqueo por VENCIDO sin devolver | Se calcula. | Existe un préstamo del estudiante en VENCIDO, o en ENTREGADO con `effective_end_date < hoy` (A-12). |
| Préstamos en curso (límite de 3) | Se calcula (`COUNT`). | Un contador guardado se desincronizaría con cada cierre automático. No cuenta una SOLICITADO con `start_date < hoy` ni un APROBADO con `pickup_deadline <= ahora` (A-12). |
| Vencimiento del refresh token (`expires_at`) y vida máxima de la sesión (`session_expires_at`) | Se guardan; los calcula el servicio al iniciar sesión y en cada rotación. | Dependen de parámetros (30 min; 1 h u 8 h según el rol) que pueden cambiar: se guardan como hecho emitido con la política vigente, igual que `pickup_deadline`. La renovación los compara por índice único sin recalcular. |
| Sesión abierta del usuario (`active_user_id`) | Columna generada `STORED`. | Depende solo de `user_id` y `revoked_at` de la misma fila; existe para poder declarar el único que sustituye al índice parcial. |
| Bloqueo del inicio de sesión (`failed_login_attempts`, `login_locked_until`, `last_failed_login_at`) | Se guarda en `users`. | Es estado actual de la cuenta, no derivable sin guardar cada intento. Se levanta solo por fecha. |
| Texto del motivo | Se calcula desde `closure_reason` y `closure_note`. | Los motivos del sistema tienen texto fijo; guardarlo en cada fila repetiría un dato que depende del código. |
| Duración en días | Se calcula (`DATEDIFF + 1`). | Su máximo se exige con `CHECK`. |

**Disponibilidad y concurrencia**

Unidades retenidas de un conjunto de equipos en el rango `[inicio, fin]` (con `inicio >= hoy`), según RN-03.2, PA-28 y la fórmula de `CLAUDE.md`. Se calcula en una sola consulta para toda la página, sin N+1 (`:now` es el instante del `Clock` y `:today = DATE(:now)`):

```sql
SELECT li.equipment_id, SUM(li.quantity) AS retained
FROM loan_items li
JOIN loans l ON l.id = li.loan_id
WHERE li.equipment_id IN (:equipmentIds)
  AND l.deleted_at IS NULL
  AND l.start_date <= :end
  AND (   (l.status = 'APROBADO'
           AND l.pickup_deadline > :now          -- A-12: con el plazo vencido ya no retiene
           AND GREATEST(l.end_date, DATE(l.pickup_deadline)) >= :start)
       OR (l.status IN ('ENTREGADO', 'VENCIDO')
           AND (l.end_date >= :start OR l.end_date < :today)) )
GROUP BY li.equipment_id;
-- disponibles = GREATEST(total_units - retained, 0)
```

Plan verificado con `EXPLAIN` en MySQL 8: `loan_items` por `idx_loan_items_equipment_loan` (solo índice) y `loans` por llave primaria (`eq_ref`). Para aprobar (RN-05a.3), `:end` es el fin del rango efectivo que tendría la solicitud si se aprobara ahora: `GREATEST(end_date, DATE(plazo calculado))`. La misma condición de APROBADO vigente se usa en las unidades comprometidas (RN-02a.6), en los préstamos activos que impiden la baja de un equipo (RN-02b.2) y en la ocupación (RN-SH04.4).

**Lecturas que no dependen de las tareas programadas (A-12)**

Las tareas (`PickupExpirationJob` cada minuto, `DailyLoanReviewJob` a las 00:05) escriben el estado final, pero pueden retrasarse (contenedor suspendido, riesgo R-1 del ADR). Las lecturas que deciden una regla no esperan a que corran: aplican la misma condición con el reloj. El estado guardado no cambia hasta que la tarea o una acción lo escribe.

| Estado guardado | Condición de reloj | Se trata como | Efecto en las lecturas |
|---|---|---|---|
| SOLICITADO | `start_date < :today` | RECHAZADO "Sin resolver a tiempo" | No cuenta en el límite de 3, no aparece en la cola por resolver, no se aprueba ni se rechaza a mano ni se cancela (`chk_loans_timeline`, `chk_loans_closure_timing`). |
| APROBADO | `pickup_deadline <= :now` | RECHAZADO "No recogido" | No retiene unidades, no cuenta en el límite ni en la ocupación, no impide la baja del equipo, no se entrega (`chk_loans_timeline`) ni se cancela (`chk_loans_closure_timing`). |
| ENTREGADO | `effective_end_date < :today` | VENCIDO | Bloquea nuevas solicitudes (RN-SH03.5) y cuenta como vencido en las métricas (RN-SH04.3). Retiene unidades igual que antes. |

Conteo de préstamos en curso (RN-04.8), una sola consulta por `idx_loans_student_status_start`:

```sql
SELECT COUNT(*) FROM loans l
WHERE l.student_id = :studentId
  AND l.deleted_at IS NULL
  AND (   (l.status = 'SOLICITADO' AND l.start_date >= :today)
       OR (l.status = 'APROBADO'   AND l.pickup_deadline > :now)
       OR  l.status IN ('ENTREGADO', 'VENCIDO'));
```

Bloqueo por préstamo vencido sin devolver (RN-SH03.5), por el mismo índice:

```sql
SELECT EXISTS (
  SELECT 1 FROM loans l
  WHERE l.student_id = :studentId
    AND l.deleted_at IS NULL
    AND (l.status = 'VENCIDO' OR (l.status = 'ENTREGADO' AND l.effective_end_date < :today)));
```

Las dos se ejecutan dentro de la transacción que crea la solicitud, después de bloquear la fila del estudiante (punto 5), y alimentan también `GET /api/loans/mine/eligibility`. Las métricas cuentan como vencidos `status = 'VENCIDO' OR (status = 'ENTREGADO' AND effective_end_date < :today)`. Las pantallas que muestran el estado de un préstamo muestran el guardado (supuesto S-12).

Cómo se garantiza a nivel de datos que lo retenido nunca supere `total_units`:

1. **Un solo punto crea retención: la aprobación** (RN-04.5, RN-05a.3). Una solicitud SOLICITADO no retiene, así que dos solicitudes pueden competir por la misma unidad; la competencia se resuelve al aprobar.
2. **Serialización por equipo.** La aprobación ocurre en una transacción que (a) bloquea la fila del préstamo con `SELECT ... FOR UPDATE` y verifica que siga SOLICITADO; (b) bloquea las filas de sus equipos con `SELECT ... FROM equipment WHERE id IN (...) ORDER BY id FOR UPDATE`; (c) calcula lo retenido con la consulta anterior; (d) actualiza `loans` e inserta en `loan_status_history`; (e) confirma. Un segundo encargado que aprueba otra solicitud del mismo equipo espera en (b) y, al continuar, ya ve la primera aprobación confirmada.
3. **Las demás operaciones que pueden reducir el margen bloquean la misma fila del equipo:** edición de `total_units` (RN-02a.6), devolución con DAÑADO o PERDIDO (RN-05d.2), entrega (RN-05b.6) y baja (RN-02b.2).
4. **Las transiciones que no aumentan la retención** (rechazo, cancelación, no recogido, sin resolver, vencido, devolución en buen estado) no bloquean equipos, pero sí el préstamo: `UPDATE loans SET ... WHERE id = ? AND status = <esperado>`. Si actualiza 0 filas, otro proceso ganó. A esto se suma `@Version`. Así se resuelven carreras como una entrega a las 9:59:59 contra el cierre de las 10:00, o una cancelación contra una entrega.
5. **Crear una solicitud** no retiene, pero bloquea la fila del estudiante (`SELECT ... FROM users WHERE id = ? FOR UPDATE`) para que dos envíos simultáneos no superen el límite de 3 (RN-04.8) ni esquiven un bloqueo (SH-03). Además lee los equipos con `FOR SHARE` para no cruzarse con una baja simultánea (RN-02b.4).
6. **Orden fijo de bloqueo** users → loans → equipment (por `id` ascendente) para evitar interbloqueos, y transacciones cortas, sin llamadas externas dentro. `refresh_tokens` va después de `users` y no se mezcla con préstamos: el inicio de sesión bloquea `users` y luego `refresh_tokens`; la baja de una cuenta sigue users → loans (solo lectura de sus préstamos en curso) → refresh_tokens; la renovación bloquea solo su fila de `refresh_tokens` y lee `users` sin bloquear.
7. **Aislamiento.** En REPEATABLE READ (por defecto en InnoDB), una lectura no bloqueante usa la instantánea tomada en la primera lectura consistente de la transacción. Si esa lectura ocurre antes de obtener el bloqueo del equipo, la suma no vería una aprobación confirmada mientras se esperaba. Por eso estas transacciones usan READ COMMITTED (o la suma es la primera lectura consistente después de los `FOR UPDATE`).
8. **Por qué no solo con el motor:** la invariante abarca varias filas y un rango de fechas. Un `CHECK` no puede consultar otras tablas, y un trigger duplicaría en SQL la lógica del calendario de servicio. Los `CHECK` protegen lo que es de una sola fila y la serialización por equipo protege la invariante entre filas.
9. **Excepción permitida por el negocio:** una devolución DAÑADO o PERDIDO puede dejar `total_units` por debajo de lo ya aprobado (RN-05d.4, PA-20). La disponibilidad se muestra con mínimo 0 y la entrega se bloquea con "Unidades insuficientes" (RN-05b.6).
10. **El instante se toma después de los bloqueos.** Como un APROBADO deja de retener al vencer su plazo sin que nada lo escriba (A-12), la aprobación, la entrega, la baja y la edición de unidades leen `:now` del `Clock` después de obtener el bloqueo de los equipos. Así, si una aprobación usa las unidades de un APROBADO vencido, una entrega de ese préstamo que esperaba el mismo bloqueo obtiene un `:now` posterior al plazo y falla por `chk_loans_timeline` (`delivered_at < pickup_deadline`) en lugar de entregar unidades ya asignadas. Si la entrega gana el bloqueo, la aprobación lo ve ENTREGADO y cuenta sus unidades.

**Normalización**

- **1FN:** todos los valores son atómicos y no hay grupos repetidos. Los equipos de una solicitud son filas de `loan_items` (no columnas `equipo1`, `equipo2`), y las cantidades por estado de devolución son filas de `loan_item_returns` (no una columna por estado). Toda tabla tiene llave primaria.
- **2FN:** las llaves primarias son simples (`id`), así que no puede haber dependencias parciales de la llave primaria. En las llaves candidatas compuestas, los atributos no clave dependen de la llave completa: `quantity` de `(loan_id, equipment_id)`; `quantity` y `notes` de `(loan_item_id, item_condition)`; `read_at` y `closed_at` de `(recipient_id, loan_id, notification_type)`. En `refresh_tokens`, `token_hash` es llave candidata simple, y `previous_token_hash` y `active_user_id` son únicos que admiten NULL.
- **3FN:** no hay dependencias transitivas. El nombre de la categoría vive en `categories`, no en `equipment`. El correo del estudiante para el CSV se lee de `users`. El texto de los motivos del sistema se deriva de `closure_reason`. El contenido de las alertas se arma desde el préstamo. `effective_end_date` la genera el motor a partir de la misma fila. `refresh_tokens` no copia el rol ni el estado de la cuenta: la renovación los lee de `users`; `session_expires_at` depende del rol que había al iniciar sesión y de la política de ese momento, no del rol actual, así que no es una dependencia transitiva sino un hecho de la sesión. `active_user_id` la genera el motor con `user_id` y `revoked_at` de la misma fila. `failed_login_attempts`, `login_locked_until`, `last_failed_login_at` y `deactivated_by` dependen solo de la cuenta (`users.id`); una tabla aparte con relación 1:1 no aportaría nada a la normalización. `revoked_by` depende solo de la sesión.
- **Desnormalizaciones deliberadas:**
  1. **Hitos en `loans` y en `loan_status_history`.** `approved_at/by`, `delivered_at/by`, `returned_at/by` y `closed_at/by` ocurren a lo sumo una vez por préstamo, así que dependen solo de su llave (no violan la 3FN de `loans`), pero repiten datos del historial. Se guardan porque la operación, el CSV (fecha de entrega y de devolución) y los `CHECK` de coherencia los necesitan sin pivotar el historial. Ambos se escriben en la misma transacción; la fuente operativa es `loans` y el historial es la bitácora.
  2. **`pickup_deadline`**, derivable de la aprobación, las fechas y el calendario de servicio. Se guarda porque su cálculo es de negocio y porque se indexa.
  3. **`sanctions` (`days_late`, `starts_on`, `ends_on`)**, derivables del préstamo al devolver. Se materializan como un hecho emitido con la política vigente.
  4. **`notifications` con una fila por destinatario** en lugar de una por evento: es lo que permite el estado leído o no leído de cada usuario.
  5. **`refresh_tokens.expires_at` y `session_expires_at`**, derivables del inicio de sesión, la última rotación, el rol y los parámetros. Se guardan como hecho emitido con la política vigente (igual que `pickup_deadline`), para que cambiar un parámetro no altere las sesiones abiertas.
  6. **`previous_token_hash`** guarda solo el token inmediatamente anterior, no la cadena completa de rotaciones (una fila por sesión, ADR D-19): un token más antiguo no existe en la tabla y se rechaza sin detectarse como reutilización.

**Supuestos de diseño**

- **S-1 Zona horaria única.** Todos los `DATETIME` se guardan en hora local de la institución (por ejemplo, `America/Bogota`, UTC-5 sin horario de verano), porque el horario de servicio, la fecha fin efectiva y el día de devolución se razonan en hora local. La conexión fija la zona de la sesión (Aiven usa UTC por defecto). Con varias sedes en distintas zonas habría que pasar a UTC más una zona por sede.
- **S-2 Nombre completo.** HU-01a solo menciona correo y contraseña. Se asume que el registro también pide el nombre, que se muestra en alertas ("estudiante") y en "aprobado por". Si no se pide, `full_name` pasa a NULL.
- **S-3 Categorías.** Ninguna historia cubre su gestión: se cargan con `R__seed_categories.sql` y el encargado elige de la lista. El "área" (laboratorio, audiovisual, biblioteca) no se modela porque PA-16 descarta filtrar por área.
- **S-4 Cuentas iniciales.** ENCARGADO y ADMIN se cargan con datos semilla (`R__seed_*.sql` o perfil `dev`), con al menos un ADMIN (RN-01a.4).
- **S-5 Observación de la devolución.** Es obligatoria por cada línea (equipo + estado) CON_DESPERFECTOS, DANADO o PERDIDO. Las historias no precisan si es una por préstamo, por equipo o por estado; la opción más fina admite cualquiera de las otras en la interfaz. Longitud máxima de 500 caracteres (no definida en las historias).
- **S-6 Vida de las alertas.** PRESTAMO_VENCIDO y PROXIMO_A_VENCER se cierran solas (`closed_at`) según RN-SH02.5 y RN-SH06.5. NO_RECOGIDO y SIN_RESOLVER_A_TIEMPO son informativas: quedan en la bandeja hasta que el usuario las marca como leídas (`read_at`). Las alertas por destinatario se generan para los ENCARGADO y ADMIN que existen en ese momento; uno creado después no las recibe, pero ve los préstamos VENCIDO en su listado.
- **S-7 Baja con solicitudes pendientes (RN-02b.3).** El rechazo automático queda con `closure_reason = 'EQUIPO_DADO_DE_BAJA'` y `closed_by` = el encargado que hizo la baja. No se genera alerta al estudiante (ninguna regla la pide); lo ve en sus solicitudes. Una SOLICITADO del equipo con el inicio ya pasado no se rechaza por la baja sino como "Sin resolver a tiempo" (`closed_by` NULL), porque ese es el cierre que ya le corresponde (`chk_loans_closure_timing`); un APROBADO con el plazo vencido no impide la baja y lo cierra la tarea como "No recogido".
- **S-8 Aviso de HU-05d** (préstamos APROBADO afectados). No se guarda: es una respuesta calculada en el momento de la devolución (RN-05d.4).
- **S-9 Préstamos sin borrado.** `loans`, `loan_items`, `loan_item_returns` y `loan_status_history` tienen `deleted_at` por convención, pero ningún flujo los borra: los préstamos se cierran por estado.
- **S-10 Devolución única y completa.** No hay devoluciones parciales (la suma por estado debe igualar lo prestado, RN-05c.2), así que hay una sola devolución por préstamo y a lo sumo una sanción.
- **S-11 Hora de la devolución.** El retraso usa `DATE(returned_at)` como "fecha de devolución" (RN-SH03.1). Las historias no limitan la devolución al horario de servicio, así que el modelo no lo restringe.
- **S-12 Estado guardado y estado efectivo (A-12).** Las reglas (disponibilidad, límite de 3, RN-SH03.5, baja de equipos, baja de cuentas, métricas) usan las condiciones de reloj de "Lecturas que no dependen de las tareas programadas". Las pantallas y el CSV muestran el estado guardado, que puede ir atrasado mientras la tarea no corre (normalmente menos de un minuto para "No recogido" y de 00:00 a 00:05 para "Sin resolver a tiempo" y VENCIDO). Las acciones sobre un préstamo que ya está cerrado por reloj (aprobar, rechazar a mano, cancelar o entregar) se rechazan como una transición no válida (el mensaje lo define la API); el cierre lo escribe la tarea con su motivo.
- **S-13 Duraciones de la sesión.** Access token 15 min, refresh token 30 min deslizantes, vida máxima de la sesión 1 h para ESTUDIANTE y 8 h para ENCARGADO y ADMIN. Son parámetros por rol; el esquema no tiene ninguna constante de tiempo. No hay cambio de roles, así que el rol con el que se fija `session_expires_at` es el de toda la sesión.
- **S-14 Una sola sesión por usuario.** Si existe una sesión vigente, el nuevo inicio de sesión no la reemplaza en silencio: el usuario confirma cerrarla (motivo REPLACED) o cancela. La API responde 409 `ACTIVE_SESSION_EXISTS` solo con credenciales correctas y el usuario repite el inicio de sesión con `replaceExistingSession` (ADR 2.6.4); ese 409 reinicia el contador de fallos. La sesión reemplazada no puede renovar, y su petición siguiente, aunque sea una consulta, recibe 401 de inmediato (comprobación por llave primaria de `refresh_tokens` y `users` en toda petición autenticada, sin caché; ver "Corte de acceso (D-20)"). Una sesión vencida y sin cerrar se cierra sin preguntar (EXPIRED).
- **S-15 Bloqueo por intentos fallidos de una cuenta.** 3 fallos consecutivos de contraseña sobre una cuenta activa bloquean su inicio de sesión 15 min (parámetros). "Consecutivos" no tiene ventana de tiempo: el contador vuelve a 0 con un acierto y empieza de nuevo con el primer fallo después del bloqueo. Durante el bloqueo no se cuentan intentos, no se alarga y la contraseña correcta tampoco entra. El bloqueo no cierra la sesión abierta. La respuesta no revela nada: correo inexistente, cuenta dada de baja, contraseña incorrecta y cuenta bloqueada reciben el mismo 401 "Credenciales inválidas" con el mismo tiempo de respuesta (RN-01b.2, D-25); el motivo real solo va al log. El modelo no tiene ninguna columna ni regla que obligue a distinguir esos casos ante quien inicia sesión.
- **S-16 Crecimiento de `refresh_tokens` en Aiven (1 GB).** Sin borrado físico (no hay excepción de purga), cada inicio de sesión deja unos 0,4 KB con los hash en `BINARY(32)` (medido). Con sesiones de 1 h para estudiantes, 2.000 inicios de sesión diarios son alrededor de 0,8 MB por día, unos 290 MB al año. Se debe vigilar el tamaño de la base (alerta al 70 % del plan) y revisar el volumen real de inicios de sesión tras la primera entrega en producción.
- **S-17 Límite por origen de conexión.** Además del bloqueo por cuenta, cada IP admite como máximo 10 inicios de sesión fallidos cada 15 min (cubeta de fichas, ADR 2.6.5; parámetros). Cuenta los fallos con cualquier correo, también inexistentes, que es lo que frena probar muchas cuentas. Se guarda **solo en memoria de cada instancia** (caché Caffeine acotada en tamaño, con expiración a los 15 min), sin tabla: una tabla por IP crecería con cada IP distinta (un atacante puede rotarlas) sin poder borrarse, y añadiría una escritura por intento en el plan de 1 GB. Consecuencias aceptadas: con varias instancias (supuesto A-11 del ADR) el límite efectivo es 10 por instancia, y se reinicia si la instancia se suspende; el bloqueo por cuenta, que sí está en la base, es la garantía compartida. La IP se toma de la cabecera que fija Vercel, no de una enviada por el cliente. Al superarse responde 429 `TOO_MANY_ATTEMPTS` antes de buscar la cuenta, igual para cualquier correo, así que no revela nada de la cuenta (ADR 2.6.5); el mismo límite se aplica al registro. Riesgo: los equipos de un laboratorio pueden compartir IP pública (NAT), así que los fallos de varios estudiantes suman en el mismo contador; el límite es un parámetro para poder ajustarlo.
- **S-18 Baja de cuentas con préstamos.** La baja se rechaza si el titular tiene cualquier préstamo en curso (SOLICITADO, APROBADO, ENTREGADO o VENCIDO), evaluado con las condiciones de reloj de A-12; primero hay que resolverlos (aprobar o rechazar, cancelar, entregar y devolver). Por eso la baja no cierra préstamos y `loans.closure_reason` no tiene un motivo de baja de cuenta. Una SOLICITADO con el inicio pasado o un APROBADO con el plazo vencido, que ya no cuentan como en curso, no impiden la baja: la tarea programada los cierra después ("Sin resolver a tiempo" o "No recogido") y la alerta al titular queda en la bandeja de una cuenta dada de baja, sin efecto. Las sanciones, el historial y las referencias a la cuenta se conservan.
- **S-19 Registro con correo existente.** El registro puede informar que el correo ya tiene una cuenta (RN-01a.2, decisión del usuario), también si la cuenta está dada de baja, porque `uk_users_email` incluye las bajas y no hay reactivación. El modelo no necesita nada más: el único ya lo resuelve y el inicio de sesión no usa esa información.

---

## 4. Especificación de la API

Documentación completa en `/api/docs` (springdoc). Contrato versionado en [`docs/api/openapi.yaml`](docs/api/openapi.yaml), generado desde el código y verificado por `OpenApiContractIT`; aquí se muestra un extracto con tres endpoints principales:

```yaml
openapi: 3.0.1
info:
  title: PrestaLab API
  version: 1.1.0
servers:
  - url: https://<proyecto>.vercel.app
security:
  - bearerAuth: []
paths:
  /api/equipment:
    get:
      summary: Busca equipos y calcula su disponibilidad para un rango de fechas
      description: Disponible para ESTUDIANTE, ENCARGADO y ADMIN. Los equipos dados de baja no aparecen.
      tags: [Catálogo]
      parameters:
        - { name: q, in: query, schema: { type: string, maxLength: 120 }, description: Texto en el nombre }
        - { name: categoryId, in: query, schema: { type: integer, format: int64 } }
        - { name: from, in: query, required: true, schema: { type: string, format: date } }
        - { name: to, in: query, required: true, schema: { type: string, format: date }, description: Rango de máximo 7 días contando ambos extremos (fin hasta 6 días después del inicio) }
        - { name: page, in: query, schema: { type: integer, minimum: 0, default: 0 } }
        - { name: size, in: query, schema: { type: integer, minimum: 1, maximum: 50, default: 12 } }
      responses:
        '200':
          description: Página de equipos con unidades disponibles
          content:
            application/json:
              schema: { $ref: '#/components/schemas/EquipmentAvailabilityPage' }
        '400': { $ref: '#/components/responses/Problem' }
        '401': { $ref: '#/components/responses/Problem' }
        '500': { $ref: '#/components/responses/Problem' }
  /api/loans:
    post:
      summary: Crea una solicitud de préstamo (rol ESTUDIANTE)
      tags: [Préstamos]
      requestBody:
        required: true
        content:
          application/json:
            schema: { $ref: '#/components/schemas/LoanRequest' }
      responses:
        '201':
          description: Préstamo creado en estado SOLICITADO
          headers:
            Location: { schema: { type: string, example: /api/loans/154 } }
          content:
            application/json:
              schema: { $ref: '#/components/schemas/LoanResponse' }
        '400': { $ref: '#/components/responses/Problem' }
        '401': { $ref: '#/components/responses/Problem' }
        '403': { $ref: '#/components/responses/Problem' }
        '409':
          description: INSUFFICIENT_UNITS, EQUIPMENT_UNAVAILABLE, LOAN_LIMIT_REACHED, STUDENT_BLOCKED, OVERDUE_LOAN_PENDING o CONCURRENT_MODIFICATION
          content:
            application/problem+json:
              schema: { $ref: '#/components/schemas/ProblemDetail' }
        '500': { $ref: '#/components/responses/Problem' }
  /api/loans/{id}/approval:
    post:
      summary: Aprueba una solicitud (rol ENCARGADO o ADMIN)
      description: >-
        Solo SOLICITADO, de 8:00 AM a 5:00 PM. Las demás acciones del préstamo son
        POST /api/loans/{id}/rejection, /delivery, /return y /cancellation
        (ver docs/api/openapi.yaml); no existe PATCH /status.
      tags: [Préstamos]
      parameters:
        - { name: id, in: path, required: true, schema: { type: integer, format: int64 } }
      responses:
        '200':
          description: Préstamo aprobado, con pickupDeadline
          content:
            application/json:
              schema: { $ref: '#/components/schemas/LoanResponse' }
        '401': { $ref: '#/components/responses/Problem' }
        '403': { $ref: '#/components/responses/Problem' }
        '404': { $ref: '#/components/responses/Problem' }
        '409':
          description: LOAN_NOT_PENDING, LOAN_ALREADY_ENDED, LOAN_ALREADY_STARTED, OUTSIDE_APPROVAL_HOURS, INSUFFICIENT_UNITS, EQUIPMENT_UNAVAILABLE o CONCURRENT_MODIFICATION
          content:
            application/problem+json:
              schema: { $ref: '#/components/schemas/ProblemDetail' }
        '500': { $ref: '#/components/responses/Problem' }
components:
  securitySchemes:
    bearerAuth: { type: http, scheme: bearer, bearerFormat: JWT }
    refreshCookie: { type: apiKey, in: cookie, name: prestalab_rt }
  responses:
    Problem:
      description: Error en formato RFC 7807 con code y requestId
      content:
        application/problem+json:
          schema: { $ref: '#/components/schemas/ProblemDetail' }
  schemas:
    PageResponse:
      type: object
      properties:
        content: { type: array, items: {} }
        page: { type: integer }
        size: { type: integer }
        totalElements: { type: integer, format: int64 }
        totalPages: { type: integer }
    EquipmentAvailabilityResponse:
      type: object
      properties:
        id: { type: integer, format: int64 }
        inventoryCode: { type: string }
        name: { type: string }
        categoryName: { type: string }
        status: { type: string, enum: [DISPONIBLE, MANTENIMIENTO] }
        availableUnits: { type: integer, minimum: 0 }
    EquipmentAvailabilityPage:
      allOf:
        - $ref: '#/components/schemas/PageResponse'
        - type: object
          properties:
            content: { type: array, items: { $ref: '#/components/schemas/EquipmentAvailabilityResponse' } }
    LoanItemRequest:
      type: object
      required: [equipmentId, quantity]
      properties:
        equipmentId: { type: integer, format: int64 }
        quantity: { type: integer, minimum: 1 }
    LoanRequest:
      type: object
      required: [startDate, endDate, items]
      properties:
        startDate: { type: string, format: date }
        endDate: { type: string, format: date, description: Rango de máximo 7 días contando ambos extremos (fin hasta 6 días después del inicio) }
        items: { type: array, minItems: 1, items: { $ref: '#/components/schemas/LoanItemRequest' } }
    LoanRejectionRequest:
      type: object
      required: [reason]
      properties:
        reason: { type: string, minLength: 10, maxLength: 250 }
    LoanCancellationRequest:
      type: object
      properties:
        reason: { type: string, maxLength: 250, description: Opcional; sin motivo queda "Cancelado por usuario" }
    LoanReturnRequest:
      type: object
      required: [items]
      properties:
        items:
          type: array
          items:
            type: object
            properties:
              equipmentId: { type: integer, format: int64 }
              lines:
                type: array
                items:
                  type: object
                  required: [condition, quantity]
                  properties:
                    condition: { type: string, enum: [BUENO, CON_DESPERFECTOS, DANADO, PERDIDO] }
                    quantity: { type: integer, minimum: 1 }
                    notes: { type: string, maxLength: 500, description: Obligatoria si la condición no es BUENO }
    LoanResponse:
      type: object
      properties:
        id: { type: integer, format: int64 }
        status: { type: string, enum: [SOLICITADO, APROBADO, RECHAZADO, CANCELADO, ENTREGADO, VENCIDO, DEVUELTO] }
        startDate: { type: string, format: date }
        endDate: { type: string, format: date }
        requester: { type: string }
        items:
          type: array
          items:
            type: object
            properties:
              equipmentId: { type: integer, format: int64 }
              name: { type: string }
              quantity: { type: integer }
        pickupDeadline: { type: string, format: date-time, nullable: true }
        createdAt: { type: string, format: date-time, description: Con el desplazamiento de la zona de la institución (America/Bogota) }
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
    ProblemDetail:
      type: object
      properties:
        type: { type: string }
        title: { type: string }
        status: { type: integer }
        detail: { type: string }
        instance: { type: string }
        code: { type: string, description: Código estable que usa el frontend }
        requestId: { type: string, description: Valor de X-Request-Id }
        timestamp: { type: string, format: date-time }
        errors: { type: array, items: { type: object, properties: { field: { type: string }, message: { type: string } } } }
        items: { type: array, items: { type: object, properties: { equipmentId: { type: integer, format: int64 }, name: { type: string }, requested: { type: integer }, available: { type: integer } } } }
        blockedUntil: { type: string, format: date }
        activeSession: { type: object, properties: { startedAt: { type: string, format: date-time }, lastActivityAt: { type: string, format: date-time } } }
        loans: { type: array, items: { type: object, properties: { loanId: { type: integer, format: int64 }, status: { type: string }, startDate: { type: string, format: date }, endDate: { type: string, format: date } } } }
```

El resto de la API está en `docs/api/openapi.yaml`:

| Grupo | Endpoints |
|---|---|
| Autenticación | `POST /api/auth/register`, `POST /api/auth/login` (con `replaceExistingSession`; respuesta `AuthResponse` y cookie `prestalab_rt`), `POST /api/auth/refresh`, `POST /api/auth/logout`, `GET /api/auth/me` |
| Cuentas (ADMIN) | `GET /api/users` (filtros `q`, `role` y `status`; incluye cuentas dadas de baja, con `status` y `deactivatedAt`), `GET /api/users/by-email?email=` (404 `USER_NOT_FOUND`), `DELETE /api/users/{id}` (200 idempotente si ya está dada de baja; 409 `LAST_ADMIN`, `CANNOT_DEACTIVATE_SELF` o `USER_HAS_LOANS_IN_PROGRESS` "La cuenta tiene préstamos en curso"), `DELETE /api/users/{id}/session` (204; 409 `NO_ACTIVE_SESSION` "La cuenta no tiene sesión activa") |
| Catálogo | `GET /api/categories`, `GET /api/equipment/inventory`, `GET /api/equipment/{id}`, `POST /api/equipment`, `PUT /api/equipment/{id}`, `DELETE /api/equipment/{id}` |
| Préstamos | `GET /api/loans`, `GET /api/loans/mine`, `GET /api/loans/mine/eligibility`, `GET /api/loans/{id}`, acciones `POST /api/loans/{id}/rejection`, `/delivery`, `/return` y `/cancellation` |
| Alertas | `GET /api/notifications`, `GET /api/notifications/unread-count`, `POST /api/notifications/{id}/read` |
| Reportes | `GET /api/reports/metrics`, `GET /api/reports/inventory.csv`, `GET /api/reports/loans.csv` |
| Tareas internas | `GET /api/internal/jobs/{job}` con `CRON_SECRET` (401 `INVALID_CRON_SECRET` "No autorizado") |

Códigos de error de autenticación y sesión: `INVALID_CREDENTIALS` ("Credenciales inválidas", el único mensaje de fallo del inicio de sesión), `SESSION_EXPIRED` ("Tu sesión expiró. Inicia sesión de nuevo"), `SESSION_REPLACED` ("Tu sesión fue cerrada porque iniciaste sesión en otro lugar"), `SESSION_INVALIDATED` ("Tu sesión ya no es válida. Inicia sesión de nuevo"; cuenta dada de baja o sesión cerrada por un ADMIN), `ACTIVE_SESSION_EXISTS` ("Ya tienes una sesión activa en otro lugar"), `TOO_MANY_ATTEMPTS` ("Demasiados intentos. Inténtalo de nuevo más tarde", 429) y `EMAIL_ALREADY_REGISTERED` ("Ya existe una cuenta asociada a ese correo", solo en el registro). Otros códigos de cuentas y alertas: `NOTIFICATION_NOT_FOUND` (404, también para una alerta ajena), `USER_NOT_FOUND`, `NO_ACTIVE_SESSION`, `CANNOT_DEACTIVATE_SELF` y `LAST_ADMIN`.

**Ejemplo: crear una solicitud**

```http
POST /api/loans
Authorization: Bearer eyJhbGciOiJIUzI1NiJ9...
Content-Type: application/json

{
  "startDate": "2026-11-10",
  "endDate": "2026-11-12",
  "items": [ { "equipmentId": 7, "quantity": 1 }, { "equipmentId": 12, "quantity": 2 } ]
}
```

Respuesta `201 Created`:

```json
{
  "id": 154,
  "status": "SOLICITADO",
  "startDate": "2026-11-10",
  "endDate": "2026-11-12",
  "requester": "Laura Gómez",
  "items": [
    { "equipmentId": 7, "name": "Cámara Canon EOS R10", "quantity": 1 },
    { "equipmentId": 12, "name": "Trípode Manfrotto", "quantity": 2 }
  ],
  "createdAt": "2026-11-03T14:22:05-05:00"
}
```

Respuesta `409 Conflict` (sin stock):

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

### Diagramas de secuencia

**Inicio de sesión (HU-01)**

```mermaid
---
title: Inicio de sesión POST /api/auth/login (diseño)
---
sequenceDiagram
    autonumber
    actor U as Usuario
    participant FE as Angular (LoginComponent / AuthService)
    participant T as RequestTraceFilter
    participant C as AuthController
    participant L as LoginRateLimiter
    participant S as AuthService
    participant A as LoginAttemptService
    participant RT as RefreshTokenService
    participant DB as MySQL (users, refresh_tokens)
    U->>FE: Ingresa correo y contraseña
    FE->>T: POST /api/auth/login {email, password, replaceExistingSession}
    T->>C: continúa con requestId en MDC
    alt campos vacíos o demasiado largos
        C-->>FE: 400 VALIDATION_ERROR con X-Request-Id
    else solicitud válida
        C->>L: comprueba intentos fallidos de la IP
        alt origen bloqueado: 10 fallos, hasta 15 min desde el primer fallo de la serie
            C-->>FE: 429 TOO_MANY_ATTEMPTS "Demasiados intentos. Inténtalo de nuevo más tarde" con Retry-After, sin mirar correo ni contraseña
        else IP dentro del límite
            C->>S: authenticate(request)
            S->>DB: busca por email en minúsculas con deleted_at IS NULL
            S->>S: BCrypt.matches, con hash ficticio si no hay cuenta, y también si está bloqueada
            alt contraseña incorrecta, correo inexistente, cuenta dada de baja o bloqueada
                S->>A: registra el fallo (REQUIRES_NEW, solo si la cuenta existe)
                A->>DB: failed_login_attempts, login_locked_until
                S->>S: espera hasta el piso de tiempo de 0,5 s y registra el motivo solo en el log
                S-->>C: InvalidCredentialsException
                C-->>FE: 401 INVALID_CREDENTIALS "Credenciales inválidas"
                FE-->>U: Muestra siempre "Credenciales inválidas"
            else credenciales correctas
                S->>DB: bloquea users FOR UPDATE, reinicia el contador
                S->>RT: abrir sesión
                RT->>DB: busca sesión no revocada del usuario
                alt sesión vigente y replaceExistingSession es false
                    RT-->>C: ActiveSessionExistsException
                    C-->>FE: 409 ACTIVE_SESSION_EXISTS con activeSession
                    FE-->>U: Aviso "Ya tienes una sesión activa en otro lugar": cerrar la otra o cancelar (ver secuencia-sesion-unica)
                else sin sesión, vencida o con reemplazo confirmado
                    RT->>DB: revoca la anterior (EXPIRED o REPLACED) e inserta la sesión con solo el hash
                    RT->>RT: JwtEncoder emite access token (sub, role, sid, exp 15 min)
                    RT-->>C: AuthResponse y cookie
                    C-->>FE: 200 {accessToken, tokenType, expiresAt, sessionExpiresAt, user} y Set-Cookie prestalab_rt
                    FE->>FE: Guarda el access token solo en memoria, activa la rotación por actividad y el aviso de fin de sesión
                    FE-->>U: Redirige al inicio de su rol
                end
            end
        end
    end
    T-->>FE: cabecera X-Request-Id en toda respuesta
```

> Fuente: [`docs/diagrams/secuencia-login.mmd`](docs/diagrams/secuencia-login.mmd) · Imagen: [`docs/diagrams/secuencia-login.png`](docs/diagrams/secuencia-login.png).

**Renovación y cierre de sesión**

```mermaid
---
title: Renovación y cierre de sesión (diseño)
---
sequenceDiagram
    autonumber
    actor U as Usuario
    participant FE as Angular (AuthService, authInterceptor, Web Locks)
    participant C as AuthController
    participant RT as RefreshTokenService
    participant DB as MySQL (users, refresh_tokens)
    U->>FE: Acción con access token de 15 min vencido
    FE->>C: GET /api/... con Bearer
    C-->>FE: 401 UNAUTHENTICATED
    FE->>FE: Una sola renovación compartida, serializada con Web Locks entre pestañas
    FE->>C: POST /api/auth/refresh con cookie prestalab_rt
    C->>RT: refresh(cookie, Origin)
    RT->>DB: SELECT refresh_tokens WHERE token_hash FOR UPDATE
    alt hash desconocido pero igual a previous_token_hash
        RT->>DB: revoca la sesión (REUSE_DETECTED) y registra WARN
        C-->>FE: 401 SESSION_EXPIRED y borra la cookie
    else sesión desplazada (REPLACED)
        C-->>FE: 401 SESSION_REPLACED y borra la cookie
    else cerrada por un ADMIN o cuenta con deleted_at
        RT->>DB: revoca con ACCOUNT_DISABLED si hace falta
        C-->>FE: 401 SESSION_INVALIDATED y borra la cookie
    else vencida por 30 min de inactividad o vida máxima, o cerrada con LOGOUT
        RT->>DB: revoca con EXPIRED si hace falta
        C-->>FE: 401 SESSION_EXPIRED y borra la cookie
        FE-->>U: Vuelve al inicio de sesión con el mensaje
    else sesión válida
        RT->>DB: lee users (rol y deleted_at)
        RT->>DB: rota: previous_token_hash = token_hash, nuevo token_hash, rotation_count + 1, expires_at = MIN(ahora + 30 min, session_expires_at)
        RT-->>C: AuthResponse
        C-->>FE: 200 con access token nuevo y Set-Cookie rotada
        FE->>C: reintenta la petición original una sola vez
        C-->>FE: respuesta de la petición
    end
    Note over FE: Rotación por actividad (como mucho una por minuto) y cierre local a los 30 min sin actividad
    Note over FE: Aviso 5 min antes de sessionExpiresAt (ESTUDIANTE a los 55 min)
    opt recarga de página
        FE->>C: POST /api/auth/refresh al arrancar (renovación silenciosa)
        C-->>FE: 200 restaura la sesión o 401 muestra el inicio de sesión
    end
    U->>FE: Cerrar sesión
    FE->>C: POST /api/auth/logout con cookie
    C->>RT: logout(cookie)
    RT->>DB: revoca la sesión (LOGOUT), idempotente
    C-->>FE: 204 y cookie borrada (Max-Age 0)
```

> Fuente: [`docs/diagrams/secuencia-sesion-refresh.mmd`](docs/diagrams/secuencia-sesion-refresh.mmd) · Imagen: [`docs/diagrams/secuencia-sesion-refresh.png`](docs/diagrams/secuencia-sesion-refresh.png).

**Sesión única por usuario**

```mermaid
---
title: Sesión única por usuario (diseño)
---
sequenceDiagram
    autonumber
    actor A as Dispositivo A
    actor B as Dispositivo B
    participant C as AuthController
    participant RT as RefreshTokenService
    participant DB as MySQL (users, refresh_tokens)
    participant I as ActiveSessionInterceptor
    participant UC as UserController
    Note over A,DB: A tiene una sesión vigente
    B->>C: POST /api/auth/login con credenciales correctas
    C->>DB: bloquea users FOR UPDATE
    C->>RT: abrir sesión
    RT->>DB: busca la sesión no revocada del usuario
    alt la sesión anterior ya venció
        RT->>DB: revoca con EXPIRED y crea la nueva
        C-->>B: 200 sin 409
    else la sesión de A sigue vigente
        C-->>B: 409 ACTIVE_SESSION_EXISTS "Ya tienes una sesión activa en otro lugar" con activeSession
        B->>B: aviso con dos opciones: cerrar la otra sesión e ingresar, o cancelar (A sigue activa)
        B->>C: POST /api/auth/login con replaceExistingSession true
        C->>RT: abrir sesión con reemplazo
        RT->>DB: revoca la sesión de A (REPLACED) y crea la de B
        C-->>B: 200 con sesión nueva
    end
    A->>I: cualquier petición con access token aún vigente
    I->>DB: lee la sesión por sid
    I-->>A: 401 SESSION_REPLACED
    A->>C: POST /api/auth/refresh
    C-->>A: 401 SESSION_REPLACED
    A->>A: mensaje "Tu sesión fue cerrada porque iniciaste sesión en otro lugar" y vuelve al inicio de sesión
    Note over UC,DB: Cierre administrativo: DELETE /api/users/{id}/session por un ADMIN
    alt hay sesión vigente
        UC->>DB: revoca la sesión con CLOSED_BY_ADMIN
        UC-->>UC: 204
        A->>I: usa la sesión cerrada
        I-->>A: 401 SESSION_INVALIDATED "Tu sesión ya no es válida. Inicia sesión de nuevo"
    else sin sesión activa
        UC-->>UC: 409 NO_ACTIVE_SESSION "La cuenta no tiene sesión activa"
    else la cuenta no existe
        UC-->>UC: 404 USER_NOT_FOUND
    end
```

> Fuente: [`docs/diagrams/secuencia-sesion-unica.mmd`](docs/diagrams/secuencia-sesion-unica.mmd) · Imagen: [`docs/diagrams/secuencia-sesion-unica.png`](docs/diagrams/secuencia-sesion-unica.png).

**Baja de cuenta (ADMIN)**

```mermaid
---
title: Baja de cuenta DELETE /api/users/{id} (diseño)
---
sequenceDiagram
    autonumber
    actor AD as ADMIN
    actor ST as Estudiante
    participant C as UserController
    participant UA as UserAccountService
    participant LA as UserLoanActivityService (loans)
    participant LS as LoanService (loans)
    participant AI as ActiveSessionInterceptor
    participant DB as MySQL
    AD->>C: DELETE /api/users/{id}
    C->>C: @PreAuthorize ADMIN
    C->>UA: deactivate(id, adminId)
    activate UA
    Note over UA,DB: Una transacción, orden users y luego refresh_tokens. Los préstamos solo se leen
    UA->>DB: bloquea users FOR UPDATE (y los ADMIN activos por id si el objetivo es ADMIN)
    alt cuenta inexistente
        UA-->>AD: 404 USER_NOT_FOUND
    else ya dada de baja
        UA-->>AD: 200 idempotente con el deactivatedAt original y sessionRevoked false
    else último ADMIN activo
        UA-->>AD: 409 LAST_ADMIN "Debe existir al menos un administrador activo"
    else es la propia cuenta
        UA-->>AD: 409 CANNOT_DEACTIVATE_SELF "No puedes darte de baja a ti mismo"
    else reglas de users cumplidas
        UA->>LA: findLoansInProgress(userId)
        LA->>DB: lee SOLICITADO, APROBADO, ENTREGADO y VENCIDO del titular, sin bloquear
        LA-->>UA: lista de LoanInProgressView
        alt hay algún préstamo en curso
            UA-->>AD: 409 USER_HAS_LOANS_IN_PROGRESS "La cuenta tiene préstamos en curso" con loans[], sin cambiar nada
        else sin préstamos en curso
            UA->>DB: deleted_at y deactivated_by
            UA->>DB: revoca la sesión (motivo interno ACCOUNT_DISABLED)
            UA-->>AD: 200 {userId, deactivatedAt, sessionRevoked}
        end
    end
    deactivate UA
    Note over AD,DB: No hay cancelación automática de préstamos al dar de baja
    par solicitud simultánea del estudiante, serializada en la fila de users
        ST->>LS: POST /api/loans
        LS->>DB: lockStudentForUpdate (users FOR UPDATE)
        alt la solicitud confirma primero
            LS-->>ST: 201 SOLICITADO (la baja, al obtener el bloqueo, responde 409 USER_HAS_LOANS_IN_PROGRESS)
        else la baja confirma primero
            LS-->>ST: 401 SESSION_INVALIDATED "Tu sesión ya no es válida. Inicia sesión de nuevo" sin crear nada
        end
    end
    Note over ST,AI: Corte inmediato en toda petición autenticada, sin ventana
    ST->>AI: consulta de ESTUDIANTE con access token aún vigente
    AI->>DB: consulta de sesión y cuenta
    AI-->>ST: 401 SESSION_INVALIDATED "Tu sesión ya no es válida. Inicia sesión de nuevo"
    ST->>AI: acción que modifica datos
    AI->>DB: lee sesión y cuenta
    AI-->>ST: 401 SESSION_INVALIDATED
    ST->>C: POST /api/auth/refresh (rotación por actividad o access token vencido)
    C-->>ST: 401 SESSION_INVALIDATED
    ST->>C: POST /api/auth/login
    C-->>ST: 401 INVALID_CREDENTIALS "Credenciales inválidas"
    Note over AD,DB: Con préstamos en curso, el ADMIN puede cortar el acceso con DELETE /api/users/{id}/session (CLOSED_BY_ADMIN)
    Note over AD,DB: Variante: si la baja se hizo fuera de la aplicación, se detecta en la renovación al leer users.deleted_at
```

> Fuente: [`docs/diagrams/secuencia-baja-cuenta.mmd`](docs/diagrams/secuencia-baja-cuenta.mmd) · Imagen: [`docs/diagrams/secuencia-baja-cuenta.png`](docs/diagrams/secuencia-baja-cuenta.png).

**Solicitar préstamo: `POST /api/loans` (HU-04)**

```mermaid
---
title: Solicitar préstamo POST /api/loans (diseño)
---
sequenceDiagram
    autonumber
    actor E as Estudiante
    participant FE as Angular (LoanRequestComponent)
    participant C as LoanController
    participant S as LoanService
    participant U as UserDirectoryService (auth.api)
    participant K as EquipmentCatalogService (catalog.api)
    participant TS as LoanTransitionService
    participant M as LoanMapper
    participant DB as MySQL
    E->>FE: Confirma la solicitud (fechas e ítems)
    FE->>C: POST /api/loans con Bearer
    C->>C: @PreAuthorize ESTUDIANTE y @Valid LoanRequest
    Note over C: Rango de máximo 7 días incluidos, inicio desde hoy, equipos sin repetir
    alt datos inválidos
        C-->>FE: 400 VALIDATION_ERROR con requestId
    else datos válidos
        C->>S: create(request, studentId)
        activate S
        Note over S,DB: Una sola transacción READ COMMITTED
        S->>U: lockStudentForUpdate(studentId)
        U->>DB: SELECT users FOR UPDATE
        S->>DB: cuenta préstamos en curso (SOLICITADO incluidos) y sanciones
        S->>K: lockForShare(equipmentIds) en orden de id
        K->>DB: SELECT equipment FOR SHARE
        S->>DB: suma retenidas con el rango efectivo
        Note right of DB: APROBADO hasta GREATEST(end_date, DATE(pickup_deadline))<br/>ENTREGADO y VENCIDO hasta la devolución
        alt ya tiene 3 préstamos en curso
            S-->>C: LoanLimitReachedException
            C-->>FE: 409 LOAN_LIMIT_REACHED
        else bloqueado por sanción o con un préstamo vencido sin devolver
            S-->>C: StudentBlockedException u OVERDUE_LOAN_PENDING
            C-->>FE: 409 STUDENT_BLOCKED u OVERDUE_LOAN_PENDING
        else equipo en mantenimiento o dado de baja
            S-->>C: EquipmentUnavailableException
            C-->>FE: 409 EQUIPMENT_UNAVAILABLE "Equipo no disponible"
        else unidades insuficientes
            S-->>C: InsufficientUnitsException
            C-->>FE: 409 INSUFFICIENT_UNITS con items[]
            FE-->>E: Muestra qué cantidades ajustar
        else todo cumple
            S->>DB: INSERT loans y loan_items (SOLICITADO)
            S->>TS: registrar creación (NULL a SOLICITADO)
            TS->>DB: INSERT loan_status_history
            S->>M: toResponse(loan)
            M-->>S: LoanResponse
            S-->>C: LoanResponse
            C-->>FE: 201 Created con Location
            FE-->>E: "Solicitud enviada" y abre Mis préstamos
        end
        deactivate S
    end
```

> Fuente: [`docs/diagrams/secuencia-solicitar-prestamo.mmd`](docs/diagrams/secuencia-solicitar-prestamo.mmd) · Imagen: [`docs/diagrams/secuencia-solicitar-prestamo.png`](docs/diagrams/secuencia-solicitar-prestamo.png).

**Aprobar préstamo: `POST /api/loans/{id}/approval` (HU-05a)**

```mermaid
---
title: Aprobar préstamo POST /api/loans/{id}/approval (diseño)
---
sequenceDiagram
    autonumber
    actor EN as Encargado
    participant C as LoanController
    participant S as LoanService
    participant K as EquipmentCatalogService (catalog.api)
    participant TS as LoanTransitionService
    participant M as LoanMapper
    participant DB as MySQL
    EN->>C: POST /api/loans/{id}/approval
    C->>C: @PreAuthorize ENCARGADO o ADMIN
    C->>S: approve(id, actorId)
    activate S
    Note over S,DB: Una transacción READ COMMITTED
    S->>S: horario de servicio con Clock (8:00 AM a 5:00 PM)
    alt fuera del horario
        S-->>C: OutsideServiceHoursException
        C-->>EN: 409 OUTSIDE_APPROVAL_HOURS "Las aprobaciones se hacen de 8:00 AM a 5:00 PM"
    else en horario
        S->>DB: SELECT loans WHERE id FOR UPDATE
        Note right of DB: un segundo encargado espera aquí el bloqueo
        alt el préstamo no está SOLICITADO
            S-->>C: LOAN_NOT_PENDING
            C-->>EN: 409 "Solo se resuelven solicitudes pendientes"
        else fecha fin ya pasó o inicio ya pasó sin poder aprobar
            C-->>EN: 409 LOAN_ALREADY_ENDED o LOAN_ALREADY_STARTED
        else SOLICITADO vigente
            S->>K: lockForUpdate(equipmentIds) en orden de id
            K->>DB: SELECT equipment FOR UPDATE
            S->>DB: suma retenidas con el rango efectivo de retención
            alt equipo en mantenimiento o dado de baja
                C-->>EN: 409 EQUIPMENT_UNAVAILABLE "Equipo no disponible"
            else unidades insuficientes
                C-->>EN: 409 INSUFFICIENT_UNITS "Unidades insuficientes" con items[]
            else hay unidades
                S->>S: PickupDeadlinePolicy calcula pickup_deadline
                S->>TS: transition(loan, APROBADO, actorId, at)
                TS->>DB: UPDATE loans WHERE id y status = SOLICITADO
                alt 0 filas afectadas
                    TS-->>C: CONCURRENT_MODIFICATION
                    C-->>EN: 409
                else 1 fila
                    TS->>DB: INSERT loan_status_history
                    TS->>TS: publica LoanStatusChangedEvent
                    S->>M: toResponse(loan)
                    S-->>C: LoanResponse con pickupDeadline
                    C-->>EN: 200 OK
                end
            end
        end
    end
    deactivate S
```

> Fuente: [`docs/diagrams/secuencia-aprobar-prestamo.mmd`](docs/diagrams/secuencia-aprobar-prestamo.mmd) · Imagen: [`docs/diagrams/secuencia-aprobar-prestamo.png`](docs/diagrams/secuencia-aprobar-prestamo.png).

**Entrega y devolución: `POST /api/loans/{id}/delivery` y `/return` (HU-05b, HU-05c)**

```mermaid
---
title: Entrega y devolución de préstamos (diseño)
---
sequenceDiagram
    autonumber
    actor EN as Encargado
    participant FE as Angular (bandeja)
    participant C as LoanController
    participant S as LoanService
    participant K as EquipmentCatalogService (catalog.api)
    participant TS as LoanTransitionService
    participant N as notifications (oyente del evento)
    participant DB as MySQL
    EN->>FE: Entregar un préstamo aprobado
    FE->>C: POST /api/loans/{id}/delivery
    C->>S: deliver(id, actorId)
    activate S
    S->>DB: SELECT loans FOR UPDATE
    S->>K: lockForUpdate(equipmentIds)
    alt no está APROBADO
        C-->>FE: 409 LOAN_NOT_APPROVED "Solo se entregan préstamos aprobados"
    else aún no inicia o servicio no abierto
        C-->>FE: 409 LOAN_NOT_STARTED o SERVICE_NOT_STARTED
    else total de unidades menor a la cantidad
        C-->>FE: 409 INSUFFICIENT_UNITS
    else puede entregarse
        S->>S: dentro del plazo de recogida, fin efectivo = fin o día de entrega
        S->>TS: transition(APROBADO a ENTREGADO)
        TS->>DB: UPDATE condicional, historial y evento
        TS->>N: LoanStatusChangedEvent
        opt préstamo de 2 días
            N->>DB: alerta de próximo a vencer
        end
        S-->>C: LoanResponse
        C-->>FE: 200 OK
    end
    deactivate S
    EN->>FE: Registrar devolución
    FE->>C: POST /api/loans/{id}/return con líneas por equipo
    C->>S: registerReturn(id, request, actorId)
    activate S
    S->>DB: SELECT loans FOR UPDATE
    alt no está ENTREGADO ni VENCIDO
        C-->>FE: 409 LOAN_NOT_DELIVERED "El préstamo no ha sido entregado"
    else suma de líneas distinta de lo prestado
        C-->>FE: 400 RETURN_QUANTITIES_MISMATCH
    else líneas válidas
        S->>DB: INSERT loan_item_returns (BUENO, CON_DESPERFECTOS, DANADO, PERDIDO)
        opt DANADO o PERDIDO
            S->>K: decreaseTotalUnits(equipmentId, n)
        end
        opt devolución con retraso
            S->>DB: INSERT sanctions
        end
        S->>TS: transition(ENTREGADO o VENCIDO a DEVUELTO)
        TS->>DB: UPDATE condicional e historial
        TS->>N: LoanStatusChangedEvent (cierra alertas)
        S-->>C: LoanReturnResponse con affectedApprovedLoans
        C-->>FE: 200 OK y aviso de APROBADO afectados
    end
    deactivate S
```

> Fuente: [`docs/diagrams/secuencia-ciclo-prestamo.mmd`](docs/diagrams/secuencia-ciclo-prestamo.mmd) · Imagen: [`docs/diagrams/secuencia-ciclo-prestamo.png`](docs/diagrams/secuencia-ciclo-prestamo.png).

**Cancelar préstamo: `POST /api/loans/{id}/cancellation` (SH-07)**

```mermaid
---
title: Cancelar préstamo POST /api/loans/{id}/cancellation (diseño)
---
sequenceDiagram
    autonumber
    actor ES as Estudiante
    participant C as LoanController
    participant S as LoanService
    participant TS as LoanTransitionService
    participant DB as MySQL
    ES->>C: POST /api/loans/{id}/cancellation {reason opcional}
    C->>C: @PreAuthorize ESTUDIANTE y @Valid (reason hasta 250)
    C->>S: cancel(id, studentId, reason)
    activate S
    S->>DB: SELECT loans FOR UPDATE
    alt el préstamo no es del titular
        S-->>C: ForbiddenOperationException
        C-->>ES: 403 ACCESS_DENIED "Acceso denegado"
    else ya fue entregado
        C-->>ES: 409 LOAN_ALREADY_DELIVERED "El préstamo ya fue entregado"
    else fuera de la ventana de cancelación
        Note over S: ventana con Clock: SOLICITADO con inicio hoy o posterior, APROBADO antes de pickup_deadline
        C-->>ES: 409 LOAN_NOT_CANCELLABLE "El préstamo ya no se puede cancelar"
    else dentro de la ventana
        S->>S: motivo vacío se guarda como "Cancelado por usuario"
        S->>TS: transition(SOLICITADO o APROBADO a CANCELADO)
        TS->>DB: UPDATE loans WHERE id y status esperado
        alt 0 filas (entrega o tarea programada simultánea)
            TS-->>C: CONCURRENT_MODIFICATION
            C-->>ES: 409
        else 1 fila
            TS->>DB: INSERT loan_status_history
            S-->>C: LoanResponse
            C-->>ES: 200 OK
        end
    end
    deactivate S
```

> Fuente: [`docs/diagrams/secuencia-cancelar-prestamo.mmd`](docs/diagrams/secuencia-cancelar-prestamo.mmd) · Imagen: [`docs/diagrams/secuencia-cancelar-prestamo.png`](docs/diagrams/secuencia-cancelar-prestamo.png).

**Tareas programadas (HU-05e, SH-02, SH-06)**

```mermaid
---
title: Tareas programadas (diseño)
---
sequenceDiagram
    autonumber
    participant SCH as "@Scheduled"
    participant VC as Vercel Cron
    participant IJ as InternalJobController
    participant J as Job (PickupExpiration, DailyLoanReview, DueSoonAlert)
    participant TS as LoanTransitionService
    participant N as notifications (oyente)
    participant DB as MySQL
    par disparo en proceso
        SCH->>J: ejecuta en la zona de la institución
    and disparo externo
        VC->>IJ: GET /api/internal/jobs/{job} con Bearer CRON_SECRET
        alt secreto incorrecto
            IJ-->>VC: 401 INVALID_CRON_SECRET "No autorizado" (comparación en tiempo constante)
        else secreto correcto
            IJ->>J: ejecuta
            IJ-->>VC: 204
        end
    end
    J->>J: MDC requestId job-nombre-uuid y userId SYSTEM
    J->>DB: selecciona todo lo pendiente hasta ahora
    Note over J,DB: PickupExpiration: APROBADO con pickup_deadline vencido<br/>DailyLoanReview 00:05: SOLICITADO con inicio pasado y ENTREGADO con fin efectivo pasado
    loop cada préstamo, una transacción corta
        J->>TS: transition(loan, estado nuevo, SYSTEM)
        TS->>DB: UPDATE WHERE id y status esperado
        alt 0 filas (otra instancia ya lo procesó)
            TS-->>J: sin historial, evento ni alertas
        else 1 fila
            TS->>DB: INSERT loan_status_history (changed_by NULL)
            TS->>N: LoanStatusChangedEvent
            N->>DB: alertas únicas por destinatario, préstamo y tipo
            Note right of N: NO_RECOGIDO a todos los ENCARGADO y al titular<br/>SIN_RESOLVER_A_TIEMPO al titular<br/>PRESTAMO_VENCIDO a ENCARGADO y ADMIN
        end
    end
    opt DueSoonAlertJob 00:05
        J->>DB: ENTREGADO con fin efectivo mañana, alerta PROXIMO_A_VENCER
    end
    J->>J: registra inicio, cantidades procesadas y duración
```

> Fuente: [`docs/diagrams/secuencia-tareas-programadas.mmd`](docs/diagrams/secuencia-tareas-programadas.mmd) · Imagen: [`docs/diagrams/secuencia-tareas-programadas.png`](docs/diagrams/secuencia-tareas-programadas.png).

---

## 5. Historias de Usuario

`docs/historias-de-usuario.md` contiene las 23 historias del proyecto: 11 Must (HU-01a a HU-05e) y 12 Should (SH-01 a SH-12), con sus reglas de negocio (RN-*) y criterios de aceptación. Están cerradas: no queda ninguna decisión pendiente. El seguimiento está en Jira (proyecto PLAB): <!-- COMPLETAR enlace al tablero de Jira y claves PLAB-n de cada historia; el archivo de historias no las incluye -->.

Se documentan aquí tres historias: dos del flujo principal del préstamo (HU-04 y HU-05a) y una de seguridad (SH-11). Los escenarios, reglas y mensajes se copian del archivo de historias; solo se traducen las palabras clave Given/When/Then a Dado/Cuando/Entonces.

**Historia de Usuario 1**

| Campo | Detalle |
|---|---|
| ID / Jira | HU-04 · <!-- COMPLETAR clave Jira (PLAB-n) --> |
| Título | Solicitud de préstamo |
| Historia | **Como** ESTUDIANTE **quiero** solicitar uno o varios equipos para un rango de hasta 7 días **para** disponer de ellos en mis prácticas sin ir presencialmente a pedirlos. |
| Prioridad / Estimación | Must · <!-- COMPLETAR estimación en Jira --> |
| Dependencias | HU-03 (consulta de disponibilidad, base de la solicitud, según el índice del archivo de historias) |

Reglas de negocio:

- RN-04.1 Una solicitud incluye uno o más equipos, cada uno con cantidad mayor o igual a 1.
- RN-04.2 El rango cumple las convenciones comunes: máximo 7 días, fin no anterior a inicio, inicio no anterior a hoy. Se permite solicitar con inicio el mismo día (antelación mínima 0 días, PA-4).
- RN-04.3 La cantidad pedida de cada equipo no supera su disponibilidad en el rango.
- RN-04.4 La solicitud se registra completa o no se registra: si un equipo no tiene unidades suficientes, no se registra ninguna parte.
- RN-04.5 Toda solicitud nace en estado SOLICITADO y no retiene unidades hasta ser aprobada. La competencia por las últimas unidades se resuelve al aprobar (HU-05a).
- RN-04.6 No se puede solicitar un equipo en MANTENIMIENTO ni dado de baja.
- RN-04.7 El estudiante ve sus solicitudes con su estado actual y, si están en RECHAZADO, el motivo. Los filtros por estado y fechas son de SH-01.
- RN-04.8 Un estudiante no puede tener más de 3 préstamos en curso (SOLICITADO, APROBADO, ENTREGADO o VENCIDO) a la vez (PA-10). Una solicitud con varios equipos cuenta como 1 préstamo. Al llegar al límite, la solicitud se rechaza con "Ya tienes 3 préstamos en curso". Si SH-03 lo bloquea, aplica además lo que indica esa historia.

Criterios de aceptación (tal como están en `docs/historias-de-usuario.md`):

```gherkin
# language: es
Escenario: 1 - Solicitud correcta
  Dado que hoy es 1 de noviembre y un equipo con 3 unidades disponibles del 10 al 12 de noviembre
  Cuando solicito 2 unidades para ese rango (RN-04.1, RN-04.5)
  Entonces se crea la solicitud en estado SOLICITADO

Escenario: 2 - Unidades insuficientes
  Dado un equipo con 1 unidad disponible en el rango
  Cuando solicito 2 unidades (RN-04.3)
  Entonces veo el mensaje "Unidades insuficientes" con la cantidad disponible y no se crea la solicitud

Escenario: 3 - Rango de 8 días
  Dado que elijo del 10 al 17 de noviembre (8 días)
  Cuando envío la solicitud (RN-04.2)
  Entonces veo el mensaje "El rango máximo es de 7 días"

Escenario: 4 - Rango de 7 días
  Dado un equipo con unidades disponibles del 10 al 16 de noviembre
  Cuando envío la solicitud para ese rango de 7 días (RN-04.2)
  Entonces se crea la solicitud en estado SOLICITADO

Escenario: 5 - Fecha fin anterior a inicio
  Dado que elijo inicio el 12 de noviembre y fin el 10 de noviembre
  Cuando envío la solicitud (RN-04.2)
  Entonces veo el mensaje "La fecha fin no puede ser anterior a la fecha inicio"

Escenario: 6 - Inicio en el pasado
  Dado que hoy es 15 de noviembre y elijo inicio el 14 de noviembre
  Cuando envío la solicitud (RN-04.2)
  Entonces veo el mensaje "La fecha de inicio no puede ser anterior a hoy"

Escenario: 7 - Varios equipos y uno sin unidades
  Dado que pido el equipo A (con unidades) y el B (sin unidades) para el mismo rango
  Cuando envío la solicitud (RN-04.4)
  Entonces no se crea ninguna solicitud y se indica que B tiene "Unidades insuficientes"

Escenario: 8 - Equipo en mantenimiento
  Dado un equipo en MANTENIMIENTO
  Cuando lo solicito (RN-04.6)
  Entonces veo el mensaje "Equipo no disponible" y no se crea la solicitud

Escenario: 9 - Cantidad 0
  Dado un equipo con unidades disponibles
  Cuando solicito 0 unidades (RN-04.1)
  Entonces veo el mensaje "La cantidad debe ser al menos 1" y no se crea la solicitud

Escenario: 10 - Ver el estado de mi solicitud
  Dado una solicitud mía en estado SOLICITADO
  Cuando abro la lista de mis solicitudes (RN-04.7)
  Entonces veo la solicitud con el estado SOLICITADO

Escenario: 11 - Ver el motivo de un rechazo
  Dado una solicitud mía RECHAZADO con motivo "Equipo reservado para examen"
  Cuando abro su detalle (RN-04.7)
  Entonces veo el estado RECHAZADO y el motivo

Escenario: 12 - El tercer préstamo en curso se permite
  Dado que tengo 2 préstamos en curso y un equipo con unidades disponibles
  Cuando envío una solicitud válida (RN-04.8)
  Entonces se crea la solicitud en estado SOLICITADO y tengo 3 préstamos en curso

Escenario: 13 - El cuarto préstamo en curso se bloquea
  Dado que tengo 3 préstamos en curso (por ejemplo 1 SOLICITADO, 1 APROBADO y 1 ENTREGADO)
  Cuando envío una solicitud válida (RN-04.8)
  Entonces se rechaza con el mensaje "Ya tienes 3 préstamos en curso" y no se crea la solicitud

Escenario: 14 - Un préstamo devuelto libera cupo
  Dado que tenía 3 préstamos en curso y uno pasó a DEVUELTO
  Cuando envío una solicitud válida (RN-04.8)
  Entonces se crea la solicitud en estado SOLICITADO

Escenario: 15 - Una solicitud rechazada libera cupo
  Dado que tenía 3 préstamos en curso y una solicitud mía pasó a RECHAZADO (por ejemplo, "Sin resolver a tiempo")
  Cuando envío una solicitud válida (RN-04.8)
  Entonces se crea la solicitud en estado SOLICITADO

Escenario: 16 - Una solicitud cancelada libera cupo
  Dado que tenía 3 préstamos en curso y una solicitud mía pasó a CANCELADO
  Cuando envío una solicitud válida (RN-04.8)
  Entonces se crea la solicitud en estado SOLICITADO
```

Notas de coherencia: una solicitud nace SOLICITADO y **no retiene unidades** (RN-04.5); solo comprueba que la cantidad pedida no supere la disponibilidad al crearla (RN-04.3). Si dos estudiantes piden la última unidad, ambas solicitudes pueden quedar creadas: la competencia se resuelve **al aprobar** (HU-05a, escenario 4). Crear la solicitud bloquea la fila del estudiante (`users ... FOR UPDATE`) para que dos envíos simultáneos no superen el límite de 3, y lee los equipos con `FOR SHARE`. Contrato: `POST /api/loans` (sección 4).

**Historia de Usuario 2**

| Campo | Detalle |
|---|---|
| ID / Jira | HU-05a · <!-- COMPLETAR clave Jira (PLAB-n) --> |
| Título | Aprobar o rechazar solicitudes |
| Historia | **Como** ENCARGADO **quiero** aprobar o rechazar solicitudes pendientes **para** controlar qué equipos salen y reservar las unidades de los préstamos aceptados. |
| Prioridad / Estimación | Must · <!-- COMPLETAR estimación en Jira --> |
| Dependencias | HU-04 (solicitudes SOLICITADO); HU-02a (equipos) |

Reglas de negocio:

- RN-05a.1 Solo una solicitud en estado SOLICITADO puede aprobarse o rechazarse. Un préstamo ya APROBADO no se rechaza.
- RN-05a.2 Rechazar exige un motivo de entre 10 y 250 caracteres que el estudiante puede ver.
- RN-05a.3 Al aprobar se comprueba la disponibilidad actual del rango para cada equipo, calculada con el total vigente del equipo (incluidas las unidades restadas por devoluciones DAÑADO o PERDIDO) y con todos los préstamos cuyo rango efectivo de retención (convenciones) se cruza con el rango efectivo que tendría la solicitud al aprobarse ahora (desde su inicio hasta el día en que vencería su plazo de recogida o su fecha fin, el que sea posterior); si no alcanza, la aprobación se bloquea con "Unidades insuficientes". Es la única barrera: una vez APROBADO, el préstamo no se rechaza.
- RN-05a.4 Al aprobar queda registrado quién y cuándo, y las unidades quedan retenidas.
- RN-05a.5 Un préstamo RECHAZADO no retiene unidades.
- RN-05a.6 Solo ENCARGADO y ADMIN aprueban o rechazan.
- RN-05a.7 No se aprueba una solicitud que incluya un equipo en MANTENIMIENTO; sí puede rechazarse. (Las solicitudes de un equipo dado de baja ya se rechazan solas, HU-02b.)
- RN-05a.8 No se aprueba una solicitud cuya fecha de inicio es anterior a hoy; sí puede rechazarse. Si la fecha de fin ya pasó, el mensaje es "La solicitud ya terminó"; si la fecha de inicio pasó pero la de fin no, es "La solicitud ya inició". Una solicitud con inicio hoy sí puede aprobarse, con el plazo de recogida de las convenciones.
- RN-05a.9 El pase de un APROBADO no recogido a RECHAZADO lo hace el sistema (HU-05e, RN-05e.1), no el encargado.
- RN-05a.10 Las aprobaciones solo se hacen en horario de servicio, de 8:00 AM a 5:00 PM (ambas horas incluidas). Fuera de ese horario se bloquean con "Las aprobaciones se hacen de 8:00 AM a 5:00 PM".
- RN-05a.11 Una solicitud SOLICITADO que llega al día siguiente de su fecha de inicio sin haberse aprobado ni rechazado se rechaza automáticamente en la revisión de las 00:05 con el motivo "Sin resolver a tiempo", y el estudiante recibe un aviso en la aplicación. Así deja de ocupar un cupo del límite de 3 (HU-04). (confirmado, PA-27).
- RN-05a.12 La aprobación no se bloquea porque el plazo de recogida sobrepase la fecha fin del préstamo (confirmado, PA-22): un préstamo de 1 día aprobado después de las 3:00 PM tiene plazo hasta las 10:00 AM del día siguiente.

Criterios de aceptación (tal como están en `docs/historias-de-usuario.md`):

```gherkin
# language: es
Escenario: 1 - Aprobar
  Dado una solicitud SOLICITADO de 2 unidades de un equipo con 3 disponibles
  Cuando la apruebo (RN-05a.3, RN-05a.4)
  Entonces pasa a APROBADO con mi nombre y la hora, y la disponibilidad del rango baja a 1 unidad

Escenario: 2 - Rechazar con motivo
  Dado una solicitud SOLICITADO
  Cuando la rechazo con el motivo "Equipo reservado para examen" (RN-05a.2, RN-05a.5)
  Entonces pasa a RECHAZADO y el motivo queda guardado para que el estudiante lo vea en su solicitud (HU-04, RN-04.7)

Escenario: 3 - Rechazar sin motivo suficiente
  Dado una solicitud SOLICITADO
  Cuando intento rechazarla con el motivo "No" (menos de 10 caracteres) (RN-05a.2)
  Entonces veo el mensaje "El motivo debe tener entre 10 y 250 caracteres" y la solicitud sigue SOLICITADO

Escenario: 4 - Competencia por la última unidad
  Dado un equipo con 1 unidad, una solicitud A ya aprobada para el rango y una solicitud B SOLICITADO de 1 unidad para el mismo rango
  Cuando intento aprobar B (RN-05a.3)
  Entonces se bloquea con "Unidades insuficientes", B sigue SOLICITADO y A sigue APROBADO

Escenario: 5 - Unidades comprometidas por otras aprobaciones
  Dado un equipo con 3 unidades, 2 retenidas por préstamos APROBADO en el rango y una solicitud SOLICITADO de 2 unidades
  Cuando intento aprobarla (RN-05a.3)
  Entonces se bloquea con "Unidades insuficientes" y sigue SOLICITADO

Escenario: 6 - Solicitud que no está pendiente
  Dado un préstamo en estado RECHAZADO
  Cuando intento aprobarlo (RN-05a.1)
  Entonces veo el mensaje "Solo se resuelven solicitudes pendientes" y el estado no cambia

Escenario: 7 - Permisos
  Dado que inicié sesión como ESTUDIANTE
  Cuando intento aprobar una solicitud (RN-05a.6)
  Entonces veo el mensaje "Acceso denegado"

Escenario: 8 - Equipo en mantenimiento
  Dado una solicitud SOLICITADO de un equipo que ahora está en MANTENIMIENTO
  Cuando intento aprobarla (RN-05a.7)
  Entonces se bloquea con el mensaje "Equipo no disponible" y sigue SOLICITADO

Escenario: 9 - Rango ya terminado
  Dado que hoy es 15 de noviembre y una solicitud SOLICITADO del 10 al 12 de noviembre
  Cuando intento aprobarla (RN-05a.8)
  Entonces se bloquea con el mensaje "La solicitud ya terminó" y sigue SOLICITADO

Escenario: 10 - Rango ya iniciado
  Dado que hoy es 11 de noviembre y una solicitud SOLICITADO del 10 al 12 de noviembre
  Cuando intento aprobarla (RN-05a.8)
  Entonces se bloquea con el mensaje "La solicitud ya inició" y sigue SOLICITADO

Escenario: 11 - Aprobación fuera de horario
  Dado que son las 5:01 PM y una solicitud SOLICITADO con inicio mañana
  Cuando intento aprobarla (RN-05a.10)
  Entonces se bloquea con el mensaje "Las aprobaciones se hacen de 8:00 AM a 5:00 PM" y sigue SOLICITADO

Escenario: 12 - Aprobación a las 5:00 PM exactas
  Dado que son las 5:00 PM y una solicitud SOLICITADO con inicio mañana y disponibilidad suficiente
  Cuando la apruebo (RN-05a.10)
  Entonces pasa a APROBADO

Escenario: 13 - Un aprobado no se rechaza
  Dado un préstamo APROBADO
  Cuando intento rechazarlo con el motivo "Equipo ya no disponible" (RN-05a.1)
  Entonces veo el mensaje "Solo se resuelven solicitudes pendientes" y sigue APROBADO

Escenario: 14 - Aprobación a las 3:01 PM de un préstamo de 1 día
  Dado que hoy es 10 de noviembre, son las 3:01 PM y una solicitud SOLICITADO del 10 al 10 de noviembre (1 día) con disponibilidad suficiente
  Cuando la apruebo (RN-05a.12)
  Entonces pasa a APROBADO con plazo de recogida hasta las 10:00 AM del 11 de noviembre

Escenario: 15 - Aprobación a las 5:00 PM de un préstamo de 1 día
  Dado que hoy es 10 de noviembre, son las 5:00 PM y una solicitud SOLICITADO del 10 al 10 de noviembre (1 día) con disponibilidad suficiente
  Cuando la apruebo (RN-05a.12)
  Entonces pasa a APROBADO con plazo de recogida hasta las 10:00 AM del 11 de noviembre

Escenario: 16 - Solicitud sin resolver tras su fecha de inicio
  Dado una solicitud SOLICITADO con inicio el 10 de noviembre que nadie aprobó ni rechazó
  Cuando el sistema realiza la revisión de las 00:05 del 11 de noviembre (RN-05a.11)
  Entonces pasa a RECHAZADO con el motivo "Sin resolver a tiempo" y el estudiante recibe un aviso con ese motivo

Escenario: 17 - Retención del plazo que cruza al día siguiente
  Dado un equipo de 1 unidad, un préstamo B APROBADO para el 11 de noviembre y una solicitud A SOLICITADO para el 10 de noviembre (1 día), a las 5:00 PM del 10
  Cuando intento aprobar A (RN-05a.3)
  Entonces se bloquea con "Unidades insuficientes", porque A retendría la unidad hasta el 11 y se cruza con B

Escenario: 18 - Aprobación cuyo plazo no cruza al día siguiente
  Dado el mismo equipo de 1 unidad y el préstamo B APROBADO para el 11 de noviembre, a las 3:00 PM del 10, y A SOLICITADO para el 10 (1 día)
  Cuando apruebo A (RN-05a.3)
  Entonces pasa a APROBADO con plazo hasta las 5:00 PM del 10, sin cruzarse con B
```

Notas de coherencia: la aprobación y el rechazo son acciones separadas, cada una con su DTO, su rol y su `@PreAuthorize`: `POST /api/loans/{id}/approval` (sin cuerpo) y `POST /api/loans/{id}/rejection` (con `reason`). No existe un cambio de estado genérico (`PATCH /status`). Aprobar es el único punto que retiene unidades: bloquea el préstamo y sus equipos en orden de `id` y comprueba la disponibilidad con el rango efectivo de retención. Un ESTUDIANTE que intenta aprobar recibe 403 "Acceso denegado" (escenario 7).

**Historia de Usuario 3**

| Campo | Detalle |
|---|---|
| ID / Jira | SH-11 · <!-- COMPLETAR clave Jira (PLAB-n) --> |
| Título | Bloqueo temporal por intentos fallidos |
| Historia | **Como** ESTUDIANTE, ENCARGADO o ADMIN **quiero** que mi cuenta se bloquee un tiempo tras varios intentos fallidos de ingreso **para** que nadie pueda adivinar mi contraseña y usar mi cuenta. |
| Prioridad / Estimación | Should · <!-- COMPLETAR estimación en Jira --> |
| Dependencias | HU-01b (usa el mismo mensaje "Credenciales inválidas", RN-01b.2); SH-08 (cuenta dada de baja, RN-SH11.7) |

Reglas de negocio:

- RN-SH11.1 Tras 3 intentos fallidos consecutivos de inicio de sesión con el mismo correo, el acceso se bloquea 15 minutos. "Consecutivos" significa 3 intentos fallidos sin ningún inicio de sesión exitoso entre medias, sin ventana de tiempo; el contador se reinicia con un inicio de sesión exitoso o al terminar el bloqueo (confirmado, PA-32).
- RN-SH11.2 El mensaje no revela si la cuenta existe, si está dada de baja, si está bloqueada ni qué dato es incorrecto: es siempre "Credenciales inválidas" para credenciales incorrectas, correo inexistente, cuenta dada de baja y cuenta bloqueada.
- RN-SH11.3 Durante el bloqueo, ni siquiera la contraseña correcta permite el acceso.
- RN-SH11.4 Un inicio de sesión correcto antes del tercer fallo reinicia la cuenta de intentos.
- RN-SH11.5 Al cumplirse los 15 minutos el bloqueo se levanta solo y la cuenta de intentos vuelve a 0.
- RN-SH11.6 Un correo que no existe cuenta intentos y se bloquea igual, para no distinguirlo de uno existente.
- RN-SH11.7 En una cuenta dada de baja (SH-08), todo intento de inicio de sesión, con la contraseña correcta o no, recibe "Credenciales inválidas" y no da acceso.
- RN-SH11.8 Además del bloqueo por cuenta, hay un límite por origen de conexión: tras 10 intentos fallidos desde el mismo origen, los intentos siguientes de ese origen reciben "Demasiados intentos. Inténtalo de nuevo más tarde". Los 15 minutos son una ventana que empieza en el primer intento fallido de la serie; al décimo fallo el origen queda bloqueado hasta que se cumplan 15 minutos desde ese primer fallo. (confirmado, PA-35). Este mensaje no depende del correo ni de si los datos son correctos (confirmado, PA-32).

Criterios de aceptación (tal como están en `docs/historias-de-usuario.md`):

```gherkin
# language: es
Escenario: 1 - Tercer intento fallido bloquea
  Dado una cuenta con 2 intentos fallidos consecutivos
  Cuando intento iniciar sesión con una contraseña equivocada por tercera vez (RN-SH11.1)
  Entonces veo "Credenciales inválidas" y el acceso queda bloqueado 15 minutos

Escenario: 2 - Contraseña correcta durante el bloqueo
  Dado una cuenta bloqueada hace 5 minutos
  Cuando inicio sesión con la contraseña correcta (RN-SH11.3)
  Entonces no accedo y veo exactamente "Credenciales inválidas"

Escenario: 3 - Fin del bloqueo
  Dado una cuenta bloqueada hace 15 minutos
  Cuando inicio sesión con la contraseña correcta (RN-SH11.5)
  Entonces accedo con normalidad

Escenario: 4 - Un acierto reinicia los intentos
  Dado una cuenta con 2 intentos fallidos consecutivos
  Cuando inicio sesión correctamente (RN-SH11.4)
  Entonces accedo y la cuenta de intentos fallidos vuelve a 0

Escenario: 5 - Correo que no existe
  Dado un correo "nadie@institucion.edu" sin cuenta
  Cuando intento iniciar sesión con él por tercera vez seguida (RN-SH11.2, RN-SH11.6)
  Entonces veo exactamente el mismo mensaje que para una cuenta existente

Escenario: 6 - Cuenta dada de baja con la contraseña correcta
  Dado una cuenta dada de baja
  Cuando intento iniciar sesión con su contraseña correcta (RN-SH11.7)
  Entonces no accedo y veo "Credenciales inválidas", igual que con una contraseña equivocada

Escenario: 7 - Límite por origen de conexión
  Dado 10 intentos fallidos desde el mismo origen, con correos distintos, el primero hace 10 minutos
  Cuando ese origen intenta iniciar sesión con cualquier correo y la contraseña correcta (RN-SH11.8)
  Entonces veo "Demasiados intentos. Inténtalo de nuevo más tarde" sin indicar si el correo existe

Escenario: 8 - Fin de la ventana del origen
  Dado un origen cuyo primer intento fallido de una serie de 10 ocurrió hace 15 minutos
  Cuando intenta iniciar sesión con credenciales correctas (RN-SH11.8)
  Entonces accede con normalidad
```

Notas de coherencia: ningún mensaje del inicio de sesión revela si el correo existe ni qué dato es incorrecto (credenciales incorrectas, correo inexistente, cuenta dada de baja y cuenta bloqueada devuelven el mismo 401 `INVALID_CREDENTIALS` "Credenciales inválidas", con tiempo de respuesta igualado). El límite por origen devuelve 429 `TOO_MANY_ATTEMPTS`. Contrato: `POST /api/auth/login` (sección 4).

---

## 6. Tickets de Trabajo

Cada historia se divide en subtareas `[DB]`, `[BACK]`, `[FRONT]` y `[TEST]`. Se documentan tres de la historia HU-04 (Solicitud de préstamo): una de base de datos, una de backend y una de frontend. Las claves de Jira no existen en el repositorio: <!-- COMPLETAR claves PLAB-n de los tres tickets y de la historia padre -->. Las ramas parten de la rama de la entrega activa (`feature/entrega-1-AFRC`, `feature/entrega-2-AFRC` o `final-project-AFRC`) <!-- COMPLETAR rama base de la entrega -->.

Reglas comunes a los tres tickets (ADR `docs/adr/0001-arquitectura.md`, revisión 7):

- Borrado lógico siempre (`deleted_at`): sin `DELETE FROM`, `TRUNCATE` ni `DROP`. Sin `@SQLRestriction` en `users` ni `equipment`; los repositorios filtran `deleted_at IS NULL` de forma explícita.
- No hay tabla `audit_log`: la trazabilidad es `loan_status_history`, escrita por `LoanTransitionService` en la misma transacción.
- Los módulos solo dependen del paquete `api` de otros módulos (verificado por `ArchitectureTest`). Las entidades de `loans` se refieren a usuarios y equipos por `Long`.
- Solo `GET /api/equipment` (búsqueda con disponibilidad) lo usan los tres roles; el inventario es de ENCARGADO y ADMIN.

**Ticket 1**

| Campo | Detalle |
|---|---|
| Clave / Tipo | <!-- COMPLETAR clave PLAB-n --> · Subtarea **[DB]** |
| Título | Crear el esquema de préstamos (`loans`, `loan_items`, `loan_status_history`) |
| Historia padre | HU-04 Solicitud de préstamo |
| Prioridad / Estimación | Alta · <!-- COMPLETAR estimación --> |
| Dependencias | Migraciones de `users` y `equipment` ya aplicadas (`fk_loans_student` y `fk_loan_items_equipment` apuntan a ellas). Bloquea al ticket [BACK] |
| Rama | `feature/PLAB-<n>-esquema-prestamos` <!-- COMPLETAR clave --> |
| Responsable IA | Subagente `database-engineer` + skill `/crear-migracion` |

**Descripción.** Crear las tablas que guardan las solicitudes de préstamo, sus ítems y la bitácora de transiciones, tal como las define la sección 3 de este README. La tabla `loans` se escribe aquí completa (aprobación, entrega, devolución y cierre) para que las historias posteriores no cambien su esquema; HU-04 solo usa el estado SOLICITADO. Quedan fuera `loan_item_returns` (HU-05c), `sanctions` (SH-03) y `notifications` (HU-05e).

**Tareas**
1. Migraciones Flyway nuevas en `backend/src/main/resources/db/migration`, con el siguiente número libre `V<n>` <!-- COMPLETAR número de versión: depende de las migraciones existentes -->: `V<n>__create_loans.sql`, `V<n+1>__create_loan_items.sql` y `V<n+2>__create_loan_status_history.sql`. Una migración aplicada nunca se edita.
2. `loans` con las columnas, tipos y `ENUM` de la sección 3.2: `student_id`, `status` (DEFAULT 'SOLICITADO'), `start_date`, `end_date`, `approved_at`, `approved_by`, `pickup_deadline`, `delivered_at`, `delivered_by`, `effective_end_date` (columna generada `STORED`: `GREATEST(end_date, DATE(delivered_at))`), `returned_at`, `returned_by`, `closed_at`, `closed_by`, `closure_reason`, `closure_note`, `version` y la auditoría (`created_at`, `updated_at`, `deleted_at`).
3. Llaves foráneas, todas `ON DELETE RESTRICT ON UPDATE RESTRICT`: `fk_loans_student`, `fk_loans_approved_by`, `fk_loans_delivered_by`, `fk_loans_returned_by`, `fk_loans_closed_by` (hacia `users.id`); `fk_loan_items_loan` y `fk_loan_items_equipment`; `fk_loan_status_history_loan` y `fk_loan_status_history_changed_by`.
4. `CHECK` de `loans`: `chk_loans_date_range` (`end_date >= start_date` y `DATEDIFF(end_date, start_date) <= 6`), `chk_loans_approval_fields`, `chk_loans_approval_status`, `chk_loans_delivery`, `chk_loans_return`, `chk_loans_closure`, `chk_loans_closure_reason`, `chk_loans_timeline` y `chk_loans_closure_timing`, con el texto exacto de la sección 3.2. Escritos para no evaluar nunca a NULL.
5. `loan_items`: `quantity INT NOT NULL` con `chk_loan_items_quantity (quantity >= 1)` y único `uk_loan_items_loan_equipment (loan_id, equipment_id)`.
6. `loan_status_history`: `from_status` NULL solo en la fila de creación, `to_status` NOT NULL con `chk_loan_status_history_transition` (solo las transiciones del diagrama de estados), `changed_by` NULL = sistema, `changed_at` DATETIME NOT NULL.
7. Índices de la sección 3.2: `idx_loans_student_status_start (student_id, status, start_date)`, `idx_loans_status_start (status, start_date)`, `idx_loans_status_pickup (status, pickup_deadline)`, `idx_loans_status_effective_end (status, effective_end_date)`, `idx_loans_approved_by`, `idx_loans_delivered_by`, `idx_loans_returned_by`, `idx_loans_closed_by`, `idx_loan_items_equipment_loan (equipment_id, loan_id, quantity)`, `idx_loan_status_history_loan_changed (loan_id, changed_at)` e `idx_loan_status_history_changed_by`.
8. Entidades JPA `Loan`, `LoanItem` y `LoanStatusHistory` en `co.prestalab.loans.entity`, sobre `BaseEntity` de `shared.persistence`, relaciones `LAZY`, `@Version` en `Loan`, `effective_end_date` de solo lectura (`insertable = false, updatable = false`), enumeraciones con `@Enumerated(EnumType.STRING)`. Referencias a `users` y `equipment` solo por `Long`. Sin `@SQLRestriction`.
9. `LoanRepository` con las consultas nativas parametrizadas de la sección 3: conteo de préstamos en curso, existencia de VENCIDO sin devolver y suma de unidades retenidas por equipo (una consulta para toda la página). Todas con `deleted_at IS NULL` explícito.
10. Semillas solo para el perfil `dev` (`classpath:db/seed`), nunca en producción: <!-- COMPLETAR si se cargan préstamos de ejemplo; no son necesarios para HU-04 -->.
11. Actualizar `docs/diagrams/modelo-datos.mmd` y su `.png` con `/generar-diagramas modelo-datos`, el bloque de la sección 3.1 y la descripción de la sección 3.2 si algo cambia respecto al diseño.

**Criterios de aceptación**
- Las migraciones se aplican sin errores sobre una base vacía y sobre una con las migraciones anteriores; `ddl-auto: validate` no reporta diferencias con las entidades.
- No se puede insertar un ítem con `quantity <= 0`, un préstamo con `end_date < start_date` ni uno de más de 7 días (`end_date` más de 6 días después de `start_date`); la base lo rechaza con `chk_loans_date_range` o `chk_loan_items_quantity`.
- No se puede repetir un equipo en el mismo préstamo (`uk_loan_items_loan_equipment`).
- No se puede insertar un préstamo con un `student_id` inexistente (`fk_loans_student`) ni borrar físicamente un usuario con préstamos (RESTRICT).
- Un préstamo en estado SOLICITADO no admite campos de aprobación, entrega, devolución ni cierre (`chk_loans_approval_status`, `chk_loans_delivery`, `chk_loans_closure`).
- `EXPLAIN` de la consulta de conteo en curso usa `idx_loans_student_status_start`, y la de unidades retenidas usa `idx_loan_items_equipment_loan` (solo índice) y `loans` por llave primaria.
- Ninguna sentencia `DELETE`, `TRUNCATE` ni `DROP` en las migraciones (lo valida el hook).

**Pruebas:** `LoanSchemaIT` con Testcontainers MySQL 8 (aplica Flyway sobre una base vacía y prueba cada `CHECK`, la unicidad y las llaves foráneas con inserciones válidas e inválidas); `LoanRepositoryIT` (conteo en curso y unidades retenidas con los casos de la sección 3: APROBADO con plazo vencido ya no retiene, ENTREGADO y VENCIDO retienen hasta devolverse).

**Definition of Done:** migraciones y entidades en verde en `./mvnw verify -Pintegration`; `ArchitectureTest` sin violaciones; diagrama ER y sección 3 del README al día; PR revisado por `code-reviewer`; commit `feat(PLAB-<n>): ...` con la clave real.

**Ticket 2**

| Campo | Detalle |
|---|---|
| Clave / Tipo | <!-- COMPLETAR clave PLAB-n --> · Subtarea **[BACK]** |
| Título | Endpoint `POST /api/loans` con validación de límite, bloqueos y disponibilidad |
| Historia padre | HU-04 Solicitud de préstamo |
| Prioridad / Estimación | Alta · <!-- COMPLETAR estimación --> |
| Dependencias | Ticket [DB] (Ticket 1); `auth` (sesión, `UserDirectoryService`); `catalog` (`EquipmentCatalogService`) |
| Rama | `feature/PLAB-<n>-crear-prestamo-api` <!-- COMPLETAR clave --> |
| Responsable IA | Subagente `backend-developer`; revisión con `code-reviewer` |

**Descripción.** Exponer `POST /api/loans`, que registra una solicitud de préstamo del estudiante autenticado. La solicitud nace en SOLICITADO y **no retiene unidades**; solo se comprueba que la cantidad pedida no supere la disponibilidad al crearla. La competencia por las últimas unidades se resuelve al aprobar (HU-05a).

**Detalle técnico** (módulo `co.prestalab.loans`)
- `controller/LoanController` (`@RequestMapping("/api/loans")`): `@PostMapping`, `@PreAuthorize("hasRole('ESTUDIANTE')")`, recibe `@Valid @RequestBody LoanRequest` y `@AuthenticationPrincipal AuthenticatedUser`, llama a `loanService.create(request, user.id())` y responde `201 Created` con `Location: /api/loans/{id}`. Sin `@Transactional`, reglas ni repositorios en el controlador.
- DTO en `dto/` (records): `LoanRequest(startDate, endDate, items)`, `LoanItemRequest(equipmentId, quantity)`, `LoanResponse` (estados, fechas, `requester`, `items`, `pickupDeadline`, `createdAt` con desplazamiento `-05:00`). Mapeo con `LoanMapper` (MapStruct) dentro de la transacción. Nombres de equipo vía `EquipmentCatalogService.findSummaries` y del estudiante vía `UserDirectoryService.findSummaries`.
- Validación en el DTO (controller, Bean Validation): cantidad mínima 1 ("La cantidad debe ser al menos 1"); al menos un ítem y equipos sin repetir; `@ValidDateRange(maxDays = 7, notBeforeToday = true)` con el `Clock` inyectado: fin no anterior a inicio ("La fecha fin no puede ser anterior a la fecha inicio"), inicio no anterior a hoy ("La fecha de inicio no puede ser anterior a hoy", se permite hoy) y máximo 7 días contando ambos extremos ("El rango máximo es de 7 días"). Un rango de 8 días responde **400 `VALIDATION_ERROR`** con `errors[]`, no 409. Los textos viven en `ValidationMessages.properties`.
- `service/LoanService.create(LoanRequest, Long studentId)`, una sola transacción en READ COMMITTED, en este orden de bloqueo (users, luego equipment por `id` ascendente):
  1. `UserDirectoryService.lockStudentForUpdate(studentId)` (`auth.api`, propagación `MANDATORY`, `SELECT users ... FOR UPDATE`). Si el snapshot indica `active = false` (la cuenta se dio de baja mientras esperaba el bloqueo): **401 `SESSION_INVALIDATED`** "Tu sesión ya no es válida. Inicia sesión de nuevo" y no se crea nada.
  2. Límite de 3: cuenta los préstamos en curso con la consulta de la sección 3 (SOLICITADO con `start_date >= hoy`, APROBADO con `pickup_deadline > ahora`, ENTREGADO y VENCIDO; las SOLICITADO cuentan). Si ya son 3: 409 `LOAN_LIMIT_REACHED` "Ya tienes 3 préstamos en curso".
  3. Bloqueo por préstamo vencido sin devolver: 409 `OVERDUE_LOAN_PENDING` "Tienes un préstamo vencido pendiente de devolución". El bloqueo por sanción (409 `STUDENT_BLOCKED` "Podrás volver a solicitar el {fecha}") se activa cuando exista la tabla `sanctions` (SH-03) <!-- COMPLETAR confirmar en Jira si SH-03 entra antes que este ticket -->.
  4. `EquipmentCatalogService.lockForShare(ids)` (`catalog.api`, `MANDATORY`, `FOR SHARE` en orden de `id`). Equipo en MANTENIMIENTO, dado de baja o inexistente: 409 `EQUIPMENT_UNAVAILABLE` "Equipo no disponible". **No** se usa `PESSIMISTIC_WRITE` sobre equipos.
  5. Disponibilidad por equipo = `totalUnits` - unidades retenidas en el rango, con el rango efectivo de retención (APROBADO hasta `GREATEST(end_date, DATE(pickup_deadline))` y solo con el plazo vigente; ENTREGADO y VENCIDO hasta la devolución). Si alguno no alcanza: 409 `INSUFFICIENT_UNITS` "Unidades insuficientes" con `items[] {equipmentId, name, requested, available}` y no se registra ninguna parte (RN-04.4).
  6. Inserta `loans` (SOLICITADO) y `loan_items`; `LoanTransitionService` inserta la fila `NULL → SOLICITADO` en `loan_status_history` (`changed_by` = estudiante, `changed_at` del `Clock`) y publica `LoanStatusChangedEvent`.
- Respeto de fronteras: `loans` no usa `EquipmentRepository` ni `UserRepository`; solo `auth.api.UserDirectoryService` y `catalog.api.EquipmentCatalogService`. La consulta de unidades retenidas es de `LoanRepository`.
- Cuenta y sesión: `ActiveSessionInterceptor` (módulo `auth`) comprueba en **toda** petición autenticada, consultas incluidas, que la cuenta siga activa y la sesión vigente (una consulta por llave primaria, sin caché, falla cerrada). Este endpoint responde por tanto 401 `UNAUTHENTICATED`, `SESSION_INVALIDATED`, `SESSION_REPLACED` o `SESSION_EXPIRED` según el caso, sin lógica propia.
- Errores con `ProblemDetail` (`code`, `requestId`, `timestamp`, `items[]` cuando aplica): 400 `VALIDATION_ERROR`, 401, 403 "Acceso denegado" (rol distinto de ESTUDIANTE), 409 (`INSUFFICIENT_UNITS`, `EQUIPMENT_UNAVAILABLE`, `LOAN_LIMIT_REACHED`, `OVERDUE_LOAN_PENDING`, `STUDENT_BLOCKED`, `CONCURRENT_MODIFICATION`) y 500 `INTERNAL_ERROR`. La espera de bloqueo es de 5 s; al agotarse, 409 `CONCURRENT_MODIFICATION`.
- Contrato: anotaciones springdoc (`@Tag`, `@Operation`, un `@ApiResponse` por estado, `@Schema` con ejemplo en cada record); regenerar `docs/api/openapi.yaml` con `./mvnw verify -Pintegration -Dopenapi.update=true`; actualizar la sección 4 del README si cambia el contrato y el diagrama `secuencia-solicitar-prestamo` si cambia el flujo.

**Criterios de aceptación** (los 16 escenarios de HU-04 de la sección 5)
- 201 con el cuerpo de la sección 4: el préstamo queda en SOLICITADO, con sus ítems y la fila de historial `NULL → SOLICITADO`; se acepta un rango de 7 días y el inicio el mismo día.
- 400 `VALIDATION_ERROR` con los mensajes exactos para rango de 8 días, fin anterior al inicio, inicio en el pasado y cantidad 0; no se persiste nada.
- 409 `INSUFFICIENT_UNITS` con el detalle por equipo si falta stock, y con varios equipos no se crea ninguna parte.
- 409 `EQUIPMENT_UNAVAILABLE` para un equipo en mantenimiento, dado de baja o inexistente.
- Con 2 préstamos en curso se crea el tercero; con 3 (por ejemplo 1 SOLICITADO, 1 APROBADO y 1 ENTREGADO) el cuarto responde 409 `LOAN_LIMIT_REACHED`; un DEVUELTO, RECHAZADO o CANCELADO libera cupo.
- Dos envíos simultáneos del mismo estudiante con 2 préstamos en curso crean solo uno (se serializan por el bloqueo de `users`).
- Dos estudiantes que piden la última unidad al mismo tiempo pueden quedar ambos en SOLICITADO: la solicitud no retiene unidades y la competencia se resuelve al aprobar.
- Una cuenta dada de baja mientras la solicitud esperaba el bloqueo recibe 401 `SESSION_INVALIDATED` y no se crea nada.
- 403 "Acceso denegado" si el rol no es ESTUDIANTE.

**Pruebas:** `LoanServiceTest` (feliz, rango límite de 7 días, sin stock, varios equipos con uno sin stock, equipo no disponible, límite de 3 con SOLICITADO incluidas, vencido sin devolver, cuenta inactiva en el snapshot); `LoanControllerIT` (MockMvc + Testcontainers: 201, 400, 401 con sesión inválida en una petición de escritura, 403, 409 con `code` y `requestId`); `LoanConcurrencyIT` (dos envíos del mismo estudiante; dos estudiantes por la última unidad); `ArchitectureTest` (sin dependencias a repositorios ajenos); `OpenApiContractIT` (contrato versionado al día); cobertura de `LoanService` ≥ 80 %.

**Definition of Done:** pruebas unitarias, de integración, de arquitectura y de contrato en verde; `docs/api/openapi.yaml` regenerado; sección 4 y diagramas al día; sin `console`/`System.out`, logs con SLF4J; PR revisado por `code-reviewer`; commit `feat(PLAB-<n>): ...`.

**Ticket 3**

| Campo | Detalle |
|---|---|
| Clave / Tipo | <!-- COMPLETAR clave PLAB-n --> · Subtarea **[FRONT]** |
| Título | Pantalla de solicitud de préstamo |
| Historia padre | HU-04 Solicitud de préstamo |
| Prioridad / Estimación | Alta · <!-- COMPLETAR estimación --> |
| Dependencias | Ticket [BACK] (Ticket 2); HU-03 (catálogo con disponibilidad, `GET /api/equipment`); HU-01b (sesión y guards) |
| Rama | `feature/PLAB-<n>-solicitud-ui` <!-- COMPLETAR clave --> |
| Responsable IA | Subagente `frontend-developer`; pruebas E2E con `qa-tester` |

**Descripción.** Permitir que el estudiante arme su solicitud desde el catálogo (equipos y cantidades), elija el rango de fechas, revise el resumen y la envíe, viendo claramente por qué una solicitud no puede crearse.

**Detalle técnico** (Angular standalone, signals, formularios reactivos, TypeScript estricto)
- `features/loans/`: `loan-cart.store.ts` (signals con los equipos y cantidades elegidos), `loan-request.component.ts` (`OnPush`: resumen, rango de fechas y cantidades), `loan.service.ts` (`POST ${environment.apiUrl}/loans` mediante `ApiClient`; `apiUrl = '/api'`, sin URLs en duro) y `loan.model.ts` (interfaces `LoanRequest`, `LoanResponse` y `LoanItem` que reflejan los DTO del contrato; sin `any`).
- Selector de rango de `shared/` con las mismas reglas que el backend: fin no anterior al inicio, inicio no anterior a hoy (se permite hoy) y máximo 7 días contando ambos extremos. Mensajes: "La fecha fin no puede ser anterior a la fecha inicio", "La fecha de inicio no puede ser anterior a hoy", "El rango máximo es de 7 días", "La cantidad debe ser al menos 1". Los mensajes aparecen antes de enviar; el backend sigue siendo la barrera.
- Cantidad entre 1 y las unidades disponibles que muestra el catálogo (`availableUnits`), recalculadas al cambiar el rango. Los equipos "No disponible" no se pueden agregar.
- Elegibilidad: al abrir la pantalla consulta `GET /api/loans/mine/eligibility` y avisa si ya tiene 3 préstamos en curso, está bloqueado hasta una fecha o tiene un préstamo vencido sin devolver; el backend vuelve a validar.
- Estados de la pantalla: cargando (botón deshabilitado con indicador, evita doble envío), éxito (mensaje "Solicitud enviada" y navegación a "Mis préstamos", donde se ve SOLICITADO), error. Manejo por `code` (el `errorInterceptor` muestra `detail` tal cual): 409 `INSUFFICIENT_UNITS` marca los ítems de `items[]` y permite ajustar la cantidad; 409 `EQUIPMENT_UNAVAILABLE`, `LOAN_LIMIT_REACHED`, `OVERDUE_LOAN_PENDING` y `STUDENT_BLOCKED` muestran el mensaje exacto; 400 muestra `errors[]` junto a cada campo; 500 muestra el código de referencia (`requestId`).
- Sesión: ante 401 `SESSION_INVALIDATED`, `SESSION_REPLACED` o `SESSION_EXPIRED` (también en una consulta, p. ej. al abrir el catálogo) el `authInterceptor` ya limpia la sesión y lleva a `/login?returnUrl=...` con el texto recibido; la pantalla no añade lógica propia.
- Ruta `/prestamos/solicitar` con carga perezosa, protegida por `authGuard` y `roleGuard(['ESTUDIANTE'])`. Archivos en kebab-case, sin `console.log`.
- Accesibilidad: etiquetas asociadas a cada control, foco al primer error, mensajes con `role="alert"`.
- `data-testid` en los controles clave: `loan-start-date`, `loan-end-date`, `loan-item-qty`, `loan-submit`, `loan-error`.

**Criterios de aceptación**
- El estudiante completa y envía la solicitud solo con teclado y con lector de pantalla; el envío correcto navega a "Mis préstamos" y la solicitud aparece SOLICITADO.
- Un rango de 8 días, una fecha fin anterior al inicio, una fecha de inicio pasada y una cantidad 0 muestran su mensaje exacto antes de enviar y no llaman a la API.
- Un 409 `INSUFFICIENT_UNITS` marca el equipo afectado con lo disponible y deja ajustar la cantidad sin perder el resto del formulario.
- El botón de envío se deshabilita mientras la petición está en curso (sin solicitudes duplicadas).
- Un estudiante con sesión inválida es llevado al inicio de sesión con el mensaje del servidor; un ENCARGADO o ADMIN no accede a la ruta (redirección o "Acceso denegado").
- Todas las URLs salen de `environment.apiUrl`; lint, convenciones (kebab-case, sin `any`, sin `console.log`) y hooks sin errores.

**Pruebas:** `loan.service.spec.ts` (cuerpo y URL de `POST /api/loans`, mapeo de errores 400 y 409), `loan-cart.store.spec.ts`, `loan-request.component.spec.ts` (validaciones de rango y cantidad) y E2E Playwright headless `e2e/tests/solicitar-prestamo.spec.ts` con `test.use({ funcionalidad: 'solicitar-prestamo' })` y `await evidence('<paso>')` por escenario de HU-04 (solicitud correcta, unidades insuficientes, rangos inválidos, equipo no disponible, límite de 3), con evidencias en `docs/testing/playwright/solicitar-prestamo/`. <!-- COMPLETAR resultados: el RESULTADO.md se genera al ejecutar las pruebas -->

**Definition of Done:** `npm run lint`, `npm run test -- --watch=false` y `npx playwright test tests/solicitar-prestamo.spec.ts` en verde; evidencias y `RESULTADO.md` generados; PR revisado por `code-reviewer`; commit `feat(PLAB-<n>): ...`.

---

## 7. Pull Requests

El primer Pull Request es el de la Entrega 1 (estructura del proyecto, harness y definición del producto) y ya está abierto. Los tres siguientes corresponden a los tickets de la historia HU-04 y todavía no existen: son plantillas. Al crear cada PR se reemplaza el marcador por el enlace real y los resultados verificados. No se inventan enlaces, números ni resultados.

**Pull Request 1 · Entrega 1: estructura del proyecto, harness y definición del producto**

| Campo | Detalle |
|---|---|
| Título | `Entrega 1: estructura del proyecto, harness y definición del producto` |
| Enlace | [ai4devs-repo/AI4Devs-finalproject#1](https://github.com/ai4devs-repo/AI4Devs-finalproject/pull/1) |
| Rama | `feature/entrega-1-AFRC` → `main` |
| Ticket | PLAB-1 (épica «[E0] Fundación técnica») |
| Estado | Abierto (2026-11-08) |

- **Descripción:** estructura del monorepo, harness de Claude Code (9 subagentes, 14 skills, 8 hooks, servidores MCP y `CLAUDE.md`), 23 historias de usuario (11 Must y 12 Should), ADR de arquitectura, modelo de datos MySQL en tercera forma normal, 15 diagramas, contrato OpenAPI de diseño, README completado, plan de tickets creado en Jira y registro de prompts. No incluye código de aplicación.
- **Pruebas y resultados:** validación del OpenAPI con `swagger-cli`, renderizado de los diagramas con `mermaid-cli` y prueba del DDL en un MySQL 8.0 desechable (reportados por los agentes que los ejecutaron); revisiones aprobadas de las historias (`us-reviewer`) y de la tabla de tickets (`arquitecto-sw`). Las pruebas unitarias, de integración y E2E no se ejecutaron porque aún no hay código. El detalle está en la descripción del PR.
- **Revisión IA:** `us-reviewer` (15 rondas sobre las historias) y `arquitecto-sw` (revisiones del ADR y de la tabla de tickets). `code-reviewer` no se ejecutó, porque el PR no contiene código.

**Pull Request previsto 1 (Ticket 1 [DB])**

| Campo | Detalle |
|---|---|
| Título | `feat(PLAB-<n>): esquema de préstamos y entidades JPA` |
| Enlace | <!-- COMPLETAR enlace del PR y resultados --> |
| Rama | `feature/PLAB-<n>-esquema-prestamos` → <!-- COMPLETAR rama de la entrega --> |
| Ticket | Ticket 1 [DB] |

- **Descripción:** migraciones Flyway de `loans`, `loan_items` y `loan_status_history`, entidades JPA y consultas de conteo en curso y unidades retenidas; diagrama ER y sección 3 actualizados.
- **Checklist:**
  - [ ] Migraciones nuevas y sin editar las ya aplicadas; sin `DELETE`, `TRUNCATE` ni `DROP`.
  - [ ] Llaves foráneas, `CHECK` e índices con los nombres de la sección 3 (`fk_loans_student`, `fk_loans_approved_by`, `idx_loans_student_status_start`, etc.).
  - [ ] `ddl-auto: validate` sin diferencias; sin `@SQLRestriction`.
  - [ ] `LoanSchemaIT` y `LoanRepositoryIT` en verde.
  - [ ] `docs/diagrams/modelo-datos.mmd` y `.png` regenerados; sección 3 al día.
  - [ ] Revisión de `code-reviewer`.
- **Pruebas y resultados:** <!-- COMPLETAR enlace del PR y resultados -->
- **Revisión IA:** <!-- COMPLETAR hallazgos de code-reviewer y cómo se resolvieron -->
- **Estado:** <!-- COMPLETAR (abierto / merged / fecha) -->

**Pull Request previsto 2 (Ticket 2 [BACK])**

| Campo | Detalle |
|---|---|
| Título | `feat(PLAB-<n>): crear solicitud de préstamo con límite y validación de disponibilidad` |
| Enlace | <!-- COMPLETAR enlace del PR y resultados --> |
| Rama | `feature/PLAB-<n>-crear-prestamo-api` → <!-- COMPLETAR rama de la entrega --> |
| Ticket | Ticket 2 [BACK] |

- **Descripción:** `POST /api/loans` con `LoanController`, `LoanService`, DTO, `LoanMapper`, errores `ProblemDetail`, límite de 3, bloqueo de la fila del estudiante y `FOR SHARE` de los equipos; OpenAPI regenerado.
- **Checklist:**
  - [ ] 201 con `Location`; 400 `VALIDATION_ERROR` (incluido el rango de más de 7 días), 401 (cuenta y sesión), 403 y 409 con `code` y `requestId`.
  - [ ] La solicitud no retiene unidades; sin `PESSIMISTIC_WRITE` sobre equipos.
  - [ ] Fronteras de módulos respetadas por `api` (`ArchitectureTest`).
  - [ ] `docs/api/openapi.yaml` regenerado y `OpenApiContractIT` en verde; sección 4 del README y diagramas al día.
  - [ ] Matriz de trazabilidad de los 16 escenarios de HU-04 completada: <!-- COMPLETAR escenario → prueba, una vez escritas las pruebas -->
  - [ ] Revisión de `code-reviewer`.
- **Pruebas y resultados:** <!-- COMPLETAR enlace del PR y resultados -->
- **Revisión IA:** <!-- COMPLETAR hallazgos de code-reviewer y cómo se resolvieron -->
- **Estado:** <!-- COMPLETAR (abierto / merged / fecha) -->

**Pull Request previsto 3 (Ticket 3 [FRONT])**

| Campo | Detalle |
|---|---|
| Título | `feat(PLAB-<n>): pantalla de solicitud de préstamo` |
| Enlace | <!-- COMPLETAR enlace del PR y resultados --> |
| Rama | `feature/PLAB-<n>-solicitud-ui` → <!-- COMPLETAR rama de la entrega --> |
| Ticket | Ticket 3 [FRONT] |

- **Descripción:** carrito con signals, formulario reactivo de solicitud, manejo de errores por `code`, ruta protegida con `authGuard` y `roleGuard`.
- **Checklist:**
  - [ ] Validaciones de rango y cantidad con los mensajes exactos; URLs vía `environment.apiUrl`.
  - [ ] Manejo de 409 `INSUFFICIENT_UNITS` con `items[]` y de los demás códigos de la solicitud.
  - [ ] Accesibilidad: etiquetas, foco en el error y navegación por teclado.
  - [ ] `npm run lint` y pruebas unitarias en verde; kebab-case, sin `any`, sin `console.log`.
  - [ ] E2E `solicitar-prestamo.spec.ts` headless con evidencias en `docs/testing/playwright/solicitar-prestamo/`.
  - [ ] Revisión de `code-reviewer`.
- **Pruebas y resultados:** <!-- COMPLETAR enlace del PR y resultados -->
- **Revisión IA:** <!-- COMPLETAR hallazgos de code-reviewer y cómo se resolvieron -->
- **Estado:** <!-- COMPLETAR (abierto / merged / fecha) -->

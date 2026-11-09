# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

# PrestaLab

Sistema web de préstamo de equipos y recursos académicos (laboratorios, audiovisuales, biblioteca).
Proyecto final del curso de Ingeniería de Software con IA. Autor: AFRC. Jira: proyecto **PLAB**.

## Stack
- **Backend:** Java 21, Spring Boot, Spring Data JPA, Spring Security (JWT), Flyway, springdoc-openapi, MapStruct. Maven.
- **Frontend:** Angular (standalone, signals, formularios reactivos), TypeScript estricto.
- **Base de datos:** MySQL 8. Local con Docker; producción en Aiven (plan gratuito, SSL obligatorio).
- **Pruebas:** JUnit 5, Mockito, Testcontainers (MySQL), Playwright headless (E2E y MCP) con evidencias en `docs/testing/playwright/<funcionalidad>/`.
- **Documentación:** README.md y PROMPTS.md con la plantilla del curso; diagramas Mermaid en `docs/diagrams/` (MCP de Mermaid).
- **Despliegue:** Vercel con contenedores (`Dockerfile.vercel` en `frontend/` y `backend/`), `/api/*` enrutado al backend.

## Estructura del monorepo
- `backend/` API REST, monolito modular (`co.prestalab.<modulo>`: controller, service, repository, dto, mapper, entity, y también `api/`, `domain/`, `exception/`, `event/`, `job/`). Módulos: `shared`, `auth`, `catalog`, `loans` (incluye sanciones), `notifications`, `reports`. Definición en `docs/adr/0001-arquitectura.md`.
- `frontend/` Angular (`core/`, `shared/`, `features/<modulo>/`)
- `e2e/` Playwright (tests, pages, `support/evidence.ts`)
- `docs/` `diagrams/` (.mmd y .png), `testing/playwright/<funcionalidad>/` (evidencias), `plans/`, `adr/`, `ai-log/`
- `.claude/` hooks, skills y subagentes

## Comandos
- Levantar todo local: `docker compose up -d --build` (MySQL 3306, API 8080, web 4200)
- Backend: `cd backend && ./mvnw spring-boot:run` | pruebas `./mvnw test` | una clase `./mvnw test -Dtest=NombreTest` | integración `./mvnw verify -Pintegration`
- Frontend: `cd frontend && npm start` | `npm run lint` | `npm run test -- --watch=false` | un spec `npm run test -- --watch=false --include=<ruta>.spec.ts`
- E2E: `cd e2e && npx playwright test` (un archivo: `npx playwright test tests/<archivo>.spec.ts`). Siempre headless; nunca `--headed`, `--ui` ni `codegen`.
- Verificación completa: `/verificar-calidad`

## Convenciones (los hooks las validan)
- Código e identificadores en inglés; textos de UI, documentación y commits en español.
- Ramas: `feature/PLAB-<n>-<slug>` desde la rama de la entrega activa (`feature/entrega-1-AFRC`, `feature/entrega-2-AFRC`, `final-project-AFRC`).
- Commits: Conventional Commits con la clave Jira: `feat(PLAB-12): agrega solicitud de préstamo`.
- REST bajo `/api/...`; DTOs `*Request`/`*Response` (records); errores con `ProblemDetail`.
- Todo contrato REST se documenta con OpenAPI (springdoc) y es consultable bajo `/api/docs`. Ante cualquier cambio de contrato se actualiza el OpenAPI y, si aplica, los diagramas (`docs/diagrams/`) y la sección 4 del readme.
- Backend: Spring Boot 3.5.x sobre Java 21. Zona horaria única `America/Bogota` (`prestalab.time-zone`, reloj `Clock` inyectable).
- Categorías solo por semillas, sin endpoint de gestión. `GET /api/equipment` (búsqueda con disponibilidad) lo usan los tres roles; `GET /api/equipment/inventory` solo ENCARGADO y ADMIN.
- El detalle de un préstamo ajeno responde 404 a un ESTUDIANTE; cancelar uno ajeno responde 403 "Acceso denegado".
- Autenticación: access token JWT de 15 min y refresh token revocable de 30 min deslizantes; vida máxima de sesión de 1 hora para ESTUDIANTE y 8 horas para ENCARGADO. Una sola sesión activa por usuario: al iniciar sesión estando ya activa en otro lugar se ofrece cerrar la otra, y un ADMIN puede cerrar la sesión de otra cuenta. Tras 3 intentos fallidos de inicio de sesión la cuenta se bloquea temporalmente (15 min), y cada origen de conexión admite como máximo 10 intentos fallidos cada 15 minutos. Una cuenta dada de baja no mantiene acceso: sus tokens expiran o se revocan. Solo hay baja de cuentas (ADMIN, nunca a sí mismo ni al último ADMIN activo; no si el titular tiene préstamos en curso: SOLICITADO, APROBADO, ENTREGADO o VENCIDO), sin cambio de roles. Sesión del ADMIN: 8 horas. Ningún mensaje de inicio de sesión o bloqueo revela si un correo existe ni qué dato es incorrecto: credenciales incorrectas, cuenta inexistente, dada de baja o bloqueada devuelven el mismo mensaje genérico. Todas las peticiones autenticadas, de cualquier rol y también las lecturas, comprueban que la cuenta esté activa y la sesión vigente (corte inmediato tras una baja o un cierre administrativo).
- El contrato OpenAPI se versiona en `docs/api/openapi.yaml`.
- Inyección por constructor; logs con SLF4J.
- **Borrado lógico siempre** (`deleted_at`). Prohibido `DELETE FROM`, `TRUNCATE`, `DROP`.
- Angular: archivos kebab-case, sin `any`, sin `console.log`, URLs vía `environment.apiUrl`.
- E2E: importar desde `e2e/support/evidence`, declarar `test.use({ funcionalidad })` y registrar `await evidence('<paso>')` por criterio.

## Seguridad
- No leer ni editar `.env*` (excepto `.env.example`). Los secretos viven en variables de entorno de Vercel.
- No hacer push a `main`, ni `--force`, ni `--no-verify`.
- No editar la sección final "Registro automático de prompts" de PROMPTS.md: la escribe el hook `scan-and-log-prompt.sh` con cada prompt (incluido `/init`) y bloquea prompts con secretos.

## Flujo de trabajo
- Por historia: `/implementar-historia PLAB-<n>` (lee Jira, crea rama, delega a subagentes, verifica, PR, actualiza Jira).
- Subagentes: `database-engineer` (opus), `backend-developer` (sonnet), `frontend-developer` (sonnet), `qa-tester` (sonnet), `code-reviewer` (opus, solo lectura), `docs-writer` (sonnet + MCP Mermaid).
- Commits: `/hacer-commit [PLAB-n]` (solo bajo petición del usuario; nunca hace push; prepara la descripción del PR con `.github/pull_request_template.md` y, si el usuario confirma, invoca `/crear-pr`). Pull Request: `/crear-pr [base] [PLAB-n]` (publica la rama con confirmación y abre el PR con la plantilla; nunca a `main` directo).
- Diagramas: `/generar-diagramas [nombre]`. Documentación: `/actualizar-documentacion [sección]`.
- Al cerrar una tarea con IA relevante: `/registrar-prompt <seccion> <tema>` (secciones 1 a 7 de PROMPTS.md, ej. `2.5 login`).

## Dominio
- Roles: ESTUDIANTE, ENCARGADO, ADMIN.
- Estados de préstamo: SOLICITADO -> APROBADO | RECHAZADO; APROBADO -> ENTREGADO -> DEVUELTO; ENTREGADO -> VENCIDO (si pasa la fecha fin); VENCIDO -> DEVUELTO; APROBADO -> RECHAZADO ("No recogido", automático) si no se recoge en el plazo de 2 horas de servicio contadas desde el inicio del servicio del primer día (o desde la aprobación si es tardía). Horario de servicio y de aprobaciones: 8:00 AM a 5:00 PM. Un préstamo APROBADO no se rechaza manualmente.
- Disponibilidad de un equipo en un rango = unidades totales - unidades en préstamos APROBADO/ENTREGADO que se cruzan con el rango. Un préstamo ENTREGADO o VENCIDO retiene sus unidades hasta que se devuelve (aunque la fecha fin ya haya pasado). Un APROBADO retiene hasta el día en que vence su plazo de recogida o su fecha fin, el que sea posterior (rango efectivo de retención).
- Si un préstamo se entrega después de su fecha fin (dentro del plazo de recogida), la fecha fin efectiva es el día de la entrega: debe devolverse ese día o pasa a VENCIDO en la revisión de las 00:05. Una SOLICITADO cuyo día de inicio pasa sin resolverse se rechaza sola ("Sin resolver a tiempo"). Excepción: un préstamo de 1 día aprobado después de las 3:00 PM tiene plazo hasta las 10:00 AM del día siguiente.
- Un estudiante puede tener como máximo 3 préstamos en curso. Las solicitudes SOLICITADO cuentan en el límite. El estudiante puede cancelar antes de la entrega (SOLICITADO -> CANCELADO, APROBADO -> CANCELADO); sin motivo queda "Cancelado por usuario". El plazo de recogida puede sobrepasar la fecha fin (p. ej. aprobación de un préstamo de 1 día después de las 3:00 PM: plazo hasta las 10:00 AM del día siguiente).
- Un estudiante con un préstamo VENCIDO sin devolver no puede crear solicitudes. El estudiante que solicita es quien tiene el préstamo.
- Detalle y reglas de negocio: `docs/historias-de-usuario.md`.

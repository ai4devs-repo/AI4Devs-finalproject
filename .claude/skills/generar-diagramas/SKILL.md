---
name: generar-diagramas
description: Genera o actualiza los diagramas Mermaid del proyecto (arquitectura, componentes, secuencia, modelo de datos e infraestructura) a partir del código, los valida y renderiza con el MCP de Mermaid y los incrusta en el README. Úsala cuando cambie la arquitectura, un flujo o el esquema, o antes de cada entrega.
argument-hint: "[todos|arquitectura|componentes|secuencia|modelo-datos|infraestructura]"
context: fork
agent: docs-writer
---
 
# Generar diagramas: $ARGUMENTS
 
Si `$ARGUMENTS` está vacío, genera todos.
 
| Diagrama | Tipo Mermaid | Fuente de verdad | Archivo | Sección del README |
|---|---|---|---|---|
| arquitectura | `flowchart LR` | `vercel.json`, Dockerfiles, `application-prod.yml` | `docs/diagrams/arquitectura.mmd` | 2.1 |
| componentes | `flowchart TB` con subgraphs | Paquetes de `backend/src/main/java/co/prestalab/` y `frontend/src/app/` | `docs/diagrams/componentes.mmd` | 2.2 |
| secuencia-login | `sequenceDiagram` | `AuthController`, `SecurityConfig`, interceptor Angular | `docs/diagrams/secuencia-login.mmd` | 4 |
| secuencia-solicitar-prestamo | `sequenceDiagram` | `LoanController#create`, `LoanService` | `docs/diagrams/secuencia-solicitar-prestamo.mmd` | 4 |
| secuencia-ciclo-prestamo | `sequenceDiagram` | `LoanController#changeStatus` y la máquina de estados | `docs/diagrams/secuencia-ciclo-prestamo.mmd` | 4 |
| modulos-backend | `flowchart LR` | ADR 0001 (1.3, 1.4), paquetes `api` de `backend/src/main/java/co/prestalab/` | `docs/diagrams/modulos-backend.mmd` | 2.2 |
| secuencia-peticion | `sequenceDiagram` | `RequestTraceFilter`, `SecurityConfig`, `GlobalExceptionHandler` | `docs/diagrams/secuencia-peticion.mmd` | 2.2 |
| secuencia-sesion-refresh | `sequenceDiagram` | `AuthController#refresh` y `#logout`, `RefreshTokenService`, `authInterceptor` | `docs/diagrams/secuencia-sesion-refresh.mmd` | 4 |
| secuencia-sesion-unica | `sequenceDiagram` | `RefreshTokenService`, `ActiveSessionInterceptor`, índice `uk_refresh_tokens_active_user` | `docs/diagrams/secuencia-sesion-unica.mmd` | 4 |
| secuencia-baja-cuenta | `sequenceDiagram` | `UserController#deactivate`, `UserAccountService`, `UserDeactivationHandler` | `docs/diagrams/secuencia-baja-cuenta.mmd` | 2.5 y 4 |
| secuencia-aprobar-prestamo | `sequenceDiagram` | `LoanController#approve`, `LoanService`, `LoanTransitionService` | `docs/diagrams/secuencia-aprobar-prestamo.mmd` | 4 |
| secuencia-cancelar-prestamo | `sequenceDiagram` | `LoanController#cancel`, `LoanService` | `docs/diagrams/secuencia-cancelar-prestamo.mmd` | 4 |
| secuencia-tareas-programadas | `sequenceDiagram` | `PickupExpirationJob`, `DailyLoanReviewJob`, `DueSoonAlertJob`, `InternalJobController` | `docs/diagrams/secuencia-tareas-programadas.mmd` | 4 |
| modelo-datos | `erDiagram` | Migraciones Flyway | `docs/diagrams/modelo-datos.mmd` | 3.1 |
| infraestructura | `flowchart TB` | `.github/workflows/ci.yml`, `vercel.json` | `docs/diagrams/infraestructura.mmd` | 2.4 |
 
## Pasos
1. Lee la fuente de verdad de cada diagrama. Si el código aún no existe (Entrega 1), usa el diseño del README y márcalo como "diseño" en el título del diagrama.
2. Escribe o actualiza el `.mmd`.
3. Renderiza con el MCP de Mermaid (salida a archivo PNG o SVG local) y guarda `docs/diagrams/<nombre>.png`. Si hay error de sintaxis, corrige y repite.
4. Reemplaza el bloque ```mermaid correspondiente en el README con el contenido del `.mmd` y deja un enlace a la imagen.
5. Devuelve una tabla: diagrama | cambió (sí/no) | qué cambió.

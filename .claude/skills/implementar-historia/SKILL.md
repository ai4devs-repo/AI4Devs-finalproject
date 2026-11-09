---
name: implementar-historia
description: Implementa de punta a punta una historia de usuario de Jira (leer el ticket, crear la rama, implementar con subagentes, verificar, abrir PR y actualizar Jira). Úsala cuando el usuario pida implementar, desarrollar o trabajar un ticket como PLAB-12.
argument-hint: "[CLAVE-JIRA]"
disable-model-invocation: true
allowed-tools: Bash(git *) Bash(gh pr *) Bash(./mvnw *) Bash(npm run *) Bash(npx playwright *)
---
 
# Implementar historia $ARGUMENTS
 
## Contexto al iniciar
- Rama actual: !`git branch --show-current`
- Cambios pendientes: !`git status --short`
 
## 0. Validar la entrada
Si `$ARGUMENTS` no tiene el formato `PLAB-<número>`, detente y pide la clave del ticket.
Si hay cambios sin commit, pregunta si se guardan (commit o stash) antes de seguir.
 
## 1. Leer de Jira
1. Con el MCP de Atlassian obtén el issue `$ARGUMENTS`: resumen, descripción, criterios de aceptación, subtareas, prioridad (MUST/SHOULD), épica y enlaces.
2. Revisa la Definition of Ready con [checklist-dor.md](checklist-dor.md). Si algo falta, lístalo y pregunta antes de continuar.
3. Reescribe la historia como "Como / Quiero / Para" y numera los criterios en Gherkin (CA1..CAn).
4. Mueve el issue a **En curso** y asígnalo al usuario actual.
 
## 2. Crear la rama
1. La base es la rama de la entrega activa (`feature/entrega-2-AFRC` o `final-project-AFRC`). Si no estás en ella, pregunta cuál usar.
2. `git pull` sobre la base y crea `feature/$ARGUMENTS-<slug>` (slug en kebab-case con el resumen, máximo 40 caracteres).
 
## 3. Planificar
Escribe `docs/plans/$ARGUMENTS.md` con: capas afectadas (DB, back, front), endpoints (método, ruta, request, response, errores), componentes y rutas Angular, y una prueba por cada criterio. Muestra el plan y espera la confirmación del usuario.
 
## 4. Implementar (en este orden, delegando)
1. Subagente `database-engineer`: migración Flyway y entidades JPA, si aplica.
2. Subagente `backend-developer`: DTOs, servicio, controlador, validaciones y pruebas unitarias.
3. Subagente `frontend-developer`: modelos, servicio HTTP, componentes, rutas y guardias.
Pasa a cada subagente la clave, los criterios y la ruta del plan. Haz commits pequeños: `feat($ARGUMENTS): ...`, `test($ARGUMENTS): ...`.
 
## 5. Verificar
1. Ejecuta `/verificar-calidad` (lint, unitarias, integración, cobertura).
2. Subagente `qa-tester` con `/generar-pruebas-e2e $ARGUMENTS <funcionalidad>`: pruebas de integración del endpoint y E2E headless para cada criterio, con evidencias en `docs/testing/playwright/<funcionalidad>/`.
3. Subagente `code-reviewer`: revisa `git diff <rama-base>...HEAD`. Corrige todo hallazgo **Bloqueante** o **Mayor** y repite la revisión.
4. Construye la matriz de trazabilidad CA -> prueba -> resultado.
 
## 6. Documentar
1. Subagente `docs-writer`: actualiza las secciones del README afectadas (API, modelo de datos, historias, tickets) y ejecuta `/generar-diagramas` para los diagramas que cambiaron (secuencia del flujo, modelo de datos, componentes).
2. Verifica que `docs/testing/playwright/<funcionalidad>/RESULTADO.md` esté enlazado en el PR.
 
## 7. Entregar
1. `git push -u origin <rama>` y crea el PR hacia la rama de entrega con [pr-template.md](pr-template.md).
2. Comenta en Jira el resumen, el enlace al PR y la matriz de trazabilidad; mueve el issue a **En revisión**.
3. Ejecuta `/registrar-prompt 7 $ARGUMENTS` con el prompt más representativo de esta historia y el ajuste humano realizado (y en la sección de la capa principal si aplica, ej. `2.5` para seguridad).
 
## Reglas
- Nunca borres filas físicamente: borrado lógico (`deleted_at`).
- No leas ni edites `.env`. Si necesitas una variable nueva, agrégala a `.env.example` y avisa al usuario.
- Si un mismo paso falla dos veces, detente y reporta qué pasó y qué propones.
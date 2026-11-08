---
name: actualizar-documentacion
description: Actualiza el README del monorepo según la plantilla del curso (secciones 0 a 7) a partir del código, Jira y GitHub. Úsala al cerrar una historia o antes de cada entrega.
argument-hint: "[seccion opcional, ej. 3 o 2.4]"
context: fork
agent: docs-writer
---
 
# Actualizar README
 
Si `$ARGUMENTS` indica una sección, trabaja solo en ella. Respeta los títulos e índice de la plantilla; no agregues ni renombres secciones.
 
| Sección | Fuente de verdad | Qué actualizar |
|---|---|---|
| 0 Ficha | Usuario, Vercel, GitHub | URL de producción y del repositorio (pregunta si faltan). |
| 1.2 Funcionalidades | Jira (MCP Atlassian) | Tabla MUST / SHOULD coherente con las historias. |
| 1.3 UX | `docs/testing/playwright/<funcionalidad>/` | Tabla de pasos con enlace al `RESULTADO.md` de cada funcionalidad y al video. |
| 1.4 Instalación | `docker-compose.yml`, `pom.xml`, `package.json` | Requisitos, comandos y semillas que realmente funcionan. |
| 2.1 / 2.2 / 2.4 / 4 Diagramas | `docs/diagrams/*.mmd` | Arquitectura, componentes, infraestructura y secuencia: ejecuta `/generar-diagramas` y copia las fuentes al README. |
| 2.2 Componentes | `pom.xml`, `package.json` | Tecnologías y versiones reales. |
| 2.3 Estructura | Árbol del repositorio (3 niveles) | Carpetas y propósito. |
| 2.5 Seguridad | `SecurityConfig`, hooks, `settings.json` | Prácticas implementadas con un ejemplo. |
| 2.6 Tests | Pruebas, reportes y `docs/testing/playwright/README.md` | Ejemplos reales de cada tipo, cobertura y enlace a las evidencias E2E. |
| 3 Modelo de datos | Migraciones Flyway | `erDiagram` con PK, FK, UK y restricciones; tabla por entidad. |
| 4 API | `http://localhost:8080/v3/api-docs` | Máximo 3 endpoints en OpenAPI con ejemplos reales. |
| 5 Historias | Jira | 3 historias principales con criterios Gherkin. |
| 6 Tickets | Jira | 3 tickets: uno [BACK], uno [FRONT] y uno [DB], con todo el detalle. |
| 7 Pull requests | GitHub (`gh pr view`) | 3 PR con enlace, rama, ticket, cambios, pruebas y revisión. |
 
## Pasos
1. Lee la fuente de verdad de cada sección afectada.
2. Valida: el YAML de la sección 4 debe parsear, los bloques Mermaid deben tener sintaxis válida y los enlaces del índice deben funcionar.
3. Busca marcadores `<!-- COMPLETAR -->` y `_Completar_` y lista los que siguen pendientes.
4. Muestra el diff antes de guardar y haz commit `docs(PLAB-n): actualiza README`.

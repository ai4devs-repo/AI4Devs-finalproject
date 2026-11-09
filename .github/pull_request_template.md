## Objetivo del cambio

<!-- Qué problema resuelve o qué valor aporta. Una o dos frases. Enlaza el ticket de Jira (PLAB-n). -->

Ticket: PLAB-<n>

## Qué se hizo

<!-- Resumen de los cambios, agrupados por área (backend, frontend, base de datos, documentación, pruebas). -->

-

## Cómo se probó

<!-- Pasos y comandos ejecutados, y los escenarios cubiertos (criterios de aceptación o historia). -->

-

## Resultados de las pruebas

<!-- Resultado real de lo ejecutado: pruebas que pasaron o fallaron, cobertura, evidencias (docs/testing/playwright/...). Si algo no se ejecutó, dilo y explica por qué. No inventes resultados. -->

| Prueba | Comando | Resultado |
|---|---|---|
|  |  |  |

## Lista de verificación

- [ ] Los cambios de esquema están en migraciones Flyway (`V<n>__nombre.sql`).
- [ ] Si cambió un contrato, se actualizó `docs/api/openapi.yaml` y, si aplica, los diagramas y la sección 4 del readme.
- [ ] No se incluyen secretos ni archivos `.env*` (salvo `.env.example`).
- [ ] Commits en formato Conventional Commits con la clave Jira.

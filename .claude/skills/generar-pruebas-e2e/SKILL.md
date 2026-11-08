---
name: generar-pruebas-e2e
description: Genera pruebas E2E con Playwright (headless) a partir de los criterios de aceptación de una historia, explorando la aplicación con el MCP de Playwright, y deja evidencias en docs/testing/playwright/<funcionalidad>/. Úsala cuando se pida crear o actualizar pruebas end-to-end.
argument-hint: "[CLAVE-JIRA] [funcionalidad-kebab-case]"
context: fork
agent: qa-tester
---
 
# Pruebas E2E para $0 (funcionalidad: $1)
 
Si no recibes `$1`, deriva la funcionalidad del título de la historia en kebab-case (ej. `solicitar-prestamo`).
 
1. Lee los criterios de `$0` en `docs/plans/$0.md` (o pídelos si no existen).
2. Con la app local arriba (`docker compose up -d --build`, `http://localhost:4200`, o la URL de `E2E_BASE_URL`), usa el MCP de Playwright (headless) para recorrer cada criterio como un usuario y anota selectores estables (`getByRole`, `getByLabel`, `data-testid`).
3. Escribe `e2e/tests/$1.spec.ts`:
   - `import { test, expect } from '../support/evidence';` y `test.use({ funcionalidad: '$1' });`
   - Un `test()` por criterio, con el nombre "CAn - <descripción>".
   - `await evidence('<paso>')` tras cada acción relevante y después del `expect` que verifica el criterio.
   - Page Objects en `e2e/pages/`; datos de prueba propios creados vía API en `beforeAll`.
   - Sin `waitForTimeout` ni `headless: false`.
4. Ejecuta `cd e2e && npx playwright test tests/$1.spec.ts` (headless) hasta que todo pase.
5. Revisa `docs/testing/playwright/$1/RESULTADO.md`: cada criterio debe tener al menos una captura que muestre el resultado esperado. Si una captura no lo demuestra (pantalla en blanco, cargando), mueve el `evidence()` después de la espera correcta.
6. Devuelve la matriz CA -> test -> resultado -> ruta de la captura.

---
name: verificar-calidad
description: Ejecuta la batería completa de verificación del monorepo (lint, unitarias, integración, E2E y cobertura) y entrega un resumen con lo que falló. Úsala antes de abrir un PR o cuando el usuario pida verificar, probar o validar.
allowed-tools: Bash(./mvnw *) Bash(npm run *) Bash(npx playwright *) Bash(docker compose *)
---
 
# Verificar calidad
 
Ejecuta en orden y detente en el primer bloque que falle (muestra las últimas 40 líneas del error):
 
1. **Backend - estilo y unitarias:** `cd backend && ./mvnw -q spotless:check checkstyle:check test`
2. **Backend - integración (Testcontainers MySQL):** `cd backend && ./mvnw -q verify -Pintegration`
3. **Cobertura:** abre `backend/target/site/jacoco/jacoco.csv` y reporta % de líneas en `service/`. Meta >= 80 %.
4. **Frontend - lint y unitarias:** `cd frontend && npm run lint && npm run test -- --watch=false`
5. **E2E (headless):** `docker compose up -d --build` y luego `cd e2e && npx playwright test`. Revisa `docs/testing/playwright/README.md`: cada funcionalidad ejecutada debe tener capturas y estar en verde. Al final `docker compose down`.
 
Entrega un resumen en tabla: bloque | resultado | tiempo | observaciones.
Si algo falla, propone la causa más probable y el arreglo; no lo cambies sin decirlo.

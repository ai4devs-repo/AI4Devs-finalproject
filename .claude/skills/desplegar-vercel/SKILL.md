---
name: desplegar-vercel
description: Despliega el monorepo en Vercel (frontend Angular y backend Spring Boot como contenedores) y valida la URL pública con pruebas de humo. Úsala solo cuando el usuario pida desplegar.
disable-model-invocation: true
allowed-tools: Bash(vercel *) Bash(npx playwright *) Bash(curl *)
---
 
# Desplegar en Vercel
 
## Pre-chequeos
1. Rama actual: debe ser `final-project-AFRC` (producción) o una rama de entrega (preview). Si no, pregunta.
2. `/verificar-calidad` en verde.
3. `vercel env ls` debe mostrar `DB_URL`, `DB_USER`, `DB_PASSWORD`, `JWT_SECRET`, `SPRING_PROFILES_ACTIVE=prod`. No leas sus valores ni los escribas en archivos.
4. Confirma que el servicio MySQL de Aiven está encendido (los planes gratuitos pueden apagarse por inactividad).
 
## Despliegue
- Preview: `vercel deploy`. Producción: `vercel deploy --prod` (pide confirmación antes).
 
## Pruebas de humo sobre la URL desplegada
1. `curl -fsS <url>/api/actuator/health` debe responder `UP` (el primer llamado puede tardar por el arranque en frío).
2. `cd e2e && E2E_BASE_URL=<url> npx playwright test --grep @smoke` (headless). Las capturas quedan en `docs/testing/playwright/<funcionalidad>/`, ahora tomadas contra producción; haz commit `test(smoke): evidencias contra producción`.
3. Guarda la URL en el README (secciones 0.4 y 2.4).

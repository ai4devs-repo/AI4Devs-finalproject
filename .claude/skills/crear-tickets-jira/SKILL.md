---
name: crear-tickets-jira
description: Convierte las historias de usuario de docs/historias-de-usuario.md en épicas, historias y subtareas en Jira (proyecto PLAB). Úsala en la Entrega 1 para generar los tickets de trabajo.
argument-hint: "[ruta-del-archivo-de-historias]"
disable-model-invocation: true
---
 
# Crear tickets en Jira desde las historias
 
Archivo de entrada: `$ARGUMENTS` (si está vacío, usa `docs/historias-de-usuario.md`).
 
1. Lee el archivo y arma una tabla: épica, historia, prioridad (MUST/SHOULD), puntos, criterios, subtareas (DB, Back, Front, Test).
2. Revisa la tabla invocando al subagente `arquitecto-sw` para verificar que se cumpla con la arquitectura definida.
3. Si el veredicto de `arquitecto-sw` es aprobado continua, si no, realiza las correcciones y vuelve a invocar a `arquitecto-sw` para una segunda revision.
4. Muestra la tabla al usuario y espera su aprobación. No crees nada sin confirmación.
5. Con el MCP de Atlassian, en el proyecto PLAB:
   - Crea primero las épicas (una por flujo F1-F4 y una para SHOULD-HAVE).
   - Crea cada historia con descripción "Como / Quiero / Para", criterios en Gherkin, etiqueta `MUST` o `SHOULD` y puntos.
   - Crea las subtareas `[DB]`, `[BACK]`, `[FRONT]`, `[TEST]` bajo cada historia.
6. Devuelve la lista de claves creadas (PLAB-n) y crea un documento en `docs/tickets-trabajo-jira.md` con una tabla clave | título | prioridad | estado.
7. Si una llamada falla, no la repitas a ciegas: informa cuál falló y por qué.

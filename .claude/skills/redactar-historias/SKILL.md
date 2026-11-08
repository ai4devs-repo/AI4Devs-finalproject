---
name: redactar-historias
description: Redacta las historias de usuario de PrestaLab con el subagente product-owner, las hace revisar por us-reviewer y itera hasta que sean aprobadas. Deja el resultado en docs/historias-de-usuario.md. Úsala al definir, ampliar o refinar el backlog de historias.
argument-hint: "[tema o alcance, ej. 'solicitud y aprobación de préstamos']"
---

# Redactar historias

Alcance pedido: $ARGUMENTS (si está vacío, cubre el dominio completo de CLAUDE.md).

Coordinas tú; los subagentes no pueden invocarse entre sí. Máximo 3 rondas.

1. **Redacción:** invoca al subagente `product-owner` con el alcance. Debe crear o actualizar `docs/historias-de-usuario.md` (patrón Como/quiero/para, reglas de negocio, mínimo 3 escenarios Gherkin, orden MoSCoW).
2. **Revisión:** invoca a `us-reviewer` para revisar ese archivo. Pásale solo la ruta, no tu opinión del contenido.
3. **Iteración:** si el veredicto es `CAMBIOS REQUERIDOS`, invoca de nuevo a `product-owner` con la tabla de hallazgos completa para que los corrija y actualice el "Registro de revisión"; luego vuelve al paso 2.
4. **Cierre:** termina cuando `us-reviewer` responde `APROBADO`. Si tras 3 rondas quedan hallazgos bloqueantes, detente y repórtalos al usuario sin aprobar.

Al final informa: número de historias por prioridad MoSCoW, rondas de revisión necesarias, preguntas abiertas pendientes y la ruta del archivo. No edites el archivo tú mismo.

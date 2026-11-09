# Definition of Ready (DoR)
 
Una historia está lista para implementarse cuando:
 
- [ ] Tiene formato "Como <rol> quiero <acción> para <beneficio>".
- [ ] Tiene al menos 2 criterios de aceptación verificables (preferible en Gherkin: Dado / Cuando / Entonces).
- [ ] Tiene prioridad MoSCoW (MUST o SHOULD) y está asociada a una épica.
- [ ] Indica las capas afectadas (front, back, db) o el flujo al que pertenece (F1-F4).
- [ ] No depende de otra historia sin terminar (o la dependencia está enlazada y cerrada).
- [ ] Está estimada en puntos de historia.
 
# Definition of Done (DoD)
 
- [ ] Todos los criterios tienen al menos una prueba automatizada que pasa.
- [ ] Lint, formato y convenciones sin errores (hooks en verde).
- [ ] Cobertura de la capa de servicio >= 80 % (JaCoCo).
- [ ] Revisión del subagente code-reviewer sin hallazgos bloqueantes.
- [ ] README/API actualizados si cambió un endpoint.
- [ ] PR abierto, enlazado en Jira y con evidencias.

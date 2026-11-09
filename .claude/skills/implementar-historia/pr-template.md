## PLAB-XX - <título de la historia>
 
**Jira:** <enlace al ticket>
**Tipo:** feat | fix | test | docs
 
### Qué cambia
- ...
 
### Matriz de trazabilidad
| Criterio | Prueba | Tipo | Resultado |
|---|---|---|---|
| CA1 | LoanServiceTest#rechazaSiNoHayStock | Unitaria | OK |
| CA2 | loan-request.spec.ts "solicita préstamo" | E2E | OK |
 
### Evidencias
- Evidencias E2E (headless): docs/testing/playwright/<funcionalidad>/RESULTADO.md
- Reporte Playwright: e2e/playwright-report/
- Diagramas actualizados: docs/diagrams/<nombre>.mmd
 
### Checklist
- [ ] Hooks de lint y convenciones en verde
- [ ] Pruebas unitarias, integración y E2E en verde
- [ ] Sin DELETE físico, sin cambios a .env
- [ ] Revisión del subagente code-reviewer atendida

---
name: scaffold-feature
description: Genera el esqueleto completo de un recurso (entidad, repositorio, DTOs, mapper, servicio, controlador, pruebas y su servicio y componentes Angular) con las convenciones del proyecto. Úsala al iniciar un CRUD o un módulo nuevo.
argument-hint: "[NombreRecurso] [ruta-api]"
---
 
# Scaffold de $0 en /api/$1
 
## Backend (`backend/src/main/java/co/prestalab/<modulo>/`)
- `entity/$0.java` con borrado lógico (`@SQLDelete`, `@SQLRestriction`).
- `repository/$0Repository.java` (JpaRepository).
- `dto/$0Request.java` y `dto/$0Response.java` como `record`, con Bean Validation.
- `mapper/$0Mapper.java` (MapStruct).
- `service/$0Service.java` con `softDelete(id)` en lugar de borrar.
- `controller/$0Controller.java` con `@RequestMapping("/api/$1")`, códigos HTTP correctos y errores como `ProblemDetail`.
- Pruebas: `$0ServiceTest` (JUnit 5 + Mockito) y `$0ControllerIT` (MockMvc + Testcontainers MySQL).
 
## Frontend (`frontend/src/app/features/<recurso-kebab>/`)
- `models/<recurso>.model.ts` (interfaces), `services/<recurso>.service.ts` (HttpClient sobre `environment.apiUrl`).
- Componentes standalone: `<recurso>-list`, `<recurso>-form`, con formularios reactivos y validaciones.
- Ruta perezosa en `app.routes.ts` protegida con el guard de rol.
- Prueba unitaria del servicio.
 
Al terminar, ejecuta `/verificar-calidad` y resume los archivos creados.

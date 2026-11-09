---
name: crear-migracion
description: Crea una migración Flyway para MySQL siguiendo las convenciones del proyecto (nombres, auditoría, borrado lógico, índices). Úsala cuando haya que crear o modificar tablas o columnas.
argument-hint: "[descripcion_en_snake_case]"
---
 
# Nueva migración: $ARGUMENTS
 
1. Lista `backend/src/main/resources/db/migration/` y toma el siguiente número de versión.
2. Crea `V<n>__$ARGUMENTS.sql`. Nunca modifiques una migración ya aplicada; crea una nueva.
3. Reglas para cada tabla nueva:
   - `id BIGINT AUTO_INCREMENT PRIMARY KEY`, motor InnoDB, `utf8mb4`.
   - Columnas `created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP`, `updated_at DATETIME NULL ON UPDATE CURRENT_TIMESTAMP`, `deleted_at DATETIME NULL`.
   - Nombres en inglés y snake_case; llaves foráneas `fk_<tabla>_<ref>`; índices `idx_<tabla>_<col>`; únicos `uk_<tabla>_<col>`.
   - Índice en cada llave foránea y en columnas de búsqueda.
4. Prohibido: `DELETE FROM`, `TRUNCATE`, `DROP TABLE` (el hook los bloquea). Para datos semilla usa `INSERT`.
5. Actualiza la entidad JPA con `@SQLDelete` y `@SQLRestriction("deleted_at IS NULL")`.
6. Valida levantando MySQL local (`docker compose up -d mysql`) y ejecutando `./mvnw -q flyway:info` o las pruebas de integración.
7. Actualiza el diagrama ER (Mermaid) en `docs/modelo-datos.md`.

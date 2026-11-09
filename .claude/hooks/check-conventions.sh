#!/usr/bin/env bash
# Hook PostToolUse (Edit|Write|MultiEdit): convenciones de código del proyecto.
# Revisa el archivo modificado y, si hay violaciones, sale con 2 para que Claude las corrija.
set -uo pipefail
 
input="$(cat)"
file="$(jq -r '.tool_input.file_path // empty' <<<"$input")"
[ -z "$file" ] && exit 0
[ -f "$file" ] || exit 0
 
ROOT="${CLAUDE_PROJECT_DIR:-$(pwd)}"
rel="${file#"$ROOT"/}"
name="$(basename "$rel")"
v=""
add() { v="${v}  - $1"$'\n'; }
has() { grep -Eq "$1" "$file"; }
 
case "$rel" in
  # ---------- Backend (código productivo) ----------
  backend/src/main/java/*.java)
    has 'System\.(out|err)\.print|printStackTrace\(' && add "Usa un logger SLF4J (@Slf4j o LoggerFactory), no System.out ni printStackTrace."
    has '^[[:space:]]*@Autowired' && add "Usa inyección por constructor (campos private final + @RequiredArgsConstructor), no @Autowired en campos."
    has '[A-Za-z]*[Rr]epository\.(delete|deleteById|deleteAll|deleteAllById)\(' && add "Borrado físico detectado. Usa borrado lógico (softDelete / @SQLDelete)."
    case "$rel" in
      */controller/*)
        case "$name" in *Controller.java) ;; *) add "Los archivos en controller/ deben terminar en Controller.java." ;; esac
        has '@RequestMapping\("/api/' || add "Los controladores REST deben exponer rutas bajo /api/... (@RequestMapping(\"/api/...\"))."
        has 'ResponseEntity<[A-Z][A-Za-z]*Entity>|public [A-Z][A-Za-z]*Entity ' && add "No expongas entidades JPA en controladores; devuelve DTOs (*Response)."
        ;;
      */dto/*)
        case "$name" in *Request.java|*Response.java) ;; *) add "Los DTO deben llamarse *Request.java o *Response.java." ;; esac
        ;;
      */service/*)
        case "$name" in *Service.java|*ServiceImpl.java) ;; *) add "Los archivos en service/ deben terminar en Service.java o ServiceImpl.java." ;; esac
        ;;
      */repository/*)
        case "$name" in *Repository.java) ;; *) add "Los archivos en repository/ deben terminar en Repository.java." ;; esac
        ;;
    esac
    ;;
  # ---------- Migraciones Flyway ----------
  backend/src/main/resources/db/migration/*)
    grep -Eq '^V[0-9]+__[a-z0-9_]+\.sql$' <<<"$name" || add "Migración mal nombrada. Formato: V<numero>__<descripcion_snake_case>.sql"
    if grep -Eiq 'CREATE[[:space:]]+TABLE' "$file" && ! grep -Eiq 'deleted_at' "$file"; then
      add "Toda tabla nueva debe incluir columnas de auditoría y borrado lógico: created_at, updated_at, deleted_at."
    fi
    ;;
  # ---------- Frontend Angular ----------
  frontend/src/app/*)
    grep -Eq '^[a-z0-9]+(-[a-z0-9]+)*(\.[a-z0-9]+)*\.(ts|html|scss|css)$' <<<"$name" \
      || add "Nombre de archivo Angular en kebab-case (ej. loan-request.component.ts)."
    case "$name" in
      *.spec.ts) ;;
      *.ts)
        has 'console\.(log|debug)' && add "Elimina console.log/console.debug del código de la app."
        has ':[[:space:]]*any([^[:alnum:]_]|$)|<any>|as any' && add "Evita el tipo any; define una interfaz o tipo."
        has 'https?://(localhost|127\.0\.0\.1)' && add "No escribas URLs en duro; usa environment.apiUrl (/api)."
        ;;
    esac
    ;;
  # ---------- Pruebas E2E (Playwright) ----------
  e2e/tests/*.spec.ts)
    has "from '\.\./support/evidence'" || add "Importa test y expect desde '../support/evidence' (fixture de evidencias), no desde '@playwright/test'."
    has 'test\.use\(\{[[:space:]]*funcionalidad:' || add "Declara la funcionalidad: test.use({ funcionalidad: '<kebab-case>' }); las capturas van a docs/testing/playwright/<funcionalidad>/."
    has 'evidence\(' || add "Cada prueba debe registrar al menos una evidencia con await evidence('<paso>') en el punto que verifica el criterio."
    has 'waitForTimeout\(' && add "No uses waitForTimeout; usa las esperas automáticas de expect/locators."
    has 'headless:[[:space:]]*false' && add "Las pruebas corren headless; no sobrescribas headless: false."
    ;;
  *) exit 0 ;;
esac
 
if [ -n "$v" ]; then
  printf "Convenciones no cumplidas en %s:\n%s" "$rel" "$v" >&2
  echo "Consulta la sección 'Convenciones' de CLAUDE.md y corrige el archivo." >&2
  exit 2
fi
exit 0

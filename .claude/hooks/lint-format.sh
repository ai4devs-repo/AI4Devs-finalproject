#!/usr/bin/env bash
# Hook PostToolUse (Edit|Write|MultiEdit): formatea y aplica lint al archivo recién modificado.
#  - frontend: Prettier + ESLint (angular-eslint) con --fix
#  - backend:  Spotless (google-java-format) sobre el archivo Java
# Si quedan errores que no se pueden corregir solos, sale con 2 y Claude recibe el detalle para arreglarlos.
set -uo pipefail
 
input="$(cat)"
file="$(jq -r '.tool_input.file_path // empty' <<<"$input")"
[ -z "$file" ] && exit 0
[ -f "$file" ] || exit 0
 
ROOT="${CLAUDE_PROJECT_DIR:-$(pwd)}"
rel="${file#"$ROOT"/}"
errors=""
 
case "$rel" in
  frontend/*.ts|frontend/*.html|frontend/*.scss|frontend/*.css|frontend/*.json)
    [ -d "$ROOT/frontend/node_modules" ] || exit 0   # proyecto Angular aún no creado
    f="${rel#frontend/}"
    (cd "$ROOT/frontend" && npx --no-install prettier --write "$f" >/dev/null 2>&1) || true
    case "$f" in
      *.ts|*.html)
        if ! out="$(cd "$ROOT/frontend" && npx --no-install eslint --fix "$f" 2>&1)"; then
          errors="$out"
        fi
        ;;
    esac
    ;;
  backend/*.java)
    [ -x "$ROOT/backend/mvnw" ] || exit 0              # proyecto Spring Boot aún no creado
    # -o: modo offline para que sea rápido; spotlessFiles acepta una expresión regular de rutas
    if ! out="$(cd "$ROOT/backend" && ./mvnw -q -o spotless:apply -DspotlessFiles="$file" 2>&1)"; then
      errors="$out"
    fi
    ;;
  *) exit 0 ;;
esac
 
if [ -n "$errors" ]; then
  {
    echo "Lint/formato con errores en $rel. Corrígelos antes de continuar:"
    echo "$errors" | tail -n 40
  } >&2
  exit 2
fi
exit 0

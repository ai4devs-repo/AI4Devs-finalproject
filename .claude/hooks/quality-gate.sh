#!/usr/bin/env bash
# Hook Stop: compuerta de calidad al terminar cada turno.
# Compila y valida estilo solo en las partes del monorepo que cambiaron.
# Si algo falla, sale con 2 y Claude sigue trabajando hasta corregirlo.
set -uo pipefail
 
input="$(cat)"
# Evita bucles infinitos: si ya estamos en una continuación provocada por este hook, no repetir
[ "$(jq -r '.stop_hook_active // false' <<<"$input")" = "true" ] && exit 0
 
ROOT="${CLAUDE_PROJECT_DIR:-$(pwd)}"
cd "$ROOT" || exit 0
changed="$( { git diff --name-only HEAD 2>/dev/null; git ls-files --others --exclude-standard 2>/dev/null; } | sort -u )"
[ -z "$changed" ] && exit 0
 
report=""
# Solo valida cada proyecto cuando ya existe (antes del paso de esqueleto no hay mvnw ni node_modules)
if grep -q '^backend/' <<<"$changed" && [ -x backend/mvnw ]; then
  if ! out="$(cd backend && ./mvnw -q -o compile checkstyle:check 2>&1)"; then
    report="${report}[backend] compile/checkstyle falló:"$'\n'"$(echo "$out" | tail -n 30)"$'\n'
  fi
fi
if grep -q '^frontend/' <<<"$changed" && [ -d frontend/node_modules ]; then
  if ! out="$(cd frontend && npx --no-install ng lint 2>&1 && npx --no-install tsc --noEmit -p tsconfig.app.json 2>&1)"; then
    report="${report}[frontend] lint/tipos falló:"$'\n'"$(echo "$out" | tail -n 30)"$'\n'
  fi
fi
 
if [ -n "$report" ]; then
  printf "La compuerta de calidad encontró problemas. Corrígelos antes de terminar:\n%s" "$report" >&2
  exit 2
fi
exit 0

#!/usr/bin/env bash
# Hook PreToolUse (Bash): las pruebas E2E siempre corren headless y dejan evidencia.
#  - Bloquea `playwright test` con --headed, --ui o --debug.
#  - Bloquea `playwright codegen` (abre ventana; para explorar usa el MCP de Playwright, que corre headless).
set -uo pipefail
 
input="$(cat)"
cmd="$(jq -r '.tool_input.command // empty' <<<"$input")"
grep -Eq 'playwright' <<<"$cmd" || exit 0
 
if grep -Eq 'playwright[[:space:]]+test.*(--headed|--ui([^-[:alnum:]]|$)|--debug)' <<<"$cmd" \
   || grep -Eq 'PWDEBUG=|HEADED=(1|true)' <<<"$cmd"; then
  echo "BLOQUEADO por hook enforce-headless-e2e: las pruebas E2E corren headless para dejar evidencia en docs/testing/playwright/<funcionalidad>/. Quita --headed/--ui/--debug y revisa el trace o las capturas generadas." >&2
  exit 2
fi
if grep -Eq 'playwright[[:space:]]+codegen' <<<"$cmd"; then
  echo "BLOQUEADO por hook enforce-headless-e2e: codegen abre un navegador con ventana. Usa el MCP de Playwright (headless) para explorar la UI." >&2
  exit 2
fi
exit 0

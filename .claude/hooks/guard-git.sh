#!/usr/bin/env bash
# Hook PreToolUse (Bash, solo comandos git): convenciones de ramas y commits.
#  - Nombres de rama: feature/entrega-N-AFRC, final-project-AFRC o <tipo>/PLAB-<n>-<slug>
#  - Commits en formato Conventional Commits: tipo(PLAB-12): descripción
#  - Sin commits directos en main, sin push --force y sin --no-verify
set -uo pipefail
 
input="$(cat)"
cmd="$(jq -r '.tool_input.command // empty' <<<"$input")"
grep -Eq '(^|[;&|[:space:]])git[[:space:]]' <<<"$cmd" || exit 0
 
ROOT="${CLAUDE_PROJECT_DIR:-$(pwd)}"
current="$(git -C "$ROOT" branch --show-current 2>/dev/null || echo '')"
BRANCH_RE='^(feature/entrega-[1-3]-AFRC|final-project-AFRC|(feature|fix|test|docs|chore|refactor)/PLAB-[0-9]+-[a-z0-9]+(-[a-z0-9]+)*)$'
COMMIT_RE='(feat|fix|docs|style|refactor|test|chore|ci|build|perf)(\([A-Za-z0-9-]+\))?!?: .{5,}'
 
fail() { echo "BLOQUEADO por hook guard-git: $1" >&2; exit 2; }
 
# 1. Operaciones peligrosas
if grep -Eq 'git[[:space:]]+push.*(--force([^-]|$)|[[:space:]]-f([[:space:]]|$))' <<<"$cmd"; then
  fail "push --force no está permitido. Si de verdad es necesario, que lo haga el usuario manualmente."
fi
if grep -Eq -- '--no-verify' <<<"$cmd"; then
  fail "--no-verify salta las validaciones del repositorio. Corrige el problema en lugar de saltarlo."
fi
 
# 2. Creación de ramas
new_branch="$(sed -nE 's/.*git[[:space:]]+(checkout[[:space:]]+-b|switch[[:space:]]+-c)[[:space:]]+([^[:space:];&|]+).*/\2/p' <<<"$cmd")"
if [ -n "$new_branch" ] && ! grep -Eq "$BRANCH_RE" <<<"$new_branch"; then
  fail "nombre de rama '$new_branch' inválido. Usa feature/PLAB-<n>-<slug-en-kebab-case> (ej. feature/PLAB-12-solicitar-prestamo) o una rama de entrega (feature/entrega-N-AFRC, final-project-AFRC)."
fi
 
# 3. Commits
if grep -Eq 'git[[:space:]]+commit' <<<"$cmd"; then
  if [ "$current" = "main" ]; then
    fail "no se hacen commits directos en main. Crea una rama feature/PLAB-<n>-<slug>."
  fi
  if grep -Eq -- '(-m|--message)' <<<"$cmd" && ! grep -Eq "$COMMIT_RE" <<<"$cmd"; then
    fail "mensaje de commit fuera de convención. Formato: tipo(PLAB-12): descripción en imperativo. Tipos: feat, fix, docs, style, refactor, test, chore, ci, build, perf."
  fi
fi
 
# 4. Push directo a main
if grep -Eq 'git[[:space:]]+push.*[[:space:]](origin[[:space:]]+)?main([[:space:]]|$)' <<<"$cmd"; then
  fail "push directo a main no permitido. Abre un Pull Request."
fi
exit 0

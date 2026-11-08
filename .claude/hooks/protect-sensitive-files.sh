#!/usr/bin/env bash
# Hook PreToolUse: bloquea leer o modificar archivos sensibles (.env, llaves, secretos).
# Se permite .env.example / .env.sample / .env.template.
# Compatible con bash 3.2 (macOS). Requiere jq (brew install jq).
set -uo pipefail
 
input="$(cat)"
tool="$(jq -r '.tool_name // empty' <<<"$input")"
 
# Rutas sensibles: .env, .env.local, .env.production, secrets/, llaves y keystores, carpeta .vercel
SENSITIVE='(^|/)\.env(\.[^/]+)?$|(^|/)secrets?/|\.(pem|key|p12|jks|keystore)$|(^|/)id_(rsa|ed25519)[^/]*$|(^|/)\.vercel/'
ALLOWED='(^|/)\.env\.(example|sample|template)$'
 
block() {
  echo "BLOQUEADO por hook protect-sensitive-files: $1" >&2
  echo "Los archivos de secretos no se leen ni se editan con IA. Si necesitas una variable nueva, agrégala a .env.example y pide al usuario que actualice su .env manualmente." >&2
  exit 2
}
 
case "$tool" in
  Read|Edit|Write|MultiEdit|NotebookEdit)
    path="$(jq -r '.tool_input.file_path // .tool_input.notebook_path // empty' <<<"$input")"
    [ -z "$path" ] && exit 0
    if grep -Eq "$SENSITIVE" <<<"$path" && ! grep -Eq "$ALLOWED" <<<"$path"; then
      block "$path"
    fi
    ;;
  Bash)
    cmd="$(jq -r '.tool_input.command // empty' <<<"$input")"
    # Quitamos menciones permitidas antes de evaluar
    cleaned="$(sed -E 's/\.env\.(example|sample|template)//g' <<<"$cmd")"
    if grep -Eq '(^|[^[:alnum:]_])\.env([^[:alnum:]_]|$)' <<<"$cleaned" \
       || grep -Eq '\.(pem|key|p12|jks)([^[:alnum:]_]|$)|id_rsa|id_ed25519' <<<"$cleaned"; then
      block "comando que accede a archivos sensibles -> $cmd"
    fi
    ;;
esac
exit 0

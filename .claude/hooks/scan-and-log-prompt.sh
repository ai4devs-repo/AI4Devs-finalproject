#!/usr/bin/env bash
# Hook UserPromptSubmit + UserPromptExpansion: registro de prompts.
#  1) Bloquea prompts que contienen secretos (contraseñas de Aiven, llaves privadas, tokens).
#  2) Registra cada prompt enviado a Claude Code, incluidos los comandos con barra como /init:
#     - al final de PROMPTS.md, en la sección "## Registro automático de prompts"
#     - en docs/ai-log/prompts.jsonl (formato máquina)
#  Se registra en los dos eventos para no perder comandos; si ambos llegan para el mismo
#  prompt, el segundo se descarta (deduplicación por sesión y texto en 15 segundos).
# Compatible con bash 3.2 (macOS). Requiere jq.
set -uo pipefail
 
input="$(cat)"
event="$(jq -r '.hook_event_name // "UserPromptSubmit"' <<<"$input")"
session="$(jq -r '.session_id // ""' <<<"$input")"
prompt="$(jq -r '.prompt // empty' <<<"$input")"
 
# En UserPromptExpansion se registra la forma escrita por el usuario (/comando args), no el
# texto expandido, para que coincida con UserPromptSubmit y no quede duplicado.
cmd="$(jq -r '.command_name // .command // empty' <<<"$input")"
if [ "$event" = "UserPromptExpansion" ] || [ -z "$prompt" ]; then
  if [ -n "$cmd" ]; then
    args="$(jq -r '.command_args // .arguments // .args // empty' <<<"$input")"
    prompt="/${cmd#/}${args:+ $args}"
  fi
fi
[ -z "$prompt" ] && exit 0
 
# ---------- 1. Secretos ----------
SECRETS='AVNS_[A-Za-z0-9_-]{10,}|-----BEGIN [A-Z ]*PRIVATE KEY-----|AKIA[0-9A-Z]{16}|gh[pousr]_[A-Za-z0-9]{30,}|xox[baprs]-[A-Za-z0-9-]{10,}|(password|passwd|pwd|secret|api[_-]?key)[[:space:]]*[:=][[:space:]]*[^[:space:]]{6,}'
if grep -Eiq "$SECRETS" <<<"$prompt"; then
  echo "Tu mensaje parece contener un secreto (contraseña, token o llave). No se envió ni se registró. Configúralo como variable de entorno en Vercel o en tu .env local y vuelve a escribir el mensaje sin el valor." >&2
  exit 2
fi
 
ROOT="${CLAUDE_PROJECT_DIR:-$(pwd)}"
LOG_DIR="$ROOT/docs/ai-log"
mkdir -p "$LOG_DIR"
 
# ---------- 2. Deduplicación entre eventos ----------
sig="$(printf '%s|%s' "$session" "$prompt" | shasum -a 256 | cut -c1-16)"
now="$(date +%s)"
STATE="$LOG_DIR/.last-prompt"
if [ -f "$STATE" ]; then
  read -r last_sig last_ts < "$STATE" || true
  if [ "${last_sig:-}" = "$sig" ] && [ $(( now - ${last_ts:-0} )) -lt 15 ]; then
    exit 0
  fi
fi
printf '%s %s\n' "$sig" "$now" > "$STATE"
 
branch="$(git -C "$ROOT" branch --show-current 2>/dev/null || echo '')"
case "$prompt" in /*) kind="comando" ;; *) kind="prompt" ;; esac
 
# ---------- 3. Registro en JSONL ----------
jq -cn --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" --arg branch "$branch" --arg event "$event" \
  --arg kind "$kind" --arg session "$session" --arg prompt "$prompt" \
  '{ts: $ts, branch: $branch, event: $event, kind: $kind, session: $session, prompt: $prompt}' \
  >> "$LOG_DIR/prompts.jsonl"
 
# ---------- 4. Registro en PROMPTS.md ----------
PROMPTS="$ROOT/PROMPTS.md"
HEADER="## Registro automático de prompts"
[ -f "$PROMPTS" ] || printf '# PROMPTS - PrestaLab\n' > "$PROMPTS"
if ! grep -qxF "$HEADER" "$PROMPTS"; then
  printf '\n---\n\n%s\n\n> Lo escribe el hook `scan-and-log-prompt.sh` (UserPromptSubmit y UserPromptExpansion) con cada prompt enviado a Claude Code, incluidos comandos como `/init`. Es el registro de la conversación completa. No se edita a mano: las secciones 1 a 7 se llenan con `/registrar-prompt`. Esta sección siempre va al final del archivo.\n' "$HEADER" >> "$PROMPTS"
fi
 
n="$(grep -c '^#### P-' "$PROMPTS" || true)"
n=$(( ${n:-0} + 1 ))
MAX=1500
text="$prompt"
note=""
if [ "${#text}" -gt "$MAX" ]; then
  text="${text:0:$MAX}"
  note=$'\n'"_(Recortado a $MAX caracteres; el texto completo está en docs/ai-log/prompts.jsonl)_"$'\n'
fi
text="$(printf '%s' "$text" | sed 's/~~~/~~ ~/g')"   # evita cerrar el bloque de código
 
{
  printf '\n#### P-%03d · %s · %s · `%s`\n\n' "$n" "$(date '+%Y-%m-%d %H:%M')" "$kind" "${branch:-sin-rama}"
  printf '~~~text\n%s\n~~~\n' "$text"
  printf '%s' "$note"
} >> "$PROMPTS"
exit 0


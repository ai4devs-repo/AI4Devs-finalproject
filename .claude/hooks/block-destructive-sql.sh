#!/usr/bin/env bash
# Hook PreToolUse: impide operaciones SQL destructivas (DELETE FROM, TRUNCATE, DROP TABLE/DATABASE/SCHEMA)
# en comandos de terminal, en archivos que Claude escribe/edita y en herramientas MCP de base de datos.
# Política del proyecto: borrado lógico (UPDATE ... SET active = FALSE, deleted_at = NOW()).
set -uo pipefail
 
input="$(cat)"
tool="$(jq -r '.tool_name // empty' <<<"$input")"
file="$(jq -r '.tool_input.file_path // empty' <<<"$input")"
 
case "$tool" in
  Bash)      text="$(jq -r '.tool_input.command // ""' <<<"$input")" ;;
  Write)     text="$(jq -r '.tool_input.content // ""' <<<"$input")" ;;
  Edit)      text="$(jq -r '.tool_input.new_string // ""' <<<"$input")" ;;
  MultiEdit) text="$(jq -r '[.tool_input.edits[]?.new_string] | join("\n")' <<<"$input")" ;;
  mcp__*)    text="$(jq -r '.tool_input | tostring' <<<"$input")" ;;
  *)         exit 0 ;;
esac
 
# La documentación y los propios hooks pueden mencionar las palabras prohibidas
case "$file" in
  *.md|*/.claude/hooks/*) exit 0 ;;
esac
 
PATTERN='(^|[^[:alnum:]_])(DELETE[[:space:]]+FROM|TRUNCATE[[:space:]]+(TABLE[[:space:]]+)?[[:alnum:]_`]|DROP[[:space:]]+(TABLE|DATABASE|SCHEMA))'
 
if grep -Eiq "$PATTERN" <<<"$text"; then
  match="$(grep -Eio "$PATTERN" <<<"$text" | head -1 | sed -E 's/^[^[:alpha:]]//')"
  {
    echo "BLOQUEADO por hook block-destructive-sql: se detectó '$match' (herramienta: $tool${file:+, archivo: $file})."
    echo "En este proyecto no se borran filas físicamente. Usa borrado lógico, por ejemplo:"
    echo "  UPDATE equipment SET active = FALSE, deleted_at = NOW() WHERE id = ?;"
    echo "En JPA: anota la entidad con @SQLDelete/@SQLRestriction o implementa softDelete() en el servicio."
  } >&2
  exit 2
fi
exit 0

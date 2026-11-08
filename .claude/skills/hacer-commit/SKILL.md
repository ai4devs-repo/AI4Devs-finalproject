---
name: hacer-commit
description: Prepara y crea commits del monorepo siguiendo las convenciones del proyecto (Conventional Commits con la clave Jira, mensajes en español, commits atómicos por tema, sin secretos). Úsala solo cuando el usuario pida hacer un commit o guardar cambios en git.
disable-model-invocation: true
argument-hint: "[PLAB-n] [descripción opcional del cambio]"
allowed-tools: Bash(git status *) Bash(git diff *) Bash(git log *) Bash(git branch *) Bash(git add *) Bash(git commit *) Bash(git restore --staged *)
---

# Hacer commit

Argumentos: $ARGUMENTS (clave Jira `PLAB-<n>` y/o una pista del cambio).

Nunca ejecutes `git push`, `--force`, `--no-verify`, `git reset --hard`, `git clean` ni `git checkout .`. No hagas commits en `main`. El push y el Pull Request los decide el usuario; la skill solo prepara la descripción del PR (paso 8).

## Pasos

1. **Contexto:** `git branch --show-current`, `git status --short` y `git diff --stat`. Si la rama es `main`, detente y propón una rama `feature/PLAB-<n>-<slug>`; las ramas de entrega válidas son `feature/entrega-N-AFRC` y `final-project-AFRC`.
2. **Revisión de seguridad antes de añadir nada:** no incluyas `.env`, `.env.*` (salvo `.env.example`), `.claude/settings.local.json`, `.vercel/`, `target/`, `dist/`, `node_modules/`, ni archivos con contraseñas, tokens o llaves. Si aparece uno en `git status`, no lo añadas y avisa. Nunca leas el contenido de `.env*`.
3. **Agrupa por tema:** divide los cambios en commits atómicos, cada uno con un único propósito (por ejemplo, historias de usuario, modelo de datos, ADR, diagramas, subagentes y skills, hooks). Muestra al usuario la propuesta de grupos y archivos antes de confirmar.
4. **Añade solo lo necesario** con `git add <rutas explícitas>`. No uses `git add -A` ni `git add .`. `docs/ai-log/prompts.jsonl` y `PROMPTS.md` se versionan; `docs/ai-log/.last-prompt` no.
5. **Mensaje:** formato `tipo(PLAB-<n>): descripción en imperativo`, en español, de 72 caracteres o menos en la primera línea. Tipos: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`, `ci`, `build`, `perf`. Si no hay clave Jira ni se conoce, pregúntala; no inventes una. En ramas de entrega sin historia, usa el tipo y la clave del trabajo (por ejemplo `docs(PLAB-1): ...`) acordada con el usuario. Cuerpo opcional con el porqué, en párrafos cortos.
6. **Crea el commit** con `git commit -m "<mensaje>"` (varias `-m` para el cuerpo). El hook `guard-git.sh` valida rama y formato; si bloquea, corrige el mensaje, no lo evites.
7. **Verifica** con `git log -1 --stat` y `git status --short`. Informa los commits creados (hash corto y mensaje) y lo que quedó sin commitear y por qué.
8. **Descripción del Pull Request:** al terminar los commits, prepara el texto del PR a partir de `.github/pull_request_template.md` (léelo; no lo modifiques) y entrégalo en la respuesta para que el usuario lo copie o lo use al abrir el PR. Rellena sus cuatro apartados con datos reales de la rama (`git log <rama-base>..HEAD --oneline` y `git diff <rama-base>...HEAD --stat`):
   - **Objetivo del cambio:** el valor o problema que resuelve, con la clave Jira.
   - **Qué se hizo:** resumen por áreas (backend, frontend, base de datos, documentación, pruebas), tomado de los commits.
   - **Cómo se probó:** los comandos y escenarios realmente ejecutados en esta sesión o por `/verificar-calidad`. Si es solo documentación, indica qué se revisó (por ejemplo, validación del YAML con `swagger-cli`, renderizado de diagramas con `mermaid-cli`).
   - **Resultados de las pruebas:** el resultado real de esas ejecuciones. Si algo no se ejecutó, escribe «No ejecutado» con el motivo. Nunca inventes resultados, enlaces ni números.
   Marca la lista de verificación solo con lo que hayas comprobado. Si el usuario pide abrir el PR, usa `gh pr create --body-file` con ese texto, pero solo después de que el usuario haya hecho el push; esta skill no hace push.

Termina cada commit con las líneas de atribución que indique la sesión, si las hay.

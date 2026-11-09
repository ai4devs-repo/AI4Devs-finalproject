---
name: crear-pr
description: Publica la rama actual y abre el Pull Request en GitHub con la descripción rellenada desde .github/pull_request_template.md (objetivo, qué se hizo, cómo se probó y resultados). Úsala solo cuando el usuario pida crear o abrir el PR, o cuando /hacer-commit la invoque después de que el usuario confirme que quiere abrirlo.
argument-hint: "[rama-base] [PLAB-n] [título opcional]"
allowed-tools: Bash(git status *) Bash(git diff *) Bash(git log *) Bash(git branch *) Bash(git remote *) Bash(git push -u origin *) Bash(gh pr create *) Bash(gh pr view *) Bash(gh auth status)
---

# Crear Pull Request

Argumentos: $ARGUMENTS (rama base, por defecto `main`; clave Jira `PLAB-<n>`; título opcional).

Puede invocarla `/hacer-commit` (paso 9), pero solo tras la confirmación del usuario; la confirmación del destino (paso 2) y la de `settings.json` para `git push` siguen siendo obligatorias, también cuando la invoca otra skill.

Nunca ejecutes `git push --force`, `-f`, `--no-verify`, ni hagas push a `main`. No cambies commits (`reset`, `rebase`, `commit --amend`). No modifiques `.github/pull_request_template.md`. Esta skill publica trabajo ya commiteado; si hay cambios sin commitear, detente y sugiere `/hacer-commit`.

## Pasos

1. **Contexto:** `git branch --show-current`, `git status --short`, `git remote -v` y `gh auth status`. Detente si: la rama es `main`; hay cambios sin commitear que formarían parte del PR; el nombre de la rama no cumple la convención (`feature/entrega-N-AFRC`, `final-project-AFRC` o `<tipo>/PLAB-<n>-<slug>`); o `gh` no está autenticado (indica `! gh auth login`).
2. **Confirma el destino:** muestra el remoto (`origin`), la rama a publicar y la rama base, y espera la confirmación del usuario antes de continuar.
3. **Alcance del PR:** `git log <base>..HEAD --oneline` y `git diff <base>...HEAD --stat`. Si no hay commits nuevos respecto a la base, detente.
4. **Descripción:** lee `.github/pull_request_template.md` y rellena sus apartados con datos reales de la rama:
   - **Objetivo del cambio:** el valor que aporta, con la clave Jira.
   - **Qué se hizo:** resumen por áreas (backend, frontend, base de datos, documentación, pruebas, harness), tomado de los commits.
   - **Cómo se probó:** los comandos y revisiones realmente ejecutados en esta sesión o por `/verificar-calidad`. Si `/hacer-commit` ya preparó la descripción (te la pasa por argumento o archivo temporal), reutilízala tal cual y actualízala solo con lo ocurrido después; no la redactes de nuevo.
   - **Resultados de las pruebas:** resultados reales. Lo que no se ejecutó va como «No ejecutado» con el motivo. Indica de quién es cada resultado si lo ejecutó un subagente y tú no lo verificaste. Nunca inventes resultados, enlaces ni números.
   - **Lista de verificación:** marca solo lo comprobado.
   Guarda el cuerpo en un archivo temporal fuera del repositorio (el directorio temporal de la sesión) y muéstralo al usuario.
5. **Título:** `<tipo>(PLAB-<n>): descripción` en español, de 72 caracteres o menos, o el título pasado como argumento.
6. **Publica la rama:** `git push -u origin <rama>` (sin `--force`). Settings pide confirmación para `git push`; si el usuario la rechaza, detente sin insistir.
7. **Abre el PR:** `gh pr create --base <base> --head <rama> --title "<título>" --body-file <archivo>`. Si ya existe un PR para la rama (`gh pr view`), no crees otro: informa su URL y ofrece actualizar el cuerpo.
8. **Resultado:** informa la URL del PR, la rama, la base y el resumen (número de commits y archivos). Si falló un paso, di cuál y por qué; no repitas a ciegas.

Termina el cuerpo del PR con la línea de atribución que indique la sesión, si la hay.

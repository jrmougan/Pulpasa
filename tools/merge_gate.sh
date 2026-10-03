#!/usr/bin/env bash
# Mergea una rama de worker en la rama actual solo si verify pasa sobre el resultado.
# Uso (lo ejecuta el producer, de una en una): tools/merge_gate.sh <rama> [--allow-outside-owns]
# Antes de mergear comprueba que la rama solo toca `owns` de su ficha (tools/check_owns.py).
set -euo pipefail
branch="${1:?uso: tools/merge_gate.sh <rama>}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
[[ -z "$(git status --porcelain)" ]] || { echo "El árbol de trabajo no está limpio." >&2; exit 1; }
if [[ "${2:-}" != "--allow-outside-owns" ]]; then
  tools/check_owns.py "$branch" || { echo "Usa --allow-outside-owns solo si el producer lo ha autorizado." >&2; exit 1; }
fi
git merge --no-ff --no-commit "$branch" || { git merge --abort; echo "Conflicto con $branch: pide al worker que haga rebase." >&2; exit 1; }
if tools/verify.sh; then
  git commit --no-edit
  echo "✓ $branch mergeada"
else
  git merge --abort
  echo "✗ verify falla tras mergear $branch; merge abortado." >&2
  exit 1
fi

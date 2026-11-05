#!/bin/sh
# PreToolUse (Edit|Write|MultiEdit): lanza guard_ownership.py y falla cerrado.
#
# Claude Code solo bloquea con rc=2: cualquier otro rc deja pasar la edición. Python puede morir antes
# de llegar al `try` del hook (intérprete ausente, PYTHONIOENCODING o PYTHONUTF8 inválidas, hook que no
# compila, señal), así que aquí todo lo que no sea una decisión del hook (0 o 2) se convierte en 2.
# Va en POSIX sh, sin dependencias: es lo único que corre si no hay Python. Lo que este fichero no puede
# cubrir (que falte él mismo) lo cubre el comando de .claude/settings.json.
#
# Sin ficha activa no se restringe nada: se sale antes de buscar Python, con el mismo criterio de
# marcador que guard_ownership.py. Un marcador vacío tampoco restringe; con contenido, decide el hook.
#
# El repositorio es el de este fichero, no $CLAUDE_PROJECT_DIR: Claude Code lo fija al directorio de
# arranque, que no tiene por qué ser la raíz. Se quita para que el hook use también su propia ubicación.

hook_dir=${0%/*}
unset CLAUDE_PROJECT_DIR
root=$hook_dir/../..
marker=$root/.claude/current-task

[ -e "$marker" ] || exit 0
if [ -f "$marker" ] && [ ! -s "$marker" ]; then
  exit 0
fi

block() {
  printf 'Bloqueado: %s\nHay ficha activa y no se ha podido comprobar `owns`; pregunta al coordinador (`orchestration ask`).\n' "$1" >&2
  exit 2
}

guard=$hook_dir/guard_ownership.py
# Un fichero vacío es Python válido y saldría con 0.
[ -s "$guard" ] || block "falta o está vacío .claude/hooks/guard_ownership.py."
python=$(command -v python3 || command -v python) || block "no hay python3 ni python en el PATH."

"$python" "$guard"
rc=$?
case $rc in
  0 | 2) exit "$rc" ;;
esac
block "guard_ownership.py ha terminado con rc=$rc sin decidir."

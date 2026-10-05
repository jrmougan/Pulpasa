#!/usr/bin/env bash
# Arranca/para Blender sin pantalla con el add-on del MCP de Blender Lab (D20, PUL-043).
# El servidor MCP (`blender` en .mcp.json) se conecta a este Blender por TCP.
# Uso: tools/blender_mcp.sh start|stop|status   (puerto: $BLENDER_MCP_PORT, por defecto 9876)
set -uo pipefail
PORT="${BLENDER_MCP_PORT:-9876}"
BLENDER="${BLENDER_PATH:-blender}"
STATE_DIR="${XDG_RUNTIME_DIR:-/tmp}/pulpasa_blender_mcp"
PID_FILE="$STATE_DIR/blender_$PORT.pid"
LOG_FILE="$STATE_DIR/blender_$PORT.log"

is_running() { [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; }

port_open() { (exec 3<>"/dev/tcp/127.0.0.1/$PORT") 2>/dev/null; }

case "${1:-}" in
  start)
    if is_running; then echo "blender_mcp: ya en marcha (pid $(cat "$PID_FILE"), puerto $PORT)"; exit 0; fi
    mkdir -p "$STATE_DIR"
    nohup "$BLENDER" -b -c blender_mcp --port "$PORT" >"$LOG_FILE" 2>&1 &
    echo $! >"$PID_FILE"
    for _ in $(seq 1 60); do
      if port_open; then echo "blender_mcp: escuchando en 127.0.0.1:$PORT (pid $(cat "$PID_FILE"))"; exit 0; fi
      if ! is_running; then break; fi
      sleep 0.5
    done
    echo "blender_mcp: no arrancó; log en $LOG_FILE" >&2
    tail -20 "$LOG_FILE" >&2
    exit 1
    ;;
  stop)
    if is_running; then kill "$(cat "$PID_FILE")" && echo "blender_mcp: parado"; else echo "blender_mcp: no estaba en marcha"; fi
    rm -f "$PID_FILE"
    ;;
  status)
    if is_running && port_open; then echo "blender_mcp: en marcha (pid $(cat "$PID_FILE"), puerto $PORT)"; else echo "blender_mcp: parado"; exit 1; fi
    ;;
  *)
    echo "Uso: $0 start|stop|status" >&2
    exit 2
    ;;
esac

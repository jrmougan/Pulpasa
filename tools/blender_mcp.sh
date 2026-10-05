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
START_TIMEOUT_S="${BLENDER_MCP_START_TIMEOUT:-30}"
STOP_TIMEOUT_S=10

# Escribe el PID del fichero solo si sigue vivo y es nuestro Blender (no mata un PID reciclado).
our_pid() {
  [[ -f "$PID_FILE" ]] || return 1
  local pid cmdline
  pid="$(cat "$PID_FILE")"
  [[ "$pid" =~ ^[0-9]+$ ]] && kill -0 "$pid" 2>/dev/null || return 1
  cmdline="$(tr '\0' ' ' <"/proc/$pid/cmdline" 2>/dev/null)" || return 1
  [[ "$cmdline" == *blender*" -c blender_mcp --port $PORT"* ]] || return 1
  echo "$pid"
}

port_open() { (exec 3<>"/dev/tcp/127.0.0.1/$PORT") 2>/dev/null; }

wait_exit() {
  local pid="$1" tenths="$2"
  for _ in $(seq 1 "$tenths"); do
    kill -0 "$pid" 2>/dev/null || return 0
    sleep 0.1
  done
  return 1
}

# TERM, espera STOP_TIMEOUT_S y escala a KILL. Devuelve 0 si el proceso terminó.
terminate() {
  local pid="$1"
  kill -TERM "$pid" 2>/dev/null
  wait_exit "$pid" $((STOP_TIMEOUT_S * 10)) && return 0
  echo "blender_mcp: pid $pid no responde a TERM; KILL" >&2
  kill -KILL "$pid" 2>/dev/null
  wait_exit "$pid" 50
}

case "${1:-}" in
  start)
    if pid="$(our_pid)"; then echo "blender_mcp: ya en marcha (pid $pid, puerto $PORT)"; exit 0; fi
    rm -f "$PID_FILE"
    if port_open; then echo "blender_mcp: el puerto $PORT ya lo ocupa otro proceso" >&2; exit 1; fi
    mkdir -p "$STATE_DIR"
    # Sin --factory-startup: desactivaría la extensión y el comando -c blender_mcp.
    nohup "$BLENDER" -b -c blender_mcp --port "$PORT" >"$LOG_FILE" 2>&1 &
    pid=$!
    echo "$pid" >"$PID_FILE"
    for _ in $(seq 1 $((START_TIMEOUT_S * 2))); do
      if port_open; then echo "blender_mcp: escuchando en 127.0.0.1:$PORT (pid $pid)"; exit 0; fi
      kill -0 "$pid" 2>/dev/null || break
      sleep 0.5
    done
    echo "blender_mcp: no arrancó; log en $LOG_FILE" >&2
    tail -20 "$LOG_FILE" >&2
    # Es nuestro hijo ($!): se limpia aunque no haya llegado a abrir el puerto.
    if kill -0 "$pid" 2>/dev/null && ! terminate "$pid"; then
      echo "blender_mcp: pid $pid sigue vivo tras KILL" >&2
    fi
    rm -f "$PID_FILE"
    exit 1
    ;;
  stop)
    if ! pid="$(our_pid)"; then
      echo "blender_mcp: no estaba en marcha"
      rm -f "$PID_FILE"
      exit 0
    fi
    if ! terminate "$pid"; then
      echo "blender_mcp: no pude parar pid $pid; conservo $PID_FILE" >&2
      exit 1
    fi
    rm -f "$PID_FILE"
    echo "blender_mcp: parado (pid $pid)"
    ;;
  status)
    if pid="$(our_pid)" && port_open; then
      echo "blender_mcp: en marcha (pid $pid, puerto $PORT)"
    else
      echo "blender_mcp: parado"
      exit 1
    fi
    ;;
  *)
    echo "Uso: $0 start|stop|status" >&2
    exit 2
    ;;
esac

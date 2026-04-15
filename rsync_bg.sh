#!/usr/bin/env bash
# rsync_bg.sh — run rsync in background with logging & PID tracking

## ── configuration ────────────────────────────────────────────
SRC="/var/lib/mongodb"
DST="john@1.2.3.4:/home/sam/mongo4417/data"
LOG_DIR="$HOME/.rsync_logs"
PID_FILE="$LOG_DIR/rsync.pid"
LOG_FILE="$LOG_DIR/rsync_$(date +%Y%m%d_%H%M%S).log"
RSYNC_OPTS="-avz --progress --partial --delete"

## ── helpers ───────────────────────────────────────────────────
setup() {
  mkdir -p "$LOG_DIR"
}

is_running() {
  [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null
}

start() {
  if is_running; then
    echo "[rsync] already running (PID $(cat "$PID_FILE"))"
    exit 1
  fi

  setup
  echo "[rsync] starting → log: $LOG_FILE"

  nohup rsync $RSYNC_OPTS \
    "$SRC" "$DST" \
    >> "$LOG_FILE" 2>&1 &

  local pid=$!
  echo "$pid" > "$PID_FILE"
  echo "[rsync] started (PID $pid)"
}

stop() {
  if ! is_running; then
    echo "[rsync] not running"
    return
  fi
  local pid=$(cat "$PID_FILE")
  kill "$pid" && rm -f "$PID_FILE"
  echo "[rsync] stopped (PID $pid)"
}

status() {
  if is_running; then
    echo "[rsync] running (PID $(cat "$PID_FILE"))"
    echo "[rsync] log: $LOG_DIR"
  else
    echo "[rsync] not running"
  fi
}

logs() {
  local latest=$(ls -t "$LOG_DIR"/rsync_*.log 2>/dev/null | head -1)
  [[ -z "$latest" ]] && { echo "no logs found"; exit 1; }
  tail -f "$latest"
}

## ── dispatch ──────────────────────────────────────────────────
case "${1:-start}" in
  start)  start  ;;   # launch rsync in background
  stop)   stop   ;;   # kill the background process
  status) status ;;   # check if running
  logs)   logs   ;;   # tail latest log
  *)
    echo "usage: $0 {start|stop|status|logs}"
    exit 1
  ;;
esac

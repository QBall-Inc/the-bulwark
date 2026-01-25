#!/bin/bash
# Simple background process spawner for testing verification scripts

PIDFILE="${PIDFILE:-/tmp/spawner-test.pid}"
LOGFILE="${LOGFILE:-/tmp/spawner-test.log}"
PORT="${PORT:-9999}"

start() {
    if [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
        echo "Already running (PID: $(cat "$PIDFILE"))"
        return 1
    fi

    # Start a simple TCP listener in background
    (
        while true; do
            echo "PONG $(date +%s)" | nc -l -p "$PORT" -q 1 2>/dev/null || true
        done
    ) >> "$LOGFILE" 2>&1 &

    echo $! > "$PIDFILE"
    echo "Started (PID: $!, PORT: $PORT)"
}

stop() {
    if [ ! -f "$PIDFILE" ]; then
        echo "Not running"
        return 1
    fi

    PID=$(cat "$PIDFILE")
    if kill -0 "$PID" 2>/dev/null; then
        kill "$PID"
        rm -f "$PIDFILE"
        echo "Stopped (PID: $PID)"
    else
        rm -f "$PIDFILE"
        echo "Not running (stale pidfile removed)"
    fi
}

status() {
    if [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
        echo "Running (PID: $(cat "$PIDFILE"), PORT: $PORT)"
        return 0
    else
        echo "Not running"
        return 1
    fi
}

case "${1:-}" in
    start)  start ;;
    stop)   stop ;;
    status) status ;;
    *)
        echo "Usage: $0 {start|stop|status}"
        exit 1
        ;;
esac

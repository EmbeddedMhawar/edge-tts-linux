#!/bin/bash
# Stop TTS playback completely
# Keybinding: SUPER+SHIFT+E

PIDFILE="/tmp/tts_read.pid"
PYPIDFILE="/tmp/tts_python.pid"
PAUSEFILE="/tmp/tts_read.paused"
FIFO="/tmp/edge_tts_fifo"
GENFILE="/tmp/tts_streaming"

stopped=false

# Kill mpv if running
if [ -f "$PIDFILE" ]; then
    MPV_PID=$(cat "$PIDFILE" 2>/dev/null)
    if [ -n "$MPV_PID" ]; then
        # Resume first in case it's paused
        kill -CONT "$MPV_PID" 2>/dev/null
        kill "$MPV_PID" 2>/dev/null
        stopped=true
    fi
fi

# Kill Python if running
if [ -f "$PYPIDFILE" ]; then
    PY_PID=$(cat "$PYPIDFILE" 2>/dev/null)
    if [ -n "$PY_PID" ]; then
        kill -CONT "$PY_PID" 2>/dev/null
        kill "$PY_PID" 2>/dev/null
        stopped=true
    fi
fi

# Check if generating flag exists (means something was starting)
if [ -f "$GENFILE" ]; then
    stopped=true
fi

# Clean up all temp files silently
rm -f "$PIDFILE" "$PYPIDFILE" "$PAUSEFILE" "$FIFO" "$GENFILE" 2>/dev/null

if [ "$stopped" = true ]; then
    notify-send -u low -t 1000 "TTS ⏹️" "Stopped"
else
    notify-send -u low -t 1000 "TTS" "Nothing playing"
fi

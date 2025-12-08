#!/bin/bash
# Stop TTS playback completely

PIDFILE="/tmp/tts_read.pid"
PAUSEFILE="/tmp/tts_read.paused"
AUDIO_FILE="/tmp/edge_tts_output.mp3"

if [ -f "$PIDFILE" ]; then
    PID=$(cat "$PIDFILE")
    if kill -0 "$PID" 2>/dev/null; then
        # Resume first if paused (so kill works properly)
        kill -CONT "$PID" 2>/dev/null
        kill "$PID" 2>/dev/null
        notify-send -u low -t 1000 "TTS ⏹️" "Stopped"
    fi
    rm -f "$PIDFILE" "$PAUSEFILE" "$AUDIO_FILE"
else
    notify-send -u low -t 1000 "TTS" "Nothing playing"
fi

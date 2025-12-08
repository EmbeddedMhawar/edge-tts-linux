#!/bin/bash

# --- CONFIG ---
# Voice options: en-US-AndrewMultilingualNeural, en-US-ChristopherNeural, en-US-GuyNeural, fr-FR-HenriNeural
VOICE="en-US-AndrewMultilingualNeural"
RATE="+10%"   # Speed: -50% to +100%
VOLUME="+0%"  # Volume: -50% to +50%
PITCH="+0Hz"  # Pitch: -50Hz to +50Hz

AUDIO_FILE="/tmp/edge_tts_output.mp3"
PIDFILE="/tmp/tts_read.pid"
PAUSEFILE="/tmp/tts_read.paused"
GENFILE="/tmp/tts_generating"
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
# ----------------

# Function to stop any running TTS
stop_tts() {
    if [ -f "$PIDFILE" ]; then
        PID=$(cat "$PIDFILE")
        if kill -0 "$PID" 2>/dev/null; then
            kill -CONT "$PID" 2>/dev/null  # Resume if paused
            kill "$PID" 2>/dev/null
        fi
        rm -f "$PIDFILE" "$PAUSEFILE" "$AUDIO_FILE"
    fi
}

# Check if currently generating (Python script running)
if [ -f "$GENFILE" ]; then
    notify-send -u low -t 1000 "TTS" "Still generating... please wait"
    exit 0
fi

# Check if already playing/paused
if [ -f "$PIDFILE" ]; then
    PID=$(cat "$PIDFILE")
    if kill -0 "$PID" 2>/dev/null; then
        if [ -f "$PAUSEFILE" ]; then
            # Currently paused - Resume
            kill -CONT "$PID" 2>/dev/null
            rm -f "$PAUSEFILE"
            notify-send -u low -t 1000 "TTS ▶️" "Resumed"
        else
            # Currently playing - Pause
            kill -STOP "$PID" 2>/dev/null
            touch "$PAUSEFILE"
            notify-send -u low -t 1000 "TTS ⏸️" "Paused"
        fi
        exit 0
    fi
    rm -f "$PIDFILE" "$PAUSEFILE"
fi

# Get text from clipboard (primary selection = highlighted text, clipboard = copied text)
# Try primary selection first (highlighted text), then clipboard (Ctrl+C)
TEXT=$(wl-paste -p 2>/dev/null | tr -d '\0')
TEXT_TRIMMED=$(echo "$TEXT" | xargs 2>/dev/null)

if [ -z "$TEXT_TRIMMED" ]; then
    TEXT=$(wl-paste 2>/dev/null | tr -d '\0')
    TEXT_TRIMMED=$(echo "$TEXT" | xargs 2>/dev/null)
fi

# Check if there's any meaningful text
if [ -z "$TEXT_TRIMMED" ]; then
    notify-send -u normal -t 2000 "TTS" "No text selected or copied!"
    exit 1
fi

TEXT="$TEXT_TRIMMED"

# Limit text preview
PREVIEW=$(echo "$TEXT" | head -c 100)
[ ${#TEXT} -gt 100 ] && PREVIEW="$PREVIEW..."

notify-send -u low -t 2000 "TTS 🔊" "Reading: $PREVIEW"

# Mark as generating
touch "$GENFILE"

# Use our custom edge_tts_client.py (same DRM approach as browser extension)
python3 "$SCRIPT_DIR/edge_tts_client.py" \
    --text "$TEXT" \
    --voice "$VOICE" \
    --rate "$RATE" \
    --volume "$VOLUME" \
    --pitch "$PITCH" \
    --output "$AUDIO_FILE" 2>/tmp/edge_tts_error.log

GEN_STATUS=$?
rm -f "$GENFILE"

if [ $GEN_STATUS -ne 0 ]; then
    ERROR=$(cat /tmp/edge_tts_error.log 2>/dev/null | tail -3)
    notify-send -u critical "TTS Error" "Failed: $ERROR"
    exit 1
fi

if [ ! -s "$AUDIO_FILE" ]; then
    notify-send -u critical "TTS Error" "No audio generated"
    exit 1
fi

sync

# Play audio in detached process
(
    setsid nohup mpv --no-video --really-quiet "$AUDIO_FILE" >/dev/null 2>&1 &
    MPV_PID=$!
    echo $MPV_PID > "$PIDFILE"
    wait $MPV_PID
    rm -f "$PIDFILE" "$PAUSEFILE" "$AUDIO_FILE"
) &
disown

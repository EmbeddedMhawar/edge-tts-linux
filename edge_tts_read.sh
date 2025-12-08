#!/bin/bash

# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║  Edge TTS - Free Text-to-Speech for Linux                                 ║
# ║  Uses Microsoft Edge's online TTS API - No API key needed!                ║
# ║  Works on any distro with Wayland or X11                                  ║
# ╚═══════════════════════════════════════════════════════════════════════════╝

# --- CONFIG ---
# Voice options: Run 'python3 edge_tts_client.py --list-voices' to see all
VOICE="en-US-AndrewMultilingualNeural"
RATE="+10%"   # Speed: -50% to +100%
VOLUME="+0%"  # Volume: -50% to +50%
PITCH="+0Hz"  # Pitch: -50Hz to +50Hz

# Temp files
AUDIO_FILE="/tmp/edge_tts_output.mp3"
PIDFILE="/tmp/tts_read.pid"
PAUSEFILE="/tmp/tts_read.paused"
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

# --- CLIPBOARD TOOL DETECTION ---
if [ "$XDG_SESSION_TYPE" = "wayland" ]; then
    PASTE_CMD="wl-paste"
    PASTE_PRIMARY="wl-paste -p"
else
    PASTE_CMD="xclip -selection clipboard -o"
    PASTE_PRIMARY="xclip -selection primary -o"
fi
# ----------------

# Check if already playing/paused - toggle behavior
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
            notify-send -u low -t 1000 "TTS ⏸️" "Paused (press again to resume)"
        fi
        exit 0
    fi
    rm -f "$PIDFILE" "$PAUSEFILE"
fi

# Get text from clipboard (try primary selection first, then clipboard)
TEXT=$($PASTE_PRIMARY 2>/dev/null | tr -d '\0')
TEXT_TRIMMED=$(echo "$TEXT" | xargs 2>/dev/null)

if [ -z "$TEXT_TRIMMED" ]; then
    TEXT=$($PASTE_CMD 2>/dev/null | tr -d '\0')
    TEXT_TRIMMED=$(echo "$TEXT" | xargs 2>/dev/null)
fi

# Check if there's any meaningful text
if [ -z "$TEXT_TRIMMED" ]; then
    notify-send -u normal -t 2000 "TTS" "No text selected or copied!"
    exit 1
fi

TEXT="$TEXT_TRIMMED"

# Limit text preview in notification
PREVIEW=$(echo "$TEXT" | head -c 100)
[ ${#TEXT} -gt 100 ] && PREVIEW="$PREVIEW..."

notify-send -u low -t 2000 "TTS 🔊" "Reading: $PREVIEW"

# Generate speech
python3 "$SCRIPT_DIR/edge_tts_client.py" \
    --text "$TEXT" \
    --voice "$VOICE" \
    --rate "$RATE" \
    --volume "$VOLUME" \
    --pitch "$PITCH" \
    --output "$AUDIO_FILE" 2>/tmp/edge_tts_error.log

if [ $? -ne 0 ]; then
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

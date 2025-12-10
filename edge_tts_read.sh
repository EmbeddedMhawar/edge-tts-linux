#!/bin/bash
# Edge TTS Streaming - FIFO-based for instant playback
# Uses a named pipe so mpv starts first and receives audio as it arrives.
# Keybinding: SUPER+E

# --- CONFIG ---
# Voice options: en-US-AndrewMultilingualNeural, en-US-ChristopherNeural, en-US-GuyNeural, fr-FR-HenriNeural
VOICE="en-US-AndrewMultilingualNeural"
RATE="+10%"   # Speed: -50% to +100%
VOLUME="+0%"  # Volume: -50% to +50%
PITCH="+0Hz"  # Pitch: -50Hz to +50Hz

FIFO="/tmp/edge_tts_fifo"
PIDFILE="/tmp/tts_read.pid"
PYPIDFILE="/tmp/tts_python.pid"
PAUSEFILE="/tmp/tts_read.paused"
GENFILE="/tmp/tts_streaming"
ERRORLOG="/tmp/edge_tts_error.log"
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
# ----------------

# Check if currently streaming (Python still generating)
if [ -f "$GENFILE" ]; then
    notify-send -u low -t 1000 "TTS" "Still streaming... please wait"
    exit 0
fi

# Check if already playing/paused
if [ -f "$PIDFILE" ]; then
    MPV_PID=$(cat "$PIDFILE" 2>/dev/null)
    if [ -n "$MPV_PID" ] && kill -0 "$MPV_PID" 2>/dev/null; then
        if [ -f "$PAUSEFILE" ]; then
            # Currently paused - Resume both mpv and Python
            kill -CONT "$MPV_PID" 2>/dev/null
            if [ -f "$PYPIDFILE" ]; then
                PY_PID=$(cat "$PYPIDFILE" 2>/dev/null)
                [ -n "$PY_PID" ] && kill -CONT "$PY_PID" 2>/dev/null
            fi
            rm -f "$PAUSEFILE"
            notify-send -u low -t 1000 "TTS ▶️" "Resumed"
        else
            # Currently playing - Pause both mpv and Python
            kill -STOP "$MPV_PID" 2>/dev/null
            if [ -f "$PYPIDFILE" ]; then
                PY_PID=$(cat "$PYPIDFILE" 2>/dev/null)
                [ -n "$PY_PID" ] && kill -STOP "$PY_PID" 2>/dev/null
            fi
            touch "$PAUSEFILE"
            notify-send -u low -t 1000 "TTS ⏸️" "Paused"
        fi
        exit 0
    fi
    # Process died, clean up
    rm -f "$PIDFILE" "$PYPIDFILE" "$PAUSEFILE" "$FIFO"
fi

# Get text from clipboard (primary selection = highlighted text, clipboard = copied text)
TEXT=$(wl-paste -p 2>/dev/null | tr -d '\0')
TEXT_TRIMMED=$(echo "$TEXT" | xargs 2>/dev/null)

if [ -z "$TEXT_TRIMMED" ]; then
    TEXT=$(wl-paste 2>/dev/null | tr -d '\0')
    TEXT_TRIMMED=$(echo "$TEXT" | xargs 2>/dev/null)
fi

if [ -z "$TEXT_TRIMMED" ]; then
    notify-send -u normal -t 2000 "TTS" "No text selected or copied!"
    exit 1
fi

TEXT="$TEXT_TRIMMED"

# Limit text preview
PREVIEW=$(echo "$TEXT" | head -c 100)
[ ${#TEXT} -gt 100 ] && PREVIEW="$PREVIEW..."

notify-send -u low -t 2000 "TTS 🔊" "Reading: $PREVIEW"

# Mark as streaming
touch "$GENFILE"

# Clean up any existing FIFO and error log
rm -f "$FIFO" "$ERRORLOG"
mkfifo "$FIFO"

# Start the streaming process in background
(
    # Start mpv first (it will block waiting for data)
    mpv --no-video --really-quiet --cache=no --demuxer-max-bytes=1M "$FIFO" &
    MPV_PID=$!
    echo $MPV_PID > "$PIDFILE"
    
    # Give mpv a moment to open the FIFO
    sleep 0.1
    
    # Start Python streaming to FIFO
    python3 "$SCRIPT_DIR/edge_tts_client.py" \
        --text "$TEXT" \
        --voice "$VOICE" \
        --rate "$RATE" \
        --volume "$VOLUME" \
        --pitch "$PITCH" \
        --output "$FIFO" 2>"$ERRORLOG" &
    PY_PID=$!
    echo $PY_PID > "$PYPIDFILE"
    
    # Remove generating flag once both processes started
    rm -f "$GENFILE"
    
    # Wait for Python to finish
    wait $PY_PID 2>/dev/null
    PY_EXIT=$?
    
    # Check if Python errored
    if [ $PY_EXIT -ne 0 ] && [ -s "$ERRORLOG" ]; then
        ERROR=$(tail -3 "$ERRORLOG" 2>/dev/null)
        notify-send -u critical "TTS Error" "$ERROR"
        kill $MPV_PID 2>/dev/null
    fi
    
    # Wait for mpv to finish playing
    wait $MPV_PID 2>/dev/null
    
    # Clean up
    rm -f "$PIDFILE" "$PYPIDFILE" "$PAUSEFILE" "$FIFO"
) &
disown

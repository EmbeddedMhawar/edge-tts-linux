#!/usr/bin/env python3
"""
Edge TTS Streaming Client - Outputs audio chunks as they arrive for immediate playback.
This enables near-instant audio start, just like the browser extension.
"""

import asyncio
import hashlib
import time
import uuid
import sys
import os
from typing import List, Optional

try:
    import websockets
except ImportError:
    print("Installing websockets...", file=sys.stderr)
    import subprocess
    subprocess.check_call([sys.executable, "-m", "pip", "install", "--user", "websockets"])
    import websockets

# Constants (matching edge-tts-extension)
TRUSTED_CLIENT_TOKEN = "6A5AA1D4EAFF4E9FB37E23D68491D6F4"
CHROMIUM_VERSION = "130.0.2849.68"
WIN_EPOCH = 11644473600
S_TO_NS = 1e9
CHUNK_SIZE = 4096  # Same as browser extension


def generate_sec_ms_gec() -> str:
    """Generate Sec-MS-GEC token (same algorithm as edge-tts-extension/browserDrm.ts)"""
    ticks = time.time()
    ticks += WIN_EPOCH
    ticks -= ticks % 300
    ticks *= S_TO_NS / 100
    
    str_to_hash = f"{int(ticks)}{TRUSTED_CLIENT_TOKEN}"
    return hashlib.sha256(str_to_hash.encode()).hexdigest().upper()


def generate_connect_id() -> str:
    """Generate unique connection ID (no dashes)"""
    return uuid.uuid4().hex


def escape_xml(text: str) -> str:
    """Escape XML special characters"""
    return (text
            .replace("&", "&amp;")
            .replace("<", "&lt;")
            .replace(">", "&gt;")
            .replace('"', "&quot;")
            .replace("'", "&#39;"))


def remove_incompatible_characters(text: str) -> str:
    """Remove characters that cause issues with TTS"""
    result = ""
    for char in text:
        code = ord(char)
        if code >= 32 or char in '\n\r\t':
            result += char
    return result


def split_text_by_byte_length(text: str, max_bytes: int) -> List[str]:
    """
    Split text into chunks of max_bytes, trying to split at natural boundaries.
    """
    chunks = []
    text_bytes = text.encode('utf-8')
    
    while len(text_bytes) > max_bytes:
        split_at = max_bytes
        
        slice_text = text_bytes[:max_bytes].decode('utf-8', errors='ignore')
        last_newline = slice_text.rfind('\n')
        last_space = slice_text.rfind(' ')
        
        if last_newline > 0:
            split_at = len(slice_text[:last_newline].encode('utf-8'))
        elif last_space > 0:
            split_at = len(slice_text[:last_space].encode('utf-8'))
        
        chunk = text_bytes[:split_at].decode('utf-8', errors='ignore').strip()
        if chunk:
            chunks.append(chunk)
        
        text_bytes = text_bytes[split_at:]
    
    remaining = text_bytes.decode('utf-8', errors='ignore').strip()
    if remaining:
        chunks.append(remaining)
    
    return chunks


def date_to_string() -> str:
    """Generate timestamp string like edge-tts-extension"""
    return time.strftime("%a %b %d %Y %H:%M:%S GMT+0000 (Coordinated Universal Time)", time.gmtime())


def parse_binary_message(data: bytes) -> tuple:
    """Parse binary message from WebSocket."""
    if len(data) < 2:
        return {}, b''
    
    header_length = (data[0] << 8) | data[1]
    
    headers = {}
    if header_length > 0 and header_length + 2 <= len(data):
        header_bytes = data[2:header_length + 2]
        header_string = header_bytes.decode('utf-8', errors='ignore')
        for line in header_string.split('\r\n'):
            if ':' in line:
                key, value = line.split(':', 1)
                headers[key.strip()] = value.strip()
    
    audio_data = data[header_length + 2:]
    return headers, audio_data


def parse_text_message(data: str) -> tuple:
    """Parse text message from WebSocket."""
    headers = {}
    header_end = data.find('\r\n\r\n')
    if header_end != -1:
        header_string = data[:header_end]
        for line in header_string.split('\r\n'):
            if ':' in line:
                key, value = line.split(':', 1)
                headers[key.strip()] = value.strip()
    return headers, data[header_end + 4:] if header_end != -1 else data


async def stream_chunk(text: str, voice: str, rate: str, volume: str, pitch: str, output_stream):
    """Stream a single chunk of text, writing audio bytes as they arrive."""
    sec_ms_gec = generate_sec_ms_gec()
    sec_ms_gec_version = f"1-{CHROMIUM_VERSION}"
    connect_id = generate_connect_id()
    request_id = generate_connect_id()
    timestamp = date_to_string()
    
    wss_url = (
        f"wss://speech.platform.bing.com/consumer/speech/synthesize/readaloud/edge/v1"
        f"?TrustedClientToken={TRUSTED_CLIENT_TOKEN}"
        f"&Sec-MS-GEC={sec_ms_gec}"
        f"&Sec-MS-GEC-Version={sec_ms_gec_version}"
        f"&ConnectionId={connect_id}"
    )
    
    escaped_text = escape_xml(text)
    
    ssml = (
        f"<speak version='1.0' xmlns='http://www.w3.org/2001/10/synthesis' xml:lang='en-US'>"
        f"<voice name='{voice}'>"
        f"<prosody pitch='{pitch}' rate='{rate}' volume='{volume}'>"
        f"{escaped_text}"
        f"</prosody></voice></speak>"
    )
    
    config_message = (
        f"X-Timestamp:{timestamp}\r\n"
        f"Content-Type:application/json; charset=utf-8\r\n"
        f"Path:speech.config\r\n\r\n"
        f'{{"context":{{"synthesis":{{"audio":{{"metadataoptions":{{'
        f'"sentenceBoundaryEnabled":"false","wordBoundaryEnabled":"true"}},'
        f'"outputFormat":"audio-24khz-48kbitrate-mono-mp3"}}}}}}}}\r\n'
    )
    
    ssml_message = (
        f"X-RequestId:{request_id}\r\n"
        f"Content-Type:application/ssml+xml\r\n"
        f"X-Timestamp:{timestamp}Z\r\n"
        f"Path:ssml\r\n\r\n"
        f"{ssml}"
    )
    
    async with websockets.connect(wss_url) as websocket:
        await websocket.send(config_message)
        await websocket.send(ssml_message)
        
        async for message in websocket:
            if isinstance(message, bytes):
                headers, data = parse_binary_message(message)
                if headers.get('Path') == 'audio' and len(data) > 0:
                    # Write audio chunk immediately to output stream
                    output_stream.write(data)
                    output_stream.flush()
            else:
                headers, _ = parse_text_message(message)
                if headers.get('Path') == 'turn.end':
                    break


async def stream_synthesize(text: str, voice: str = "en-US-AndrewMultilingualNeural", 
                            rate: str = "+0%", volume: str = "+0%", pitch: str = "+0Hz",
                            output_file: Optional[str] = None) -> bool:
    """
    Stream text to speech, outputting audio as chunks arrive.
    If output_file is provided, writes to that file.
    Otherwise writes to stdout for piping to mpv.
    """
    clean_text = remove_incompatible_characters(text)
    chunks = split_text_by_byte_length(escape_xml(clean_text), CHUNK_SIZE)
    
    if not chunks:
        print("No text to synthesize", file=sys.stderr)
        return False
    
    try:
        # Decide where to output
        if output_file:
            output_stream = open(output_file, 'wb')
        else:
            # Write to stdout binary mode
            output_stream = sys.stdout.buffer
        
        for chunk in chunks:
            await stream_chunk(chunk, voice, rate, volume, pitch, output_stream)
        
        if output_file:
            output_stream.close()
        
        return True
            
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        import traceback
        traceback.print_exc()
        return False


def main():
    import argparse
    parser = argparse.ArgumentParser(description="Edge TTS Streaming Client")
    parser.add_argument("--text", "-t", required=True, help="Text to synthesize")
    parser.add_argument("--voice", "-v", default="en-US-AndrewMultilingualNeural", help="Voice name")
    parser.add_argument("--rate", "-r", default="+0%", help="Speech rate (e.g., +10%, -20%)")
    parser.add_argument("--volume", default="+0%", help="Volume (e.g., +10%, -20%)")
    parser.add_argument("--pitch", "-p", default="+0Hz", help="Pitch (e.g., +10Hz, -5Hz)")
    parser.add_argument("--output", "-o", default=None, help="Output file (default: stdout for streaming)")
    
    args = parser.parse_args()
    
    success = asyncio.run(stream_synthesize(
        text=args.text,
        voice=args.voice,
        rate=args.rate,
        volume=args.volume,
        pitch=args.pitch,
        output_file=args.output
    ))
    
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()

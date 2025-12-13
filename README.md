# Edge TTS for Linux

**Free, streaming text-to-speech for your desktop.**

A lightweight, instant text-to-speech solution for Linux using Microsoft Edge's online API. No API key required.

## Core Philosophy
TTS on Linux shouldn't be complicated or robotic. This tool provides **instant, high-quality streaming audio** without the need for heavy downloads or paid API keys. It's designed to be a seamless part of your workflow—just highlight and listen.

## Features

### 1. Instant Playback
Stream audio immediately as it's generated. No waiting for the whole file to download.

### 2. Zero Config
Uses Microsoft Edge's free TTS API. No accounts, no keys, no hassle.

### 3. Desktop Integration
Works with any text selection.
- **Read**: Highlight text -> Press Keybind -> Listen.
- **Control**: Pause, Resume, or Stop instantly.

## Setup

### 1. Install Dependencies

<details>
<summary><b>Arch Linux / Manjaro</b></summary>

```bash
sudo pacman -S python mpv libnotify python-websockets
# For Wayland:
sudo pacman -S wl-clipboard
# For X11:
sudo pacman -S xclip
```
</details>

<details>
<summary><b>Ubuntu / Debian / Pop!_OS</b></summary>

```bash
sudo apt install python3 mpv libnotify-bin python3-websockets
# For Wayland:
sudo apt install wl-clipboard
# For X11:
sudo apt install xclip
```
</details>

<details>
<summary><b>Fedora</b></summary>

```bash
sudo dnf install python3 mpv libnotify python3-websockets
# For Wayland:
sudo dnf install wl-clipboard
# For X11:
sudo dnf install xclip
```
</details>

<details>
<summary><b>NixOS</b></summary>

```nix
environment.systemPackages = with pkgs; [
  python3
  python3Packages.websockets
  mpv
  libnotify
  wl-clipboard  # For Wayland
  # xclip       # For X11
];
```
</details>

### 2. Install Script

```bash
git clone https://github.com/EmbeddedMhawar/edge-tts.git
cd edge-tts
chmod +x *.sh *.py
```

### 3. Keybindings

<details>
<summary><b>Hyprland</b></summary>

Add to `~/.config/hypr/hyprland.conf`:
```conf
bind = SUPER, E, exec, /path/to/edge_tts_read.sh
bind = SUPER SHIFT, E, exec, /path/to/edge_tts_stop.sh
```
</details>

<details>
<summary><b>Sway</b></summary>

Add to `~/.config/sway/config`:
```conf
bindsym $mod+e exec /path/to/edge_tts_read.sh
bindsym $mod+Shift+e exec /path/to/edge_tts_stop.sh
```
</details>

<details>
<summary><b>GNOME</b></summary>

1. Open **Settings** → **Keyboard** → **Keyboard Shortcuts**
2. Scroll to bottom → **Custom Shortcuts** → **+**
3. Name: `Edge TTS Read`, Command: `/path/to/edge_tts_read.sh`, Shortcut: `Super+E`
4. Add another: `Edge TTS Stop`, Command: `/path/to/edge_tts_stop.sh`, Shortcut: `Super+Shift+E`
</details>

<details>
<summary><b>KDE Plasma</b></summary>

1. Open **System Settings** → **Shortcuts** → **Custom Shortcuts**
2. **Edit** → **New** → **Global Shortcut** → **Command/URL**
3. Set trigger to `Super+E`, Action: `/path/to/edge_tts_read.sh`
4. Add another for `Super+Shift+E` → `/path/to/edge_tts_stop.sh`
</details>

<details>
<summary><b>i3</b></summary>

Add to `~/.config/i3/config`:
```conf
bindsym $mod+e exec /path/to/edge_tts_read.sh
bindsym $mod+Shift+e exec /path/to/edge_tts_stop.sh
```
</details>

## License
MIT

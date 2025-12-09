# 🔊 Edge TTS - Free Text-to-Speech for Linux

> **Read any text aloud using Microsoft Edge's free TTS API - no API key needed!**

A lightweight, **streaming** text-to-speech solution for Linux using Microsoft Edge's online TTS service. Audio starts playing **instantly** as it's being generated - no waiting for full downloads!

![Demo](https://img.shields.io/badge/Highlight_Text-Super%2BE-blue?style=for-the-badge) → 🔊 Reads aloud!

## ✨ Features

- 🆓 **Completely free** – Uses Microsoft Edge's TTS API, no API key required
- ⚡ **Instant playback** – Streaming audio starts immediately, no waiting
- 🎯 **400+ voices** – Multiple languages and voice styles
- ⏯️ **Pause/Resume** – Press keybind again to pause, again to resume
- ⏹️ **Stop anytime** – Shift+keybind to stop playback
- 📋 **Read highlighted text** – Just select text and press keybind
- 🔁 **Long text support** – Automatically chunks long text
- 🎯 **Lightweight** – Just bash + Python, no bloat

## 📦 Installation

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

### 2. Set Up the Script

```bash
# Clone the repository
git clone https://github.com/EmbeddedMhawar/edge-tts.git
cd edge-tts

# Make scripts executable
chmod +x edge_tts_read.sh edge_tts_stop.sh edge_tts_client.py

# Copy to your preferred location (optional)
cp edge_tts_*.sh edge_tts_client.py ~/bin/
```

### 3. Set Up Keybindings

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

## 🎯 Usage

| Action | Keybinding | Description |
|--------|-----------|-------------|
| **Read** | `Super+E` | Reads highlighted or copied text |
| **Pause** | `Super+E` (while playing) | Pauses playback |
| **Resume** | `Super+E` (while paused) | Resumes playback |
| **Stop** | `Super+Shift+E` | Stops playback completely |

### Quick Start
1. **Highlight any text** in any application
2. **Press `Super+E`** → Audio starts playing instantly!
3. **Press `Super+E` again** → Pause/Resume
4. **Press `Super+Shift+E`** → Stop

## ⚙️ Configuration

Edit `edge_tts_read.sh` to customize:

```bash
# Voice (run: edge-tts --list-voices to see all 400+ options)
VOICE="en-US-AndrewMultilingualNeural"

# Speed (-50% to +100%)
RATE="+10%"

# Volume (-50% to +50%)
VOLUME="+0%"

# Pitch (-50Hz to +50Hz)
PITCH="+0Hz"
```

### Popular Voices

| Voice | Language | Gender |
|-------|----------|--------|
| `en-US-AndrewMultilingualNeural` | English (US) | Male |
| `en-US-JennyNeural` | English (US) | Female |
| `en-GB-RyanNeural` | English (UK) | Male |
| `fr-FR-HenriNeural` | French | Male |
| `de-DE-ConradNeural` | German | Male |
| `es-ES-AlvaroNeural` | Spanish | Male |
| `zh-CN-YunxiNeural` | Chinese | Male |

## 🔧 Troubleshooting

### No audio playing
Make sure mpv is installed and audio is working:
```bash
mpv /usr/share/sounds/freedesktop/stereo/bell.oga
```

### "No text selected" error
- On Wayland: Make sure `wl-clipboard` is installed
- On X11: Make sure `xclip` is installed

### Python errors
Install websockets:
```bash
# Arch
sudo pacman -S python-websockets

# Ubuntu/Debian
sudo apt install python3-websockets

# Pip (if not available in repos)
pip install --user websockets
```

## 🤝 Contributing

PRs welcome! Ideas for improvements:
- [ ] Voice selection via rofi/dmenu
- [ ] Speed control via keybinds
- [ ] Subtitle display while reading

## 📜 License

MIT License - Use it however you want!

## 🙏 Acknowledgments

- [rany2/edge-tts](https://github.com/rany2/edge-tts) - Original edge-tts Python package (our implementation uses the same DRM approach)
- Microsoft Edge TTS for the free API

---

**Made with ❤️ for the Linux community**

# 🎬 Animated Wallpaper

<p align="center">
  <img src="docs/icon.png" alt="Animated Wallpaper Icon" width="128" height="128">
</p>

<p align="center">
  <strong>Transform your macOS desktop with animated wallpapers</strong>
</p>

<p align="center">
  <a href="#features">Features</a> •
  <a href="#installation">Installation</a> •
  <a href="#usage">Usage</a> •
  <a href="#building">Building</a> •
  <a href="#architecture">Architecture</a>
</p>

---

## ✨ Features

- **🎥 Video Wallpapers** — Use MP4, MOV, or M4V files as your desktop background
- **🖼️ GIF Support** — Animated GIFs with proper frame timing
- **📺 Multi-Monitor** — Automatically spans across all connected displays
- **📁 Wallpaper Library** — Save, manage, and quickly switch between wallpapers
- **🎛️ Menu Bar App** — Lives quietly in your menu bar, no dock clutter
- **⏯️ Playback Controls** — Play, pause, and stop from the menu

## 📸 Screenshots

<p align="center">
  <img src="docs/menu.png" alt="Menu Bar" width="300">
  <img src="docs/library.png" alt="Library Window" width="500">
</p>

## 💻 Requirements

- macOS 13.0 (Ventura) or later
- Apple Silicon or Intel Mac

## 📦 Installation

### Download

Download the latest installer from the [Releases](../../releases) page:

1. Download `AnimatedWallpaper-Installer.pkg`
2. Double-click to run the installer
3. Follow the installation wizard

### Homebrew (Coming Soon)

```bash
brew install --cask animated-wallpaper
```

## 🚀 Usage

1. **Launch** — Open Animated Wallpaper from your Applications folder
2. **Find the icon** — Look for the icon in your menu bar (top-right of screen)
3. **Open Library** — Click the icon → "Wallpaper Library..."
4. **Add Wallpapers** — Click "Add" to import videos or GIFs
5. **Set Wallpaper** — Hover over any wallpaper and click "Use"

### Supported Formats

| Format | Extensions |
|--------|------------|
| Video | `.mp4`, `.mov`, `.m4v` |
| Image | `.gif` |

### Menu Options

| Option | Description |
|--------|-------------|
| Wallpaper Library... | Open the wallpaper management window |
| Open File... | Quick-open a file without saving to library |
| Play/Pause | Toggle playback of current wallpaper |
| Stop Wallpaper | Remove animated wallpaper, show system wallpaper |
| Recent Wallpapers | Quick access to your last 5 wallpapers |

## 🏗️ Building

### Prerequisites

- Xcode 15.0 or later
- macOS 13.0 SDK or later

### Build from Source

```bash
# Clone the repository
git clone https://github.com/davidmedvedev/AnimatedWallpaper.git
cd AnimatedWallpaper

# Open in Xcode
open AnimatedWallpaper.xcworkspace

# Or build from command line
xcodebuild -workspace AnimatedWallpaper.xcworkspace \
           -scheme AnimatedWallpaper \
           -configuration Release
```

### Create Installer

```bash
# Build release
xcodebuild -workspace AnimatedWallpaper.xcworkspace \
           -scheme AnimatedWallpaper \
           -configuration Release \
           -derivedDataPath build

# Create installer package
./scripts/create-installer.sh
```

## 🏛️ Architecture

```
AnimatedWallpaper/
├── main.swift                    # App entry point
├── AppDelegate.swift             # Menu bar & app lifecycle
├── WallpaperWindowManager.swift  # Desktop window management
├── WallpaperLibrary.swift        # Persistence & library management
├── LibraryWindowController.swift # SwiftUI library UI
├── VideoWallpaperView.swift      # AVPlayer-based video playback
├── GIFWallpaperView.swift        # Timer-based GIF animation
└── Assets.xcassets/              # App icons
```

### Key Components

#### WallpaperWindowManager
Creates borderless windows at the desktop level (`CGWindowLevelForKey(.desktopWindow)`) that render behind Finder's desktop icons.

#### VideoWallpaperView
Uses `AVQueuePlayer` with `AVPlayerLooper` for seamless, gapless video looping with hardware-accelerated playback.

#### GIFWallpaperView
Extracts frames from GIFs using `CGImageSource` and animates them with a 60fps timer for smooth playback.

#### WallpaperLibrary
Manages saved wallpapers with:
- File copying to `~/Library/Application Support/AnimatedWallpaper/`
- Metadata persistence via UserDefaults
- Thumbnail generation for videos and GIFs

### Data Flow

```
┌─────────────┐     ┌──────────────────────┐     ┌─────────────────┐
│  Menu Bar   │────▶│  WallpaperManager    │────▶│  Desktop Window │
│  (AppDelegate)    │  (Window Management) │     │  (NSWindow)     │
└─────────────┘     └──────────────────────┘     └─────────────────┘
       │                      │                          │
       │                      ▼                          ▼
       │            ┌──────────────────┐       ┌─────────────────┐
       │            │  VideoWallpaper  │       │   GIFWallpaper  │
       │            │  View (AVPlayer) │       │   View (Timer)  │
       │            └──────────────────┘       └─────────────────┘
       │
       ▼
┌─────────────────┐
│ WallpaperLibrary│
│ (Persistence)   │
└─────────────────┘
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👤 Author

**David Medvedev**

- GitHub: [@davidmedvedev](https://github.com/davidmedvedev)

## 🙏 Acknowledgments

- Built with Swift and AppKit
- Icons created with custom pixel art generator
- Inspired by the need for more lively desktops

---

<p align="center">
  Made with ❤️ for macOS
</p>

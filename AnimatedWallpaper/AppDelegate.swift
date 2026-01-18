import AppKit
import AVFoundation

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var wallpaperManager: WallpaperWindowManager!
    private var libraryController: LibraryWindowController!
    private var currentMediaURL: URL?
    private var isPlaying = false
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        wallpaperManager = WallpaperWindowManager()
        libraryController = LibraryWindowController()
        setupMenuBar()
    }
    
    // MARK: - Menu Bar Setup
    
    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = statusItem.button {
            if let image = NSImage(systemSymbolName: "play.rectangle.fill", accessibilityDescription: "Animated Wallpaper") {
                image.isTemplate = true
                button.image = image
            } else {
                button.title = "🎬"
            }
        }
        
        updateMenu()
    }
    
    private func updateMenu() {
        let menu = NSMenu()
        
        // Library
        let libraryItem = NSMenuItem(title: "Wallpaper Library...", action: #selector(openLibrary), keyEquivalent: "l")
        libraryItem.target = self
        menu.addItem(libraryItem)
        
        // Open file
        let openItem = NSMenuItem(title: "Open File...", action: #selector(openFile), keyEquivalent: "o")
        openItem.target = self
        menu.addItem(openItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Current wallpaper controls
        if currentMediaURL != nil {
            // Now Playing header
            let nowPlaying = NSMenuItem(title: "Now Playing:", action: nil, keyEquivalent: "")
            nowPlaying.isEnabled = false
            menu.addItem(nowPlaying)
            
            let nameItem = NSMenuItem(title: "  \(currentMediaURL?.lastPathComponent ?? "Unknown")", action: nil, keyEquivalent: "")
            nameItem.isEnabled = false
            menu.addItem(nameItem)
            
            menu.addItem(NSMenuItem.separator())
            
            // Play/Pause
            let playPauseItem = NSMenuItem(
                title: isPlaying ? "Pause" : "Play",
                action: #selector(togglePlayPause),
                keyEquivalent: "p"
            )
            playPauseItem.target = self
            menu.addItem(playPauseItem)
            
            // Save to Library (if not already from library)
            if !isFromLibrary(currentMediaURL) {
                let saveItem = NSMenuItem(title: "Save to Library", action: #selector(saveToLibrary), keyEquivalent: "")
                saveItem.target = self
                menu.addItem(saveItem)
            }
            
            // Stop
            let stopItem = NSMenuItem(title: "Stop Wallpaper", action: #selector(stopWallpaper), keyEquivalent: "s")
            stopItem.target = self
            menu.addItem(stopItem)
            
            menu.addItem(NSMenuItem.separator())
        }
        
        // Recent wallpapers submenu
        let recentWallpapers = WallpaperLibrary.shared.wallpapers.prefix(5)
        if !recentWallpapers.isEmpty {
            let recentMenu = NSMenu()
            for item in recentWallpapers {
                let menuItem = NSMenuItem(title: item.name, action: #selector(selectRecentWallpaper(_:)), keyEquivalent: "")
                menuItem.target = self
                menuItem.representedObject = item
                recentMenu.addItem(menuItem)
            }
            
            let recentItem = NSMenuItem(title: "Recent Wallpapers", action: nil, keyEquivalent: "")
            recentItem.submenu = recentMenu
            menu.addItem(recentItem)
            
            menu.addItem(NSMenuItem.separator())
        }
        
        // Quit
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem.menu = menu
    }
    
    private func isFromLibrary(_ url: URL?) -> Bool {
        guard let url = url else { return false }
        let libraryPath = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("AnimatedWallpaper/Library").path
        return url.path.hasPrefix(libraryPath)
    }
    
    // MARK: - Actions
    
    @objc private func openLibrary() {
        // Temporarily become a regular app to properly take focus
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        
        libraryController.showWindow { [weak self] item in
            self?.loadWallpaperItem(item)
        }
        
        // Return to accessory mode after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            NSApp.setActivationPolicy(.accessory)
        }
    }
    
    @objc private func openFile() {
        // Temporarily become a regular app to properly take focus
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [
            .mpeg4Movie,
            .quickTimeMovie,
            .movie,
            .gif
        ]
        panel.message = "Select a video or GIF file for your animated wallpaper"
        
        let result = panel.runModal()
        
        // Return to accessory mode
        NSApp.setActivationPolicy(.accessory)
        
        if result == .OK, let url = panel.url {
            loadWallpaper(from: url)
        }
    }
    
    @objc private func saveToLibrary() {
        guard let url = currentMediaURL else { return }
        _ = WallpaperLibrary.shared.addWallpaper(from: url)
        updateMenu()
    }
    
    @objc private func selectRecentWallpaper(_ sender: NSMenuItem) {
        guard let item = sender.representedObject as? WallpaperItem else { return }
        loadWallpaperItem(item)
    }
    
    private func loadWallpaperItem(_ item: WallpaperItem) {
        guard let url = item.url, item.exists else { return }
        
        currentMediaURL = url
        isPlaying = true
        
        wallpaperManager.setWallpaper(url: url, isGIF: item.isGIF)
        wallpaperManager.play()
        
        updateMenu()
    }
    
    private func loadWallpaper(from url: URL) {
        currentMediaURL = url
        isPlaying = true
        
        let fileExtension = url.pathExtension.lowercased()
        let isGIF = fileExtension == "gif"
        
        wallpaperManager.setWallpaper(url: url, isGIF: isGIF)
        wallpaperManager.play()
        
        updateMenu()
    }
    
    @objc private func togglePlayPause() {
        if isPlaying {
            wallpaperManager.pause()
        } else {
            wallpaperManager.play()
        }
        isPlaying.toggle()
        updateMenu()
    }
    
    @objc private func stopWallpaper() {
        wallpaperManager.stop()
        currentMediaURL = nil
        isPlaying = false
        updateMenu()
    }
    
    @objc private func quitApp() {
        wallpaperManager.stop()
        NSApplication.shared.terminate(nil)
    }
}

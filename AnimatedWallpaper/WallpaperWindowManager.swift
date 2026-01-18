import AppKit
import AVFoundation

/// Manages desktop-level windows for displaying animated wallpapers across all screens
class WallpaperWindowManager {
    private var wallpaperWindows: [String: NSWindow] = [:]  // Key by screen identifier
    private var videoViews: [String: VideoWallpaperView] = [:]
    private var gifViews: [String: GIFWallpaperView] = [:]
    private var currentURL: URL?
    private var currentIsGIF = false
    private var screenObserver: NSObjectProtocol?
    
    init() {
        setupScreenObserver()
    }
    
    deinit {
        if let observer = screenObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    private func screenID(_ screen: NSScreen) -> String {
        return "\(screen.frame)"
    }
    
    // MARK: - Screen Observer
    
    private func setupScreenObserver() {
        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleScreenChange()
        }
    }
    
    private func handleScreenChange() {
        guard let url = currentURL else { return }
        
        // Just refresh all screens
        for screen in NSScreen.screens {
            let id = screenID(screen)
            if let window = wallpaperWindows[id] {
                window.setFrame(screen.frame, display: true)
            } else {
                setupWindow(for: screen, url: url, isGIF: currentIsGIF)
            }
        }
    }
    
    // MARK: - Window Management
    
    private func setupWindow(for screen: NSScreen, url: URL, isGIF: Bool) {
        let id = screenID(screen)
        
        // Reuse existing window or create new one
        let window: NSWindow
        if let existingWindow = wallpaperWindows[id] {
            window = existingWindow
            window.setFrame(screen.frame, display: false)
        } else {
            window = NSWindow(
                contentRect: screen.frame,
                styleMask: .borderless,
                backing: .buffered,
                defer: false
            )
            window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow)))
            window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
            window.isOpaque = false
            window.backgroundColor = .clear
            window.ignoresMouseEvents = true
            window.acceptsMouseMovedEvents = false
            window.hasShadow = false
            wallpaperWindows[id] = window
        }
        
        // Setup content based on media type
        if isGIF {
            // Stop and hide any video view
            if let videoView = videoViews[id] {
                videoView.stop()
                videoView.isHidden = true
            }
            
            // Setup GIF view
            let gifView: GIFWallpaperView
            if let existingView = gifViews[id] {
                gifView = existingView
                gifView.stop()  // Stop previous animation
                gifView.frame = screen.frame
                gifView.isHidden = false
            } else {
                gifView = GIFWallpaperView(frame: screen.frame)
                gifViews[id] = gifView
            }
            
            window.contentView = gifView
            gifView.loadGIF(from: url)
            
        } else {
            // Stop and hide any GIF view
            if let gifView = gifViews[id] {
                gifView.stop()
                gifView.isHidden = true
            }
            
            // Setup video view
            let videoView: VideoWallpaperView
            if let existingView = videoViews[id] {
                videoView = existingView
                videoView.stop()  // Stop previous video
                videoView.frame = screen.frame
                videoView.isHidden = false
            } else {
                videoView = VideoWallpaperView(frame: screen.frame)
                videoViews[id] = videoView
            }
            
            window.contentView = videoView
            videoView.loadVideo(from: url)
        }
        
        window.orderFront(nil)
    }
    
    // MARK: - Public Interface
    
    func setWallpaper(url: URL, isGIF: Bool) {
        currentURL = url
        currentIsGIF = isGIF
        
        for screen in NSScreen.screens {
            setupWindow(for: screen, url: url, isGIF: isGIF)
        }
    }
    
    func play() {
        if currentIsGIF {
            for view in gifViews.values where !view.isHidden {
                view.play()
            }
        } else {
            for view in videoViews.values where !view.isHidden {
                view.play()
            }
        }
    }
    
    func pause() {
        for view in videoViews.values {
            view.pause()
        }
        for view in gifViews.values {
            view.pause()
        }
    }
    
    func stop() {
        // Just stop playback, don't destroy anything
        for view in videoViews.values {
            view.stop()
            view.isHidden = true
        }
        for view in gifViews.values {
            view.stop()
            view.isHidden = true
        }
        for window in wallpaperWindows.values {
            window.orderOut(nil)
        }
        currentURL = nil
    }
}

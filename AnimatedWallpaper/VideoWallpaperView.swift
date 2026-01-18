import AppKit
import AVFoundation
import AVKit

/// A view that displays looping video content using AVPlayer
class VideoWallpaperView: NSView {
    private var player: AVQueuePlayer?
    private var playerLooper: AVPlayerLooper?
    private var playerLayer: AVPlayerLayer?
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.black.cgColor
    }
    
    override func layout() {
        super.layout()
        playerLayer?.frame = bounds
    }
    
    // MARK: - Video Loading
    
    func loadVideo(from url: URL) {
        // Stop current playback
        player?.pause()
        player?.replaceCurrentItem(with: nil)
        playerLooper?.disableLooping()
        
        // Remove old layer
        playerLayer?.removeFromSuperlayer()
        
        // Create new player
        let playerItem = AVPlayerItem(url: url)
        let queuePlayer = AVQueuePlayer(playerItem: playerItem)
        let looper = AVPlayerLooper(player: queuePlayer, templateItem: playerItem)
        
        // Create new layer
        let newLayer = AVPlayerLayer(player: queuePlayer)
        newLayer.frame = bounds
        newLayer.videoGravity = .resizeAspectFill
        newLayer.backgroundColor = NSColor.black.cgColor
        
        self.layer?.addSublayer(newLayer)
        
        // Store references
        self.player = queuePlayer
        self.playerLooper = looper
        self.playerLayer = newLayer
        
        // Mute
        queuePlayer.isMuted = true
    }
    
    // MARK: - Playback Control
    
    func play() {
        player?.play()
    }
    
    func pause() {
        player?.pause()
    }
    
    func stop() {
        player?.pause()
        player?.replaceCurrentItem(with: nil)
        // Don't nil out references - just stop playback
    }
}

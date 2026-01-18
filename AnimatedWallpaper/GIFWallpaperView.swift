import AppKit
import ImageIO

/// A view that displays animated GIF content using CGImageSource frame extraction
class GIFWallpaperView: NSView {
    private var frames: [CGImage] = []
    private var frameDelays: [TimeInterval] = []
    private var currentFrameIndex = 0
    private weak var animationTimer: Timer?
    private var lastFrameTime: CFTimeInterval = 0
    private var accumulatedTime: CFTimeInterval = 0
    private var isAnimating = false
    private var imageLayer: CALayer?
    
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
        
        let imgLayer = CALayer()
        imgLayer.contentsGravity = .resizeAspectFill
        imgLayer.frame = bounds
        layer?.addSublayer(imgLayer)
        imageLayer = imgLayer
    }
    
    override func layout() {
        super.layout()
        imageLayer?.frame = bounds
    }
    
    // MARK: - GIF Loading
    
    func loadGIF(from url: URL) {
        // Stop current animation
        stopTimer()
        isAnimating = false
        
        // Load on background thread
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let data = try? Data(contentsOf: url),
                  let source = CGImageSourceCreateWithData(data as CFData, nil) else {
                return
            }
            
            let frameCount = CGImageSourceGetCount(source)
            guard frameCount > 0 else { return }
            
            var loadedFrames: [CGImage] = []
            var loadedDelays: [TimeInterval] = []
            
            for i in 0..<frameCount {
                guard let image = CGImageSourceCreateImageAtIndex(source, i, nil) else { continue }
                loadedFrames.append(image)
                loadedDelays.append(self?.getFrameDelay(from: source, at: i) ?? 0.1)
            }
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                self.frames = loadedFrames
                self.frameDelays = loadedDelays
                self.currentFrameIndex = 0
                self.accumulatedTime = 0
                
                // Display first frame
                if let firstFrame = self.frames.first {
                    CATransaction.begin()
                    CATransaction.setDisableActions(true)
                    self.imageLayer?.contents = firstFrame
                    CATransaction.commit()
                }
            }
        }
    }
    
    private func getFrameDelay(from source: CGImageSource, at index: Int) -> TimeInterval {
        let defaultDelay: TimeInterval = 0.1
        
        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [CFString: Any],
              let gifProperties = properties[kCGImagePropertyGIFDictionary] as? [CFString: Any] else {
            return defaultDelay
        }
        
        if let unclampedDelay = gifProperties[kCGImagePropertyGIFUnclampedDelayTime] as? TimeInterval, unclampedDelay > 0 {
            return unclampedDelay
        }
        
        if let delay = gifProperties[kCGImagePropertyGIFDelayTime] as? TimeInterval, delay > 0 {
            return delay
        }
        
        return defaultDelay
    }
    
    // MARK: - Timer Animation
    
    private func startTimer() {
        stopTimer()
        
        lastFrameTime = CACurrentMediaTime()
        accumulatedTime = 0
        
        let timer = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            self.updateFrame()
        }
        RunLoop.main.add(timer, forMode: .common)
        animationTimer = timer
    }
    
    private func stopTimer() {
        animationTimer?.invalidate()
        animationTimer = nil
    }
    
    private func updateFrame() {
        guard isAnimating, !frames.isEmpty, !frameDelays.isEmpty else { return }
        
        let currentTime = CACurrentMediaTime()
        let delta = currentTime - lastFrameTime
        lastFrameTime = currentTime
        accumulatedTime += delta
        
        let frameCount = frames.count
        let delayCount = frameDelays.count
        
        guard currentFrameIndex >= 0, currentFrameIndex < delayCount, currentFrameIndex < frameCount else {
            currentFrameIndex = 0
            return
        }
        
        let currentDelay = frameDelays[currentFrameIndex]
        
        if accumulatedTime >= currentDelay {
            accumulatedTime -= currentDelay
            currentFrameIndex = (currentFrameIndex + 1) % frameCount
            
            guard currentFrameIndex < frameCount else { return }
            
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            imageLayer?.contents = frames[currentFrameIndex]
            CATransaction.commit()
        }
    }
    
    // MARK: - Playback Control
    
    func play() {
        guard !frames.isEmpty else { return }
        isAnimating = true
        startTimer()
    }
    
    func pause() {
        isAnimating = false
        stopTimer()
    }
    
    func stop() {
        isAnimating = false
        stopTimer()
        currentFrameIndex = 0
        accumulatedTime = 0
        // Don't clear frames - just stop animation
        imageLayer?.contents = frames.first
    }
}

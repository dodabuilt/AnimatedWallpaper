import AppKit

// Traditional AppKit entry point for menu bar apps
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()

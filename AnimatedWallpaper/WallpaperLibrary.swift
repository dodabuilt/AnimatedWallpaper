import AppKit
import UniformTypeIdentifiers

/// Represents a saved wallpaper in the library
struct WallpaperItem: Codable, Identifiable, Equatable {
    let id: UUID
    let name: String
    let path: String
    let isGIF: Bool
    let dateAdded: Date
    
    var url: URL? {
        URL(fileURLWithPath: path)
    }
    
    var exists: Bool {
        FileManager.default.fileExists(atPath: path)
    }
}

/// Manages the wallpaper library with persistence
class WallpaperLibrary: ObservableObject {
    static let shared = WallpaperLibrary()
    
    @Published private(set) var wallpapers: [WallpaperItem] = []
    
    private let saveKey = "SavedWallpapers"
    private let libraryDirectory: URL
    
    private init() {
        // Create library directory in Application Support
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        libraryDirectory = appSupport.appendingPathComponent("AnimatedWallpaper/Library", isDirectory: true)
        
        try? FileManager.default.createDirectory(at: libraryDirectory, withIntermediateDirectories: true)
        
        loadWallpapers()
    }
    
    // MARK: - Persistence
    
    private func loadWallpapers() {
        guard let data = UserDefaults.standard.data(forKey: saveKey),
              let decoded = try? JSONDecoder().decode([WallpaperItem].self, from: data) else {
            return
        }
        // Filter out wallpapers whose files no longer exist
        wallpapers = decoded.filter { $0.exists }
    }
    
    private func saveWallpapers() {
        guard let data = try? JSONEncoder().encode(wallpapers) else { return }
        UserDefaults.standard.set(data, forKey: saveKey)
    }
    
    // MARK: - Library Management
    
    func addWallpaper(from sourceURL: URL) -> WallpaperItem? {
        let fileName = sourceURL.lastPathComponent
        let destinationURL = libraryDirectory.appendingPathComponent(UUID().uuidString + "_" + fileName)
        
        do {
            // Copy file to library
            try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
            
            let isGIF = sourceURL.pathExtension.lowercased() == "gif"
            let item = WallpaperItem(
                id: UUID(),
                name: sourceURL.deletingPathExtension().lastPathComponent,
                path: destinationURL.path,
                isGIF: isGIF,
                dateAdded: Date()
            )
            
            wallpapers.insert(item, at: 0)
            saveWallpapers()
            
            return item
        } catch {
            print("Failed to copy wallpaper: \(error)")
            return nil
        }
    }
    
    func removeWallpaper(_ item: WallpaperItem) {
        // Remove file
        if let url = item.url {
            try? FileManager.default.removeItem(at: url)
        }
        
        // Remove from list
        wallpapers.removeAll { $0.id == item.id }
        saveWallpapers()
    }
    
    func renameWallpaper(_ item: WallpaperItem, to newName: String) {
        guard let index = wallpapers.firstIndex(where: { $0.id == item.id }) else { return }
        
        let updated = WallpaperItem(
            id: item.id,
            name: newName,
            path: item.path,
            isGIF: item.isGIF,
            dateAdded: item.dateAdded
        )
        
        wallpapers[index] = updated
        saveWallpapers()
    }
    
    // MARK: - Thumbnails
    
    func generateThumbnail(for item: WallpaperItem, size: CGSize = CGSize(width: 200, height: 120)) -> NSImage? {
        guard let url = item.url else { return nil }
        
        if item.isGIF {
            return generateGIFThumbnail(from: url, size: size)
        } else {
            return generateVideoThumbnail(from: url, size: size)
        }
    }
    
    private func generateGIFThumbnail(from url: URL, size: CGSize) -> NSImage? {
        guard let data = try? Data(contentsOf: url),
              let source = CGImageSourceCreateWithData(data as CFData, nil),
              CGImageSourceGetCount(source) > 0,
              let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            return nil
        }
        
        return NSImage(cgImage: cgImage, size: size)
    }
    
    private func generateVideoThumbnail(from url: URL, size: CGSize) -> NSImage? {
        let asset = AVAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = size
        
        do {
            let cgImage = try generator.copyCGImage(at: .zero, actualTime: nil)
            return NSImage(cgImage: cgImage, size: size)
        } catch {
            return nil
        }
    }
}

import AVFoundation

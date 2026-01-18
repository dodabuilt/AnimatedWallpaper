import AppKit
import SwiftUI

/// Controller for the wallpaper library window
class LibraryWindowController: NSObject, NSWindowDelegate {
    private var window: NSWindow?
    private var onSelectWallpaper: ((WallpaperItem) -> Void)?
    
    func showWindow(onSelect: @escaping (WallpaperItem) -> Void) {
        onSelectWallpaper = onSelect
        
        if let existingWindow = window {
            existingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let contentView = LibraryView(onSelect: { [weak self] item in
            onSelect(item)
            self?.window?.close()
        })
        
        let hostingController = NSHostingController(rootView: contentView)
        
        let newWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 720, height: 520),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        newWindow.title = "Wallpaper Library"
        newWindow.contentViewController = hostingController
        newWindow.center()
        newWindow.setFrameAutosaveName("WallpaperLibrary")
        newWindow.minSize = NSSize(width: 500, height: 400)
        newWindow.isReleasedWhenClosed = false
        newWindow.delegate = self
        newWindow.level = .floating
        
        window = newWindow
        newWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func close() {
        window?.close()
    }
    
    // MARK: - NSWindowDelegate
    
    func windowWillClose(_ notification: Notification) {
        // Return to accessory mode when window closes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            NSApp.setActivationPolicy(.accessory)
        }
    }
}

// MARK: - SwiftUI Views

struct LibraryView: View {
    @ObservedObject private var library = WallpaperLibrary.shared
    @State private var selectedItem: WallpaperItem?
    @State private var hoveredItem: WallpaperItem?
    @State private var showingDeleteAlert = false
    @State private var itemToDelete: WallpaperItem?
    
    let onSelect: (WallpaperItem) -> Void
    
    private let columns = [
        GridItem(.adaptive(minimum: 180, maximum: 220), spacing: 16)
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                Text("Your Wallpapers")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: addWallpaper) {
                    Label("Add", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // Content
            if library.wallpapers.isEmpty {
                emptyState
            } else {
                wallpaperGrid
            }
        }
        .frame(minWidth: 500, minHeight: 400)
        .alert("Delete Wallpaper?", isPresented: $showingDeleteAlert, presenting: itemToDelete) { item in
            Button("Delete", role: .destructive) {
                library.removeWallpaper(item)
            }
            Button("Cancel", role: .cancel) {}
        } message: { item in
            Text("Are you sure you want to delete \"\(item.name)\"? This cannot be undone.")
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            Text("No Wallpapers Yet")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("Add videos or GIFs to your library to use as animated wallpapers.")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 300)
            
            Button("Add Wallpaper", action: addWallpaper)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    private var wallpaperGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(library.wallpapers) { item in
                    WallpaperCard(
                        item: item,
                        isSelected: selectedItem?.id == item.id,
                        isHovered: hoveredItem?.id == item.id,
                        onSelect: {
                            selectedItem = item
                            onSelect(item)
                        },
                        onDelete: {
                            itemToDelete = item
                            showingDeleteAlert = true
                        }
                    )
                    .onHover { hovering in
                        hoveredItem = hovering ? item : nil
                    }
                }
            }
            .padding()
        }
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    private func addWallpaper() {
        NSApp.activate(ignoringOtherApps: true)
        
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.mpeg4Movie, .quickTimeMovie, .movie, .gif]
        panel.message = "Select videos or GIFs to add to your library"
        
        if panel.runModal() == .OK {
            for url in panel.urls {
                _ = library.addWallpaper(from: url)
            }
        }
    }
}

struct WallpaperCard: View {
    let item: WallpaperItem
    let isSelected: Bool
    let isHovered: Bool
    let onSelect: () -> Void
    let onDelete: () -> Void
    
    @State private var thumbnail: NSImage?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Thumbnail
            ZStack {
                if let thumbnail = thumbnail {
                    Image(nsImage: thumbnail)
                        .resizable()
                        .aspectRatio(16/9, contentMode: .fill)
                        .frame(height: 110)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .aspectRatio(16/9, contentMode: .fill)
                        .frame(height: 110)
                        .overlay(
                            ProgressView()
                                .scaleEffect(0.7)
                        )
                }
                
                // Type badge
                VStack {
                    HStack {
                        Spacer()
                        Text(item.isGIF ? "GIF" : "VIDEO")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.ultraThinMaterial)
                            .cornerRadius(4)
                    }
                    Spacer()
                }
                .padding(8)
                
                // Hover overlay
                if isHovered {
                    Color.black.opacity(0.4)
                    
                    HStack(spacing: 12) {
                        Button(action: onSelect) {
                            Label("Use", systemImage: "play.fill")
                                .font(.caption)
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button(action: onDelete) {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 3)
            )
            
            // Name
            Text(item.name)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .onAppear {
            loadThumbnail()
        }
    }
    
    private func loadThumbnail() {
        DispatchQueue.global(qos: .userInitiated).async {
            let image = WallpaperLibrary.shared.generateThumbnail(for: item)
            DispatchQueue.main.async {
                thumbnail = image
            }
        }
    }
}

#Preview {
    LibraryView(onSelect: { _ in })
        .frame(width: 720, height: 520)
}

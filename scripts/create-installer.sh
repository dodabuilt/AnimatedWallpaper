#!/bin/bash

# Create Installer Script for Animated Wallpaper
# Usage: ./scripts/create-installer.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_DIR/build"
INSTALLER_DIR="$PROJECT_DIR/installer"
VERSION="1.0.4"

echo "🔨 Building Animated Wallpaper..."

# Build the app
xcodebuild -workspace "$PROJECT_DIR/AnimatedWallpaper.xcworkspace" \
           -scheme AnimatedWallpaper \
           -configuration Release \
           -derivedDataPath "$BUILD_DIR" \
           build

echo "📦 Creating installer package..."

# Create staging directory
rm -rf "$INSTALLER_DIR/staging"
mkdir -p "$INSTALLER_DIR/staging"

# Copy app to staging
cp -R "$BUILD_DIR/Build/Products/Release/AnimatedWallpaper.app" "$INSTALLER_DIR/staging/"

# Add icon to app if not present
if [ ! -f "$INSTALLER_DIR/staging/AnimatedWallpaper.app/Contents/Resources/AppIcon.icns" ]; then
    # Generate icon
    mkdir -p /tmp/AppIcon.iconset
    cp "$PROJECT_DIR/AnimatedWallpaper/Assets.xcassets/AppIcon.appiconset/icon_"*.png /tmp/AppIcon.iconset/
    iconutil -c icns /tmp/AppIcon.iconset -o /tmp/AppIcon.icns
    cp /tmp/AppIcon.icns "$INSTALLER_DIR/staging/AnimatedWallpaper.app/Contents/Resources/"
    
    # Add icon reference to Info.plist if not present
    if ! grep -q "CFBundleIconFile" "$INSTALLER_DIR/staging/AnimatedWallpaper.app/Contents/Info.plist"; then
        /usr/libexec/PlistBuddy -c "Add :CFBundleIconFile string AppIcon" \
            "$INSTALLER_DIR/staging/AnimatedWallpaper.app/Contents/Info.plist"
    fi
fi

# Remove old packages
rm -f "$INSTALLER_DIR/AnimatedWallpaper-component.pkg"
rm -f "$INSTALLER_DIR/AnimatedWallpaper-Installer.pkg"

# Create component package
pkgbuild --root "$INSTALLER_DIR/staging" \
         --install-location /Applications \
         --identifier com.davidmedvedev.animatedwallpaper \
         --version "$VERSION" \
         "$INSTALLER_DIR/AnimatedWallpaper-component.pkg"

# Create final installer
cd "$INSTALLER_DIR"
productbuild --distribution distribution.xml \
             --resources resources \
             --package-path . \
             AnimatedWallpaper-Installer.pkg

echo ""
echo "✅ Installer created: $INSTALLER_DIR/AnimatedWallpaper-Installer.pkg"
echo "   Version: $VERSION"

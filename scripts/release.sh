#!/bin/bash

# Release Script for Animated Wallpaper
# Usage: ./scripts/release.sh 1.0.5

set -e

VERSION=$1

if [ -z "$VERSION" ]; then
    echo "Usage: ./scripts/release.sh <version>"
    echo "Example: ./scripts/release.sh 1.0.5"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "🚀 Releasing Animated Wallpaper v$VERSION"
echo ""

# Update version in xcconfig
sed -i '' "s/MARKETING_VERSION = .*/MARKETING_VERSION = $VERSION/" "$PROJECT_DIR/Config/Shared.xcconfig"

# Commit version bump
cd "$PROJECT_DIR"
git add Config/Shared.xcconfig
git commit -m "Bump version to $VERSION" || true

# Create and push tag
git tag -a "v$VERSION" -m "Release v$VERSION"
git push origin main
git push origin "v$VERSION"

echo ""
echo "✅ Tag v$VERSION pushed!"
echo ""
echo "GitHub Actions will now:"
echo "  1. Build the app"
echo "  2. Create the installer"
echo "  3. Create a GitHub release"
echo "  4. Update the Homebrew tap"
echo ""
echo "Monitor progress at:"
echo "  https://github.com/dodabuilt/AnimatedWallpaper/actions"

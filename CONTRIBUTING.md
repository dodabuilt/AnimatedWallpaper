# Contributing to Animated Wallpaper

Thank you for your interest in contributing! This document explains how to set up the development environment and release process.

## Development Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/dodabuilt/AnimatedWallpaper.git
   cd AnimatedWallpaper
   ```

2. Open in Xcode:
   ```bash
   open AnimatedWallpaper.xcworkspace
   ```

3. Build and run (⌘R)

## Making Changes

1. Create a feature branch:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. Make your changes and test locally

3. Commit with a descriptive message:
   ```bash
   git commit -m "Add feature: description"
   ```

4. Push and create a Pull Request:
   ```bash
   git push origin feature/your-feature-name
   ```

## Release Process

### Automated (Recommended)

When you push a version tag, GitHub Actions automatically:
1. Builds the app
2. Creates the installer package
3. Creates a GitHub release with the installer
4. Updates the Homebrew tap formula

To create a release:

```bash
./scripts/release.sh 1.0.5
```

Or manually:

```bash
# Update version in Config/Shared.xcconfig
git add .
git commit -m "Bump version to 1.0.5"
git tag -a v1.0.5 -m "Release v1.0.5"
git push origin main --tags
```

### Manual Release

If you need to release manually:

1. Build the app:
   ```bash
   ./scripts/create-installer.sh
   ```

2. Create GitHub release:
   ```bash
   gh release create v1.0.5 installer/AnimatedWallpaper-Installer.pkg
   ```

3. Update Homebrew tap manually in the `homebrew-tap` repository

## Setting Up CI/CD

For the automated release to update the Homebrew tap, you need to:

1. Create a Personal Access Token (PAT):
   - Go to GitHub Settings → Developer settings → Personal access tokens
   - Create a token with `repo` scope
   - Copy the token

2. Add the secret to your repository:
   - Go to AnimatedWallpaper repo → Settings → Secrets → Actions
   - Add a new secret named `TAP_GITHUB_TOKEN`
   - Paste your PAT

## Code Style

- Use Swift's standard naming conventions
- Keep functions focused and small
- Add comments for complex logic
- Use `// MARK: -` to organize code sections

## Testing

Before submitting a PR:
1. Build successfully (⌘B)
2. Test with various video formats (MP4, MOV)
3. Test with animated GIFs
4. Test on multiple monitors if available
5. Test the wallpaper library save/load

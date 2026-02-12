# Release Process

This document describes the automated release process for GOATpad using GitHub Actions.

## Overview

GOATpad uses GitHub Actions to automatically build and publish releases for multiple platforms:
- **Windows** (x64 EXE)
- **Linux** (x64 tarball)
- **Android** (APK)

## How to Create a Release

### 1. Update Version Number

First, update the version number in `pubspec.yaml`:

```yaml
version: 1.0.0+1
```

The format is `MAJOR.MINOR.PATCH+BUILD_NUMBER`.

### 2. Commit Your Changes

Commit all your changes to the main branch:

```bash
git add .
git commit -m "Release v1.0.0"
git push origin main
```

### 3. Create and Push a Tag

Create a git tag with the version number (must start with 'v'):

```bash
git tag v1.0.0
git push origin v1.0.0
```

### 4. Automated Build Process

Once you push the tag, GitHub Actions will automatically:

1. **Build Android APK**
   - Setup Java 17 and Flutter
   - Build release APK
   - Upload as artifact

2. **Build Linux App**
   - Install Linux dependencies
   - Build Linux desktop app
   - Create tarball archive
   - Upload as artifact

3. **Build Windows EXE**
   - Build Windows desktop app
   - Create zip archive
   - Upload as artifact

4. **Create GitHub Release**
   - Download all build artifacts
   - Extract version from pubspec.yaml
   - Create a new GitHub release with all files attached
   - Generate release notes automatically

### 5. Monitor the Build

You can monitor the build progress:

1. Go to your repository on GitHub
2. Click on the "Actions" tab
3. Click on the running workflow

The entire process typically takes 15-20 minutes.

## Manual Trigger

You can also manually trigger a release build without creating a tag:

1. Go to the "Actions" tab on GitHub
2. Select "Build and Release" workflow
3. Click "Run workflow"
4. Select the branch and click "Run workflow"

Note: Manual runs will still create a release, but you should create a proper tag for versioning.

## Release Artifacts

After successful build, the following files will be available in the release:

- `app-release.apk` - Android application
- `goatpad-linux-x64.tar.gz` - Linux application (tarball)
- `goatpad-windows-x64.zip` - Windows application (zip archive)

## Troubleshooting

### Build Fails

If a build fails:

1. Check the Actions tab for error logs
2. Common issues:
   - Missing dependencies in pubspec.yaml
   - Platform-specific build errors
   - Insufficient permissions

### Release Not Created

If builds succeed but release isn't created:

1. Verify the tag name starts with 'v'
2. Check if you have proper repository permissions
3. Ensure `GITHUB_TOKEN` has write permissions

### Version Mismatch

The release version is automatically extracted from `pubspec.yaml`. Always ensure:

1. Version in pubspec.yaml matches your git tag
2. Version follows semantic versioning (MAJOR.MINOR.PATCH)

## Configuration

The workflow is defined in `.github/workflows/release.yml`.

### Key Settings

- **Flutter Version**: Currently set to 3.27.1 (stable)
- **Java Version**: 17 (Zulu distribution)
- **Platforms**: Android, Linux, Windows

### Modifying the Workflow

To modify the workflow:

1. Edit `.github/workflows/release.yml`
2. Test changes in a fork or feature branch first
3. Common modifications:
   - Change Flutter version
   - Add/remove platforms
   - Modify build flags
   - Change archive formats

## Best Practices

1. **Test Before Tagging**: Always test your changes locally before creating a release tag
2. **Semantic Versioning**: Follow semantic versioning for version numbers
3. **Changelog**: Update changelog/release notes before releasing
4. **Tag Messages**: Add meaningful messages to your tags:
   ```bash
   git tag -a v1.0.0 -m "Release version 1.0.0 - Initial stable release"
   ```

## Platform-Specific Notes

### Windows

- Builds on `windows-latest` runner
- Produces a zip file with all necessary DLLs and dependencies
- Users need to extract and run `goatpad.exe`

### Linux

- Builds on `ubuntu-latest` runner
- Requires GTK3 and other system dependencies
- Produces a tarball that users extract and run
- Users may need to install dependencies on their system

### Android

- Builds on `ubuntu-latest` runner
- Uses Java 17 (Zulu distribution)
- Produces an APK (not AAB)
- Users may need to enable "Install from Unknown Sources"

## Future Enhancements

Potential improvements to the release process:

- [ ] Add iOS builds (requires macOS runner and certificates)
- [ ] Add macOS builds
- [ ] Create signed Android APK/AAB for Play Store
- [ ] Add automated testing before release
- [ ] Generate detailed changelog from commits
- [ ] Add code signing for Windows executables
- [ ] Create installer packages (MSI for Windows, DEB/RPM for Linux)
- [ ] Add web deployment to GitHub Pages


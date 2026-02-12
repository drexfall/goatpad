#!/bin/bash

# Local Build Test Script
# This script helps you test builds locally before pushing to GitHub

set -e

echo "🔨 GOATpad Local Build Test"
echo "=============================="
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Get current version from pubspec.yaml
VERSION=$(grep '^version: ' pubspec.yaml | cut -d ' ' -f 2 | cut -d '+' -f 1)
echo -e "${GREEN}Current Version: $VERSION${NC}"
echo ""

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}Error: Flutter is not installed or not in PATH${NC}"
    exit 1
fi

echo -e "${YELLOW}Flutter Version:${NC}"
flutter --version
echo ""

# Function to build platform
build_platform() {
    local platform=$1
    echo -e "${YELLOW}Building for $platform...${NC}"

    case $platform in
        "android")
            flutter build apk --release
            echo -e "${GREEN}✓ Android APK built successfully${NC}"
            echo "Location: build/app/outputs/flutter-apk/app-release.apk"
            ;;
        "linux")
            if [[ "$OSTYPE" == "linux-gnu"* ]]; then
                flutter config --enable-linux-desktop
                flutter build linux --release
                echo -e "${GREEN}✓ Linux app built successfully${NC}"
                echo "Location: build/linux/x64/release/bundle/"
            else
                echo -e "${YELLOW}⚠ Skipping Linux build (not on Linux)${NC}"
            fi
            ;;
        "windows")
            if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" || "$OSTYPE" == "win32" ]]; then
                flutter config --enable-windows-desktop
                flutter build windows --release
                echo -e "${GREEN}✓ Windows app built successfully${NC}"
                echo "Location: build/windows/x64/runner/Release/"
            else
                echo -e "${YELLOW}⚠ Skipping Windows build (not on Windows)${NC}"
            fi
            ;;
        *)
            echo -e "${RED}Unknown platform: $platform${NC}"
            return 1
            ;;
    esac
    echo ""
}

# Get dependencies first
echo -e "${YELLOW}Getting Flutter dependencies...${NC}"
flutter pub get
echo -e "${GREEN}✓ Dependencies installed${NC}"
echo ""

# Parse command line arguments
if [ $# -eq 0 ]; then
    echo "Select platforms to build:"
    echo "1) Android"
    echo "2) Linux"
    echo "3) Windows"
    echo "4) All available platforms"
    echo ""
    read -p "Enter choice (1-4): " choice

    case $choice in
        1) build_platform "android" ;;
        2) build_platform "linux" ;;
        3) build_platform "windows" ;;
        4)
            build_platform "android"
            build_platform "linux"
            build_platform "windows"
            ;;
        *)
            echo -e "${RED}Invalid choice${NC}"
            exit 1
            ;;
    esac
else
    # Build specified platforms
    for platform in "$@"; do
        build_platform "$platform"
    done
fi

echo ""
echo -e "${GREEN}=============================="
echo "✓ Build test complete!"
echo -e "==============================${NC}"
echo ""
echo "If all builds succeeded, you're ready to create a release:"
echo ""
echo "  git tag v$VERSION"
echo "  git push origin v$VERSION"
echo ""


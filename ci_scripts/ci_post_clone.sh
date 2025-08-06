#!/bin/bash

# Xcode Cloud Post-Clone Script
# Konfiguriert das Runner-Release Schema für TestFlight Builds

set -e

echo "🔧 Configuring Xcode Cloud for Runner-Release schema..."

# Zum Projekt-Root wechseln
cd /Volumes/workspace/repository
echo "📍 Working directory: $(pwd)"

# Überprüfen verfügbare Befehle
echo "🔍 Checking available commands..."
which pod || echo "⚠️ pod not found in PATH"

# PATH erweitern falls nötig
export PATH="/usr/local/bin:/opt/homebrew/bin:$PATH"
echo "📍 Updated PATH: $PATH"

# Überprüfen ob wir im richtigen Verzeichnis sind
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Error: pubspec.yaml not found. Current directory: $(pwd)"
    ls -la
    exit 1
fi

echo "✅ Found pubspec.yaml - we're in the Flutter project"

# iOS Setup (Flutter wird später im Pre-Build Script behandelt)
echo "🍎 Installing iOS dependencies..."
cd ios
if [ ! -f "Podfile" ]; then
    echo "❌ Error: Podfile not found in ios directory"
    exit 1
fi

if command -v pod >/dev/null 2>&1; then
    pod install
else
    echo "❌ Error: pod command not available"
    exit 1
fi
cd ..

# Verify Runner-Release schema exists
echo "🔍 Verifying Runner-Release schema..."
if [ -f "ios/Runner.xcodeproj/xcshareddata/xcschemes/Runner-Release.xcscheme" ]; then
    echo "✅ Runner-Release schema found"
else
    echo "❌ Runner-Release schema not found!"
    echo "Available schemas:"
    ls -la ios/Runner.xcodeproj/xcshareddata/xcschemes/
    exit 1
fi

# Set environment variable for Xcode Cloud to use Runner-Release
export XCODE_CLOUD_SCHEME="Runner-Release"
export XCODE_CLOUD_CONFIGURATION="Release"

echo "✅ Xcode Cloud configured for Runner-Release schema!" 
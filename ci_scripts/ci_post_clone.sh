#!/bin/bash
# Xcode Cloud Post-Clone Script
# Konfiguriert das Runner-Release Schema für TestFlight Builds
# UND bereitet Flutter/CocoaPods vor dem Xcode Build vor

set -e

echo "🔧 Configuring Xcode Cloud for Runner-Release schema..."

# Zum Projekt-Root wechseln
cd /Volumes/workspace/repository
echo "📍 Working directory: $(pwd)"

# Überprüfen verfügbare Befehle
echo "🔍 Checking available commands..."
which flutter || echo "⚠️ flutter not found in PATH"
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

# Flutter installieren falls nicht verfügbar
echo "📦 Installing Flutter..."
if ! command -v flutter >/dev/null 2>&1; then
    echo "🔄 Flutter not found, installing..."
    # Flutter von GitHub herunterladen
    git clone https://github.com/flutter/flutter.git -b stable --depth 1 /tmp/flutter
    export PATH="/tmp/flutter/bin:$PATH"
    echo "✅ Flutter installed at /tmp/flutter/bin"
else
    echo "✅ Flutter already available"
fi

# Flutter Setup (MUSS vor pod install laufen)
echo "📦 Installing Flutter dependencies..."
flutter pub get

# Flutter iOS Engine precache (WICHTIG für pod install)
echo "⚙️ Pre-caching Flutter iOS engine..."
flutter precache --ios

# Verifizieren dass Generated.xcconfig erstellt wurde
echo "🔍 Verifying Flutter generated files..."
if [ ! -f "ios/Flutter/Generated.xcconfig" ]; then
    echo "❌ Error: Generated.xcconfig not found after flutter pub get"
    echo "Flutter files in ios/Flutter/:"
    ls -la ios/Flutter/ || echo "ios/Flutter/ directory not found"
    exit 1
fi
echo "✅ Generated.xcconfig found"

# Sicherstellen dass ios/Flutter Verzeichnis existiert
echo "🔧 Ensuring ios/Flutter directory exists..."
mkdir -p ios/Flutter

# Generated.xcconfig explizit kopieren falls nötig
if [ -f "ios/Flutter/Generated.xcconfig" ]; then
    echo "✅ Generated.xcconfig already in correct location"
else
    echo "🔄 Copying Generated.xcconfig to correct location..."
    cp ios/Flutter/Generated.xcconfig ios/Flutter/Generated.xcconfig 2>/dev/null || echo "⚠️ Copy failed, but file might already exist"
fi

# Pods installieren (NACH flutter precache --ios)
echo "🍎 Installing CocoaPods dependencies..."
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
echo "✅ Flutter and CocoaPods prepared for Xcode build!" 
#!/bin/bash

# CI Script für Xcode Cloud mit Runner-Release Schema
# Version: 2025-08-06 - Fixed Runner.xcworkspace directory check
set -e

echo "🔧 Setting up Xcode Cloud build with Runner-Release schema..."

# Zum Projekt-Root wechseln
cd /Volumes/workspace/repository
echo "📍 Working directory: $(pwd)"

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

# Überprüfen verfügbare Befehle
echo "🔍 Checking available commands..."
which flutter || echo "⚠️ flutter not found in PATH"
which pod || echo "⚠️ pod not found in PATH"
which xcodebuild || echo "⚠️ xcodebuild not found in PATH"

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

# Verifizieren dass Flutter.xcframework existiert
echo "🔍 Verifying Flutter iOS engine..."
if [ ! -d "/tmp/flutter/bin/cache/artifacts/engine/ios/Flutter.xcframework" ]; then
    echo "❌ Error: Flutter.xcframework not found after flutter precache --ios"
    echo "Flutter cache directory:"
    ls -la /tmp/flutter/bin/cache/artifacts/engine/ios/ || echo "iOS engine directory not found"
    exit 1
fi
echo "✅ Flutter.xcframework found"

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

# Flutter Build mit Release-Konfiguration
echo "📱 Building Flutter app with release configuration..."
flutter build ios --release --no-codesign

echo "✅ Flutter build completed successfully!"
echo "🚀 Xcode Cloud will now handle the Xcode build and code signing automatically"
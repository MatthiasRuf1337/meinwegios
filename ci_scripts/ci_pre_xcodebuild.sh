#!/bin/bash

# CI Script für Xcode Cloud mit Runner-Release Schema
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

# Flutter Setup
echo "📦 Installing Flutter dependencies..."
flutter pub get

# Pods installieren
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

# Xcode Build mit Runner-Release Schema
echo "🏗️ Building with Runner-Release schema..."
cd ios
if [ ! -f "Runner.xcworkspace" ]; then
    echo "❌ Error: Runner.xcworkspace not found"
    exit 1
fi

if command -v xcodebuild >/dev/null 2>&1; then
    xcodebuild -workspace Runner.xcworkspace -scheme Runner-Release -configuration Release archive -archivePath build/Runner.xcarchive
else
    echo "❌ Error: xcodebuild command not available"
    exit 1
fi

echo "✅ Build completed successfully with Runner-Release schema!"
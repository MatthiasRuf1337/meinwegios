#!/bin/bash

# CI Script für Xcode Cloud mit Runner-Release Schema
set -e

echo "🔧 Setting up Xcode Cloud build with Runner-Release schema..."

# Zum Projekt-Root wechseln
cd /Volumes/workspace/repository
echo "📍 Working directory: $(pwd)"

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

pod install
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

xcodebuild -workspace Runner.xcworkspace -scheme Runner-Release -configuration Release archive -archivePath build/Runner.xcarchive

echo "✅ Build completed successfully with Runner-Release schema!"
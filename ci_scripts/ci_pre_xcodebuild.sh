#!/bin/bash

# CI Script für Xcode Cloud mit Runner-Release Schema
set -e

echo "🔧 Setting up Xcode Cloud build with Runner-Release schema..."

# Pods installieren
cd ios
pod install
cd ..

# Flutter Build mit Release-Konfiguration
echo "📱 Building Flutter app with release configuration..."
flutter build ios --release --no-codesign

# Xcode Build mit Runner-Release Schema
echo "🏗️ Building with Runner-Release schema..."
cd ios
xcodebuild -workspace Runner.xcworkspace -scheme Runner-Release -configuration Release archive -archivePath build/Runner.xcarchive

echo "✅ Build completed successfully with Runner-Release schema!"
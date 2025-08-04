#!/bin/sh

# Xcode Cloud Pre-Build Script for Flutter
# This script runs before Xcode builds the project

set -e

echo "🚀 Starting Xcode Cloud Pre-Build Script"

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Error: pubspec.yaml not found. Are we in the Flutter project root?"
    exit 1
fi

# Install Flutter dependencies
echo "📦 Running flutter pub get..."
flutter pub get

# Navigate to iOS directory
cd ios

# Install CocoaPods dependencies
echo "🍎 Running pod install..."
pod install --repo-update

# Go back to project root
cd ..

# Generate Flutter configuration for iOS
echo "🔧 Generating Flutter iOS configuration..."
flutter build ios --config-only

echo "✅ Xcode Cloud Pre-Build Script completed successfully"
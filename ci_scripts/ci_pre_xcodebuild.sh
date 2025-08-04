#!/bin/sh

# Xcode Cloud Pre-Build Script for Flutter
# This script runs before Xcode builds the project

set -e

echo "🚀 Starting Xcode Cloud Pre-Build Script"

# Debug: Show environment
echo "📍 Current directory: $(pwd)"
echo "📍 Available files: $(ls -la | head -10)"

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Error: pubspec.yaml not found. Are we in the Flutter project root?"
    exit 1
fi

# Install Flutter if not available
if ! command -v flutter &> /dev/null; then
    echo "📦 Flutter not found, installing Flutter..."
    
    # Download and install Flutter
    git clone https://github.com/flutter/flutter.git -b stable --depth 1 /tmp/flutter
    export PATH="/tmp/flutter/bin:$PATH"
    
    # Run flutter doctor to initialize
    flutter doctor
else
    echo "📦 Flutter found: $(flutter --version | head -1)"
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
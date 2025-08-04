#!/bin/sh

# Xcode Cloud Pre-Build Script for Flutter
# COMPLETE Flutter installation and setup

set -e

echo "🚀 Starting COMPLETE Flutter Setup for Xcode Cloud"

# Debug: Show environment
echo "📍 Current directory: $(pwd)"
echo "📍 Available commands: $(which git || echo 'git not found')"

# Navigate to project root (parent directory)
cd ..
echo "📍 Moved to project root: $(pwd)"

# Check if we're in the right directory  
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Error: pubspec.yaml not found"
    ls -la
    exit 1
fi

echo "✅ Found pubspec.yaml - we're in the Flutter project"

# Install Flutter SDK
echo "📦 Installing Flutter SDK..."
if [ ! -d "/tmp/flutter" ]; then
    echo "🔄 Downloading Flutter SDK..."
    git clone https://github.com/flutter/flutter.git -b stable --depth 1 /tmp/flutter
else
    echo "✅ Flutter SDK already exists"
fi

# Add Flutter to PATH
export PATH="/tmp/flutter/bin:$PATH"
echo "📍 Flutter path: $(which flutter)"

# Initialize Flutter
echo "🔧 Initializing Flutter..."
flutter doctor --no-version-check

# Install Flutter dependencies
echo "📦 Installing Flutter dependencies..."
flutter pub get

# Precache iOS engine artifacts (IMPORTANT!)
echo "⚙️ Downloading Flutter iOS engine artifacts..."
flutter precache --ios

# Navigate to iOS directory and install CocoaPods
echo "📱 Setting up iOS..."
cd ios

if [ -f "Podfile" ]; then
    echo "🍎 Installing CocoaPods dependencies..."
    pod install --repo-update
    echo "✅ CocoaPods installation completed"
else
    echo "❌ No Podfile found!"
    exit 1
fi

cd ..

# Generate Flutter iOS configuration
echo "🔧 Generating Flutter iOS configuration..."
flutter build ios --config-only

# Verify that Generated.xcconfig was created
if [ -f "ios/Flutter/Generated.xcconfig" ]; then
    echo "✅ Generated.xcconfig created successfully!"
    echo "📄 Generated.xcconfig content:"
    head -5 ios/Flutter/Generated.xcconfig
else
    echo "❌ Generated.xcconfig was not created!"
    exit 1
fi

echo "🎉 Flutter setup completed successfully for Xcode Cloud!"
exit 0
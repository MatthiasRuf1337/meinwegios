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

# CRITICAL: Copy Pods directory to ROOT where Xcode Cloud expects it
echo "📁 Copying Pods directory to Xcode Cloud expected location..."
if [ -d "ios/Pods" ]; then
    cp -r ios/Pods .
    echo "✅ Pods directory copied to root location"
else
    echo "❌ ios/Pods directory not found!"
    exit 1
fi

# Generate Flutter iOS configuration
echo "🔧 Generating Flutter iOS configuration..."
flutter build ios --config-only

# Verify that Generated.xcconfig was created
if [ -f "ios/Flutter/Generated.xcconfig" ]; then
    echo "✅ Generated.xcconfig created successfully!"
    echo "📄 Generated.xcconfig content:"
    head -5 ios/Flutter/Generated.xcconfig
    
    # CRITICAL: Copy Flutter config files to ROOT where Xcode Cloud expects them
    echo "📋 Copying Flutter config files to Xcode Cloud expected location..."
    mkdir -p Flutter
    cp -r ios/Flutter/* Flutter/
    echo "✅ Flutter files copied to root Flutter/ directory"
    
    # Paths are already correct: ../Pods/ from Flutter/ points to ROOT Pods/
    echo "✅ Relative paths ../Pods/ are correct from Flutter/ to ROOT Pods/"
    
    # Verify the copy worked
    if [ -f "Flutter/Generated.xcconfig" ]; then
        echo "✅ Generated.xcconfig now available at root Flutter/ location"
    else
        echo "❌ Failed to copy Generated.xcconfig to root location"
        exit 1
    fi
else
    echo "❌ Generated.xcconfig was not created!"
    exit 1
fi

echo "🎉 Flutter setup completed successfully for Xcode Cloud!"
exit 0
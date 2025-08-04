#!/bin/sh

# Xcode Cloud Pre-Build Script for Flutter
# Simplified version that only handles CocoaPods

echo "🚀 Starting Xcode Cloud Pre-Build Script (Simplified)"

# Debug: Show environment
echo "📍 Current directory: $(pwd)"
echo "📍 Available files:"
ls -la

# Check if we're in the right directory  
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Error: pubspec.yaml not found"
    exit 1
fi

echo "✅ Found pubspec.yaml - we're in the Flutter project"

# Navigate to iOS directory and install CocoaPods
if [ -d "ios" ]; then
    echo "📱 Found iOS directory"
    cd ios
    
    if [ -f "Podfile" ]; then
        echo "🍎 Installing CocoaPods dependencies..."
        pod install
        echo "✅ CocoaPods installation completed"
    else
        echo "⚠️ No Podfile found, skipping pod install"
    fi
    
    cd ..
else
    echo "⚠️ No iOS directory found, skipping CocoaPods"
fi

echo "✅ Pre-Build Script completed (fallback configs will handle Flutter)"

# Exit successfully - let the fallback configs handle the rest
exit 0
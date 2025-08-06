#!/bin/bash

# Xcode Cloud Post-Clone Script
# Konfiguriert das Runner-Release Schema für TestFlight Builds

set -e

echo "🔧 Configuring Xcode Cloud for Runner-Release schema..."

# Flutter Setup
echo "📦 Installing Flutter dependencies..."
flutter pub get

# iOS Setup
echo "🍎 Installing iOS dependencies..."
cd ios
pod install
cd ..

# Verify Runner-Release schema exists
echo "🔍 Verifying Runner-Release schema..."
if [ -f "ios/Runner.xcodeproj/xcshareddata/xcschemes/Runner-Release.xcscheme" ]; then
    echo "✅ Runner-Release schema found"
else
    echo "❌ Runner-Release schema not found!"
    exit 1
fi

# Set environment variable for Xcode Cloud to use Runner-Release
export XCODE_CLOUD_SCHEME="Runner-Release"
export XCODE_CLOUD_CONFIGURATION="Release"

echo "✅ Xcode Cloud configured for Runner-Release schema!" 
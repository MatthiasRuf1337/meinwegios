#!/bin/bash
# CI Script für Xcode Cloud mit Runner-Release schema
# Version: 2025-08-06 - Simplified - main work done in post-clone
set -e

echo "🔧 Final preparation for Xcode Cloud build..."

# Zum Projekt-Root wechseln
cd /Volumes/workspace/repository
echo "📍 Working directory: $(pwd)"

# Final verification
echo "🔍 Final verification before Xcode build..."

# Check Flutter files
if [ ! -f "ios/Flutter/Generated.xcconfig" ]; then
    echo "❌ Error: Generated.xcconfig not found"
    exit 1
fi
echo "✅ Generated.xcconfig found"

# Check CocoaPods
if [ ! -d "ios/Pods" ]; then
    echo "❌ Error: Pods directory not found"
    exit 1
fi
echo "✅ Pods directory found"

# Check Runner-Release schema
if [ ! -f "ios/Runner.xcodeproj/xcshareddata/xcschemes/Runner-Release.xcscheme" ]; then
    echo "❌ Error: Runner-Release schema not found"
    exit 1
fi
echo "✅ Runner-Release schema found"

echo "✅ All preparations complete! Xcode Cloud can now build with Runner-Release schema"
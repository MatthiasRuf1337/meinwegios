#!/bin/bash
# Xcode Cloud Post-Clone Script
# Konfiguriert das Runner-Release Schema für TestFlight Builds
# UND bereitet Flutter/CocoaPods vor dem Xcode Build vor

set -e

echo "🔧 Configuring Xcode Cloud for Runner-Release schema..."

# Zum Projekt-Root wechseln
cd /Volumes/workspace/repository
echo "📍 Working directory: $(pwd)"

# Überprüfen verfügbare Befehle
echo "🔍 Checking available commands..."
which flutter || echo "⚠️ flutter not found in PATH"
which pod || echo "⚠️ pod not found in PATH"

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

# Flutter Setup (MUSS vor pod install laufen)
echo "📦 Installing Flutter dependencies..."
flutter pub get

# Flutter iOS Engine precache (WICHTIG für pod install)
echo "⚙️ Pre-caching Flutter iOS engine..."
flutter precache --ios

# Sicherstellen dass ios/Flutter Verzeichnis existiert
echo "🔧 Ensuring ios/Flutter directory exists..."
mkdir -p ios/Flutter

# Generated.xcconfig manuell erstellen falls es nicht existiert
echo "🔧 Creating Generated.xcconfig..."
if [ ! -f "ios/Flutter/Generated.xcconfig" ]; then
    echo "🔄 Generated.xcconfig not found, creating manually..."
    cat > ios/Flutter/Generated.xcconfig << EOF
// This is a generated file; do not edit or check into version control.
FLUTTER_ROOT=/tmp/flutter
FLUTTER_APPLICATION_PATH=/Volumes/workspace/repository
COCOAPODS_PARALLEL_CODE_SIGN=true
FLUTTER_TARGET=lib/main.dart
FLUTTER_BUILD_DIR=build
FLUTTER_BUILD_NAME=1.0.0
FLUTTER_BUILD_NUMBER=1
EXCLUDED_ARCHS[sdk=iphonesimulator*]=i386
EXCLUDED_ARCHS[sdk=iphoneos*]=armv7
DART_OBFUSCATION=false
TRACK_WIDGET_CREATION=true
TREE_SHAKE_ICONS=false
PACKAGE_CONFIG=.dart_tool/package_config.json
EOF
    echo "✅ Generated.xcconfig created manually"
else
    echo "✅ Generated.xcconfig already exists"
fi

# Zusätzlich: Generated.xcconfig im Repository-Verzeichnis erstellen
echo "🔧 Creating Generated.xcconfig in repository root..."
mkdir -p Flutter
cat > Flutter/Generated.xcconfig << EOF
// This is a generated file; do not edit or check into version control.
FLUTTER_ROOT=/tmp/flutter
FLUTTER_APPLICATION_PATH=/Volumes/workspace/repository
COCOAPODS_PARALLEL_CODE_SIGN=true
FLUTTER_TARGET=lib/main.dart
FLUTTER_BUILD_DIR=build
FLUTTER_BUILD_NAME=1.0.0
FLUTTER_BUILD_NUMBER=1
EXCLUDED_ARCHS[sdk=iphonesimulator*]=i386
EXCLUDED_ARCHS[sdk=iphoneos*]=armv7
DART_OBFUSCATION=false
TRACK_WIDGET_CREATION=true
TREE_SHAKE_ICONS=false
PACKAGE_CONFIG=.dart_tool/package_config.json
EOF
echo "✅ Generated.xcconfig created in repository root"

# Verifizieren dass Generated.xcconfig erstellt wurde
echo "🔍 Verifying Flutter generated files..."
if [ ! -f "ios/Flutter/Generated.xcconfig" ]; then
    echo "❌ Error: Generated.xcconfig still not found after creation"
    echo "Flutter files in ios/Flutter/:"
    ls -la ios/Flutter/ || echo "ios/Flutter/ directory not found"
    exit 1
fi
echo "✅ Generated.xcconfig found and verified"

# Pods installieren (NACH flutter precache --ios)
echo "🍎 Installing CocoaPods dependencies..."
cd ios
if [ ! -f "Podfile" ]; then
    echo "❌ Error: Podfile not found in ios directory"
    exit 1
fi

if command -v pod >/dev/null 2>&1; then
    echo "🔄 Running pod install..."
    pod install
    
    # Zusätzlich: Pod install mit repo update für FileLists
    echo "🔄 Running pod install --repo-update to ensure FileLists..."
    pod install --repo-update
    
    # Verifizieren dass FileLists existieren
    echo "🔍 Verifying CocoaPods FileLists..."
    if [ -f "Pods/Target Support Files/Pods-Runner/Pods-Runner-frameworks-Release-input-files.xcfilelist" ]; then
        echo "✅ Release input files xcfilelist found"
    else
        echo "⚠️ Release input files xcfilelist not found"
    fi
    
    if [ -f "Pods/Target Support Files/Pods-Runner/Pods-Runner-frameworks-Release-output-files.xcfilelist" ]; then
        echo "✅ Release output files xcfilelist found"
    else
        echo "⚠️ Release output files xcfilelist not found"
    fi
else
    echo "❌ Error: pod command not available"
    exit 1
fi
cd ..

# Verify Runner-Release schema exists
echo "🔍 Verifying Runner-Release schema..."
if [ -f "ios/Runner.xcodeproj/xcshareddata/xcschemes/Runner-Release.xcscheme" ]; then
    echo "✅ Runner-Release schema found"
else
    echo "❌ Runner-Release schema not found!"
    echo "Available schemas:"
    ls -la ios/Runner.xcodeproj/xcshareddata/xcschemes/
    exit 1
fi

# Set environment variable for Xcode Cloud to use Runner-Release
export XCODE_CLOUD_SCHEME="Runner-Release"
export XCODE_CLOUD_CONFIGURATION="Release"

echo "✅ Xcode Cloud configured for Runner-Release schema!"
echo "✅ Flutter and CocoaPods prepared for Xcode build!" 
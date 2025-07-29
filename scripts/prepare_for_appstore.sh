#!/bin/bash

# Apple App Store Vorbereitung Script
# Führt alle notwendigen Schritte für die App Store Vorbereitung aus

echo "🚀 Apple App Store Vorbereitung für MeinWeg"
echo "=============================================="

# 1. Flutter Setup
echo ""
echo "📱 1. Flutter Setup..."
flutter doctor
flutter clean
flutter pub get

# 2. iOS Dependencies
echo ""
echo "🍎 2. iOS Dependencies aktualisieren..."
cd ios
pod install
cd ..

# 3. Build Test
echo ""
echo "🔨 3. Release Build erstellen..."
flutter build ios --release

if [ $? -eq 0 ]; then
    echo "✅ Release Build erfolgreich!"
else
    echo "❌ Release Build fehlgeschlagen!"
    exit 1
fi

# 4. Bundle Identifier prüfen
echo ""
echo "🔍 4. Bundle Identifier prüfen..."
BUNDLE_ID=$(grep -A 1 "PRODUCT_BUNDLE_IDENTIFIER" ios/Runner.xcodeproj/project.pbxproj | grep -o '"[^"]*"' | head -1 | tr -d '"')
echo "Bundle ID: $BUNDLE_ID"

# 5. App Icon prüfen
echo ""
echo "🎨 5. App Icon prüfen..."
if [ -f "ios/Runner/Assets.xcassets/AppIcon.appiconset/1024.png" ]; then
    echo "✅ 1024x1024 App Icon gefunden"
else
    echo "⚠️  1024x1024 App Icon fehlt - wichtig für App Store!"
fi

# 6. Info.plist prüfen
echo ""
echo "📋 6. Info.plist prüfen..."
if grep -q "NSCameraUsageDescription" ios/Runner/Info.plist; then
    echo "✅ Berechtigungen konfiguriert"
else
    echo "⚠️  Berechtigungen prüfen"
fi

# 7. Xcode öffnen
echo ""
echo "🛠️  7. Xcode öffnen..."
echo "Öffne Xcode für Archive-Erstellung..."
open ios/Runner.xcworkspace

echo ""
echo "=============================================="
echo "✅ Vorbereitung abgeschlossen!"
echo ""
echo "Nächste Schritte:"
echo "1. In Xcode: Product → Archive"
echo "2. App Store Connect: Neue App erstellen"
echo "3. Archive hochladen"
echo "4. TestFlight Setup"
echo ""
echo "📖 Siehe APP_STORE_PREPARATION.md für Details" 
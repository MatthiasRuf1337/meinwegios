# Xcode Cloud Setup für Flutter

## Option 1: Mit Pre-Build Script (Aktuell)
- ✅ `ci_scripts/ci_pre_xcodebuild.sh` installiert CocoaPods
- ✅ Fallback-Konfigurationen in xcconfig-Dateien

## Option 2: Komplett ohne Script (Falls Script weiter fehlschlägt)

### Schritte für Option 2:

1. **Script deaktivieren:**
   ```bash
   # Script umbenennen um es zu deaktivieren
   mv ci_scripts/ci_pre_xcodebuild.sh ci_scripts/ci_pre_xcodebuild.sh.disabled
   ```

2. **Xcode Cloud Workflow Einstellungen:**
   - In Xcode Cloud: **Workflow bearbeiten**
   - **Build Actions** → **Pre-Actions** hinzufügen:
   ```bash
   # Nur CocoaPods installieren
   cd ios && pod install
   ```

3. **Oder komplett ohne Pre-Actions:**
   - xcconfig-Dateien haben bereits Fallback-Konfigurationen
   - Sollte auch ohne CocoaPods-Installation funktionieren

## Debugging Xcode Cloud

Wenn der Build fehlschlägt:
1. **Build Logs** in Xcode Cloud prüfen
2. **Environment Variables** prüfen  
3. **Simplest possible solution** verwenden

## Aktuelle Konfiguration
- ✅ xcconfig-Dateien haben Fallback-Flutter-Konfiguration
- ✅ Alle Includes sind optional (`#include?`)
- ✅ Build sollte auch ohne Script funktionieren
# TestFlight Upload Guide - Release Schema

## ✅ Release Build erfolgreich erstellt!

```
✓ Built build/ios/iphoneos/Runner.app (83.7MB)
```

## 🔍 Wie Sie erkennen, dass der Build richtig ist:

### **1. Terminal-Befehl zur Überprüfung:**

```bash
# Release Schema prüfen
xcodebuild -workspace ios/Runner.xcworkspace -scheme Runner-Release -showBuildSettings | grep CONFIGURATION

# Debug Schema zum Vergleich
xcodebuild -workspace ios/Runner.xcworkspace -scheme Runner -showBuildSettings | grep CONFIGURATION
```

### **2. Was Sie sehen sollten:**

| Schema             | CONFIGURATION | Verwendung        |
| ------------------ | ------------- | ----------------- |
| **Runner**         | `Debug`       | ❌ Für TestFlight |
| **Runner-Release** | `Release`     | ✅ Für TestFlight |

### **3. In Xcode erkennen:**

- **Schema-Auswahl**: Oben links sollte "Runner-Release" stehen
- **Build Configuration**: In Build Settings → "Release"
- **Archive**: Product → Archive → Release-Konfiguration

### **4. Build-Verzeichnis prüfen:**

```bash
# Release Build (richtig)
ls build/ios/iphoneos/Runner.app

# Debug Build (falsch für TestFlight)
ls build/ios/iphoneos/Runner.app
```

## 🚀 Nächste Schritte für TestFlight:

### **Option 1: Xcode Archive (Empfohlen)**

1. **Xcode öffnen:**

   ```bash
   open ios/Runner.xcworkspace
   ```

2. **Release Schema wählen:**

   - Oben links auf "Runner" klicken
   - **Runner-Release** auswählen ✅

3. **Archive erstellen:**

   - **Product** → **Archive**
   - Warten bis Archive fertig ist

4. **Zu TestFlight hochladen:**

   - **Distribute App** → **App Store Connect**
   - **Upload** → **TestFlight**

### **Option 2: App Store Connect direkt**

1. **App Store Connect** öffnen: https://appstoreconnect.apple.com
2. **Ihre App** auswählen
3. **TestFlight** Tab
4. **Build hochladen** → **Xcode öffnen**
5. **Runner-Release Schema** verwenden

### **Option 3: Terminal (ohne Codesigning)**

```bash
# Release Build erstellen
flutter build ios --release --no-codesign

# Dann manuell in Xcode öffnen und Archive erstellen
open ios/Runner.xcworkspace
```

## 🔧 Schema Konfiguration

| Schema             | Verwendung  | Status     |
| ------------------ | ----------- | ---------- |
| **Runner**         | Entwicklung | Debug      |
| **Runner-Release** | TestFlight  | ✅ Release |

## 📱 TestFlight Upload

Nach dem Upload:

1. **App Store Connect** → **TestFlight**
2. **Builds** → Ihr Build sollte erscheinen
3. **Internal Testing** aktivieren
4. **Testers hinzufügen**

## 🎯 Wichtig!

- **Immer Runner-Release Schema** für TestFlight verwenden
- **Nicht Runner Schema** (das ist für Debug)
- **Release-Konfiguration** ist für Produktion optimiert

## ✅ Erfolg!

Ihr Release-Build ist bereit für TestFlight! 🚀

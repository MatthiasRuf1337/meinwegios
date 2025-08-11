# Xcode Cloud Setup für TestFlight

## ✅ Release Schema erstellen (ERFORDERLICH)

### Schritt 1: Release Schema in Xcode erstellen

1. **Xcode öffnen:**

   ```bash
   open ios/Runner.xcworkspace
   ```

2. **Neues Schema erstellen:**

   - **Product** → **Scheme** → **Manage Schemes**
   - **+** Button klicken
   - **Runner** auswählen
   - **Name**: `Runner-Release`
   - **Shared** aktivieren ✅

3. **Release-Konfiguration setzen:**

   - **Edit Scheme** → **Run** → **Info**
   - **Build Configuration**: `Release` auswählen
   - **Archive** → **Build Configuration**: `Release` auswählen

### Schritt 2: Xcode Cloud konfigurieren

1. **Xcode Cloud Build konfigurieren:**

   - **Product** → **Xcode Cloud** → **View Cloud Builds**
   - **Ihr Projekt** auswählen
   - **Build Configuration** → **Runner-Release** auswählen (WICHTIG!)

2. **Automatische Builds:**

   - Bei jedem Git Push wird jetzt das Release-Schema verwendet
   - Builds werden automatisch zu TestFlight hochgeladen

## 🔧 Xcode Cloud Schema ändern (AKTUELL ERFORDERLICH)

**Problem**: Xcode Cloud verwendet noch das Debug-Schema "Runner"

**Lösung**:

1. **Xcode öffnen:**

   ```bash
   open ios/Runner.xcworkspace
   ```

2. **Xcode Cloud konfigurieren:**

   - **Product** → **Xcode Cloud** → **View Cloud Builds**
   - **Ihr Projekt** auswählen
   - **Build Configuration** → **Runner-Release** auswählen ✅
   - **Speichern**

3. **Neuen Build starten:**
   - **Start Build** klicken
   - Oder neuen Git Push machen

## 🔐 Code-Signing Problem lösen (AKTUELL ERFORDERLICH)

**Problem**: `No signing certificate "iOS Development" found`

**Lösung**:

1. **Apple Developer Account prüfen:**

   - Gehen Sie zu [developer.apple.com](https://developer.apple.com)
   - **Certificates, Identifiers & Profiles**
   - Stellen Sie sicher, dass Sie ein **iOS Development Certificate** haben

2. **Xcode Cloud Code-Signing konfigurieren:**

   - **Xcode** → **Product** → **Xcode Cloud** → **View Cloud Builds**
   - **Ihr Projekt** auswählen
   - **Settings** → **Code Signing**
   - **Automatic** auswählen (empfohlen)
   - Oder **Manual** und Zertifikat hochladen

3. **Team ID prüfen:**

   - **Xcode** → **Runner.xcodeproj** → **Signing & Capabilities**
   - **Team**: `V3VVPQ9SZ3` sollte korrekt sein
   - **Bundle Identifier**: Sollte eindeutig sein

4. **Provisioning Profile:**

   - Xcode Cloud erstellt automatisch Provisioning Profiles
   - Falls nicht: **Manual** auswählen und Profile hochladen

## Release Schema Konfiguration

Für TestFlight-Builds muss das **Release-Schema** verwendet werden:

### Verfügbare Schemas:

| Schema             | Konfiguration | Verwendung            | Status        |
| ------------------ | ------------- | --------------------- | ------------- |
| **Runner**         | Debug         | Entwicklung, Testing  | ❌ TestFlight |
| **Runner-Release** | Release       | TestFlight, App Store | ✅ TestFlight |

## Automatische Builds nach Git Push

Nach der Konfiguration:

1. **Git Push** → Xcode Cloud baut automatisch
2. **Release-Schema** wird verwendet
3. **Build** wird zu TestFlight hochgeladen
4. **Keine manuelle Intervention** nötig

## Manueller Build für TestFlight

```bash
# Flutter Build mit Release-Konfiguration
flutter build ios --release

# Oder mit Xcode direkt
xcodebuild -scheme Runner-Release -configuration Release archive
```

## Troubleshooting

### Problem: Build kommt nicht in TestFlight

**Lösung**: Stellen Sie sicher, dass das **Runner-Release** Schema erstellt und konfiguriert wurde.

### Problem: Debug-Build wird hochgeladen

**Lösung**: Xcode Cloud Schema auf **Runner-Release** ändern.

### Problem: Code-Signing Fehler

```
No signing certificate "iOS Development" found
```

**Lösung**:

1. **Apple Developer Account** prüfen
2. **Xcode Cloud Code-Signing** auf **Automatic** setzen
3. **Team ID** in Xcode prüfen
4. **Provisioning Profile** konfigurieren

### Problem: `The sandbox is not in sync with the Podfile.lock`

**Lösung**:

1. `cd ios && pod install` lokal ausführen
2. `git add ios/Podfile.lock && git commit && git push`

## Nächste Schritte

1. **Xcode Cloud Schema ändern** (siehe Schritt 2)
2. **Neuen Build starten**
3. **Git Push** → Automatischer Release-Build
4. **TestFlight** → Build sollte erscheinen

## ✅ Erfolg!

Nach der Konfiguration wird bei jedem Git Push automatisch ein Release-Build erstellt und zu TestFlight hochgeladen! 🚀

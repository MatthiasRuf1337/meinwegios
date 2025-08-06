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
   - **Build Configuration** → **Runner-Release** auswählen

2. **Automatische Builds:**
   - Bei jedem Git Push wird jetzt das Release-Schema verwendet
   - Builds werden automatisch zu TestFlight hochgeladen

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

**Lösung**: Überprüfen Sie die Xcode Cloud Einstellungen und wählen Sie das Release-Schema.

## Nächste Schritte

1. **Release Schema erstellen** (siehe Schritt 1)
2. **Xcode Cloud konfigurieren** (siehe Schritt 2)
3. **Git Push** → Automatischer Release-Build
4. **TestFlight** → Build sollte erscheinen

## ✅ Erfolg!

Nach der Konfiguration wird bei jedem Git Push automatisch ein Release-Build erstellt und zu TestFlight hochgeladen! 🚀

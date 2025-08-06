# Xcode Cloud Setup für TestFlight

## Release Schema Konfiguration

Für TestFlight-Builds muss das **Release-Schema** verwendet werden. Wir haben ein separates Release-Schema erstellt:

### Verfügbare Schemas:

1. **Runner** (Debug) - Für Entwicklung
2. **Runner-Release** (Release) - Für TestFlight ✅

## Xcode Cloud Konfiguration

### 1. Schema in Xcode Cloud auswählen:

- Gehen Sie zu Xcode → Product → Xcode Cloud → View Cloud Builds
- Wählen Sie Ihr Projekt aus
- Unter "Build Configuration" wählen Sie **Runner-Release** aus

### 2. Build Settings für Release:

```
Build Configuration: Release
Scheme: Runner-Release
Archive Action: Release
```

### 3. Automatische Builds:

Das Release-Schema wird automatisch für alle TestFlight-Builds verwendet.

## Manueller Build für TestFlight

```bash
# Flutter Build mit Release-Konfiguration
flutter build ios --release

# Oder mit Xcode direkt
xcodebuild -scheme Runner-Release -configuration Release archive
```

## Troubleshooting

### Problem: Build kommt nicht in TestFlight

**Lösung**: Stellen Sie sicher, dass das **Runner-Release** Schema verwendet wird.

### Problem: Debug-Build wird hochgeladen

**Lösung**: Überprüfen Sie die Xcode Cloud Einstellungen und wählen Sie das Release-Schema.

## Schema Unterschiede

| Schema         | Konfiguration | Verwendung            |
| -------------- | ------------- | --------------------- |
| Runner         | Debug         | Entwicklung, Testing  |
| Runner-Release | Release       | TestFlight, App Store |

## Nächste Schritte

1. Öffnen Sie Xcode
2. Wählen Sie das **Runner-Release** Schema aus
3. Führen Sie einen neuen Cloud Build aus
4. Das Build sollte jetzt in TestFlight erscheinen

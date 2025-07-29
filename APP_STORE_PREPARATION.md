# Apple App Store Vorbereitung - Developer Test

## 1. Voraussetzungen

### Apple Developer Account

- [Apple Developer Account](https://developer.apple.com) (99$/Jahr)
- App Store Connect Zugang
- Xcode installiert (neueste Version)

### Flutter Setup

```bash
flutter doctor
flutter clean
flutter pub get
```

## 2. App-Konfiguration

### Bundle Identifier

In `ios/Runner.xcodeproj/project.pbxproj` oder Xcode:

- Eindeutige Bundle ID: `com.yourcompany.meinweg`
- Version: `1.0.0`
- Build Number: `1`

### App-Icon

- Alle erforderlichen Icon-Größen in `ios/Runner/Assets.xcassets/AppIcon.appiconset/`
- 1024x1024 Icon für App Store (wichtig!)

### App-Name und Beschreibung

- Display Name: "MeinWeg" (bereits in Info.plist)
- Beschreibung für App Store vorbereiten

## 3. Berechtigungen (bereits konfiguriert)

Alle erforderlichen Berechtigungen sind in `Info.plist` definiert:

- Kamera
- Standort
- Fotos
- Mikrofon
- Bewegung

## 4. Build für iOS

### Release Build erstellen

```bash
# iOS Release Build
flutter build ios --release

# Oder für Simulator
flutter build ios --release --simulator
```

### Archive erstellen

1. Xcode öffnen: `open ios/Runner.xcworkspace`
2. Scheme auf "Runner" setzen
3. Device auf "Any iOS Device" setzen
4. Product → Archive

## 5. App Store Connect Setup

### 1. App erstellen

1. [App Store Connect](https://appstoreconnect.apple.com) öffnen
2. "My Apps" → "+" → "New App"
3. Plattform: iOS
4. Name: "MeinWeg"
5. Bundle ID: `com.yourcompany.meinweg`
6. SKU: eindeutige ID (z.B. `meinweg2024`)

### 2. App-Informationen

- **App Information**:

  - Name: "MeinWeg"
  - Subtitle: "Etappen-Tracking App"
  - Keywords: "wanderung, etappen, gps, tracking"
  - Description: App-Beschreibung
  - Support URL: Ihre Website
  - Marketing URL: Optional

- **Pricing**: Kostenlos oder Preis festlegen

### 3. Screenshots

- iPhone 6.7" Display (1290 x 2796)
- iPhone 6.5" Display (1242 x 2688)
- iPhone 5.5" Display (1242 x 2208)
- iPad Pro 12.9" Display (2048 x 2732)

### 4. App Review Information

- Demo Account (falls erforderlich)
- Anmerkungen für Reviewer
- Kontaktinformationen

## 6. Upload und TestFlight

### 1. Archive hochladen

1. In Xcode: Window → Organizer
2. Archive auswählen
3. "Distribute App" → "App Store Connect"
4. "Upload" wählen
5. Automatische Signierung verwenden

### 2. TestFlight Setup

1. In App Store Connect: "TestFlight" Tab
2. Build hochladen
3. Externe Tester hinzufügen (max. 10.000)
4. E-Mail-Adressen eingeben
5. Test-Informationen bereitstellen

### 3. Interne Tests

- Bis zu 100 interne Tester
- Sofort verfügbar nach Upload
- Für Team-Mitglieder

## 7. App Store Review

### 1. App Store Review vorbereiten

1. Alle Metadaten vervollständigen
2. Screenshots hochladen
3. App-Informationen prüfen
4. "Submit for Review" klicken

### 2. Review-Prozess

- Dauer: 1-7 Tage
- Status in App Store Connect verfolgen
- Bei Problemen: Feedback erhalten

## 8. Häufige Probleme und Lösungen

### Build-Fehler

```bash
# Flutter Clean
flutter clean
flutter pub get

# iOS Dependencies
cd ios
pod install
cd ..

# Build erneut
flutter build ios --release
```

### Code Signing

- Automatische Signierung in Xcode aktivieren
- Provisioning Profile prüfen
- Certificate Gültigkeit kontrollieren

### App Store Guidelines

- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- Datenschutz-Richtlinien beachten
- App-Funktionalität testen

## 9. Nächste Schritte

### Für Developer Test

1. TestFlight Build erstellen
2. Externe Tester einladen
3. Feedback sammeln
4. Bugs beheben

### Für App Store Release

1. App Store Review durchführen
2. Marketing-Materialien vorbereiten
3. Launch-Plan erstellen
4. Analytics einrichten

## 10. Wichtige Commands

```bash
# Flutter Setup
flutter doctor
flutter clean
flutter pub get

# iOS Build
flutter build ios --release
flutter build ios --release --simulator

# Pods aktualisieren
cd ios && pod install && cd ..

# App Bundle erstellen
flutter build appbundle

# TestFlight Build
flutter build ios --release
# Dann in Xcode: Product → Archive
```

## 11. Checkliste

- [ ] Apple Developer Account
- [ ] App Store Connect Setup
- [ ] Bundle Identifier konfiguriert
- [ ] App-Icon erstellt
- [ ] Berechtigungen definiert
- [ ] Release Build erfolgreich
- [ ] Archive erstellt
- [ ] TestFlight Upload
- [ ] Externe Tester eingeladen
- [ ] App Store Metadaten vervollständigt

## Support

Bei Problemen:

- [Flutter iOS Deployment](https://docs.flutter.dev/deployment/ios)
- [Apple Developer Documentation](https://developer.apple.com/documentation/)
- [App Store Connect Help](https://help.apple.com/app-store-connect/)

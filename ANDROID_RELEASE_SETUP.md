# Android Release Setup

## Aktuelle Konfiguration ✅

Die folgenden Punkte sind bereits konfiguriert:

### 1. Berechtigungen (AndroidManifest.xml) ✅

- Alle notwendigen Berechtigungen sind bereits gesetzt:
  - Location (Fine, Coarse, Background)
  - Camera, Audio Recording
  - Storage, Internet
  - Foreground Service

### 2. App-Konfiguration ✅

- Application ID: `com.marcobachpilgern.meinweg`
- App Name: "Mein Weg"
- Icons sind in allen Auflösungen vorhanden

### 3. Build-Konfiguration ✅

- Kotlin 11 Support
- Release-Signing vorbereitet
- ProGuard-Regeln erstellt

## Noch zu erledigende Schritte

### 1. Keystore für Release-Signing erstellen

```bash
keytool -genkey -v -keystore ~/meinweg-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias meinweg
```

### 2. key.properties Datei erstellen

Erstelle `android/key.properties` mit:

```
storePassword=dein_store_passwort
keyPassword=dein_key_passwort
keyAlias=meinweg
storeFile=/Users/matthias/meinweg-release-key.jks
```

### 3. App Bundle für Play Store erstellen

```bash
flutter build appbundle --release
```

Die .aab Datei findest du dann unter:
`build/app/outputs/bundle/release/app-release.aab`

### 4. APK für direkten Download erstellen

```bash
flutter build apk --release
```

Die .apk Datei findest du dann unter:
`build/app/outputs/flutter-apk/app-release.apk`

## Google Play Store Anforderungen

### Target API Level

- Die App ist bereits für die aktuellen Android-Anforderungen konfiguriert
- `targetSdk` wird automatisch von Flutter gesetzt

### Berechtigungen

- Alle Berechtigungen haben entsprechende Begründungen in der App
- Background Location ist korrekt als Foreground Service implementiert

### App Signing

- Google Play App Signing wird empfohlen
- Upload-Key kann separat vom Signing-Key sein

## Testen vor Release

1. **Debug-Build testen:**

   ```bash
   flutter run --debug
   ```

2. **Release-Build testen:**

   ```bash
   flutter run --release
   ```

3. **App Bundle validieren:**
   - Mit `bundletool` testen
   - Verschiedene Gerätekonfigurationen prüfen

## Wichtige Hinweise

- Die `key.properties` Datei NIEMALS in Git committen
- Keystore-Datei sicher aufbewahren (Backup!)
- Bei Verlust des Keystores können keine Updates mehr veröffentlicht werden

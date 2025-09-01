# Background-Location Setup für iOS

## Problem

In iOS-Einstellungen unter "Datenschutz & Sicherheit" → "Standortdienste" → "Mein Weg" werden zwei wichtige Optionen angezeigt:

- **Live-Aktivitäten**
- **Hintergrundaktualisierung**

Diese sind essentiell für zuverlässiges GPS-Tracking auch bei Telefonaten oder wenn die App im Hintergrund läuft.

## Lösung implementiert

### 1. iOS-Konfiguration aktiviert

✅ **Podfile aktualisiert**: `PERMISSION_LOCATION_ALWAYS=1` aktiviert
✅ **Info.plist konfiguriert**: Alle Location-Berechtigungen definiert
✅ **Background-Modi**: `location` und `audio` aktiviert

### 2. Intelligente Berechtigungs-Anfrage

✅ **Nutzerfreundlicher Dialog**: Erklärt warum Background-Location benötigt wird
✅ **Automatische Erkennung**: Prüft ob Berechtigung bereits vorhanden
✅ **Fallback-Handling**: Funktioniert auch ohne Background-Berechtigung

### 3. Benutzer-Feedback

✅ **Erfolgs-Bestätigung**: "Live-Aufzeichnung aktiviert"
✅ **Hinweis bei Verweigerung**: Link zu Einstellungen
✅ **Transparenz**: Nutzer weiß was passiert

## Was der Nutzer sieht

### Beim ersten Start einer Etappe:

1. **Dialog erscheint**: "Live-Aufzeichnung aktivieren"
2. **Erklärung**: Warum Background-Location benötigt wird
3. **iOS-Berechtigung**: System fragt nach "Immer" erlauben
4. **Bestätigung**: "✅ Live-Aufzeichnung aktiviert"

### In iOS-Einstellungen:

- **Standortdienste** → **Mein Weg** → **Immer** ✅
- **Live-Aktivitäten**: Automatisch aktiviert
- **Hintergrundaktualisierung**: Automatisch aktiviert

## Technische Details

### Berechtigungen in Info.plist:

```xml
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Die App benötigt dauerhaften Zugriff auf den Standort, um Ihre Etappen auch im Hintergrund zu verfolgen und aufzuzeichnen.</string>

<key>UIBackgroundModes</key>
<array>
    <string>location</string>
    <string>audio</string>
</array>
```

### Podfile-Konfiguration:

```ruby
'PERMISSION_LOCATION_ALWAYS=1',  # Background-Location aktiviert
```

### App-Verhalten:

- **Mit Background-Berechtigung**: GPS läuft auch bei Telefonaten weiter
- **Ohne Background-Berechtigung**: GPS pausiert bei App-Wechsel, funktioniert aber im Vordergrund

## Für Entwickler

### Nach Code-Änderungen:

1. **iOS-Pods neu installieren**:

   ```bash
   cd ios
   pod install
   ```

2. **App neu kompilieren**:

   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

3. **Testen**:
   - Etappe starten
   - Dialog sollte erscheinen
   - "Immer" in iOS-Berechtigung wählen
   - Telefonat simulieren → GPS läuft weiter

## Ergebnis

✅ **Live-Aktivitäten**: Automatisch verfügbar
✅ **Hintergrundaktualisierung**: Automatisch verfügbar  
✅ **Kontinuierliches GPS**: Auch bei Telefonaten
✅ **Nutzerfreundlich**: Klare Erklärung warum benötigt

Die App fragt jetzt proaktiv nach der Background-Location-Berechtigung und erklärt dem Nutzer den Nutzen!

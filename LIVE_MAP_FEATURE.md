# Live-Karte Feature

## Übersicht

Die App unterstützt jetzt eine Live-Karte mit OpenStreetMap, die während des Trackings die gelaufene Route in Echtzeit anzeigt.

## Features

### 🗺️ OpenStreetMap Integration

- Verwendet OpenStreetMap statt Google Maps
- Keine Google-Abhängigkeiten erforderlich
- Kostenlose und offene Kartendaten

### 🏃‍♂️ Live-Tracking

- **Route-Aufzeichnung**: Zeigt die gelaufene Strecke als grüne Linie auf der Karte
- **GPS-Punkte**: Sammelt und visualisiert GPS-Koordinaten in Echtzeit
- **Start-Marker**: Grüner Kreis mit Play-Symbol markiert den Startpunkt
- **Aktuelle Position**: Blauer Kreis mit Person-Symbol zeigt die aktuelle Position

### 🎛️ Interaktive Bedienelemente

- **Follow-Modus**: Automatisches Zentrieren auf aktuelle Position
- **Zoom-Buttons**: Vergrößern/Verkleinern der Kartenansicht
- **Vollbild-Modus**: Karte in separatem Bildschirm anzeigen
- **Manuelle Navigation**: Follow-Modus wird automatisch deaktiviert bei manueller Bewegung

## Technische Details

### Dependencies

```yaml
flutter_map: ^6.1.0 # OpenStreetMap-Karten für Flutter
latlong2: ^0.9.1 # GPS-Koordinaten-Handling
```

### Implementierung

- **Widget**: `LiveMapWidget` in `lib/widgets/live_map_widget.dart`
- **Integration**: Eingebettet in `_buildLiveStatistics()` des Tracking-Screens
- **Datenquelle**: Verwendet `TrackingData` aus dem `TrackingServiceV2`

### Karteneinstellungen

- **Tile-Server**: `https://tile.openstreetmap.org/{z}/{x}/{y}.png`
- **Zoom-Bereich**: 3.0 - 18.0
- **Standard-Zoom**: 16.0 (bei verfügbarer GPS-Position)
- **Route-Farbe**: `#00847E` (App-Primärfarbe)
- **Linienstärke**: 4.0 Pixel

## Nutzung

### Im Live-Tracking

1. Starte eine Etappe im Tracking-Modus
2. Scrolle zu den "Live-Statistiken"
3. Die Karte zeigt automatisch deine aktuelle Position und Route
4. Verwende die Bedienelemente für Zoom und Navigation

### Vollbild-Ansicht

1. Tippe auf das Vollbild-Symbol (⛶) in der oberen rechten Ecke
2. Die Karte öffnet sich in einem separaten Bildschirm
3. Alle Bedienelemente sind auch im Vollbild verfügbar

## Berechtigungen

Die Karte nutzt die bereits vorhandenen GPS-Berechtigungen der App. Keine zusätzlichen Berechtigungen erforderlich.

## Performance

- **Tile-Caching**: Automatisches Zwischenspeichern der Kartenkacheln
- **GPS-Filterung**: Nur realistische GPS-Punkte werden zur Route hinzugefügt
- **Optimierte Updates**: Karte wird nur bei signifikanten Positionsänderungen aktualisiert

## Offline-Funktionalität

- Bereits geladene Kartenkacheln funktionieren offline
- GPS-Tracking funktioniert unabhängig von der Internetverbindung
- Route wird lokal gespeichert und bei Wiederherstellung der Verbindung angezeigt

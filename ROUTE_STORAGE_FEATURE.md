# Route-Speicherung und Anzeige

## Übersicht

Die App speichert jetzt automatisch alle GPS-Punkte während des Live-Trackings und zeigt die abgeschlossenen Routen in den Etappen-Details an.

## Funktionsweise

### 🗂️ Datenspeicherung

- **Automatische Speicherung**: Alle GPS-Punkte werden während des Trackings automatisch in der Datenbank gespeichert
- **JSON-Format**: GPS-Punkte werden als JSON in der SQLite-Datenbank gespeichert
- **Persistenz**: Routen bleiben dauerhaft gespeichert und können jederzeit angezeigt werden

### 📍 GPS-Daten Struktur

```dart
class GPSPunkt {
  final double latitude;      // Breitengrad
  final double longitude;     // Längengrad
  final double? altitude;     // Höhe (optional)
  final DateTime timestamp;   // Zeitstempel
  final double? accuracy;     // GPS-Genauigkeit
}
```

### 🗃️ Datenbank-Schema

```sql
CREATE TABLE etappen (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  startzeit INTEGER NOT NULL,
  endzeit INTEGER,
  status INTEGER NOT NULL,
  gesamtDistanz REAL DEFAULT 0.0,
  schrittAnzahl INTEGER DEFAULT 0,
  gpsPunkte TEXT,            -- JSON Array der GPS-Punkte
  notizen TEXT,
  erstellungsDatum INTEGER NOT NULL,
  bildIds TEXT,
  startWetter TEXT,
  wetterVerlauf TEXT
);
```

## 📱 Anzeige der gespeicherten Routen

### 1. **Live-Tracking Screen**

- Zeigt die Route in Echtzeit während des Trackings
- Verwendet `LiveMapWidget` mit aktuellen TrackingData

### 2. **Etappe-Completed Screen** (direkt nach Abschluss)

- Zeigt die vollständige Route mit Start- und Endmarkern
- Statistiken: GPS-Punkte, Distanz, Dauer
- Konfetti-Animation zur Feier

### 3. **Etappen-Detail Screen** (Archiv)

- Vollständige Routenanzeige für alle abgeschlossenen Etappen
- Interaktive Karte mit Zoom- und Vollbild-Funktionen
- Automatische Anpassung der Kartenansicht an die Route

## 🗺️ StaticRouteMapWidget Features

### Automatische Kartenanpassung

- **Bounding Box**: Berechnet automatisch den optimalen Kartenausschnitt
- **Smart Zoom**: Passt Zoom-Level basierend auf Routenlänge an
- **Zentrierung**: Zentriert die Karte auf die gesamte Route

### Interaktive Bedienelemente

- **🔍 Zoom In/Out**: Manuelles Vergrößern/Verkleinern
- **🎯 Route anpassen**: Zurück zur optimalen Ansicht
- **⛶ Vollbild**: Karte in separatem Screen öffnen

### Visuelle Elemente

- **Grüne Linie**: Gelaufene Route als Polyline
- **Start-Marker**: Grüner Kreis mit Play-Symbol
- **End-Marker**: Roter Kreis mit Stop-Symbol (nur wenn Start ≠ Ende)
- **Info-Banner**: Route-Statistiken oben links
- **Status-Badge**: Etappen-Status unten rechts

### Fallback für Etappen ohne GPS

```dart
// Zeigt hilfreiche Nachricht wenn keine GPS-Daten vorhanden
if (routePoints.isEmpty) {
  return Container(
    child: Center(
      child: Column(
        children: [
          Icon(Icons.location_off),
          Text('Keine GPS-Daten verfügbar'),
          Text('Diese Etappe wurde ohne GPS-Aufzeichnung erstellt'),
        ],
      ),
    ),
  );
}
```

## 🔄 Datenfluss

### Während des Trackings

1. `TrackingServiceV2` sammelt GPS-Punkte
2. GPS-Punkte werden gefiltert (Genauigkeit, realistische Bewegung)
3. Validierte Punkte werden zur `_gpsPoints` Liste hinzugefügt
4. Bei `_saveCurrentProgress()` werden Punkte in Etappe gespeichert
5. `LiveMapWidget` zeigt Route in Echtzeit

### Nach dem Abschluss

1. `_finishEtappe()` speichert finale GPS-Punkte in Datenbank
2. Navigation zu `EtappeCompletedScreen` mit vollständiger Route
3. `StaticRouteMapWidget` lädt GPS-Punkte aus Etappe-Objekt
4. Karte wird automatisch an Route angepasst

### Im Archiv

1. Nutzer öffnet Etappen-Details aus Archiv
2. `EtappeDetailScreen` lädt Etappe aus Datenbank
3. GPS-Punkte werden aus JSON deserialisiert
4. `StaticRouteMapWidget` rendert gespeicherte Route

## 🎯 Vorteile

### Für den Nutzer

- **Vollständige Dokumentation**: Jede Route wird automatisch gespeichert
- **Langzeit-Archiv**: Alle Routen bleiben dauerhaft verfügbar
- **Visuelle Erinnerungen**: Karten zeigen genau wo gelaufen wurde
- **Keine Datenverluste**: Offline-Speicherung, keine Cloud-Abhängigkeit

### Technisch

- **Effiziente Speicherung**: JSON-Kompression für GPS-Daten
- **Skalierbar**: Unterstützt beliebig viele GPS-Punkte
- **Performant**: Lazy Loading und intelligente Kartenanpassung
- **Offline-First**: Funktioniert ohne Internet-Verbindung

## 🔧 Konfiguration

### GPS-Filterung (in TrackingServiceV2)

```dart
bool _isRealisticMovement(double distance, Position position) {
  if (position.accuracy > 20.0) return false;  // Max. 20m Ungenauigkeit
  if (distance > 50.0) return false;           // Max. 50m Sprünge
  if (position.speed > 15.0) return false;     // Max. 54 km/h
  if (distance < 0.5) return false;            // Min. 0.5m Bewegung
  return true;
}
```

### Karten-Zoom-Level

```dart
double zoom = 15.0; // Standard
if (maxDiff > 0.01) zoom = 12.0;  // ~1km Route
if (maxDiff > 0.05) zoom = 10.0;  // ~5km Route
if (maxDiff > 0.1) zoom = 9.0;    // ~10km Route
if (maxDiff > 0.5) zoom = 7.0;    // ~50km Route
```

Die Route-Speicherung funktioniert vollautomatisch - Nutzer müssen nichts zusätzlich tun, um ihre Routen zu dokumentieren!

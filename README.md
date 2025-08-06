# MeinWeg - Etappen-Tracking App

Eine Flutter-App für das Tracking von Wanderungen und Touren mit GPS, Schrittzählung, Foto- und Audioaufnahmen sowie PDF-Mediathek.

## Features

- **Etappen-Tracking**: GPS-basiertes Tracking von Wanderungen
- **Schrittzählung**: Automatische Schrittzählung während der Wanderung
- **Foto-Aufnahmen**: Bilder mit GPS-Koordinaten aufnehmen
- **Audio-Aufnahmen**: Sprachmemos während der Wanderung
- **PDF-Mediathek**: PDFs anzeigen und verwalten
- **Offline-Funktionalität**: Alle Daten werden lokal gespeichert

## Vorab geladene PDFs

Die App unterstützt vorab geladene PDFs, die automatisch in der Mediathek verfügbar sind. Um PDFs vorab zu laden:

### Option 1: PDFs in den Assets-Ordner legen

1. Legen Sie Ihre PDF-Dateien in den `assets/pdf/` Ordner
2. Die PDFs werden automatisch beim ersten App-Start in die Mediathek importiert
3. Die PDFs sind dann immer verfügbar, auch offline

### Option 2: PDFs über die App hinzufügen

1. Öffnen Sie die Mediathek in der App
2. Verwenden Sie die "Hinzufügen"-Funktion
3. Wählen Sie eine PDF-Datei aus

### Beispiel-PDFs

Sie können beliebige PDFs verwenden, zum Beispiel:

- Wanderkarten
- Routenbeschreibungen
- Informationsbroschüren
- Notfallkontakte

## Installation

1. Flutter installieren
2. Repository klonen
3. Dependencies installieren: `flutter pub get`
4. App starten: `flutter run`

## Berechtigungen

Die App benötigt folgende Berechtigungen:

- Standort (GPS-Tracking)
- Kamera (Foto-Aufnahmen)
- Mikrofon (Audio-Aufnahmen)
- Speicher (PDF-Downloads)

## Technische Details

- **Framework**: Flutter
- **Datenbank**: SQLite (sqflite)
- **GPS**: geolocator
- **PDF-Viewer**: flutter_pdfview
- **Audio**: just_audio
- **State Management**: Provider

## Entwicklung

### Projektstruktur

```
lib/
├── models/          # Datenmodelle
├── providers/       # State Management
├── screens/         # UI-Screens
├── services/        # Business Logic
└── main.dart        # App-Einstiegspunkt
```

### Datenbank-Schema

- **etappen**: Wanderungen und Touren
- **bilder**: Foto-Aufnahmen mit GPS-Daten
- **medien_dateien**: PDFs und Audio-Dateien

## Lizenz

Dieses Projekt ist für private Nutzung bestimmt.

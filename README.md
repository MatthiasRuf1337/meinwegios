# MeinWeg - Etappen-Tracking App

Eine Flutter-App für das Tracking und die Verwaltung von Wanderungen und Touren mit GPS-Tracking, Schrittzählung und Multimedia-Integration.

## Features

### 📱 Hauptmodule

- **Archiv**: Übersicht und Verwaltung aller Etappen
- **Etappen-Tracking**: Live-Tracking mit GPS und Schrittzählung
- **Galerie**: Zentrale Verwaltung aller aufgenommenen Bilder
- **Mediathek**: Verwaltung von PDF- und MP3-Dateien (PIN-geschützt)

### 🎯 Kernfunktionen

- **GPS-Tracking**: Präzise Aufzeichnung von Routen
- **Schrittzählung**: Automatische Schrittzählung während Etappen
- **Bildaufnahme**: Fotos mit GPS-Koordinaten
- **Multimedia**: PDF-Viewer und MP3-Player
- **PIN-Schutz**: Sichere Mediathek mit PIN-Code (Standard: 1234)
- **Offline-Funktionalität**: Alle Daten werden lokal gespeichert

### 📊 Statistiken

- Zurückgelegte Distanz
- Anzahl Schritte
- Verstrichene Zeit
- GPS-Punkte
- Bildanzahl pro Etappe

## Installation

### Voraussetzungen

- Flutter SDK (Version 3.0.0 oder höher)
- Dart SDK
- Android Studio / VS Code
- Android SDK (für Android-Build)
- Xcode (für iOS-Build, nur auf macOS)

### Setup

1. **Repository klonen**

   ```bash
   git clone <repository-url>
   cd meinweg
   ```

2. **Dependencies installieren**

   ```bash
   flutter pub get
   ```

3. **App starten**
   ```bash
   flutter run
   ```

### Berechtigungen

Die App benötigt folgende Berechtigungen:

- **Standort**: Für GPS-Tracking
- **Kamera**: Für Bildaufnahme
- **Speicher**: Für Datenspeicherung
- **Aktivitätserkennung**: Für Schrittzählung
- **Fotos**: Für Galerie-Import

## Projektstruktur

```
lib/
├── main.dart                 # App-Einstiegspunkt
├── models/                   # Datenmodelle
│   ├── etappe.dart          # Etappen-Modell
│   ├── bild.dart            # Bild-Modell
│   ├── medien_datei.dart    # Medien-Datei-Modell
│   └── app_settings.dart    # App-Einstellungen
├── providers/               # State Management
│   ├── settings_provider.dart
│   ├── etappen_provider.dart
│   ├── bilder_provider.dart
│   └── medien_provider.dart
├── screens/                 # UI-Screens
│   ├── onboarding_screen.dart
│   ├── main_navigation.dart
│   ├── archiv_screen.dart
│   ├── etappe_start_screen.dart
│   ├── etappe_tracking_screen.dart
│   ├── galerie_screen.dart
│   ├── mediathek_screen.dart
│   ├── mediathek_login_screen.dart
│   ├── etappe_detail_screen.dart
│   ├── bild_detail_screen.dart
│   ├── pdf_viewer_screen.dart
│   └── audio_player_screen.dart
└── services/               # Services
    ├── database_service.dart
    └── permission_service.dart
```

## Technische Details

### Verwendete Packages

- **geolocator**: GPS-Tracking
- **pedometer**: Schrittzählung
- **google_maps_flutter**: Kartenanzeige
- **image_picker**: Kamera-Integration
- **flutter_pdfview**: PDF-Anzeige
- **just_audio**: Audio-Wiedergabe
- **sqflite**: Lokale Datenbank
- **path_provider**: Dateisystem-Zugriff
- **permission_handler**: Berechtigungen
- **file_picker**: Datei-Import
- **shared_preferences**: App-Einstellungen
- **crypto**: PIN-Verschlüsselung
- **provider**: State Management

### Datenbank-Schema

- **etappen**: Etappen-Metadaten
- **bilder**: Bild-Informationen
- **medien_dateien**: PDF/MP3-Dateien

## Entwicklung

### Erste Schritte

1. **Onboarding**: Beim ersten App-Start wird der Benutzer durch die Funktionen geführt
2. **Berechtigungen**: Schrittweise Anfrage der erforderlichen Berechtigungen
3. **PIN-Setup**: Standard-PIN für Mediathek ist "1234"

### Debugging

```bash
# App im Debug-Modus starten
flutter run --debug

# Hot Reload aktivieren
flutter run --hot

# Release-Build erstellen
flutter build apk --release
```

## Roadmap

### Phase 1: Grundfunktionen ✅

- [x] App-Onboarding
- [x] Etappen-Erstellung und -Verwaltung
- [x] Basis GPS-Tracking
- [x] Schrittzählung
- [x] Mediathek mit PIN-Schutz

### Phase 2: Multimedia-Integration 🔄

- [ ] Kamera-Funktionalität
- [ ] Galerie-Modul
- [ ] PDF-Viewer mit Lorem Ipsum Inhalten
- [ ] MP3-Player mit Lorem Ipsum Audio
- [ ] PIN-Verwaltung für Mediathek

### Phase 3: Erweiterte Features 📋

- [ ] Erweiterte Karten-Funktionen
- [ ] Export-Funktionen
- [ ] Performance-Optimierungen
- [ ] UI/UX-Verbesserungen

### Phase 4: Polish und Release 📋

- [ ] Umfangreiche Tests
- [ ] Bug-Fixes
- [ ] Store-Vorbereitung
- [ ] Dokumentation

## Lizenz

Dieses Projekt ist unter der MIT-Lizenz lizenziert.

## Support

Bei Fragen oder Problemen erstellen Sie bitte ein Issue im Repository.

---

**Entwickelt mit ❤️ und Flutter**

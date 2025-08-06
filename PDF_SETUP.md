# PDF-Setup für MeinWeg App

Diese Anleitung erklärt, wie Sie PDFs vorab in die Mediathek der MeinWeg App laden können.

## Option 1: PDFs in den Assets-Ordner legen (Empfohlen)

### Schritt 1: PDFs vorbereiten

1. Sammeln Sie die PDFs, die Sie in der App verfügbar machen möchten
2. Stellen Sie sicher, dass die Dateinamen keine Sonderzeichen enthalten
3. Empfohlene Dateinamen: `wanderkarte.pdf`, `notfallkontakte.pdf`, `routenplan.pdf`

### Schritt 2: PDFs in den Assets-Ordner kopieren

1. Öffnen Sie den Projektordner `meinweg`
2. Navigieren Sie zum Ordner `assets/pdf/`
3. Kopieren Sie Ihre PDF-Dateien in diesen Ordner

### Schritt 3: App neu starten

1. Stoppen Sie die App (falls sie läuft)
2. Führen Sie `flutter clean` aus
3. Führen Sie `flutter pub get` aus
4. Starten Sie die App neu: `flutter run`

### Schritt 4: Überprüfung

1. Öffnen Sie die Mediathek in der App
2. Die PDFs sollten automatisch verfügbar sein
3. Sie können die PDFs öffnen und anzeigen

## Option 2: PDFs über die App hinzufügen

### Schritt 1: PDFs auf das Gerät kopieren

1. Kopieren Sie die PDFs auf Ihr Smartphone/Tablet
2. Speichern Sie sie in einem Ordner, den Sie wiederfinden

### Schritt 2: Über die App importieren

1. Öffnen Sie die Mediathek in der App
2. Verwenden Sie die "Hinzufügen"-Funktion
3. Wählen Sie die gewünschten PDF-Dateien aus
4. Die PDFs werden in die lokale Datenbank importiert

## Empfohlene PDF-Typen

### Wanderkarten

- Topographische Karten
- Wanderwege und Routen
- Höhenprofile
- Notfallpunkte

### Informationsbroschüren

- Regionale Informationen
- Sehenswürdigkeiten
- Gastronomie-Tipps
- Verkehrsinformationen

### Sicherheitsinformationen

- Notfallkontakte
- Erste-Hilfe-Anleitungen
- Wetterinformationen
- Sicherheitsrichtlinien

### Routenbeschreibungen

- Detaillierte Wegbeschreibungen
- Markierungen und Wegzeichen
- Schwierigkeitsgrade
- Zeitangaben

## Technische Details

### Automatischer Import

- PDFs werden beim ersten App-Start automatisch importiert
- Die Dateien werden in das temporäre Verzeichnis kopiert
- Metadaten werden in der SQLite-Datenbank gespeichert
- Die PDFs sind auch offline verfügbar

### Dateigröße

- Empfohlene maximale Dateigröße: 50 MB pro PDF
- Größere Dateien können die App-Performance beeinträchtigen
- Komprimieren Sie große PDFs vor dem Import

### Dateinamen

- Verwenden Sie nur ASCII-Zeichen
- Keine Leerzeichen am Anfang oder Ende
- Empfohlene Zeichen: Buchstaben, Zahlen, Bindestriche, Unterstriche

## Troubleshooting

### PDFs werden nicht angezeigt

1. Prüfen Sie, ob die PDFs im `assets/pdf/` Ordner liegen
2. Führen Sie `flutter clean` und `flutter pub get` aus
3. Starten Sie die App neu

### Fehler beim Import

1. Prüfen Sie die Dateigröße der PDFs
2. Stellen Sie sicher, dass die PDFs nicht beschädigt sind
3. Versuchen Sie es mit einer anderen PDF-Datei

### Performance-Probleme

1. Reduzieren Sie die Anzahl der PDFs
2. Komprimieren Sie große PDF-Dateien
3. Verwenden Sie einfachere PDFs ohne viele Bilder

## Beispiel-Struktur

```
meinweg/
├── assets/
│   └── pdf/
│       ├── wanderkarte_region.pdf
│       ├── notfallkontakte.pdf
│       ├── routenbeschreibung.pdf
│       └── sicherheitshinweise.pdf
└── lib/
    └── ...
```

## Support

Bei Problemen oder Fragen:

1. Prüfen Sie die Konsole-Ausgaben der App
2. Stellen Sie sicher, dass alle Dependencies installiert sind
3. Versuchen Sie es mit einer einfachen PDF-Datei zuerst

# PDF-Assets für MeinWeg App

Dieser Ordner ist für vorab geladene PDFs bestimmt, die automatisch in der Mediathek der App verfügbar gemacht werden.

## Anleitung

1. **PDFs hinzufügen**: Kopieren Sie Ihre PDF-Dateien in diesen Ordner
2. **Dateinamen**: Verwenden Sie nur ASCII-Zeichen, keine Leerzeichen am Anfang/Ende
3. **App neu starten**: Führen Sie `flutter clean` und `flutter pub get` aus
4. **Überprüfung**: Die PDFs sind dann in der Mediathek verfügbar

## Empfohlene PDF-Typen

- Wanderkarten und topographische Karten
- Routenbeschreibungen und Wegzeichen
- Notfallkontakte und Sicherheitsinformationen
- Regionale Informationsbroschüren
- Erste-Hilfe-Anleitungen

## Technische Hinweise

- Maximale Dateigröße: 50 MB pro PDF
- Format: PDF (.pdf)
- Die PDFs werden automatisch beim ersten App-Start importiert
- Die Dateien sind auch offline verfügbar

## Beispiel-Dateien

- `wanderkarte_region.pdf` - Topographische Karte der Region
- `notfallkontakte.pdf` - Wichtige Notfallnummern
- `routenbeschreibung.pdf` - Detaillierte Wegbeschreibung
- `sicherheitshinweise.pdf` - Sicherheitsrichtlinien für Wanderungen

## Support

Bei Problemen siehe `PDF_SETUP.md` im Hauptverzeichnis des Projekts.

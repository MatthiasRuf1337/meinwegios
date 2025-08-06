# Audio-Assets für MeinWeg App

Dieser Ordner ist für vorab geladene MP3-Dateien bestimmt, die automatisch in der Mediathek der App verfügbar gemacht werden.

## Anleitung

1. **MP3s hinzufügen**: Kopieren Sie Ihre MP3-Dateien in diesen Ordner
2. **Dateinamen**: Verwenden Sie nur ASCII-Zeichen, keine Leerzeichen am Anfang/Ende
3. **App neu starten**: Führen Sie `flutter clean` und `flutter pub get` aus
4. **Überprüfung**: Die MP3s sind dann in der Mediathek verfügbar

## Empfohlene MP3-Typen

- Wander-Audioguides und Routenbeschreibungen
- Naturgeräusche und Entspannungsmusik
- Informationspodcasts über die Region
- Notfall-Anleitungen als Audio
- Sprachmemos und persönliche Notizen

## Technische Hinweise

- Maximale Dateigröße: 50 MB pro MP3
- Format: MP3 (.mp3)
- Die MP3s werden automatisch beim ersten App-Start importiert
- Die Dateien sind auch offline verfügbar

## Beispiel-Dateien

- `wanderung_audioguide.mp3` - Audioguide für Wanderungen
- `naturgeraeusche.mp3` - Entspannende Naturgeräusche
- `notfall_anleitung.mp3` - Notfall-Anweisungen als Audio
- `region_info.mp3` - Informationen über die Region

## Support

Bei Problemen siehe `PDF_SETUP.md` im Hauptverzeichnis des Projekts.

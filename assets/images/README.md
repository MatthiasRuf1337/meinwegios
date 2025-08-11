# Thumbnails für MP3-Dateien

Dieser Ordner ist für Thumbnail-Bilder für MP3-Dateien bestimmt. Die Thumbnails werden automatisch in der App angezeigt.

## Anleitung

### Thumbnails hinzufügen

1. **Bild vorbereiten**: Erstellen Sie ein quadratisches Bild (empfohlen: 400x400 Pixel oder größer)
2. **Dateiname**: Verwenden Sie das Format `Thumbnail_[MP3_NAME].jpg`
   - Beispiel: Für `Atem Ruhe Freundlichkeit.mp3` → `Thumbnail_Atem Ruhe Freundlichkeit.jpg`
3. **Format**: Verwenden Sie JPG oder PNG
4. **Datei ablegen**: Legen Sie das Bild in diesen Ordner
5. **App neu starten**: Führen Sie `flutter clean` und `flutter pub get` aus

### Namenskonvention

- **MP3-Datei**: `Atem Ruhe Freundlichkeit.mp3`
- **Thumbnail**: `Thumbnail_Atem Ruhe Freundlichkeit.jpg`

- **MP3-Datei**: `3 Minuten Atemraum.mp3`
- **Thumbnail**: `Thumbnail_3 Minuten Atemraum.jpg`

### Anzeige in der App

- **Mediathek-Liste**: Kleine Thumbnails (50x50 Pixel) neben MP3-Dateien
- **Audio Player**: Große Thumbnails (200x200 Pixel) als Album-Cover
- **Fallback**: Wenn kein Thumbnail vorhanden ist, wird ein Standard-Musik-Icon angezeigt

### Empfohlene Bildgrößen

- **Thumbnail-Datei**: 400x400 Pixel oder größer (wird automatisch skaliert)
- **Format**: JPG oder PNG
- **Dateigröße**: Unter 1 MB pro Bild

### Verfügbare Thumbnails

- `Thumbnail_Atem Ruhe Freundlichkeit.jpg` - Für die Atem-Meditation
- `Thumbnail_3 Minuten Atemraum.jpg` - Für die 3-Minuten-Atemübung

### Support

Bei Problemen siehe `PDF_SETUP.md` im Hauptverzeichnis des Projekts.

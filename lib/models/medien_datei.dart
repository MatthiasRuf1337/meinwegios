import 'dart:convert';

enum MedienTyp {
  pdf,
  mp3,
  bild,
  andere,
}

class MedienDatei {
  final String id;
  final MedienTyp typ;
  final String dateiname;
  final String dateipfad;
  final int groesse;
  final DateTime importDatum;
  final Map<String, dynamic> metadaten;

  MedienDatei({
    required this.id,
    required this.typ,
    required this.dateiname,
    required this.dateipfad,
    required this.groesse,
    required this.importDatum,
    this.metadaten = const {},
  });

  // Thumbnail-Pfad für MP3-Dateien
  String? get thumbnailPath {
    if (typ != MedienTyp.mp3) return null;

    // Entferne .mp3 Erweiterung und füge .jpg hinzu
    final baseName = dateiname.replaceAll('.mp3', '');
    final thumbnailName = 'Thumbnail_$baseName.jpg';

    // Prüfe ob das Asset für die bekannten Thumbnails verfügbar ist
    if (thumbnailName == 'Thumbnail_3 Minuten Atemraum.jpg' ||
        thumbnailName == 'Thumbnail_Atem Ruhe Freundlichkeit.jpg') {
      return 'assets/images/$thumbnailName';
    }

    return null;
  }

  // Prüft ob ein Thumbnail verfügbar ist
  bool get hasThumbnail => thumbnailPath != null;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'typ': typ.index,
      'dateiname': dateiname,
      'dateipfad': dateipfad,
      'groesse': groesse,
      'importDatum': importDatum.millisecondsSinceEpoch,
      'metadaten': json.encode(metadaten),
    };
  }

  factory MedienDatei.fromMap(Map<String, dynamic> map) {
    Map<String, dynamic> metadaten = {};
    if (map['metadaten'] != null) {
      try {
        if (map['metadaten'] is String) {
          metadaten = Map<String, dynamic>.from(json.decode(map['metadaten']));
        } else {
          metadaten = Map<String, dynamic>.from(map['metadaten']);
        }
      } catch (e) {
        print('Fehler beim Parsen der Metadaten: $e');
        metadaten = {};
      }
    }

    return MedienDatei(
      id: map['id'],
      typ: MedienTyp.values[map['typ']],
      dateiname: map['dateiname'],
      dateipfad: map['dateipfad'],
      groesse: map['groesse'],
      importDatum: DateTime.fromMillisecondsSinceEpoch(map['importDatum']),
      metadaten: metadaten,
    );
  }

  MedienDatei copyWith({
    String? id,
    MedienTyp? typ,
    String? dateiname,
    String? dateipfad,
    int? groesse,
    DateTime? importDatum,
    Map<String, dynamic>? metadaten,
  }) {
    return MedienDatei(
      id: id ?? this.id,
      typ: typ ?? this.typ,
      dateiname: dateiname ?? this.dateiname,
      dateipfad: dateipfad ?? this.dateipfad,
      groesse: groesse ?? this.groesse,
      importDatum: importDatum ?? this.importDatum,
      metadaten: metadaten ?? this.metadaten,
    );
  }

  String get formatierteGroesse {
    String sizeText;
    if (groesse < 1024) {
      sizeText = '${groesse} B';
    } else if (groesse < 1024 * 1024) {
      sizeText = '${(groesse / 1024).toStringAsFixed(1)} KB';
    } else {
      sizeText = '${(groesse / (1024 * 1024)).toStringAsFixed(1)} MB';
    }

    // Dateityp und "Aus dem Buch"-Zusatz hinzufügen
    if (istVerlagsdatei) {
      String fileType = '';
      if (istPDF) {
        fileType = 'PDF';
      } else if (istMP3) {
        fileType = 'MP3';
      } else {
        fileType = typ.name.toUpperCase();
      }
      return '$sizeText, $fileType aus dem Buch';
    }

    return sizeText;
  }

  String get formatiertesImportDatum {
    return '${importDatum.day}.${importDatum.month}.${importDatum.year}';
  }

  bool get istPDF => typ == MedienTyp.pdf;
  bool get istMP3 => typ == MedienTyp.mp3;
  bool get istBild => typ == MedienTyp.bild;
  bool get istAndere => typ == MedienTyp.andere;
  bool get istVerlagsdatei => metadaten['isPreloaded'] == true;

  // Sortierpriorität für "Aus dem Buch"-Dateien
  int get buchSortierPrioritaet {
    if (!istVerlagsdatei)
      return 999; // Normale Dateien kommen nach den Buchdateien

    final name = dateiname.toLowerCase();
    if (name.contains('3 minuten atemraum')) return 1;
    if (name.contains('atem ruhe freundlichkeit')) return 2;
    if (name.contains('die magie des pilgerns')) return 3;
    if (name.contains('mache dich auf den weg')) return 4;
    if (name.contains('packliste')) return 5;

    return 6; // Andere Buchdateien
  }

  String get anzeigeName {
    String baseName;

    if (istPDF) {
      // Benutzerfreundliche Namen für PDF-Dateien
      final name = dateiname.replaceAll('.pdf', '');
      final nameLower = name.toLowerCase();
      
      // Case-insensitive Vergleich für benutzerfreundliche Namen
      if (nameLower == 'die magie des pilgerns') {
        baseName = 'Die Magie des Pilgerns';
      } else if (nameLower == 'mache dich auf den weg') {
        baseName = 'Mache dich auf den Weg';
      } else if (nameLower == 'packliste') {
        baseName = 'Packliste';
      } else {
        baseName = name;
      }
    } else if (istMP3) {
      // Benutzerfreundliche Namen für MP3-Dateien
      final name = dateiname.replaceAll('.mp3', '');
      final nameLower = name.toLowerCase();
      
      // Case-insensitive Vergleich für benutzerfreundliche Namen
      if (nameLower == 'atem ruhe freundlichkeit') {
        baseName = 'Atem Ruhe Freundlichkeit';
      } else if (nameLower == '3 minuten atemraum') {
        baseName = '3 Minuten Atemraum';
      } else {
        baseName = name;
      }
    } else {
      baseName = dateiname;
    }

    return baseName;
  }
}

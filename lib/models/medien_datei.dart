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
    if (groesse < 1024) {
      return '${groesse} B';
    } else if (groesse < 1024 * 1024) {
      return '${(groesse / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(groesse / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  String get formatiertesImportDatum {
    return '${importDatum.day}.${importDatum.month}.${importDatum.year}';
  }

  bool get istPDF => typ == MedienTyp.pdf;
  bool get istMP3 => typ == MedienTyp.mp3;
  bool get istBild => typ == MedienTyp.bild;
  bool get istAndere => typ == MedienTyp.andere;

  String get anzeigeName {
    if (istPDF) {
      // Benutzerfreundliche Namen für PDF-Dateien
      final name = dateiname.replaceAll('.pdf', '');
      switch (name) {
        case 'Die Magie des Pilgerns':
          return 'Die Magie des Pilgerns';
        case 'Mache dich auf den Weg':
          return 'Mache dich auf den Weg';
        case 'Packliste':
          return 'Packliste';
        default:
          return name;
      }
    } else if (istMP3) {
      // Benutzerfreundliche Namen für MP3-Dateien
      final name = dateiname.replaceAll('.mp3', '');
      switch (name) {
        case 'Atem Ruhe Freundlichkeit':
          return 'Atem Ruhe Freundlichkeit';
        case '3 Minuten Atemraum':
          return '3 Minuten Atemraum';
        default:
          return name;
      }
    }
    return dateiname;
  }
}

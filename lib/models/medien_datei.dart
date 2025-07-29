enum MedienTyp {
  pdf,
  mp3,
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
      'metadaten': metadaten,
    };
  }

  factory MedienDatei.fromMap(Map<String, dynamic> map) {
    return MedienDatei(
      id: map['id'],
      typ: MedienTyp.values[map['typ']],
      dateiname: map['dateiname'],
      dateipfad: map['dateipfad'],
      groesse: map['groesse'],
      importDatum: DateTime.fromMillisecondsSinceEpoch(map['importDatum']),
      metadaten: Map<String, dynamic>.from(map['metadaten'] ?? {}),
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
} 
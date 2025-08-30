class AudioAufnahme {
  final String id;
  final String dateiname;
  final String dateipfad;
  final DateTime aufnahmeZeit;
  final Duration dauer;
  final String etappenId;
  final String? notiz;
  final Map<String, dynamic>? metadaten;
  final String typ; // 'impulsfrage' oder 'allgemein'

  AudioAufnahme({
    required this.id,
    required this.dateiname,
    required this.dateipfad,
    required this.aufnahmeZeit,
    required this.dauer,
    required this.etappenId,
    this.notiz,
    this.metadaten,
    this.typ = 'allgemein', // Standard: allgemeine Audio-Aufnahme
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'dateiname': dateiname,
      'dateipfad': dateipfad,
      'aufnahmeZeit': aufnahmeZeit.millisecondsSinceEpoch,
      'dauer': dauer.inMilliseconds,
      'etappenId': etappenId,
      'notiz': notiz,
      'metadaten': metadaten != null ? metadaten.toString() : null,
      'typ': typ,
    };
  }

  factory AudioAufnahme.fromMap(Map<String, dynamic> map) {
    return AudioAufnahme(
      id: map['id'],
      dateiname: map['dateiname'],
      dateipfad: map['dateipfad'],
      aufnahmeZeit: DateTime.fromMillisecondsSinceEpoch(map['aufnahmeZeit']),
      dauer: Duration(milliseconds: map['dauer']),
      etappenId: map['etappenId'],
      notiz: map['notiz'],
      metadaten: map['metadaten'] != null
          ? Map<String, dynamic>.from(map['metadaten'])
          : null,
      typ: map['typ'] ?? 'allgemein', // Fallback für bestehende Daten
    );
  }

  String get formatierteDauer {
    final minutes = dauer.inMinutes;
    final seconds = dauer.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  AudioAufnahme copyWith({
    String? id,
    String? dateiname,
    String? dateipfad,
    DateTime? aufnahmeZeit,
    Duration? dauer,
    String? etappenId,
    String? notiz,
    Map<String, dynamic>? metadaten,
    String? typ,
  }) {
    return AudioAufnahme(
      id: id ?? this.id,
      dateiname: dateiname ?? this.dateiname,
      dateipfad: dateipfad ?? this.dateipfad,
      aufnahmeZeit: aufnahmeZeit ?? this.aufnahmeZeit,
      dauer: dauer ?? this.dauer,
      etappenId: etappenId ?? this.etappenId,
      notiz: notiz ?? this.notiz,
      metadaten: metadaten ?? this.metadaten,
      typ: typ ?? this.typ,
    );
  }

  @override
  String toString() {
    return 'AudioAufnahme{id: $id, dateiname: $dateiname, aufnahmeZeit: $aufnahmeZeit, dauer: $dauer, etappenId: $etappenId}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AudioAufnahme &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

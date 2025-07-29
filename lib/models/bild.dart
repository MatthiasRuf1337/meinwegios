class Bild {
  final String id;
  final String dateiname;
  final String dateipfad;
  final double? latitude;
  final double? longitude;
  final DateTime aufnahmeZeit;
  final String? etappenId;
  final Map<String, dynamic> metadaten;

  Bild({
    required this.id,
    required this.dateiname,
    required this.dateipfad,
    this.latitude,
    this.longitude,
    required this.aufnahmeZeit,
    this.etappenId,
    this.metadaten = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'dateiname': dateiname,
      'dateipfad': dateipfad,
      'latitude': latitude,
      'longitude': longitude,
      'aufnahmeZeit': aufnahmeZeit.millisecondsSinceEpoch,
      'etappenId': etappenId,
      'metadaten': metadaten,
    };
  }

  factory Bild.fromMap(Map<String, dynamic> map) {
    return Bild(
      id: map['id'],
      dateiname: map['dateiname'],
      dateipfad: map['dateipfad'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      aufnahmeZeit: DateTime.fromMillisecondsSinceEpoch(map['aufnahmeZeit']),
      etappenId: map['etappenId'],
      metadaten: Map<String, dynamic>.from(map['metadaten'] ?? {}),
    );
  }

  Bild copyWith({
    String? id,
    String? dateiname,
    String? dateipfad,
    double? latitude,
    double? longitude,
    DateTime? aufnahmeZeit,
    String? etappenId,
    Map<String, dynamic>? metadaten,
  }) {
    return Bild(
      id: id ?? this.id,
      dateiname: dateiname ?? this.dateiname,
      dateipfad: dateipfad ?? this.dateipfad,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      aufnahmeZeit: aufnahmeZeit ?? this.aufnahmeZeit,
      etappenId: etappenId ?? this.etappenId,
      metadaten: metadaten ?? this.metadaten,
    );
  }

  bool get hatGPS => latitude != null && longitude != null;

  String get formatierteAufnahmeZeit {
    return '${aufnahmeZeit.day}.${aufnahmeZeit.month}.${aufnahmeZeit.year} '
           '${aufnahmeZeit.hour.toString().padLeft(2, '0')}:'
           '${aufnahmeZeit.minute.toString().padLeft(2, '0')}';
  }
} 
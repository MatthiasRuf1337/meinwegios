class Notiz {
  final String id;
  final String titel;
  final String inhalt;
  final DateTime erstelltAm;
  final DateTime? bearbeitetAm;
  final String etappenId;

  Notiz({
    required this.id,
    required this.titel,
    required this.inhalt,
    required this.erstelltAm,
    this.bearbeitetAm,
    required this.etappenId,
  });

  Notiz copyWith({
    String? id,
    String? titel,
    String? inhalt,
    DateTime? erstelltAm,
    DateTime? bearbeitetAm,
    String? etappenId,
  }) {
    return Notiz(
      id: id ?? this.id,
      titel: titel ?? this.titel,
      inhalt: inhalt ?? this.inhalt,
      erstelltAm: erstelltAm ?? this.erstelltAm,
      bearbeitetAm: bearbeitetAm ?? this.bearbeitetAm,
      etappenId: etappenId ?? this.etappenId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titel': titel,
      'inhalt': inhalt,
      'erstellt_am': erstelltAm.millisecondsSinceEpoch,
      'bearbeitet_am': bearbeitetAm?.millisecondsSinceEpoch,
      'etappen_id': etappenId,
    };
  }

  factory Notiz.fromMap(Map<String, dynamic> map) {
    return Notiz(
      id: map['id'] ?? '',
      titel: map['titel'] ?? '',
      inhalt: map['inhalt'] ?? '',
      erstelltAm: DateTime.fromMillisecondsSinceEpoch(map['erstellt_am'] ?? 0),
      bearbeitetAm: map['bearbeitet_am'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['bearbeitet_am'])
          : null,
      etappenId: map['etappen_id'] ?? '',
    );
  }

  String get formatierteErstellungszeit {
    return '${erstelltAm.day}.${erstelltAm.month}.${erstelltAm.year} ${erstelltAm.hour.toString().padLeft(2, '0')}:${erstelltAm.minute.toString().padLeft(2, '0')}';
  }
}

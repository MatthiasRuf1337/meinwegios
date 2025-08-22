class AppSettings {
  final bool ersteAppNutzung;
  final String mediathekPIN;
  final bool onboardingAbgeschlossen;
  final DateTime? letzteMediathekAnmeldung;
  final int aktuellerZitatIndex;
  final DateTime? letztesZitatDatum;

  AppSettings({
    this.ersteAppNutzung = true,
    this.mediathekPIN = '1234',
    this.onboardingAbgeschlossen = false,
    this.letzteMediathekAnmeldung,
    this.aktuellerZitatIndex = 0,
    this.letztesZitatDatum,
  });

  Map<String, dynamic> toMap() {
    return {
      'ersteAppNutzung': ersteAppNutzung,
      'mediathekPIN': mediathekPIN,
      'onboardingAbgeschlossen': onboardingAbgeschlossen,
      'letzteMediathekAnmeldung':
          letzteMediathekAnmeldung?.millisecondsSinceEpoch,
      'aktuellerZitatIndex': aktuellerZitatIndex,
      'letztesZitatDatum': letztesZitatDatum?.millisecondsSinceEpoch,
    };
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      ersteAppNutzung: map['ersteAppNutzung'] ?? true,
      mediathekPIN: map['mediathekPIN'] ?? '1234',
      onboardingAbgeschlossen: map['onboardingAbgeschlossen'] ?? false,
      letzteMediathekAnmeldung: map['letzteMediathekAnmeldung'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['letzteMediathekAnmeldung'])
          : null,
      aktuellerZitatIndex: map['aktuellerZitatIndex'] ?? 0,
      letztesZitatDatum: map['letztesZitatDatum'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['letztesZitatDatum'])
          : null,
    );
  }

  AppSettings copyWith({
    bool? ersteAppNutzung,
    String? mediathekPIN,
    bool? onboardingAbgeschlossen,
    DateTime? letzteMediathekAnmeldung,
    int? aktuellerZitatIndex,
    DateTime? letztesZitatDatum,
  }) {
    return AppSettings(
      ersteAppNutzung: ersteAppNutzung ?? this.ersteAppNutzung,
      mediathekPIN: mediathekPIN ?? this.mediathekPIN,
      onboardingAbgeschlossen:
          onboardingAbgeschlossen ?? this.onboardingAbgeschlossen,
      letzteMediathekAnmeldung:
          letzteMediathekAnmeldung ?? this.letzteMediathekAnmeldung,
      aktuellerZitatIndex: aktuellerZitatIndex ?? this.aktuellerZitatIndex,
      letztesZitatDatum: letztesZitatDatum ?? this.letztesZitatDatum,
    );
  }
}

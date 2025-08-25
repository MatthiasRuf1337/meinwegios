class AppSettings {
  final bool ersteAppNutzung;
  final String mediathekPIN;
  final bool onboardingAbgeschlossen;
  final DateTime? letzteMediathekAnmeldung;
  final int aktuellerZitatIndex;
  final DateTime? letztesZitatDatum;
  final bool beispielEtappeGeloescht;

  AppSettings({
    this.ersteAppNutzung = true,
    this.mediathekPIN = 'WEG.jetzt=42',
    this.onboardingAbgeschlossen = false,
    this.letzteMediathekAnmeldung,
    this.aktuellerZitatIndex = 0,
    this.letztesZitatDatum,
    this.beispielEtappeGeloescht = false,
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
      'beispielEtappeGeloescht': beispielEtappeGeloescht,
    };
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      ersteAppNutzung: map['ersteAppNutzung'] ?? true,
      mediathekPIN: map['mediathekPIN'] ?? 'WEG.jetzt=42',
      onboardingAbgeschlossen: map['onboardingAbgeschlossen'] ?? false,
      letzteMediathekAnmeldung: map['letzteMediathekAnmeldung'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['letzteMediathekAnmeldung'])
          : null,
      aktuellerZitatIndex: map['aktuellerZitatIndex'] ?? 0,
      letztesZitatDatum: map['letztesZitatDatum'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['letztesZitatDatum'])
          : null,
      beispielEtappeGeloescht: map['beispielEtappeGeloescht'] ?? false,
    );
  }

  AppSettings copyWith({
    bool? ersteAppNutzung,
    String? mediathekPIN,
    bool? onboardingAbgeschlossen,
    DateTime? letzteMediathekAnmeldung,
    int? aktuellerZitatIndex,
    DateTime? letztesZitatDatum,
    bool? beispielEtappeGeloescht,
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
      beispielEtappeGeloescht:
          beispielEtappeGeloescht ?? this.beispielEtappeGeloescht,
    );
  }
}

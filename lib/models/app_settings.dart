class AppSettings {
  final bool ersteAppNutzung;
  final String mediathekPIN;
  final bool onboardingAbgeschlossen;
  final DateTime? letzteMediathekAnmeldung;

  AppSettings({
    this.ersteAppNutzung = true,
    this.mediathekPIN = '1234',
    this.onboardingAbgeschlossen = false,
    this.letzteMediathekAnmeldung,
  });

  Map<String, dynamic> toMap() {
    return {
      'ersteAppNutzung': ersteAppNutzung,
      'mediathekPIN': mediathekPIN,
      'onboardingAbgeschlossen': onboardingAbgeschlossen,
      'letzteMediathekAnmeldung': letzteMediathekAnmeldung?.millisecondsSinceEpoch,
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
    );
  }

  AppSettings copyWith({
    bool? ersteAppNutzung,
    String? mediathekPIN,
    bool? onboardingAbgeschlossen,
    DateTime? letzteMediathekAnmeldung,
  }) {
    return AppSettings(
      ersteAppNutzung: ersteAppNutzung ?? this.ersteAppNutzung,
      mediathekPIN: mediathekPIN ?? this.mediathekPIN,
      onboardingAbgeschlossen: onboardingAbgeschlossen ?? this.onboardingAbgeschlossen,
      letzteMediathekAnmeldung: letzteMediathekAnmeldung ?? this.letzteMediathekAnmeldung,
    );
  }
} 
import 'dart:convert';

class WetterDaten {
  final double temperatur;
  final String beschreibung;
  final String hauptKategorie; // z.B. "Clear", "Rain", "Clouds"
  final String icon;
  final double luftfeuchtigkeit;
  final double windgeschwindigkeit;
  final double windrichtung;
  final double luftdruck;
  final double gefuehlteTemperatur;
  final DateTime zeitstempel;
  final String? ort;

  WetterDaten({
    required this.temperatur,
    required this.beschreibung,
    required this.hauptKategorie,
    required this.icon,
    required this.luftfeuchtigkeit,
    required this.windgeschwindigkeit,
    required this.windrichtung,
    required this.luftdruck,
    required this.gefuehlteTemperatur,
    required this.zeitstempel,
    this.ort,
  });

  Map<String, dynamic> toMap() {
    return {
      'temperatur': temperatur,
      'beschreibung': beschreibung,
      'hauptKategorie': hauptKategorie,
      'icon': icon,
      'luftfeuchtigkeit': luftfeuchtigkeit,
      'windgeschwindigkeit': windgeschwindigkeit,
      'windrichtung': windrichtung,
      'luftdruck': luftdruck,
      'gefuehlteTemperatur': gefuehlteTemperatur,
      'zeitstempel': zeitstempel.millisecondsSinceEpoch,
      'ort': ort,
    };
  }

  factory WetterDaten.fromMap(Map<String, dynamic> map) {
    return WetterDaten(
      temperatur: (map['temperatur'] ?? 0.0).toDouble(),
      beschreibung: map['beschreibung'] ?? '',
      hauptKategorie: map['hauptKategorie'] ?? '',
      icon: map['icon'] ?? '',
      luftfeuchtigkeit: (map['luftfeuchtigkeit'] ?? 0.0).toDouble(),
      windgeschwindigkeit: (map['windgeschwindigkeit'] ?? 0.0).toDouble(),
      windrichtung: (map['windrichtung'] ?? 0.0).toDouble(),
      luftdruck: (map['luftdruck'] ?? 0.0).toDouble(),
      gefuehlteTemperatur: (map['gefuehlteTemperatur'] ?? 0.0).toDouble(),
      zeitstempel: DateTime.fromMillisecondsSinceEpoch(map['zeitstempel']),
      ort: map['ort'],
    );
  }

  String toJson() => json.encode(toMap());

  factory WetterDaten.fromJson(String source) =>
      WetterDaten.fromMap(json.decode(source));

  WetterDaten copyWith({
    double? temperatur,
    String? beschreibung,
    String? hauptKategorie,
    String? icon,
    double? luftfeuchtigkeit,
    double? windgeschwindigkeit,
    double? windrichtung,
    double? luftdruck,
    double? gefuehlteTemperatur,
    DateTime? zeitstempel,
    String? ort,
  }) {
    return WetterDaten(
      temperatur: temperatur ?? this.temperatur,
      beschreibung: beschreibung ?? this.beschreibung,
      hauptKategorie: hauptKategorie ?? this.hauptKategorie,
      icon: icon ?? this.icon,
      luftfeuchtigkeit: luftfeuchtigkeit ?? this.luftfeuchtigkeit,
      windgeschwindigkeit: windgeschwindigkeit ?? this.windgeschwindigkeit,
      windrichtung: windrichtung ?? this.windrichtung,
      luftdruck: luftdruck ?? this.luftdruck,
      gefuehlteTemperatur: gefuehlteTemperatur ?? this.gefuehlteTemperatur,
      zeitstempel: zeitstempel ?? this.zeitstempel,
      ort: ort ?? this.ort,
    );
  }

  // Hilfsmethoden für die UI
  String get formatierteTemperatur => '${temperatur.round()}°C';

  String get formatierteGefuehlteTemperatur =>
      '${gefuehlteTemperatur.round()}°C';

  String get formatierteWindgeschwindigkeit =>
      '${windgeschwindigkeit.toStringAsFixed(1)} km/h';

  String get formatierteWindrichtung {
    if (windrichtung >= 337.5 || windrichtung < 22.5) return 'N';
    if (windrichtung >= 22.5 && windrichtung < 67.5) return 'NO';
    if (windrichtung >= 67.5 && windrichtung < 112.5) return 'O';
    if (windrichtung >= 112.5 && windrichtung < 157.5) return 'SO';
    if (windrichtung >= 157.5 && windrichtung < 202.5) return 'S';
    if (windrichtung >= 202.5 && windrichtung < 247.5) return 'SW';
    if (windrichtung >= 247.5 && windrichtung < 292.5) return 'W';
    if (windrichtung >= 292.5 && windrichtung < 337.5) return 'NW';
    return 'N';
  }

  String get formatierterLuftdruck => '${luftdruck.round()} hPa';

  String get formatierteLuftfeuchtigkeit => '${luftfeuchtigkeit.round()}%';

  // Wetter-Icon Emoji basierend auf Hauptkategorie und Icon
  String get wetterEmoji {
    switch (hauptKategorie.toLowerCase()) {
      case 'clear':
        return icon.contains('d') ? '☀️' : '🌙';
      case 'clouds':
        if (icon == '02d' || icon == '02n') return '⛅';
        if (icon == '03d' || icon == '03n') return '☁️';
        if (icon == '04d' || icon == '04n') return '☁️';
        return '☁️';
      case 'rain':
        if (icon == '09d' || icon == '09n') return '🌧️';
        if (icon == '10d' || icon == '10n') return '🌦️';
        return '🌧️';
      case 'drizzle':
        return '🌦️';
      case 'thunderstorm':
        return '⛈️';
      case 'snow':
        return '❄️';
      case 'mist':
      case 'fog':
        return '🌫️';
      default:
        return '🌤️';
    }
  }

  @override
  String toString() {
    return 'WetterDaten(temperatur: $temperatur, beschreibung: $beschreibung, ort: $ort)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is WetterDaten &&
        other.temperatur == temperatur &&
        other.beschreibung == beschreibung &&
        other.hauptKategorie == hauptKategorie &&
        other.icon == icon &&
        other.luftfeuchtigkeit == luftfeuchtigkeit &&
        other.windgeschwindigkeit == windgeschwindigkeit &&
        other.windrichtung == windrichtung &&
        other.luftdruck == luftdruck &&
        other.gefuehlteTemperatur == gefuehlteTemperatur &&
        other.zeitstempel == zeitstempel &&
        other.ort == ort;
  }

  @override
  int get hashCode {
    return temperatur.hashCode ^
        beschreibung.hashCode ^
        hauptKategorie.hashCode ^
        icon.hashCode ^
        luftfeuchtigkeit.hashCode ^
        windgeschwindigkeit.hashCode ^
        windrichtung.hashCode ^
        luftdruck.hashCode ^
        gefuehlteTemperatur.hashCode ^
        zeitstempel.hashCode ^
        ort.hashCode;
  }
}

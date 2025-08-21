import 'dart:convert';
import 'wetter_daten.dart';

class Etappe {
  final String id;
  final String name;
  final DateTime startzeit;
  final DateTime? endzeit;
  final EtappenStatus status;
  final double gesamtDistanz;
  final int schrittAnzahl;
  final List<GPSPunkt> gpsPunkte;
  final String? notizen;
  final DateTime erstellungsDatum;
  final List<String> bildIds;
  final WetterDaten? startWetter;
  final List<WetterDaten> wetterVerlauf;

  Etappe({
    required this.id,
    required this.name,
    required this.startzeit,
    this.endzeit,
    required this.status,
    this.gesamtDistanz = 0.0,
    this.schrittAnzahl = 0,
    this.gpsPunkte = const [],
    this.notizen,
    required this.erstellungsDatum,
    this.bildIds = const [],
    this.startWetter,
    this.wetterVerlauf = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'startzeit': startzeit.millisecondsSinceEpoch,
      'endzeit': endzeit?.millisecondsSinceEpoch,
      'status': status.index,
      'gesamtDistanz': gesamtDistanz,
      'schrittAnzahl': schrittAnzahl,
      // In DB als TEXT (JSON) gespeichert
      'gpsPunkte': jsonEncode(gpsPunkte.map((punkt) => punkt.toMap()).toList()),
      'notizen': notizen,
      'erstellungsDatum': erstellungsDatum.millisecondsSinceEpoch,
      'bildIds': bildIds,
      'startWetter': startWetter?.toJson(),
      'wetterVerlauf': jsonEncode(wetterVerlauf.map((w) => w.toMap()).toList()),
    };
  }

  factory Etappe.fromMap(Map<String, dynamic> map) {
    return Etappe(
      id: map['id'],
      name: map['name'],
      startzeit: DateTime.fromMillisecondsSinceEpoch(map['startzeit']),
      endzeit: map['endzeit'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['endzeit'])
          : null,
      status: EtappenStatus.values[map['status']],
      gesamtDistanz: map['gesamtDistanz'] ?? 0.0,
      schrittAnzahl: map['schrittAnzahl'] ?? 0,
      // Aus DB (TEXT) JSON parsen, aber auch Liste unterstützen (Abwärtskompatibilität)
      gpsPunkte: (() {
        final raw = map['gpsPunkte'];
        if (raw == null) return <GPSPunkt>[];
        try {
          if (raw is String) {
            final decoded = jsonDecode(raw);
            if (decoded is List) {
              return decoded.map((e) => GPSPunkt.fromMap(e)).toList();
            }
          } else if (raw is List) {
            return raw.map((e) => GPSPunkt.fromMap(e)).toList();
          }
        } catch (_) {}
        return <GPSPunkt>[];
      })(),
      notizen: map['notizen'],
      erstellungsDatum:
          DateTime.fromMillisecondsSinceEpoch(map['erstellungsDatum']),
      bildIds: List<String>.from(map['bildIds'] ?? []),
      startWetter: map['startWetter'] != null
          ? WetterDaten.fromJson(map['startWetter'])
          : null,
      wetterVerlauf: (() {
        final raw = map['wetterVerlauf'];
        if (raw == null) return <WetterDaten>[];
        try {
          if (raw is String) {
            final decoded = jsonDecode(raw);
            if (decoded is List) {
              return decoded.map((e) => WetterDaten.fromMap(e)).toList();
            }
          } else if (raw is List) {
            return raw.map((e) => WetterDaten.fromMap(e)).toList();
          }
        } catch (_) {}
        return <WetterDaten>[];
      })(),
    );
  }

  Etappe copyWith({
    String? id,
    String? name,
    DateTime? startzeit,
    DateTime? endzeit,
    EtappenStatus? status,
    double? gesamtDistanz,
    int? schrittAnzahl,
    List<GPSPunkt>? gpsPunkte,
    String? notizen,
    DateTime? erstellungsDatum,
    List<String>? bildIds,
    WetterDaten? startWetter,
    List<WetterDaten>? wetterVerlauf,
  }) {
    return Etappe(
      id: id ?? this.id,
      name: name ?? this.name,
      startzeit: startzeit ?? this.startzeit,
      endzeit: endzeit ?? this.endzeit,
      status: status ?? this.status,
      gesamtDistanz: gesamtDistanz ?? this.gesamtDistanz,
      schrittAnzahl: schrittAnzahl ?? this.schrittAnzahl,
      gpsPunkte: gpsPunkte ?? this.gpsPunkte,
      notizen: notizen ?? this.notizen,
      erstellungsDatum: erstellungsDatum ?? this.erstellungsDatum,
      bildIds: bildIds ?? this.bildIds,
      startWetter: startWetter ?? this.startWetter,
      wetterVerlauf: wetterVerlauf ?? this.wetterVerlauf,
    );
  }

  Duration get dauer {
    final end = endzeit ?? DateTime.now();
    return end.difference(startzeit);
  }

  String get formatierteDauer {
    final duration = dauer;
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  String get formatierteDistanz {
    if (!gesamtDistanz.isFinite || gesamtDistanz.isNaN) {
      return '0 m';
    }
    if (gesamtDistanz < 1000) {
      return '${gesamtDistanz.toStringAsFixed(0)} m';
    } else {
      return '${(gesamtDistanz / 1000).toStringAsFixed(2)} km';
    }
  }
}

enum EtappenStatus {
  aktiv,
  pausiert,
  abgeschlossen,
}

class GPSPunkt {
  final double latitude;
  final double longitude;
  final double? altitude;
  final DateTime timestamp;
  final double? accuracy;

  GPSPunkt({
    required this.latitude,
    required this.longitude,
    this.altitude,
    required this.timestamp,
    this.accuracy,
  });

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'altitude': altitude,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'accuracy': accuracy,
    };
  }

  factory GPSPunkt.fromMap(Map<String, dynamic> map) {
    return GPSPunkt(
      latitude: map['latitude'],
      longitude: map['longitude'],
      altitude: map['altitude'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      accuracy: map['accuracy'],
    );
  }
}

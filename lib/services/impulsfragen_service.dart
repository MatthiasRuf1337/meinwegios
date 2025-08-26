import 'package:flutter/services.dart';
import 'package:csv/csv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ImpulsfrageService {
  static final ImpulsfrageService _instance = ImpulsfrageService._internal();
  factory ImpulsfrageService() => _instance;
  ImpulsfrageService._internal();

  List<Impulsfrage> _impulsfragen = [];
  int _aktuellerIndex = 0;

  static const String _indexKey = 'impulsfrage_index';

  /// Lädt die Impulsfragen aus der CSV-Datei
  Future<void> loadImpulsfragen() async {
    try {
      // CSV-Datei aus den Assets laden
      final csvString = await rootBundle.loadString('Impulsfragen.csv');

      // CSV parsen
      List<List<dynamic>> csvTable = CsvToListConverter().convert(csvString);

      _impulsfragen = csvTable.map((row) {
        return Impulsfrage(
          nummer: int.parse(row[0].toString()),
          text: row[1].toString(),
        );
      }).toList();

      // Aktuellen Index aus SharedPreferences laden
      await _loadCurrentIndex();

      print('${_impulsfragen.length} Impulsfragen geladen');
    } catch (e) {
      print('Fehler beim Laden der Impulsfragen: $e');
      // Fallback: Demo-Impulsfragen
      _impulsfragen = [
        Impulsfrage(
            nummer: 1,
            text:
                "Fallen dir gerade kleine Details auf, die dir sonst entgangen wären?"),
        Impulsfrage(
            nummer: 2, text: "Für welche Begegnung bist du heute dankbar?"),
        Impulsfrage(
            nummer: 3, text: "Wem könntest du heute innerlich Gutes wünschen?"),
      ];
    }
  }

  /// Lädt den aktuellen Index aus SharedPreferences
  Future<void> _loadCurrentIndex() async {
    final prefs = await SharedPreferences.getInstance();
    _aktuellerIndex = prefs.getInt(_indexKey) ?? 0;

    // Sicherstellen, dass der Index im gültigen Bereich ist
    if (_aktuellerIndex >= _impulsfragen.length) {
      _aktuellerIndex = 0;
    }
  }

  /// Speichert den aktuellen Index in SharedPreferences
  Future<void> _saveCurrentIndex() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_indexKey, _aktuellerIndex);
  }

  /// Gibt die nächste Impulsfrage zurück und erhöht den Index
  Future<Impulsfrage?> getNextImpulsfrage() async {
    if (_impulsfragen.isEmpty) {
      await loadImpulsfragen();
    }

    if (_impulsfragen.isEmpty) {
      return null;
    }

    final impulsfrage = _impulsfragen[_aktuellerIndex];

    // Index für nächste Frage erhöhen
    _aktuellerIndex = (_aktuellerIndex + 1) % _impulsfragen.length;
    await _saveCurrentIndex();

    return impulsfrage;
  }

  /// Gibt die aktuelle Impulsfrage zurück ohne den Index zu ändern
  Impulsfrage? getCurrentImpulsfrage() {
    if (_impulsfragen.isEmpty || _aktuellerIndex >= _impulsfragen.length) {
      return null;
    }
    return _impulsfragen[_aktuellerIndex];
  }

  /// Gibt alle Impulsfragen zurück
  List<Impulsfrage> getAllImpulsfragen() {
    return List.unmodifiable(_impulsfragen);
  }

  /// Setzt den Index zurück auf 0
  Future<void> resetIndex() async {
    _aktuellerIndex = 0;
    await _saveCurrentIndex();
  }
}

class Impulsfrage {
  final int nummer;
  final String text;

  Impulsfrage({
    required this.nummer,
    required this.text,
  });

  @override
  String toString() {
    return 'Impulsfrage(nummer: $nummer, text: $text)';
  }
}

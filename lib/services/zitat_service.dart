import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import '../models/zitat.dart';

class ZitatService {
  static List<Zitat>? _zitate;
  static const int _maxZitate = 35;

  static Future<List<Zitat>> _loadZitate() async {
    if (_zitate != null) return _zitate!;

    try {
      final String csvContent = await rootBundle.loadString('Zitate.csv');
      final List<String> lines = csvContent.split('\n');

      // Erste Zeile (Header) überspringen
      final List<Zitat> zitate = [];
      for (int i = 1; i < lines.length; i++) {
        final String line = lines[i].trim();
        if (line.isEmpty) continue;

        // CSV-Parsing (einfach mit Komma-Trennung)
        final List<String> parts = _parseCsvLine(line);
        if (parts.length >= 2) {
          zitate.add(Zitat.fromCsvRow(parts));
        }
      }

      _zitate = zitate;
      return zitate;
    } catch (e) {
      print('Fehler beim Laden der Zitate: $e');
      // Fallback-Zitat
      return [
        Zitat(
          text: 'Der Weg zu allem Großen geht durch die Stille.',
          autor: 'Friedrich Nietzsche',
        ),
      ];
    }
  }

  static List<String> _parseCsvLine(String line) {
    final List<String> result = [];
    bool inQuotes = false;
    String current = '';

    for (int i = 0; i < line.length; i++) {
      final char = line[i];

      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        result.add(current);
        current = '';
      } else {
        current += char;
      }
    }

    result.add(current);
    return result;
  }

  static Future<Zitat> getZitatByIndex(int index) async {
    final zitate = await _loadZitate();
    if (zitate.isEmpty) {
      return Zitat(
        text: 'Der Weg zu allem Großen geht durch die Stille.',
        autor: 'Friedrich Nietzsche',
      );
    }

    // Index auf verfügbare Zitate begrenzen
    final validIndex = index % zitate.length;
    return zitate[validIndex];
  }

  static int getNextZitatIndex(int currentIndex) {
    return (currentIndex + 1) % _maxZitate;
  }

  static Future<Zitat> getRandomZitat() async {
    final zitate = await _loadZitate();
    if (zitate.isEmpty) {
      return Zitat(
        text: 'Der Weg zu allem Großen geht durch die Stille.',
        autor: 'Friedrich Nietzsche',
      );
    }

    final random = Random();
    return zitate[random.nextInt(zitate.length)];
  }
}

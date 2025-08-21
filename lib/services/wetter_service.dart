import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/wetter_daten.dart';

class WetterService {
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';
  static const String _apiKey =
      '346932534a7b64618179d9fbb159cb81'; // TODO: API Key hinzufügen

  // Singleton Pattern
  static final WetterService _instance = WetterService._internal();
  factory WetterService() => _instance;
  WetterService._internal();

  /// Aktuelles Wetter für gegebene Koordinaten abrufen
  static Future<WetterDaten?> getAktuellesWetter(double lat, double lon) async {
    // Prüfe zuerst ob API-Key gültig ist
    if (!await _isApiKeyValid()) {
      print(
          '⚠️ API-Key ungültig oder noch nicht aktiviert - verwende Demo-Daten');
      return getDemoWetter();
    }

    try {
      final url = Uri.parse(
          '$_baseUrl/weather?lat=$lat&lon=$lon&appid=$_apiKey&units=metric&lang=de');

      final response = await http.get(url).timeout(
        Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout beim Abrufen der Wetterdaten');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseWetterDaten(data);
      } else if (response.statusCode == 401) {
        print('⚠️ API-Key ungültig - verwende Demo-Daten');
        return getDemoWetter();
      } else if (response.statusCode == 404) {
        throw Exception('Standort nicht gefunden');
      } else {
        final errorBody = response.body.isNotEmpty
            ? response.body
            : 'Keine Details verfügbar';
        throw Exception(
            'Fehler beim Abrufen der Wetterdaten: ${response.statusCode} - $errorBody');
      }
    } on SocketException {
      print('⚠️ Keine Internetverbindung - verwende Demo-Daten');
      return getDemoWetter();
    } catch (e) {
      print('⚠️ Wetter-API Fehler: $e - verwende Demo-Daten');
      return getDemoWetter();
    }
  }

  /// Prüft ob der API-Key gültig ist (mit Caching)
  static bool? _apiKeyValidCache;
  static DateTime? _lastApiKeyCheck;

  static Future<bool> _isApiKeyValid() async {
    // Cache für 1 Stunde
    if (_apiKeyValidCache != null &&
        _lastApiKeyCheck != null &&
        DateTime.now().difference(_lastApiKeyCheck!).inHours < 1) {
      return _apiKeyValidCache!;
    }

    try {
      final testUrl = Uri.parse(
          '$_baseUrl/weather?lat=52.52&lon=13.405&appid=$_apiKey&units=metric');

      final response = await http.get(testUrl).timeout(Duration(seconds: 5));

      _apiKeyValidCache = response.statusCode == 200;
      _lastApiKeyCheck = DateTime.now();

      if (!_apiKeyValidCache!) {
        print('🔍 API-Key Test: Status ${response.statusCode}');
        if (response.statusCode == 401) {
          print(
              '💡 Tipp: Neue API-Keys brauchen bis zu 2 Stunden um aktiv zu werden');
        }
      }

      return _apiKeyValidCache!;
    } catch (e) {
      print('🔍 API-Key Test Fehler: $e');
      _apiKeyValidCache = false;
      _lastApiKeyCheck = DateTime.now();
      return false;
    }
  }

  /// Wetter-Vorhersage für die nächsten Stunden abrufen
  static Future<List<WetterDaten>> getWetterVorhersage(double lat, double lon,
      {int stunden = 12}) async {
    try {
      final url = Uri.parse(
          '$_baseUrl/forecast?lat=$lat&lon=$lon&appid=$_apiKey&units=metric&lang=de&cnt=${(stunden / 3).ceil()}');

      final response = await http.get(url).timeout(
        Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Timeout beim Abrufen der Wettervorhersage');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> list = data['list'] ?? [];

        return list
            .map((item) => _parseWetterDaten(item, data['city']))
            .toList();
      } else {
        throw Exception(
            'Fehler beim Abrufen der Wettervorhersage: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Keine Internetverbindung');
    } catch (e) {
      print('Fehler beim Abrufen der Wettervorhersage: $e');
      return [];
    }
  }

  /// Wetterdaten aus OpenWeatherMap API Response parsen
  static WetterDaten _parseWetterDaten(Map<String, dynamic> data,
      [Map<String, dynamic>? cityData]) {
    final main = data['main'] ?? {};
    final weather = (data['weather'] as List?)?.first ?? {};
    final wind = data['wind'] ?? {};

    // Zeitstempel - entweder aus 'dt' oder aktuell
    DateTime zeitstempel;
    if (data['dt'] != null) {
      zeitstempel = DateTime.fromMillisecondsSinceEpoch(data['dt'] * 1000);
    } else {
      zeitstempel = DateTime.now();
    }

    // Ortsname bestimmen
    String? ort;
    if (data['name'] != null && data['name'].toString().isNotEmpty) {
      ort = data['name'];
    } else if (cityData != null && cityData['name'] != null) {
      ort = cityData['name'];
    }

    return WetterDaten(
      temperatur: (main['temp'] ?? 0.0).toDouble(),
      beschreibung: weather['description'] ?? 'Unbekannt',
      hauptKategorie: weather['main'] ?? 'Unknown',
      icon: weather['icon'] ?? '01d',
      luftfeuchtigkeit: (main['humidity'] ?? 0.0).toDouble(),
      windgeschwindigkeit:
          ((wind['speed'] ?? 0.0).toDouble() * 3.6), // m/s zu km/h
      windrichtung: (wind['deg'] ?? 0.0).toDouble(),
      luftdruck: (main['pressure'] ?? 0.0).toDouble(),
      gefuehlteTemperatur:
          (main['feels_like'] ?? main['temp'] ?? 0.0).toDouble(),
      zeitstempel: zeitstempel,
      ort: ort,
    );
  }

  /// Prüft ob der API-Key konfiguriert ist
  static bool get isConfigured =>
      _apiKey != 'YOUR_API_KEY_HERE' && _apiKey.isNotEmpty;

  /// Wetter-Warnung basierend auf Bedingungen
  static String? getWetterWarnung(WetterDaten wetter) {
    // Extreme Temperaturen
    if (wetter.temperatur < -10) {
      return 'Achtung: Sehr kalte Temperaturen (${wetter.formatierteTemperatur})';
    }
    if (wetter.temperatur > 35) {
      return 'Achtung: Sehr heiße Temperaturen (${wetter.formatierteTemperatur})';
    }

    // Starker Wind
    if (wetter.windgeschwindigkeit > 50) {
      return 'Achtung: Starker Wind (${wetter.formatierteWindgeschwindigkeit})';
    }

    // Unwetter
    if (wetter.hauptKategorie.toLowerCase() == 'thunderstorm') {
      return 'Warnung: Gewitter in der Gegend';
    }

    // Starker Regen
    if (wetter.hauptKategorie.toLowerCase() == 'rain' &&
        wetter.beschreibung.contains('heavy')) {
      return 'Achtung: Starker Regen erwartet';
    }

    return null;
  }

  /// Demo-Wetterdaten für Tests (wenn kein API-Key vorhanden)
  static WetterDaten getDemoWetter() {
    return WetterDaten(
      temperatur: 18.5,
      beschreibung: 'Leicht bewölkt (Demo)',
      hauptKategorie: 'Clouds',
      icon: '02d',
      luftfeuchtigkeit: 65.0,
      windgeschwindigkeit: 12.0,
      windrichtung: 180.0,
      luftdruck: 1013.0,
      gefuehlteTemperatur: 19.0,
      zeitstempel: DateTime.now(),
      ort: 'Demo-Daten',
    );
  }

  /// Test-Funktion für API-Key Validierung
  static Future<bool> testApiKey() async {
    try {
      print('Testing API Key: $_apiKey');

      // Test mit festen Koordinaten (Berlin)
      final testUrl = Uri.parse(
          '$_baseUrl/weather?lat=52.52&lon=13.405&appid=$_apiKey&units=metric&lang=de');

      print('Test URL: $testUrl');

      final response = await http.get(testUrl).timeout(Duration(seconds: 10));

      print('Test Response Status: ${response.statusCode}');
      print('Test Response Body: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ API-Key ist gültig!');
        return true;
      } else {
        print('❌ API-Key Test fehlgeschlagen: ${response.statusCode}');
        if (response.statusCode == 401) {
          final errorData = json.decode(response.body);
          print('Fehlerdetails: ${errorData['message']}');
        }
        return false;
      }
    } catch (e) {
      print('❌ API-Key Test Fehler: $e');
      return false;
    }
  }
}

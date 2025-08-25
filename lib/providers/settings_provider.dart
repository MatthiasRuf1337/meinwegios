import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_settings.dart';
import '../models/zitat.dart';
import '../services/zitat_service.dart';
import '../services/database_service.dart';

class SettingsProvider with ChangeNotifier {
  AppSettings _settings = AppSettings();
  bool _isLoading = true;
  Function? _onExampleStageCreated;

  AppSettings get settings => _settings;
  bool get isLoading => _isLoading;
  bool get isFirstAppUsage => _settings.ersteAppNutzung;
  bool get isOnboardingCompleted => _settings.onboardingAbgeschlossen;
  String get mediathekPIN => _settings.mediathekPIN;
  bool get isBeispielEtappeGeloescht => _settings.beispielEtappeGeloescht;

  SettingsProvider() {
    _loadSettings();
  }

  // Callback setzen für wenn Beispiel-Etappe erstellt wurde
  void setOnExampleStageCreatedCallback(Function callback) {
    _onExampleStageCreated = callback;
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      _settings = AppSettings(
        ersteAppNutzung: prefs.getBool('ersteAppNutzung') ?? true,
        mediathekPIN: prefs.getString('mediathekPIN') ?? 'WEG.jetzt=42',
        onboardingAbgeschlossen:
            prefs.getBool('onboardingAbgeschlossen') ?? false,
        letzteMediathekAnmeldung:
            prefs.getInt('letzteMediathekAnmeldung') != null
                ? DateTime.fromMillisecondsSinceEpoch(
                    prefs.getInt('letzteMediathekAnmeldung')!)
                : null,
        aktuellerZitatIndex: prefs.getInt('aktuellerZitatIndex') ?? 0,
        letztesZitatDatum: prefs.getInt('letztesZitatDatum') != null
            ? DateTime.fromMillisecondsSinceEpoch(
                prefs.getInt('letztesZitatDatum')!)
            : null,
        beispielEtappeGeloescht:
            prefs.getBool('beispielEtappeGeloescht') ?? false,
      );

      _isLoading = false;
      notifyListeners();

      // Beispiel-Etappe erstellen (nur wenn nicht gelöscht)
      _createExampleStageIfNeeded();
    } catch (e) {
      print('Fehler beim Laden der Einstellungen: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  // Hilfsmethode um Beispiel-Etappe zu erstellen
  Future<void> _createExampleStageIfNeeded() async {
    print(
        'SettingsProvider: Prüfe Beispiel-Etappe - beispielEtappeGeloescht: ${_settings.beispielEtappeGeloescht}');
    await DatabaseService.instance.createExampleStageIfNeeded(
      isBeispielEtappeGeloescht: _settings.beispielEtappeGeloescht,
    );

    // Callback aufrufen um EtappenProvider zu benachrichtigen
    if (_onExampleStageCreated != null) {
      _onExampleStageCreated!();
    }
  }

  Future<void> setFirstAppUsage(bool value) async {
    _settings = _settings.copyWith(ersteAppNutzung: value);
    await _saveSettings();
  }

  Future<void> setOnboardingCompleted(bool value) async {
    _settings = _settings.copyWith(onboardingAbgeschlossen: value);
    await _saveSettings();
  }

  Future<void> setMediathekPIN(String pin) async {
    _settings = _settings.copyWith(mediathekPIN: pin);
    await _saveSettings();
  }

  Future<void> setLastMediathekLogin(DateTime? dateTime) async {
    _settings = _settings.copyWith(letzteMediathekAnmeldung: dateTime);
    await _saveSettings();
  }

  Future<void> setZitatIndex(int index) async {
    _settings = _settings.copyWith(aktuellerZitatIndex: index);
    await _saveSettings();
  }

  Future<void> setLetztesZitatDatum(DateTime dateTime) async {
    _settings = _settings.copyWith(letztesZitatDatum: dateTime);
    await _saveSettings();
  }

  Future<void> setBeispielEtappeGeloescht(bool value) async {
    _settings = _settings.copyWith(beispielEtappeGeloescht: value);
    await _saveSettings();
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setBool('ersteAppNutzung', _settings.ersteAppNutzung);
      await prefs.setString('mediathekPIN', _settings.mediathekPIN);
      await prefs.setBool(
          'onboardingAbgeschlossen', _settings.onboardingAbgeschlossen);
      await prefs.setInt('aktuellerZitatIndex', _settings.aktuellerZitatIndex);
      await prefs.setBool(
          'beispielEtappeGeloescht', _settings.beispielEtappeGeloescht);

      if (_settings.letzteMediathekAnmeldung != null) {
        await prefs.setInt('letzteMediathekAnmeldung',
            _settings.letzteMediathekAnmeldung!.millisecondsSinceEpoch);
      } else {
        await prefs.remove('letzteMediathekAnmeldung');
      }

      if (_settings.letztesZitatDatum != null) {
        await prefs.setInt('letztesZitatDatum',
            _settings.letztesZitatDatum!.millisecondsSinceEpoch);
      } else {
        await prefs.remove('letztesZitatDatum');
      }

      notifyListeners();
    } catch (e) {
      print('Fehler beim Speichern der Einstellungen: $e');
    }
  }

  bool validateMediathekPIN(String enteredPIN) {
    return enteredPIN == _settings.mediathekPIN;
  }

  bool get isMediathekSessionValid {
    if (_settings.letzteMediathekAnmeldung == null) {
      return false;
    }

    // Session ist 30 Minuten gültig
    final sessionDuration = Duration(minutes: 30);
    final now = DateTime.now();
    final sessionEnd = _settings.letzteMediathekAnmeldung!.add(sessionDuration);

    return now.isBefore(sessionEnd);
  }

  Future<void> logoutMediathek() async {
    await setLastMediathekLogin(null);
  }

  // Zitat-Funktionalität
  bool shouldShowZitat() {
    // Kein Zitat während des Onboardings oder bei erster App-Nutzung
    if (_settings.ersteAppNutzung || !_settings.onboardingAbgeschlossen) {
      return false;
    }

    final now = DateTime.now();
    final heute = DateTime(now.year, now.month, now.day);

    // Wenn noch nie ein Zitat gezeigt wurde (nach Onboarding), zeige eins
    if (_settings.letztesZitatDatum == null) {
      return true;
    }

    final letztesZitat = DateTime(
      _settings.letztesZitatDatum!.year,
      _settings.letztesZitatDatum!.month,
      _settings.letztesZitatDatum!.day,
    );

    // Zeige Zitat, wenn es ein neuer Tag ist
    return heute.isAfter(letztesZitat);
  }

  Future<Zitat> getHeutigesZitat() async {
    final zitat =
        await ZitatService.getZitatByIndex(_settings.aktuellerZitatIndex);

    print('Zitat geladen: "${zitat.text}" - ${zitat.autor}');
    print('Aktueller Zitat-Index: ${_settings.aktuellerZitatIndex}');

    return zitat;
  }

  Future<void> markZitatAsShown() async {
    // Zitat-Index für nächstes Mal erhöhen
    final nextIndex =
        ZitatService.getNextZitatIndex(_settings.aktuellerZitatIndex);
    await setZitatIndex(nextIndex);

    // Speichere nur das Datum (ohne Zeit) für konsistente Vergleiche
    final heute = DateTime.now();
    final heuteOhneZeit = DateTime(heute.year, heute.month, heute.day);
    await setLetztesZitatDatum(heuteOhneZeit);

    print('Zitat als angezeigt markiert');
    print('Neuer Zitat-Index: $nextIndex');
    print('Zitat-Datum gespeichert: $heuteOhneZeit');
  }

  // Debug-Funktionen
  Future<void> resetZitatDatum() async {
    _settings = _settings.copyWith(letztesZitatDatum: null);
    await _saveSettings();
    print('Zitat-Datum zurückgesetzt');
  }

  Future<void> forceShowZitat() async {
    // Setze das letzte Zitat-Datum auf gestern
    final gestern = DateTime.now().subtract(Duration(days: 1));
    await setLetztesZitatDatum(gestern);
    print('Zitat wird beim nächsten App-Start angezeigt');
  }
}

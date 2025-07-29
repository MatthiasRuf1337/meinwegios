import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_settings.dart';

class SettingsProvider with ChangeNotifier {
  AppSettings _settings = AppSettings();
  bool _isLoading = true;

  AppSettings get settings => _settings;
  bool get isLoading => _isLoading;
  bool get isFirstAppUsage => _settings.ersteAppNutzung;
  bool get isOnboardingCompleted => _settings.onboardingAbgeschlossen;
  String get mediathekPIN => _settings.mediathekPIN;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      _settings = AppSettings(
        ersteAppNutzung: prefs.getBool('ersteAppNutzung') ?? true,
        mediathekPIN: prefs.getString('mediathekPIN') ?? '1234',
        onboardingAbgeschlossen: prefs.getBool('onboardingAbgeschlossen') ?? false,
        letzteMediathekAnmeldung: prefs.getInt('letzteMediathekAnmeldung') != null
            ? DateTime.fromMillisecondsSinceEpoch(prefs.getInt('letzteMediathekAnmeldung')!)
            : null,
      );
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Fehler beim Laden der Einstellungen: $e');
      _isLoading = false;
      notifyListeners();
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

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setBool('ersteAppNutzung', _settings.ersteAppNutzung);
      await prefs.setString('mediathekPIN', _settings.mediathekPIN);
      await prefs.setBool('onboardingAbgeschlossen', _settings.onboardingAbgeschlossen);
      
      if (_settings.letzteMediathekAnmeldung != null) {
        await prefs.setInt('letzteMediathekAnmeldung', 
            _settings.letzteMediathekAnmeldung!.millisecondsSinceEpoch);
      } else {
        await prefs.remove('letzteMediathekAnmeldung');
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
} 
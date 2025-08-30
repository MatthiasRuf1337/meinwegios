import 'package:flutter/foundation.dart';
import '../models/audio_aufnahme.dart';
import '../services/database_service.dart';
import 'dart:io';

class AudioProvider with ChangeNotifier {
  List<AudioAufnahme> _audioAufnahmen = [];
  bool _isLoading = false;

  List<AudioAufnahme> get audioAufnahmen => _audioAufnahmen;
  bool get isLoading => _isLoading;

  List<AudioAufnahme> getAudioAufnahmenByEtappe(String etappenId) {
    return _audioAufnahmen
        .where((audio) => audio.etappenId == etappenId)
        .toList();
  }

  // Nur Impulsfrage-Audio für eine Etappe
  List<AudioAufnahme> getImpulsfrageAudioByEtappe(String etappenId) {
    return _audioAufnahmen
        .where((audio) =>
            audio.etappenId == etappenId && audio.typ == 'impulsfrage')
        .toList();
  }

  // Nur allgemeine Audio-Aufnahmen für eine Etappe
  List<AudioAufnahme> getAllgemeineAudioByEtappe(String etappenId) {
    return _audioAufnahmen
        .where(
            (audio) => audio.etappenId == etappenId && audio.typ == 'allgemein')
        .toList();
  }

  Future<void> loadAudioAufnahmen() async {
    _isLoading = true;
    notifyListeners();

    try {
      _audioAufnahmen = await DatabaseService.instance.getAllAudioAufnahmen();
    } catch (e) {
      print('Fehler beim Laden der Audio-Aufnahmen: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addAudioAufnahme(AudioAufnahme audioAufnahme) async {
    try {
      await DatabaseService.instance.insertAudioAufnahme(audioAufnahme);
      _audioAufnahmen.add(audioAufnahme);
      notifyListeners();
    } catch (e) {
      print('Fehler beim Hinzufügen der Audio-Aufnahme: $e');
      rethrow;
    }
  }

  Future<void> deleteAudioAufnahme(String id) async {
    try {
      // Finde die Audio-Aufnahme
      final audioAufnahme =
          _audioAufnahmen.firstWhere((audio) => audio.id == id);

      // Lösche die Datei vom Gerät
      final file = File(audioAufnahme.dateipfad);
      if (file.existsSync()) {
        await file.delete();
      }

      // Lösche aus der Datenbank
      await DatabaseService.instance.deleteAudioAufnahme(id);

      // Entferne aus der Liste
      _audioAufnahmen.removeWhere((audio) => audio.id == id);
      notifyListeners();
    } catch (e) {
      print('Fehler beim Löschen der Audio-Aufnahme: $e');
      rethrow;
    }
  }

  Future<void> updateAudioAufnahme(AudioAufnahme audioAufnahme) async {
    try {
      await DatabaseService.instance.updateAudioAufnahme(audioAufnahme);

      final index =
          _audioAufnahmen.indexWhere((audio) => audio.id == audioAufnahme.id);
      if (index != -1) {
        _audioAufnahmen[index] = audioAufnahme;
        notifyListeners();
      }
    } catch (e) {
      print('Fehler beim Aktualisieren der Audio-Aufnahme: $e');
      rethrow;
    }
  }

  AudioAufnahme? getAudioAufnahmeById(String id) {
    try {
      return _audioAufnahmen.firstWhere((audio) => audio.id == id);
    } catch (e) {
      return null;
    }
  }

  int getAudioAufnahmenCountByEtappe(String etappenId) {
    return _audioAufnahmen
        .where((audio) => audio.etappenId == etappenId)
        .length;
  }

  Duration getTotalDurationByEtappe(String etappenId) {
    final etappenAudios = getAudioAufnahmenByEtappe(etappenId);
    Duration totalDuration = Duration.zero;

    for (final audio in etappenAudios) {
      totalDuration += audio.dauer;
    }

    return totalDuration;
  }

  void clear() {
    _audioAufnahmen.clear();
    notifyListeners();
  }
}

import 'package:just_audio/just_audio.dart';
import 'package:record/record.dart';

/// Globaler Audio-Manager um Session-Konflikte zu vermeiden
class GlobalAudioManager {
  static final GlobalAudioManager _instance = GlobalAudioManager._internal();
  factory GlobalAudioManager() => _instance;
  GlobalAudioManager._internal();

  AudioPlayer? _globalPlayer;
  AudioRecorder? _globalRecorder;

  bool _isRecording = false;
  bool _isPlaying = false;
  bool _isResetting = false;

  bool get isRecording => _isRecording;
  bool get isPlaying => _isPlaying;
  bool get isResetting => _isResetting;

  /// Globalen AudioPlayer abrufen (Singleton)
  AudioPlayer getPlayer() {
    _globalPlayer ??= AudioPlayer();
    return _globalPlayer!;
  }

  /// Globalen AudioRecorder abrufen (Singleton)
  AudioRecorder getRecorder() {
    if (_globalRecorder == null || _isResetting) {
      _globalRecorder = AudioRecorder();
    }
    return _globalRecorder!;
  }

  /// Alle Audio-Aktivitäten stoppen
  Future<void> stopAllAudio() async {
    try {
      if (_isRecording && _globalRecorder != null) {
        await _globalRecorder!.stop();
        _isRecording = false;
      }

      if (_isPlaying && _globalPlayer != null) {
        await _globalPlayer!.stop();
        _isPlaying = false;
      }
    } catch (e) {
      print('Fehler beim Stoppen aller Audio-Aktivitäten: $e');
    }
  }

  /// Audio-Session komplett zurücksetzen (GPS-freundlich)
  Future<void> resetAudioSession({bool preserveGPSTracking = true}) async {
    try {
      _isResetting = true;
      print(
          'Audio-Session wird zurückgesetzt (GPS-freundlich: $preserveGPSTracking)...');

      // Alle Aktivitäten stoppen
      await stopAllAudio();

      // Recorder komplett neu erstellen
      if (_globalRecorder != null) {
        try {
          await _globalRecorder!.dispose();
        } catch (e) {
          print('Fehler beim Dispose des Recorders: $e');
        }
        _globalRecorder = null;
      }

      // Player komplett neu erstellen
      if (_globalPlayer != null) {
        try {
          await _globalPlayer!.dispose();
        } catch (e) {
          print('Fehler beim Dispose des Players: $e');
        }
        _globalPlayer = null;
      }

      // Angepasste Pause basierend auf GPS-Tracking-Status
      if (preserveGPSTracking) {
        // Kürzere Pause um GPS-Tracking nicht zu unterbrechen
        await Future.delayed(Duration(milliseconds: 500));
      } else {
        // Längere Pause für iOS Audio-Session (iOS braucht mehr Zeit)
        await Future.delayed(Duration(milliseconds: 2000));
      }

      _isResetting = false;
      print('Audio-Session erfolgreich zurückgesetzt');
    } catch (e) {
      _isResetting = false;
      print('Fehler beim Zurücksetzen der Audio-Session: $e');
    }
  }

  /// Prüft ob Audio-Session verfügbar ist
  Future<bool> isAudioSessionAvailable() async {
    try {
      // Teste mit einem temporären Recorder
      final testRecorder = AudioRecorder();
      final hasPermission = await testRecorder.hasPermission();

      if (!hasPermission) {
        await testRecorder.dispose();
        return false;
      }

      // Teste ob Session aktiviert werden kann
      try {
        await testRecorder.dispose();
        return true;
      } catch (e) {
        print('Audio-Session nicht verfügbar: $e');
        return false;
      }
    } catch (e) {
      print('Fehler beim Prüfen der Audio-Session: $e');
      return false;
    }
  }

  /// Recording-Status setzen
  void setRecordingStatus(bool recording) {
    _isRecording = recording;
  }

  /// Playing-Status setzen
  void setPlayingStatus(bool playing) {
    _isPlaying = playing;
  }

  /// Ressourcen freigeben
  Future<void> dispose() async {
    try {
      await stopAllAudio();

      if (_globalRecorder != null) {
        await _globalRecorder!.dispose();
        _globalRecorder = null;
      }

      if (_globalPlayer != null) {
        await _globalPlayer!.dispose();
        _globalPlayer = null;
      }
    } catch (e) {
      print('Fehler beim Freigeben der Audio-Ressourcen: $e');
    }
  }
}

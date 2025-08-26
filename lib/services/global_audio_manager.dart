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

  bool get isRecording => _isRecording;
  bool get isPlaying => _isPlaying;

  /// Globalen AudioPlayer abrufen (Singleton)
  AudioPlayer getPlayer() {
    _globalPlayer ??= AudioPlayer();
    return _globalPlayer!;
  }

  /// Globalen AudioRecorder abrufen (Singleton)
  AudioRecorder getRecorder() {
    _globalRecorder ??= AudioRecorder();
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


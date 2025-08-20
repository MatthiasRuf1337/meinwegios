import 'dart:io';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/audio_aufnahme.dart';
import '../services/permission_service.dart';

class AudioRecordingService {
  static final AudioRecordingService _instance =
      AudioRecordingService._internal();
  factory AudioRecordingService() => _instance;
  AudioRecordingService._internal();

  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();

  bool _isRecording = false;
  bool _isPlaying = false;
  String? _currentRecordingPath;
  DateTime? _recordingStartTime;

  bool get isRecording => _isRecording;
  bool get isPlaying => _isPlaying;

  // Aufnahme starten
  Future<bool> startRecording() async {
    try {
      // Prüfen ob bereits aufgenommen wird
      if (_isRecording) {
        throw Exception('Aufnahme läuft bereits');
      }

      // Mikrofon-Berechtigung prüfen
      final hasPermission =
          await PermissionService.requestMicrophonePermission();
      if (!hasPermission) {
        throw Exception('Mikrofon-Berechtigung verweigert');
      }

      // Prüfen ob der Recorder die Berechtigung hat
      final hasRecordPermission = await _recorder.hasPermission();
      if (!hasRecordPermission) {
        throw Exception('Record-Package hat keine Mikrofon-Berechtigung');
      }

      // Aufnahme-Pfad erstellen
      final directory = await getApplicationDocumentsDirectory();
      final audioDir = Directory(p.join(directory.path, 'audio'));
      if (!audioDir.existsSync()) {
        await audioDir.create(recursive: true);
      }

      final fileName = 'audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
      final filePath = p.join(audioDir.path, fileName);

      // Kurze Verzögerung vor dem Start
      await Future.delayed(Duration(milliseconds: 200));

      // Aufnahme mit minimaler Konfiguration starten
      await _recorder.start(
        const RecordConfig(),
        path: filePath,
      );

      _currentRecordingPath = filePath;

      _isRecording = true;
      _recordingStartTime = DateTime.now();

      return true;
    } catch (e) {
      print('Fehler beim Starten der Aufnahme: $e');
      print('Fehler-Typ: ${e.runtimeType}');
      if (e is Exception) {
        print('Exception Details: ${e.toString()}');
      }
      return false;
    }
  }

  // Aufnahme stoppen
  Future<AudioAufnahme?> stopRecording(String etappenId) async {
    try {
      if (!_isRecording ||
          _currentRecordingPath == null ||
          _recordingStartTime == null) {
        throw Exception('Keine aktive Aufnahme');
      }

      // Aufnahme stoppen
      await _recorder.stop();
      _isRecording = false;

      // Audio Session wird automatisch verwaltet

      // Dauer berechnen
      final duration = DateTime.now().difference(_recordingStartTime!);

      // Prüfen ob Datei existiert
      final file = File(_currentRecordingPath!);
      if (!file.existsSync()) {
        throw Exception('Aufnahme-Datei nicht gefunden');
      }

      // AudioAufnahme-Objekt erstellen
      final audioAufnahme = AudioAufnahme(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        dateiname: p.basename(_currentRecordingPath!),
        dateipfad: _currentRecordingPath!,
        aufnahmeZeit: _recordingStartTime!,
        dauer: duration,
        etappenId: etappenId,
        metadaten: {
          'encoder': 'default',
          'bitRate': 'default',
          'sampleRate': 'default',
        },
      );

      // Reset
      _currentRecordingPath = null;
      _recordingStartTime = null;

      return audioAufnahme;
    } catch (e) {
      print('Fehler beim Stoppen der Aufnahme: $e');
      _isRecording = false;
      _currentRecordingPath = null;
      _recordingStartTime = null;
      return null;
    }
  }

  // Aufnahme abbrechen
  Future<void> cancelRecording() async {
    try {
      if (_isRecording) {
        await _recorder.stop();
        _isRecording = false;
      }

      // Audio Session wird automatisch verwaltet

      // Temporäre Datei löschen
      if (_currentRecordingPath != null) {
        final file = File(_currentRecordingPath!);
        if (file.existsSync()) {
          await file.delete();
        }
        _currentRecordingPath = null;
      }

      _recordingStartTime = null;
    } catch (e) {
      print('Fehler beim Abbrechen der Aufnahme: $e');
    }
  }

  // Audio abspielen
  Future<bool> playAudio(String filePath) async {
    try {
      if (_isPlaying) {
        await stopPlayback();
      }

      // Audio Session wird automatisch von just_audio verwaltet

      await _player.setFilePath(filePath);
      await _player.play();
      _isPlaying = true;

      // Listener für Ende der Wiedergabe
      _player.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          _isPlaying = false;
        }
      });

      return true;
    } catch (e) {
      print('Fehler beim Abspielen der Audio-Datei: $e');
      return false;
    }
  }

  // Wiedergabe stoppen
  Future<void> stopPlayback() async {
    try {
      await _player.stop();
      _isPlaying = false;
    } catch (e) {
      print('Fehler beim Stoppen der Wiedergabe: $e');
    }
  }

  // Wiedergabe pausieren
  Future<void> pausePlayback() async {
    try {
      await _player.pause();
      _isPlaying = false;
    } catch (e) {
      print('Fehler beim Pausieren der Wiedergabe: $e');
    }
  }

  // Aktuelle Wiedergabe-Position
  Duration get currentPosition => _player.position;

  // Gesamtdauer der aktuellen Audio-Datei
  Duration? get duration => _player.duration;

  // Stream für Wiedergabe-Position
  Stream<Duration> get positionStream => _player.positionStream;

  // Stream für Player-Status
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  // Aufnahme-Dauer (während der Aufnahme)
  Duration get recordingDuration {
    if (_recordingStartTime != null && _isRecording) {
      return DateTime.now().difference(_recordingStartTime!);
    }
    return Duration.zero;
  }

  // Ressourcen freigeben
  Future<void> dispose() async {
    try {
      if (_isRecording) {
        await cancelRecording();
      }
      if (_isPlaying) {
        await stopPlayback();
      }
      await _recorder.dispose();
      await _player.dispose();
    } catch (e) {
      print('Fehler beim Freigeben der Audio-Ressourcen: $e');
    }
  }

  // Audio-Datei löschen
  Future<bool> deleteAudioFile(String filePath) async {
    try {
      final file = File(filePath);
      if (file.existsSync()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('Fehler beim Löschen der Audio-Datei: $e');
      return false;
    }
  }

  // Prüfen ob Audio-Datei existiert
  bool audioFileExists(String filePath) {
    try {
      return File(filePath).existsSync();
    } catch (e) {
      return false;
    }
  }
}

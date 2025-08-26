import 'dart:io';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/audio_aufnahme.dart';
import '../services/permission_service.dart';
import '../services/global_audio_manager.dart';

class AudioRecordingService {
  static final AudioRecordingService _instance =
      AudioRecordingService._internal();
  factory AudioRecordingService() => _instance;
  AudioRecordingService._internal();

  final GlobalAudioManager _audioManager = GlobalAudioManager();

  String? _currentRecordingPath;
  DateTime? _recordingStartTime;

  bool get isRecording => _audioManager.isRecording;
  bool get isPlaying => _audioManager.isPlaying;

  // Aufnahme starten
  Future<bool> startRecording() async {
    try {
      // Prüfen ob bereits aufgenommen wird
      if (_audioManager.isRecording) {
        throw Exception('Aufnahme läuft bereits');
      }

      // Alle Audio-Aktivitäten stoppen
      await _audioManager.stopAllAudio();

      // Mikrofon-Berechtigung prüfen
      final hasPermission =
          await PermissionService.requestMicrophonePermission();
      if (!hasPermission) {
        throw Exception('Mikrofon-Berechtigung verweigert');
      }

      // Prüfen ob der Recorder die Berechtigung hat
      final recorder = _audioManager.getRecorder();
      final hasRecordPermission = await recorder.hasPermission();
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

      // Aufnahme mit Standard-Konfiguration starten
      await recorder.start(
        const RecordConfig(),
        path: filePath,
      );

      _currentRecordingPath = filePath;
      _audioManager.setRecordingStatus(true);
      _recordingStartTime = DateTime.now();

      return true;
    } catch (e) {
      print('Fehler beim Starten der Aufnahme: $e');
      print('Fehler-Typ: ${e.runtimeType}');
      if (e is Exception) {
        print('Exception Details: ${e.toString()}');
      }

      // Cleanup bei Fehler
      _audioManager.setRecordingStatus(false);
      _currentRecordingPath = null;
      _recordingStartTime = null;

      // Zusätzliche Informationen bei Session-Fehlern
      if (e.toString().contains('setActive') ||
          e.toString().contains('Session activation failed')) {
        print(
            'Audio-Session-Konflikt erkannt. Versuche es in ein paar Sekunden erneut.');
      }

      return false;
    }
  }

  // Aufnahme stoppen
  Future<AudioAufnahme?> stopRecording(String etappenId) async {
    try {
      if (!_audioManager.isRecording ||
          _currentRecordingPath == null ||
          _recordingStartTime == null) {
        throw Exception('Keine aktive Aufnahme');
      }

      // Aufnahme stoppen
      final recorder = _audioManager.getRecorder();
      await recorder.stop();
      _audioManager.setRecordingStatus(false);

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
      _audioManager.setRecordingStatus(false);
      _currentRecordingPath = null;
      _recordingStartTime = null;
      return null;
    }
  }

  // Aufnahme abbrechen
  Future<void> cancelRecording() async {
    try {
      if (_audioManager.isRecording) {
        await _audioManager.getRecorder().stop();
        _audioManager.setRecordingStatus(false);
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
      if (_audioManager.isPlaying) {
        await stopPlayback();
      }

      // Aufnahme stoppen falls aktiv
      if (_audioManager.isRecording) {
        await cancelRecording();
      }

      final player = _audioManager.getPlayer();
      await player.setFilePath(filePath);
      await player.play();
      _audioManager.setPlayingStatus(true);

      // Listener für Ende der Wiedergabe
      player.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          _audioManager.setPlayingStatus(false);
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
      await _audioManager.getPlayer().stop();
      _audioManager.setPlayingStatus(false);
    } catch (e) {
      print('Fehler beim Stoppen der Wiedergabe: $e');
    }
  }

  // Wiedergabe pausieren
  Future<void> pausePlayback() async {
    try {
      await _audioManager.getPlayer().pause();
      _audioManager.setPlayingStatus(false);
    } catch (e) {
      print('Fehler beim Pausieren der Wiedergabe: $e');
    }
  }

  // Aktuelle Wiedergabe-Position
  Duration get currentPosition => _audioManager.getPlayer().position;

  // Gesamtdauer der aktuellen Audio-Datei
  Duration? get duration => _audioManager.getPlayer().duration;

  // Stream für Wiedergabe-Position
  Stream<Duration> get positionStream =>
      _audioManager.getPlayer().positionStream;

  // Stream für Player-Status
  Stream<PlayerState> get playerStateStream =>
      _audioManager.getPlayer().playerStateStream;

  // Aufnahme-Dauer (während der Aufnahme)
  Duration get recordingDuration {
    if (_recordingStartTime != null && _audioManager.isRecording) {
      return DateTime.now().difference(_recordingStartTime!);
    }
    return Duration.zero;
  }

  // Audio-Service komplett zurücksetzen
  Future<void> resetAudioService() async {
    try {
      print('Audio-Service wird zurückgesetzt...');

      await _audioManager.stopAllAudio();

      // Kurze Pause
      await Future.delayed(Duration(milliseconds: 500));

      print('Audio-Service erfolgreich zurückgesetzt');
    } catch (e) {
      print('Fehler beim Zurücksetzen des Audio-Services: $e');
    }
  }

  // Ressourcen freigeben
  Future<void> dispose() async {
    try {
      if (_audioManager.isRecording) {
        await cancelRecording();
      }
      if (_audioManager.isPlaying) {
        await stopPlayback();
      }
      await _audioManager.dispose();
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

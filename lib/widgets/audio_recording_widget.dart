import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../models/audio_aufnahme.dart';
import '../providers/audio_provider.dart';
import '../services/audio_recording_service.dart';

class AudioRecordingWidget extends StatefulWidget {
  final String etappenId;

  const AudioRecordingWidget({Key? key, required this.etappenId})
      : super(key: key);

  @override
  _AudioRecordingWidgetState createState() => _AudioRecordingWidgetState();
}

class _AudioRecordingWidgetState extends State<AudioRecordingWidget> {
  final AudioRecordingService _audioService = AudioRecordingService();
  Timer? _recordingTimer;
  Duration _recordingDuration = Duration.zero;
  String? _playingAudioId;

  @override
  void initState() {
    super.initState();
    // Audio-Aufnahmen laden
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AudioProvider>(context, listen: false).loadAudioAufnahmen();
    });
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    super.dispose();
  }

  void _startRecording() async {
    final success = await _audioService.startRecording();
    if (success) {
      setState(() {
        _recordingDuration = Duration.zero;
      });

      _recordingTimer = Timer.periodic(Duration(seconds: 1), (timer) {
        setState(() {
          _recordingDuration = _audioService.recordingDuration;
        });
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Starten der Aufnahme'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _stopRecording() async {
    _recordingTimer?.cancel();

    final audioAufnahme = await _audioService.stopRecording(widget.etappenId);
    if (audioAufnahme != null) {
      final audioProvider = Provider.of<AudioProvider>(context, listen: false);
      await audioProvider.addAudioAufnahme(audioAufnahme);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Aufnahme gespeichert!'),
          backgroundColor: Color(0xFF5A7D7D),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Speichern der Aufnahme'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() {
      _recordingDuration = Duration.zero;
    });
  }

  void _cancelRecording() async {
    _recordingTimer?.cancel();
    await _audioService.cancelRecording();
    setState(() {
      _recordingDuration = Duration.zero;
    });
  }

  void _playAudio(AudioAufnahme audio) async {
    if (_playingAudioId == audio.id) {
      // Audio stoppen
      await _audioService.stopPlayback();
      setState(() {
        _playingAudioId = null;
      });
    } else {
      // Andere Audio stoppen und neue starten
      await _audioService.stopPlayback();
      final success = await _audioService.playAudio(audio.dateipfad);
      if (success) {
        setState(() {
          _playingAudioId = audio.id;
        });

        // Listener für Ende der Wiedergabe
        _audioService.playerStateStream.listen((state) {
          if (state.processingState.name == 'completed') {
            setState(() {
              _playingAudioId = null;
            });
          }
        });
      }
    }
  }

  void _deleteAudio(AudioAufnahme audio) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Audio löschen'),
        content: Text('Möchten Sie diese Audioaufnahme wirklich löschen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Abbrechen'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Löschen'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final audioProvider = Provider.of<AudioProvider>(context, listen: false);
      await audioProvider.deleteAudioAufnahme(audio.id);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Audioaufnahme gelöscht'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioProvider>(
      builder: (context, audioProvider, child) {
        final audioAufnahmen =
            audioProvider.getAudioAufnahmenByEtappe(widget.etappenId);

        return Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Audio-Aufnahmen',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Icon(Icons.mic, color: Color(0xFF5A7D7D)),
                  ],
                ),
                SizedBox(height: 16),

                // Aufnahme-Steuerung
                _buildRecordingControls(),

                SizedBox(height: 16),

                // Liste der Aufnahmen
                if (audioAufnahmen.isEmpty)
                  _buildEmptyState()
                else
                  _buildAudioList(audioAufnahmen),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecordingControls() {
    final isRecording = _audioService.isRecording;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          if (isRecording) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.fiber_manual_record, color: Colors.red, size: 16),
                SizedBox(width: 8),
                Text(
                  'Aufnahme läuft: ${_formatDuration(_recordingDuration)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _cancelRecording,
                  icon: Icon(Icons.cancel),
                  label: Text('Abbrechen'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _stopRecording,
                  icon: Icon(Icons.stop),
                  label: Text('Stoppen'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ] else ...[
            Center(
              child: ElevatedButton.icon(
                onPressed: _startRecording,
                icon: Icon(Icons.mic),
                label: Text('Aufnahme starten'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF5A7D7D),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.mic_none,
            size: 48,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 16),
          Text(
            'Keine Audioaufnahmen vorhanden',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Starten Sie eine Aufnahme, um Audio-Notizen zu erstellen',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAudioList(List<AudioAufnahme> audioAufnahmen) {
    return Column(
      children: audioAufnahmen.map((audio) => _buildAudioTile(audio)).toList(),
    );
  }

  Widget _buildAudioTile(AudioAufnahme audio) {
    final isPlaying = _playingAudioId == audio.id;

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isPlaying ? Color(0xFF5A7D7D).withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isPlaying ? Color(0xFF5A7D7D) : Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          // Play/Pause Button
          IconButton(
            onPressed: () => _playAudio(audio),
            icon: Icon(
              isPlaying ? Icons.pause : Icons.play_arrow,
              color: Color(0xFF5A7D7D),
            ),
          ),

          // Audio Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Aufnahme vom ${audio.aufnahmeZeit.day}.${audio.aufnahmeZeit.month}.${audio.aufnahmeZeit.year}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: Colors.grey),
                    SizedBox(width: 4),
                    Text(
                      audio.formatierteDauer,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(width: 16),
                    Icon(Icons.schedule, size: 16, color: Colors.grey),
                    SizedBox(width: 4),
                    Text(
                      '${audio.aufnahmeZeit.hour.toString().padLeft(2, '0')}:${audio.aufnahmeZeit.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Delete Button
          IconButton(
            onPressed: () => _deleteAudio(audio),
            icon: Icon(Icons.delete, color: Colors.red),
            tooltip: 'Löschen',
          ),
        ],
      ),
    );
  }
}

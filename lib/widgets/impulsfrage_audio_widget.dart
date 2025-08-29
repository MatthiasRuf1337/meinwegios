import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../models/audio_aufnahme.dart';
import '../providers/audio_provider.dart';
import '../services/audio_recording_service.dart';

class ImpulsfrageAudioWidget extends StatefulWidget {
  final String etappenId;

  const ImpulsfrageAudioWidget({
    Key? key,
    required this.etappenId,
  }) : super(key: key);

  @override
  _ImpulsfrageAudioWidgetState createState() => _ImpulsfrageAudioWidgetState();
}

class _ImpulsfrageAudioWidgetState extends State<ImpulsfrageAudioWidget> {
  final AudioRecordingService _audioService = AudioRecordingService();
  Timer? _recordingTimer;
  Duration _recordingDuration = Duration.zero;
  String? _playingAudioId;

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
      // Bei Fehlern Audio-Service zurücksetzen
      await _audioService.resetAudioService();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Fehler beim Starten der Aufnahme. Audio-Service wurde zurückgesetzt.'),
          backgroundColor: Color(0xFF8C0A28),
          action: SnackBarAction(
            label: 'Erneut versuchen',
            onPressed: () => _startRecording(),
          ),
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
          content: Text('Aufnahme zur Impulsfrage gespeichert!'),
          backgroundColor: Color(0xFF8C0A28),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Speichern der Aufnahme'),
          backgroundColor: Color(0xFF8C0A28),
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

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioProvider>(
      builder: (context, audioProvider, child) {
        // Nur die neueste Audio-Aufnahme für diese Etappe anzeigen
        final audioAufnahmen =
            audioProvider.getAudioAufnahmenByEtappe(widget.etappenId);
        final neuesteAufnahme =
            audioAufnahmen.isNotEmpty ? audioAufnahmen.last : null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Aufnahme-Steuerung oder vorhandene Aufnahme
            if (_audioService.isRecording)
              _buildRecordingControls()
            else if (neuesteAufnahme != null)
              _buildExistingAudio(neuesteAufnahme)
            else
              _buildStartRecordingButton(),
          ],
        );
      },
    );
  }

  Widget _buildStartRecordingButton() {
    return Container(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _startRecording,
        icon: Icon(Icons.fiber_manual_record, size: 18),
        label: Text(
          'Audio-Notiz aufnehmen',
          style: TextStyle(fontSize: 14),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF8C0A28),
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Widget _buildRecordingControls() {
    return Column(
      children: [
        // Aufnahme-Status
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 8),
              Text(
                'Aufnahme läuft: ${_formatDuration(_recordingDuration)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 12),

        // Buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _cancelRecording,
                icon: Icon(Icons.cancel, size: 16),
                label: Text('Abbrechen'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey.shade600,
                  side: BorderSide(color: Colors.grey.shade400),
                  padding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _stopRecording,
                icon: Icon(Icons.stop, size: 16),
                label: Text('Speichern'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF8C0A28),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExistingAudio(AudioAufnahme audio) {
    final isPlaying = _playingAudioId == audio.id;

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isPlaying ? Color(0xFF8C0A28).withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Color(0xFF8C0A28).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          // Play/Pause Button
          IconButton(
            onPressed: () => _playAudio(audio),
            icon: Icon(
              isPlaying ? Icons.pause : Icons.play_arrow,
              color: Color(0xFF8C0A28),
            ),
            constraints: BoxConstraints(),
            padding: EdgeInsets.zero,
          ),

          SizedBox(width: 12),

          // Audio Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Audio-Notiz zur Impulsfrage',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                    color: Color(0xFF8C0A28),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Dauer: ${audio.formatierteDauer}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Neue Aufnahme Button
          TextButton.icon(
            onPressed: _startRecording,
            icon: Icon(Icons.add, size: 16),
            label: Text('Neu', style: TextStyle(fontSize: 12)),
            style: TextButton.styleFrom(
              foregroundColor: Color(0xFF8C0A28),
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
          ),
        ],
      ),
    );
  }
}

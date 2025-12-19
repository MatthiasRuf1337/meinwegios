import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../models/audio_aufnahme.dart';
import '../providers/audio_provider.dart';
import '../services/audio_recording_service.dart';
import '../services/permission_service.dart';

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
  StreamSubscription<Duration>? _recordingDurationSubscription;
  Duration _recordingDuration = Duration.zero;
  String? _playingAudioId;

  @override
  void dispose() {
    _recordingDurationSubscription?.cancel();
    super.dispose();
  }

  void _startRecording() async {
    // SOFORT UI-State ändern für besseres Feedback
    setState(() {
      _recordingDuration = Duration.zero;
    });

    // Prüfe zuerst ob Aufnahme möglich ist
    final canRecord = await _audioService.canStartRecording();
    if (!canRecord) {
      // Bei Fehler: UI zurücksetzen
      setState(() {
        _recordingDuration = Duration.zero;
      });

      // Prüfen, ob die Mikrofon-Berechtigung verweigert wurde
      final hasPermission = await PermissionService.checkMicrophonePermission();
      if (!hasPermission) {
        _showMicrophonePermissionDialog();
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Audio-Aufnahme momentan nicht möglich. Bitte schließen Sie andere Audio-Apps und versuchen Sie es erneut.'),
          backgroundColor: Color(0xFF8C0A28),
          action: SnackBarAction(
            label: 'Erneut versuchen',
            textColor: Colors.white,
            onPressed: () => _startRecording(),
          ),
          duration: Duration(seconds: 6),
        ),
      );
      return;
    }

    // Loading-Indikator entfernt

    // Aufnahme im Hintergrund starten (mit Typ 'impulsfrage')
    final success = await _audioService.startRecording(type: 'impulsfrage');

    // Loading-Indikator entfernt

    if (success) {
      // Stream für Aufnahme-Dauer abonnieren (nur für Impulsfrage-Aufnahmen)
      _recordingDurationSubscription = _audioService.recordingDurationStream
          .where((_) => _audioService.isRecordingType('impulsfrage'))
          .listen((duration) {
        if (mounted) {
          setState(() {
            _recordingDuration = duration;
          });
        }
      });

      // Erfolgsmeldung entfernt - keine SnackBar mehr
    } else {
      // Bei Fehler: UI zurücksetzen
      setState(() {
        _recordingDuration = Duration.zero;
      });

      // Prüfen, ob die Mikrofon-Berechtigung verweigert wurde
      final hasPermission = await PermissionService.checkMicrophonePermission();
      if (!hasPermission) {
        _showMicrophonePermissionDialog();
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Fehler beim Starten der Aufnahme. Bitte versuchen Sie es erneut.'),
          backgroundColor: Color(0xFF8C0A28),
          action: SnackBarAction(
            label: 'Erneut versuchen',
            textColor: Colors.white,
            onPressed: () => _startRecording(),
          ),
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  void _stopRecording() async {
    _recordingDurationSubscription?.cancel();

    final audioAufnahme =
        await _audioService.stopRecording(widget.etappenId, typ: 'impulsfrage');
    if (audioAufnahme != null) {
      final audioProvider = Provider.of<AudioProvider>(context, listen: false);
      await audioProvider.addAudioAufnahme(audioAufnahme);
      
      // Sicherstellen, dass die Liste aktualisiert wird
      await audioProvider.loadAudioAufnahmen();

      // Erfolgsmeldung entfernt - keine SnackBar mehr
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
    _recordingDurationSubscription?.cancel();
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
        // Nur Impulsfrage-Audio für diese Etappe anzeigen
        final audioAufnahmen =
            audioProvider.getImpulsfrageAudioByEtappe(widget.etappenId);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Aufnahme-Steuerung (nur für Impulsfrage-Aufnahmen)
            if (_audioService.isRecordingType('impulsfrage'))
              _buildRecordingControls()
            else
              _buildStartRecordingButton(),

            // Vorhandene Aufnahmen anzeigen
            if (audioAufnahmen.isNotEmpty) ...[
              SizedBox(height: 16),
              _buildAudioList(audioAufnahmen),
            ],
          ],
        );
      },
    );
  }

  Widget _buildStartRecordingButton() {
    // Button deaktivieren wenn eine andere Art von Aufnahme läuft
    final isOtherRecordingActive = _audioService.isRecording &&
        !_audioService.isRecordingType('impulsfrage');

    return Container(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: isOtherRecordingActive ? null : _startRecording,
        icon: Icon(Icons.fiber_manual_record, size: 18),
        label: Text(
          isOtherRecordingActive
              ? 'Andere Aufnahme läuft...'
              : 'Audio-Notiz aufnehmen',
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
            color: Color(0xFF8C0A28).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Color(0xFF8C0A28),
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 8),
              Text(
                'Aufnahme läuft: ${_formatDuration(_recordingDuration)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF8C0A28),
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

  Widget _buildAudioList(List<AudioAufnahme> audioAufnahmen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Audio-Notizen zur Impulsfrage',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF8C0A28),
          ),
        ),
        SizedBox(height: 8),
        ...audioAufnahmen.reversed
            .map((audio) => _buildAudioTile(audio))
            .toList(),
      ],
    );
  }

  Widget _buildAudioTile(AudioAufnahme audio) {
    final isPlaying = _playingAudioId == audio.id;

    return Container(
      margin: EdgeInsets.only(bottom: 8),
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
                  'Aufnahme vom ${audio.aufnahmeZeit.day}.${audio.aufnahmeZeit.month}.${audio.aufnahmeZeit.year}',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                    color: Color(0xFF8C0A28),
                  ),
                ),
                SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: Colors.grey),
                    SizedBox(width: 4),
                    Text(
                      audio.formatierteDauer,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(width: 12),
                    Icon(Icons.schedule, size: 14, color: Colors.grey),
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
            icon: Icon(Icons.delete_outline,
                color: Colors.grey.shade600, size: 18),
            constraints: BoxConstraints(),
            padding: EdgeInsets.zero,
            tooltip: 'Löschen',
          ),
        ],
      ),
    );
  }

  void _deleteAudio(AudioAufnahme audio) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Audio-Notiz löschen'),
        content: Text(
            'Möchten Sie diese Audio-Notiz zur Impulsfrage wirklich löschen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Abbrechen'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF8C0A28),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Löschen'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final audioProvider = Provider.of<AudioProvider>(context, listen: false);
      await audioProvider.deleteAudioAufnahme(audio.id);
    }
  }

  void _showMicrophonePermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.mic, color: Color(0xFF5A7D7D)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Berechtigung erforderlich',
                softWrap: true,
                overflow: TextOverflow.visible,
              ),
            ),
          ],
        ),
        content: Text(
          'Für Audio-Aufnahmen benötigt die App die Mikrofon-Berechtigung. '
          'Bitte aktivieren Sie diese in den Einstellungen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              PermissionService.openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF5A7D7D),
              foregroundColor: Colors.white,
            ),
            child: Text('Einstellungen öffnen'),
          ),
        ],
      ),
    );
  }
}

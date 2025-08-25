import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../providers/etappen_provider.dart';
import '../providers/bilder_provider.dart';
import '../providers/audio_provider.dart';
import '../providers/notiz_provider.dart';
import '../models/etappe.dart';
import '../models/bild.dart';

import '../models/notiz.dart';
import '../services/database_service.dart';
import '../services/tracking_service_v2.dart';
import '../services/audio_recording_service.dart';
import '../services/wetter_service.dart';
import '../models/wetter_daten.dart';
import '../widgets/wetter_widget.dart';
import '../widgets/live_map_widget.dart';
import 'etappe_completed_screen.dart';
import 'dart:io';
import 'dart:async';

class EtappeTrackingScreenNew extends StatefulWidget {
  final Etappe etappe;

  const EtappeTrackingScreenNew({Key? key, required this.etappe})
      : super(key: key);

  @override
  _EtappeTrackingScreenNewState createState() =>
      _EtappeTrackingScreenNewState();
}

class _EtappeTrackingScreenNewState extends State<EtappeTrackingScreenNew>
    with WidgetsBindingObserver {
  final TrackingServiceV2 _trackingService = TrackingServiceV2();
  final ImagePicker _picker = ImagePicker();
  final AudioRecordingService _audioService = AudioRecordingService();

  TrackingData? _currentTrackingData;
  String? _errorMessage;
  Timer? _uiUpdateTimer;

  // Wetter-Daten
  WetterDaten? _aktuellesWetter;
  Timer? _wetterUpdateTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeTracking();

    // Provider laden
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BilderProvider>(context, listen: false).loadBilder();
      Provider.of<AudioProvider>(context, listen: false).loadAudioAufnahmen();
      Provider.of<NotizProvider>(context, listen: false).loadNotizen();
    });

    // Timer für UI-Updates (für Audio-Button-Status)
    _uiUpdateTimer = Timer.periodic(Duration(milliseconds: 500), (timer) {
      if (mounted) {
        setState(() {});
      }
    });

    // Wetter initialisieren
    _initializeWeather();
  }

  @override
  void dispose() {
    _uiUpdateTimer?.cancel();
    _wetterUpdateTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.paused:
        print('App pausiert - Tracking läuft im Hintergrund weiter');
        _saveCurrentProgress();
        break;
      case AppLifecycleState.resumed:
        print('App wieder aufgenommen');
        break;
      case AppLifecycleState.detached:
        print('App wird beendet - speichere finale Daten');
        _saveCurrentProgress();
        break;
      default:
        break;
    }
  }

  void _initializeTracking() async {
    print('Initialisiere Tracking für Etappe: ${widget.etappe.name}');

    // Wenn die Etappe bereits läuft, von vorhandenen Daten fortsetzen
    if (widget.etappe.status == EtappenStatus.aktiv) {
      _trackingService.resumeFromEtappe(widget.etappe);
    }

    // Tracking starten
    final success = await _trackingService.startTracking(
      onUpdate: _onTrackingUpdate,
      onError: _onTrackingError,
      onSpeedWarning: _onSpeedWarning,
    );

    if (!success) {
      setState(() {
        _errorMessage = 'Tracking konnte nicht gestartet werden';
      });
    }
  }

  void _onTrackingUpdate(TrackingData data) {
    if (mounted) {
      setState(() {
        _currentTrackingData = data;
        _errorMessage = null;
      });

      // Periodisch speichern (alle 30 Sekunden)
      if (data.elapsedTime.inSeconds % 30 == 0) {
        _saveCurrentProgress();
      }
    }
  }

  void _onTrackingError(String error) {
    if (mounted) {
      setState(() {
        _errorMessage = error;
      });
    }
  }

  void _onSpeedWarning(String message, double speed) {
    if (mounted) {
      // Sofortige UI-Aktualisierung
      setState(() {});

      // SnackBar-Warnung anzeigen
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.orange.shade700,
          duration: Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _saveCurrentProgress() {
    if (_currentTrackingData == null) return;

    final etappenProvider =
        Provider.of<EtappenProvider>(context, listen: false);
    final updatedEtappe = widget.etappe.copyWith(
      schrittAnzahl: _currentTrackingData!.totalSteps,
      gesamtDistanz: _currentTrackingData!.totalDistance,
      gpsPunkte: _currentTrackingData!.gpsPoints,
    );

    etappenProvider.updateAktuelleEtappe(updatedEtappe);
    etappenProvider.updateEtappe(updatedEtappe);

    print(
        'Fortschritt gespeichert: ${_currentTrackingData!.totalSteps} Schritte, ${_currentTrackingData!.formattedDistance}');
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EtappenProvider>(
      builder: (context, etappenProvider, child) {
        final currentEtappe = etappenProvider.aktuelleEtappe;

        if (currentEtappe == null) {
          return _buildNoActiveEtappe();
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(currentEtappe.name),
            backgroundColor: Color(0xFF5A7D7D),
            foregroundColor: Colors.white,
            actions: [
              Container(
                margin: EdgeInsets.only(right: 8),
                child: ElevatedButton.icon(
                  onPressed: _togglePause,
                  icon: Icon(
                    _trackingService.isPaused ? Icons.play_arrow : Icons.pause,
                    size: 18,
                  ),
                  label: Text(
                    _trackingService.isPaused ? 'Start' : 'Pause',
                    style: TextStyle(fontSize: 12),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _trackingService.isPaused
                        ? Colors.green
                        : Colors.orange,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: Size(0, 36),
                  ),
                ),
              ),
              Container(
                margin: EdgeInsets.only(right: 16),
                child: ElevatedButton.icon(
                  onPressed: () => _stopTracking(etappenProvider),
                  icon: Icon(Icons.stop, size: 18),
                  label: Text('Stop', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: Size(0, 36),
                  ),
                ),
              ),
            ],
          ),
          body: _buildTrackingInterface(currentEtappe),
        );
      },
    );
  }

  Widget _buildNoActiveEtappe() {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tracking'),
        backgroundColor: Color(0xFF5A7D7D),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.directions_walk,
              size: 64,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: 16),
            Text(
              'Keine aktive Etappe',
              style: TextStyle(
                fontSize: 20,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Starte eine neue Etappe im Etappen-Tab',
              style: TextStyle(
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackingInterface(Etappe etappe) {
    if (_currentTrackingData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5A7D7D)),
            ),
            SizedBox(height: 16),
            Text('Tracking wird initialisiert...'),
            if (_errorMessage != null) ...[
              SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // Status Card
          _buildStatusCard(),
          SizedBox(height: 24),

          // Live Statistics
          _buildLiveStatistics(),
          SizedBox(height: 24),

          // Medien-Sektion
          _buildMedienSection(),
          SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    final data = _currentTrackingData!;

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: data.isPaused
            ? (data.isPausedBySpeed
                ? Colors.red.shade50
                : Colors.orange.shade50)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: data.isPaused
              ? (data.isPausedBySpeed
                  ? Colors.red.shade200
                  : Colors.orange.shade200)
              : Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          // Status und Icon in einer Zeile (breiter, niedriger)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                data.isPaused
                    ? (data.isPausedBySpeed ? Icons.speed : Icons.pause_circle)
                    : Icons.play_circle,
                size: 20,
                color: data.isPaused
                    ? (data.isPausedBySpeed ? Colors.red : Colors.orange)
                    : Color(0xFF5A7D7D),
              ),
              SizedBox(width: 12),
              Text(
                data.isPaused
                    ? (data.isPausedBySpeed ? 'ZU SCHNELL' : 'PAUSIERT')
                    : 'TRACKING AKTIV',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: data.isPaused
                      ? (data.isPausedBySpeed
                          ? Colors.red.shade800
                          : Colors.orange.shade800)
                      : Color(0xFF5A7D7D),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            data.formattedElapsedTime,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: data.isPaused
                  ? (data.isPausedBySpeed
                      ? Colors.red.shade700
                      : Colors.orange.shade700)
                  : Color(0xFF5A7D7D),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveStatistics() {
    final data = _currentTrackingData!;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Live-Statistiken',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                    'Distanz', data.formattedDistance, Icons.straighten),
              ),
              Expanded(
                child: _buildStatItem(
                    'Schritte', '${data.totalSteps}', Icons.directions_walk),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                    'Geschwindigkeit', data.formattedSpeed, Icons.speed),
              ),
              if (_aktuellesWetter != null)
                Expanded(
                  child: _buildStatItem('Wetter',
                      _aktuellesWetter!.formatierteTemperatur, Icons.wb_sunny),
                ),
            ],
          ),
          SizedBox(height: 16),

          // Live-Karte
          Text(
            'Live-Karte',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 8),
          LiveMapWidget(
            trackingData: data,
            height: 250,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Color(0xFF5A7D7D), size: 24),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF5A7D7D),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildMedienSection() {
    return Consumer3<BilderProvider, AudioProvider, NotizProvider>(
      builder: (context, bilderProvider, audioProvider, notizProvider, child) {
        final bilder = bilderProvider.getBilderByEtappe(widget.etappe.id);
        final audioAufnahmen =
            audioProvider.getAudioAufnahmenByEtappe(widget.etappe.id);
        final notizen = notizProvider.getNotizenByEtappe(widget.etappe.id);

        return Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade200,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Medien',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  GestureDetector(
                    onTap: _audioService.isRecording
                        ? _recordAudio
                        : _showActionMenu,
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _audioService.isRecording
                            ? Colors.red
                            : Color(0xFF5A7D7D),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _audioService.isRecording ? Icons.stop : Icons.add,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              if (bilder.isEmpty && audioAufnahmen.isEmpty && notizen.isEmpty)
                _buildEmptyMediaState()
              else
                _buildMediaContent(bilder, audioAufnahmen, notizen),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyMediaState() {
    return Center(
      child: Text(
        'Noch keine Medien hinzugefügt',
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }

  Widget _buildMediaContent(List bilder, List audioAufnahmen, List notizen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (bilder.isNotEmpty) ...[
          Row(
            children: [
              Icon(Icons.photo, size: 16, color: Colors.blue),
              SizedBox(width: 8),
              Text(
                '${bilder.length} Foto${bilder.length != 1 ? 's' : ''}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
        ],

        if (audioAufnahmen.isNotEmpty) ...[
          Row(
            children: [
              Icon(Icons.mic, size: 16, color: Color(0xFF5A7D7D)),
              SizedBox(width: 8),
              Text(
                '${audioAufnahmen.length} Audio-Aufnahme${audioAufnahmen.length != 1 ? 'n' : ''}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
        ],

        if (notizen.isNotEmpty) ...[
          Row(
            children: [
              Icon(Icons.note, size: 16, color: Colors.orange),
              SizedBox(width: 8),
              Text(
                '${notizen.length} Notiz${notizen.length != 1 ? 'en' : ''}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
        ],

        // Vorschau der letzten Medien
        if (bilder.isNotEmpty ||
            audioAufnahmen.isNotEmpty ||
            notizen.isNotEmpty) ...[
          SizedBox(height: 8),
          Text(
            'Zuletzt hinzugefügt:',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 8),
          _buildRecentMediaPreview(bilder, audioAufnahmen, notizen),
        ],
      ],
    );
  }

  Widget _buildRecentMediaPreview(
      List bilder, List audioAufnahmen, List notizen) {
    return Container(
      height: 60,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // Letzte Bilder
          ...bilder.take(3).map((bild) => Container(
                margin: EdgeInsets.only(right: 8),
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(bild.dateipfad),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey.shade200,
                        child: Icon(Icons.image, color: Colors.grey.shade400),
                      );
                    },
                  ),
                ),
              )),

          // Audio-Aufnahmen
          ...audioAufnahmen.take(2).map((audio) => Container(
                margin: EdgeInsets.only(right: 8),
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Color(0xFF5A7D7D).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Color(0xFF5A7D7D).withOpacity(0.3)),
                ),
                child: Icon(
                  Icons.audiotrack,
                  color: Color(0xFF5A7D7D),
                  size: 24,
                ),
              )),

          // Notizen
          ...notizen.take(2).map((notiz) => Container(
                margin: EdgeInsets.only(right: 8),
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Icon(
                  Icons.note,
                  color: Colors.orange,
                  size: 24,
                ),
              )),
        ],
      ),
    );
  }

  void _showActionMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle-Bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 20),

            Text(
              'Inhalte zur Etappe hinzufügen',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),

            // Action-Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionMenuItem(
                  icon: Icons.camera_alt,
                  label: 'Foto',
                  color: Color(0xFF5A7D7D),
                  onTap: () {
                    Navigator.pop(context);
                    _takePhoto();
                  },
                ),
                _buildActionMenuItem(
                  icon: _audioService.isRecording ? Icons.stop : Icons.mic,
                  label: _audioService.isRecording ? 'Stopp' : 'Audio',
                  color: _audioService.isRecording
                      ? Colors.red
                      : Color(0xFF5A7D7D),
                  onTap: () {
                    Navigator.pop(context);
                    _recordAudio();
                  },
                ),
                _buildActionMenuItem(
                  icon: Icons.note_add,
                  label: 'Notiz',
                  color: Color(0xFF5A7D7D),
                  onTap: () {
                    Navigator.pop(context);
                    _addNote();
                  },
                ),
              ],
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildActionMenuItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 28,
            ),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _togglePause() {
    _trackingService.togglePause();
  }

  void _stopTracking(EtappenProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Etappe beenden'),
        content: Text('Möchtest du die Etappe wirklich beenden?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _finishEtappe(provider);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF5A7D7D),
              foregroundColor: Colors.white,
            ),
            child: Text('Beenden'),
          ),
        ],
      ),
    );
  }

  void _finishEtappe(EtappenProvider provider) async {
    print('Beende Etappe...');

    // Tracking stoppen und finale Daten abrufen
    final finalData = await _trackingService.stopTracking();

    // Finale Daten in Etappe speichern - NaN-Werte vermeiden
    final completedEtappe = widget.etappe.copyWith(
      schrittAnzahl: finalData.totalSteps.isFinite ? finalData.totalSteps : 0,
      gesamtDistanz:
          finalData.totalDistance.isFinite ? finalData.totalDistance : 0.0,
      gpsPunkte: finalData.gpsPoints,
      endzeit: DateTime.now(),
      status: EtappenStatus.abgeschlossen,
      // Wetter-Verlauf wird beim Stop finalisiert
      wetterVerlauf: widget.etappe.wetterVerlauf,
    );

    provider.updateAktuelleEtappe(completedEtappe);
    await provider.updateEtappe(completedEtappe);
    provider.stopEtappe();

    // Direkt zur Abgeschlossen-Seite navigieren
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => EtappeCompletedScreen(etappe: completedEtappe),
        ),
      );
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (photo != null) {
        // Position abrufen
        Position? position = _currentTrackingData?.currentPosition;

        // Bild dauerhaft in das App-Dokumente-Verzeichnis kopieren
        final appDocsDir = await getApplicationDocumentsDirectory();
        final bilderDir = Directory(p.join(appDocsDir.path, 'bilder'));
        if (!bilderDir.existsSync()) {
          await bilderDir.create(recursive: true);
        }
        final newFileName = 'IMG_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final newPath = p.join(bilderDir.path, newFileName);
        final savedFile = await File(photo.path).copy(newPath);

        // Bild in Datenbank speichern
        final bild = Bild(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          dateiname: newFileName,
          dateipfad: savedFile.path, // Dauerhafter Pfad statt temporärer
          latitude: position?.latitude,
          longitude: position?.longitude,
          aufnahmeZeit: DateTime.now(),
          etappenId: widget.etappe.id,
          metadaten: {
            'kamera': 'Hauptkamera',
            'qualitaet': '80%',
          },
        );

        await DatabaseService.instance.insertBild(bild);

        // Provider aktualisieren
        final bilderProvider =
            Provider.of<BilderProvider>(context, listen: false);
        await bilderProvider.loadBilder();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Foto erfolgreich aufgenommen!'),
            backgroundColor: Color(0xFF5A7D7D),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Aufnehmen des Fotos: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _recordAudio() async {
    if (_audioService.isRecording) {
      // Aufnahme stoppen
      try {
        final audioAufnahme =
            await _audioService.stopRecording(widget.etappe.id);

        if (audioAufnahme != null) {
          // Audio in Provider hinzufügen
          final audioProvider =
              Provider.of<AudioProvider>(context, listen: false);
          await audioProvider.addAudioAufnahme(audioAufnahme);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Audio-Aufnahme gespeichert!'),
              backgroundColor: Color(0xFF5A7D7D),
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Stoppen der Aufnahme: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      // Aufnahme starten
      final success = await _audioService.startRecording();
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Audio-Aufnahme gestartet'),
            backgroundColor: Color(0xFF5A7D7D),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Starten der Aufnahme'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _addNote() {
    final notizProvider = Provider.of<NotizProvider>(context, listen: false);
    final existingNotizen = notizProvider.getNotizenByEtappe(widget.etappe.id);

    // Wenn bereits eine Notiz existiert, diese bearbeiten, sonst neue erstellen
    if (existingNotizen.isNotEmpty) {
      _showNotizDialog(existingNotiz: existingNotizen.first);
    } else {
      _showNotizDialog();
    }
  }

  void _showNotizDialog({Notiz? existingNotiz}) {
    final TextEditingController titelController = TextEditingController(
      text: existingNotiz?.titel ?? 'Live-Tracking Notiz',
    );
    final TextEditingController inhaltController = TextEditingController(
      text: existingNotiz?.inhalt ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
            existingNotiz != null ? 'Notiz bearbeiten' : 'Notiz hinzufügen'),
        contentPadding: EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 0.0),
        content: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titelController,
                decoration: InputDecoration(
                  labelText: 'Titel',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Color(0xFF5A7D7D), width: 2),
                  ),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: inhaltController,
                decoration: InputDecoration(
                  labelText: 'Notiz',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Color(0xFF5A7D7D), width: 2),
                  ),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  hintText: 'Hier können Sie Ihre Notizen eingeben...',
                ),
                maxLines: 5,
                minLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          if (existingNotiz != null)
            TextButton(
              onPressed: () async {
                try {
                  final notizProvider =
                      Provider.of<NotizProvider>(context, listen: false);
                  await notizProvider.deleteNotiz(existingNotiz.id);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Notiz gelöscht!'),
                      backgroundColor: Colors.red,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Fehler beim Löschen: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Text('Löschen', style: TextStyle(color: Colors.red)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (inhaltController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Bitte geben Sie eine Notiz ein')),
                );
                return;
              }

              try {
                final notizProvider =
                    Provider.of<NotizProvider>(context, listen: false);

                if (existingNotiz != null) {
                  // Bestehende Notiz aktualisieren
                  final updatedNotiz = existingNotiz.copyWith(
                    titel: titelController.text.trim(),
                    inhalt: inhaltController.text.trim(),
                    bearbeitetAm: DateTime.now(),
                  );
                  await notizProvider.updateNotiz(updatedNotiz);

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Notiz aktualisiert!'),
                      backgroundColor: Color(0xFF5A7D7D),
                    ),
                  );
                } else {
                  // Neue Notiz erstellen
                  final notiz = Notiz(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    titel: titelController.text.trim(),
                    inhalt: inhaltController.text.trim(),
                    erstelltAm: DateTime.now(),
                    etappenId: widget.etappe.id,
                  );

                  await notizProvider.addNotiz(notiz);

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Notiz hinzugefügt!'),
                      backgroundColor: Color(0xFF5A7D7D),
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Fehler beim Speichern: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF5A7D7D),
              foregroundColor: Colors.white,
            ),
            child: Text(existingNotiz != null ? 'Aktualisieren' : 'Speichern'),
          ),
        ],
      ),
    );
  }

  void _initializeWeather() {
    // Startdaten aus Etappe verwenden falls vorhanden
    if (widget.etappe.startWetter != null) {
      _aktuellesWetter = widget.etappe.startWetter;
    }

    // Periodische Updates alle 30 Minuten
    _wetterUpdateTimer = Timer.periodic(Duration(minutes: 30), (timer) {
      _updateWeather();
    });

    // Initiales Update nach 5 Sekunden
    Timer(Duration(seconds: 5), () {
      _updateWeather();
    });
  }

  Future<void> _updateWeather() async {
    if (!WetterService.isConfigured) {
      return;
    }

    try {
      final trackingData = _currentTrackingData;
      if (trackingData?.currentPosition == null) {
        return;
      }

      final position = trackingData!.currentPosition!;
      final wetter = await WetterService.getAktuellesWetter(
        position.latitude,
        position.longitude,
      );

      if (wetter != null && mounted) {
        setState(() {
          _aktuellesWetter = wetter;
        });

        // Wetter-Verlauf zur Etappe hinzufügen
        _addWeatherToEtappe(wetter);
      }
    } catch (e) {
      print('Fehler beim Aktualisieren der Wetterdaten: $e');
    }
  }

  void _addWeatherToEtappe(WetterDaten wetter) {
    final etappenProvider =
        Provider.of<EtappenProvider>(context, listen: false);
    final currentEtappe = etappenProvider.aktuelleEtappe;

    if (currentEtappe != null) {
      final updatedWetterVerlauf =
          List<WetterDaten>.from(currentEtappe.wetterVerlauf);
      updatedWetterVerlauf.add(wetter);

      final updatedEtappe = currentEtappe.copyWith(
        wetterVerlauf: updatedWetterVerlauf,
      );

      etappenProvider.updateAktuelleEtappe(updatedEtappe);
      etappenProvider.updateEtappe(updatedEtappe);
    }
  }
}

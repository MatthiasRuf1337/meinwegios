import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../providers/etappen_provider.dart';
import '../providers/bilder_provider.dart';
import '../models/etappe.dart';
import '../models/bild.dart';
import '../services/database_service.dart';
import '../services/tracking_service_v2.dart';

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

  TrackingData? _currentTrackingData;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeTracking();
  }

  @override
  void dispose() {
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
            backgroundColor: Color(0xFF00847E),
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: Icon(
                    _trackingService.isPaused ? Icons.play_arrow : Icons.pause),
                onPressed: _togglePause,
              ),
              IconButton(
                icon: Icon(Icons.stop),
                onPressed: () => _stopTracking(etappenProvider),
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
        backgroundColor: Color(0xFF00847E),
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
                fontSize: 18,
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
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00847E)),
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

          // GPS Information
          _buildGPSInfo(),
          SizedBox(height: 24),

          // Action Buttons
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    final data = _currentTrackingData!;

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: data.isPaused
              ? [Colors.orange.shade50, Colors.orange.shade100]
              : [
                  Color(0xFF00847E).withOpacity(0.1),
                  Color(0xFF00847E).withOpacity(0.2)
                ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: data.isPaused
              ? Colors.orange.shade200
              : Color(0xFF00847E).withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            data.isPaused ? Icons.pause_circle : Icons.play_circle,
            size: 48,
            color: data.isPaused ? Colors.orange : Color(0xFF00847E),
          ),
          SizedBox(height: 12),
          Text(
            data.isPaused ? 'PAUSIERT' : 'TRACKING AKTIV',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: data.isPaused ? Colors.orange.shade800 : Color(0xFF00847E),
            ),
          ),
          SizedBox(height: 8),
          Text(
            data.formattedElapsedTime,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: data.isPaused ? Colors.orange.shade700 : Color(0xFF00847E),
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
              fontSize: 18,
              fontWeight: FontWeight.bold,
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
              Expanded(
                child: _buildStatItem(
                    'Geschwindigkeit', data.formattedSpeed, Icons.speed),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Color(0xFF00847E), size: 24),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF00847E),
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

  Widget _buildGPSInfo() {
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
            'GPS-Informationen',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          if (data.currentPosition != null) ...[
            _buildGPSRow('Breitengrad',
                data.currentPosition!.latitude.toStringAsFixed(6)),
            _buildGPSRow('Längengrad',
                data.currentPosition!.longitude.toStringAsFixed(6)),
            _buildGPSRow('Höhe',
                '${data.currentPosition!.altitude.toStringAsFixed(1)} m'),
            _buildGPSRow('Genauigkeit',
                '${data.currentPosition!.accuracy.toStringAsFixed(1)} m'),
          ] else ...[
            Text(
              'GPS-Signal wird gesucht...',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          SizedBox(height: 8),
          Text(
            'GPS-Punkte: ${data.gpsPoints.length}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGPSRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _takePhoto,
            icon: Icon(Icons.camera_alt),
            label: Text('Foto'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _addNote,
            icon: Icon(Icons.note_add),
            label: Text('Notiz'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
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
              backgroundColor: Color(0xFF00847E),
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

    // Finale Daten in Etappe speichern
    final completedEtappe = widget.etappe.copyWith(
      schrittAnzahl: finalData.totalSteps,
      gesamtDistanz: finalData.totalDistance,
      gpsPunkte: finalData.gpsPoints,
      endzeit: DateTime.now(),
      status: EtappenStatus.abgeschlossen,
    );

    provider.updateAktuelleEtappe(completedEtappe);
    await provider.updateEtappe(completedEtappe);
    provider.stopEtappe();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Etappe beendet! ${finalData.totalSteps} Schritte, ${finalData.formattedDistance}'),
        backgroundColor: Color(0xFF00847E),
      ),
    );
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

        // Bild in Datenbank speichern
        final bild = Bild(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          dateiname: 'IMG_${DateTime.now().millisecondsSinceEpoch}.jpg',
          dateipfad: photo.path,
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
            backgroundColor: Color(0xFF00847E),
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

  void _addNote() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Notiz-Funktion wird implementiert...')),
    );
  }
}

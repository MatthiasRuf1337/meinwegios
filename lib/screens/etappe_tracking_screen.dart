import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:pedometer/pedometer.dart';
import '../providers/etappen_provider.dart';
import '../models/etappe.dart';
import '../models/etappe.dart' as etappe_models;
import '../models/bild.dart';
import '../providers/bilder_provider.dart';
import '../services/database_service.dart';
import 'dart:io';

class EtappeTrackingScreen extends StatefulWidget {
  final Etappe etappe;

  const EtappeTrackingScreen({Key? key, required this.etappe}) : super(key: key);

  @override
  _EtappeTrackingScreenState createState() => _EtappeTrackingScreenState();
}

class _EtappeTrackingScreenState extends State<EtappeTrackingScreen> {
  bool _isTracking = false;
  bool _isPaused = false;
  Duration _elapsedTime = Duration.zero;
  int _stepCount = 0;
  double _distance = 0.0;
  double _currentSpeed = 0.0;
  Position? _currentPosition;
  List<etappe_models.GPSPunkt> _gpsPoints = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _startTracking();
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
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
                onPressed: () => _togglePause(),
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
        backgroundColor: Colors.green,
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
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isPaused 
              ? [Colors.orange.shade50, Colors.orange.shade100]
              : [Colors.green.shade50, Colors.green.shade100],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isPaused ? Colors.orange.shade200 : Colors.green.shade200,
        ),
      ),
      child: Column(
        children: [
          Icon(
            _isPaused ? Icons.pause_circle : Icons.play_circle,
            size: 48,
            color: _isPaused ? Colors.orange : Colors.green,
          ),
          SizedBox(height: 12),
          Text(
            _isPaused ? 'PAUSIERT' : 'TRACKING AKTIV',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _isPaused ? Colors.orange.shade800 : Colors.green.shade800,
            ),
          ),
          SizedBox(height: 8),
          Text(
            _formatDuration(_elapsedTime),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _isPaused ? Colors.orange.shade700 : Colors.green.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveStatistics() {
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
              Expanded(child: _buildStatItem('Distanz', _formatDistance(_distance), Icons.straighten)),
              Expanded(child: _buildStatItem('Schritte', '$_stepCount', Icons.directions_walk)),
              Expanded(child: _buildStatItem('Geschwindigkeit', _formatSpeed(_currentSpeed), Icons.speed)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.green, size: 24),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.green.shade800,
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
          if (_currentPosition != null) ...[
            _buildGPSRow('Breitengrad', _currentPosition!.latitude.toStringAsFixed(6)),
            _buildGPSRow('Längengrad', _currentPosition!.longitude.toStringAsFixed(6)),
            _buildGPSRow('Höhe', '${_currentPosition!.altitude?.toStringAsFixed(1) ?? 'N/A'} m'),
            _buildGPSRow('Genauigkeit', '${_currentPosition!.accuracy?.toStringAsFixed(1) ?? 'N/A'} m'),
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
            'GPS-Punkte: ${_gpsPoints.length}',
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
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _takePhoto(),
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
                onPressed: () => _addNote(),
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
        ),
        SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _showMap(),
            icon: Icon(Icons.map),
            label: Text('Karte anzeigen'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitHours = twoDigits(duration.inHours);
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitHours:$twoDigitMinutes:$twoDigitSeconds";
  }

  String _formatDistance(double distance) {
    if (distance < 1000) {
      return '${distance.toStringAsFixed(0)} m';
    } else {
      return '${(distance / 1000).toStringAsFixed(2)} km';
    }
  }

  String _formatSpeed(double speed) {
    if (speed < 1) {
      return '${(speed * 1000).toStringAsFixed(0)} m/h';
    } else {
      return '${speed.toStringAsFixed(1)} km/h';
    }
  }

  void _startTracking() {
    setState(() {
      _isTracking = true;
    });
    
    // Timer für verstrichene Zeit
    _startTimer();
    
    // GPS-Tracking starten
    _startGPSTracking();
    
    // Schrittzähler starten
    _startStepCounting();
  }

  void _startTimer() {
    // Implementierung für Timer
  }

  void _startGPSTracking() {
    // Implementierung für GPS-Tracking
    _getCurrentLocation();
  }

  void _startStepCounting() {
    // Implementierung für Schrittzählung
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      setState(() {
        _currentPosition = position;
        _gpsPoints.add(etappe_models.GPSPunkt(
          latitude: position.latitude,
          longitude: position.longitude,
          altitude: position.altitude,
          timestamp: DateTime.now(),
          accuracy: position.accuracy,
        ));
      });
    } catch (e) {
      print('Fehler beim Abrufen der Position: $e');
    }
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
    });
    
    if (_isPaused) {
      // Tracking pausieren
    } else {
      // Tracking fortsetzen
    }
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text('Beenden'),
          ),
        ],
      ),
    );
  }

  void _finishEtappe(EtappenProvider provider) {
    // Etappe beenden und speichern
    provider.stopEtappe();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Etappe erfolgreich beendet!')),
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
        Position? position;
        try {
          position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );
        } catch (e) {
          print('Fehler beim Abrufen der Position: $e');
        }

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
        final bilderProvider = Provider.of<BilderProvider>(context, listen: false);
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

  void _showMap() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Karten-Funktion wird implementiert...')),
    );
  }
} 
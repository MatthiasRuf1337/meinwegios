import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/etappen_provider.dart';
import '../models/etappe.dart';
import '../models/etappe.dart' as etappe_models;
import '../models/bild.dart';
import '../providers/bilder_provider.dart';
import '../services/database_service.dart';
import 'dart:io';
import 'dart:async';

class EtappeTrackingScreen extends StatefulWidget {
  final Etappe etappe;

  const EtappeTrackingScreen({Key? key, required this.etappe})
      : super(key: key);

  @override
  _EtappeTrackingScreenState createState() => _EtappeTrackingScreenState();
}

class _EtappeTrackingScreenState extends State<EtappeTrackingScreen>
    with WidgetsBindingObserver {
  bool _isTracking = false;
  bool _isPaused = false;
  Duration _elapsedTime = Duration.zero;
  int _stepCount = 0;
  int _initialStepCount = 0; // Schritte beim Start
  int _lastStepCount = 0; // Letzte abgefragte Schritte
  double _distance = 0.0;
  double _currentSpeed = 0.0;
  Position? _currentPosition;
  List<etappe_models.GPSPunkt> _gpsPoints = [];
  final ImagePicker _picker = ImagePicker();
  Timer? _timer;
  Timer? _stepUpdateTimer; // Timer für Schrittabfrage
  StreamSubscription<Position>? _positionSubscription;
  DateTime? _appPausedTime; // Zeitpunkt als App pausiert wurde

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadExistingData();
    _startTracking();
  }

  void _loadExistingData() {
    final etappenProvider =
        Provider.of<EtappenProvider>(context, listen: false);
    if (etappenProvider.aktuelleEtappe != null) {
      final etappe = etappenProvider.aktuelleEtappe!;

      // Zeit basierend auf Startzeit berechnen (funktioniert auch nach App-Neustart)
      final now = DateTime.now();
      final elapsedTime = now.difference(etappe.startzeit);

      setState(() {
        _elapsedTime = elapsedTime;
        _stepCount = etappe.schrittAnzahl;
        _distance = etappe.gesamtDistanz;
        _gpsPoints = List.from(etappe.gpsPunkte);
      });
      print(
          'Geladene Daten: $elapsedTime, ${etappe.schrittAnzahl} Schritte, ${etappe.gesamtDistanz}m');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _stepUpdateTimer?.cancel();
    _positionSubscription?.cancel();
    super.dispose();
  }

    @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
 
    switch (state) {
      case AppLifecycleState.paused:
        print('App pausiert - speichere aktuelle Zeit und Schritte');
        _appPausedTime = DateTime.now();
        _saveCurrentSteps('APP_PAUSE'); // Schritte speichern
        _updateEtappeData(); // Finale Speicherung vor Pause
        break;
      case AppLifecycleState.resumed:
        print('App wieder aufgenommen');
        if (_appPausedTime != null && !_isPaused) {
          // Zeit korrigieren basierend auf Pause
          final pauseDuration = DateTime.now().difference(_appPausedTime!);
          print('App war pausiert für: $pauseDuration');
        }
        break;
      case AppLifecycleState.detached:
        print('App wird beendet - speichere finale Daten');
        _saveCurrentSteps('APP_DETACHED'); // Finale Schritte
        _updateEtappeData();
        break;
      default:
        break;
    }
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
              : [
                  Color(0xFF00847E).withOpacity(0.1),
                  Color(0xFF00847E).withOpacity(0.2)
                ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isPaused
              ? Colors.orange.shade200
              : Color(0xFF00847E).withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            _isPaused ? Icons.pause_circle : Icons.play_circle,
            size: 48,
            color: _isPaused ? Colors.orange : Color(0xFF00847E),
          ),
          SizedBox(height: 12),
          Text(
            _isPaused ? 'PAUSIERT' : 'TRACKING AKTIV',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _isPaused ? Colors.orange.shade800 : Color(0xFF00847E),
            ),
          ),
          SizedBox(height: 8),
          Text(
            _formatDuration(_elapsedTime),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _isPaused ? Colors.orange.shade700 : Color(0xFF00847E),
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
              Expanded(
                  child: _buildStatItem(
                      'Distanz', _formatDistance(_distance), Icons.straighten)),
              Expanded(
                  child: _buildStatItem(
                      'Schritte', '$_stepCount', Icons.directions_walk)),
              Expanded(
                  child: _buildStatItem('Geschwindigkeit',
                      _formatSpeed(_currentSpeed), Icons.speed)),
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
            _buildGPSRow(
                'Breitengrad', _currentPosition!.latitude.toStringAsFixed(6)),
            _buildGPSRow(
                'Längengrad', _currentPosition!.longitude.toStringAsFixed(6)),
            _buildGPSRow('Höhe',
                '${_currentPosition!.altitude?.toStringAsFixed(1) ?? 'N/A'} m'),
            _buildGPSRow('Genauigkeit',
                '${_currentPosition!.accuracy?.toStringAsFixed(1) ?? 'N/A'} m'),
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
              backgroundColor: Color(0xFF00847E),
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

  void _startTracking() async {
    print('Starte Tracking...');

    // Berechtigungen prüfen
    bool locationGranted = await Geolocator.isLocationServiceEnabled();
    print('Standort aktiviert: $locationGranted');

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
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!_isPaused && mounted) {
        setState(() {
          _elapsedTime = _elapsedTime + Duration(seconds: 1);
        });

        // Alle 10 Sekunden die Etappe aktualisieren
        if (_elapsedTime.inSeconds % 10 == 0) {
          _updateEtappeData();
        }
      }
    });

    // Hintergrund-Timer für kontinuierliche Zeitmessung
    _startBackgroundTimer();
  }

  void _startBackgroundTimer() {
    // Timer der auch im Hintergrund läuft
    Timer.periodic(Duration(seconds: 30), (timer) {
      if (!_isPaused) {
        // Zeit basierend auf Startzeit berechnen (funktioniert auch im Hintergrund)
        final now = DateTime.now();
        final startTime = Provider.of<EtappenProvider>(context, listen: false)
                .aktuelleEtappe
                ?.startzeit ??
            now;

        final elapsed = now.difference(startTime);

        if (mounted) {
          setState(() {
            _elapsedTime = elapsed;
          });
        }

        // Hintergrund-Update
        _updateEtappeData();
      }
    });
  }

  void _updateEtappeData() {
    final etappenProvider =
        Provider.of<EtappenProvider>(context, listen: false);
    if (etappenProvider.aktuelleEtappe != null) {
      final updatedEtappe = etappenProvider.aktuelleEtappe!.copyWith(
        schrittAnzahl: _stepCount,
        gesamtDistanz: _distance,
        gpsPunkte: _gpsPoints,
      );
      etappenProvider.updateAktuelleEtappe(updatedEtappe);
    }
  }

  void _startGPSTracking() {
    print('Starte GPS-Tracking...');
    // Kontinuierliches GPS-Tracking mit Hintergrund-Unterstützung
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // Update alle 5 Meter für bessere Genauigkeit
        timeLimit: Duration(seconds: 30), // Timeout für bessere Performance
      ),
    ).listen(
      (Position position) {
        print('GPS Update: ${position.latitude}, ${position.longitude}');
        if (!_isPaused && mounted) {
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

          // Distanz berechnen
          _calculateDistance();

          // Sofort aktualisieren
          _updateEtappeData();
        }
      },
      onError: (error) {
        print('GPS Fehler: $error');
      },
    );
  }

    void _startStepCounting() async {
    print('Starte Schrittzählung...');
    
    // Berechtigung prüfen
    bool granted = await Permission.activityRecognition.isGranted;
    if (!granted) {
      granted = await Permission.activityRecognition.request() == PermissionStatus.granted;
    }
    
    if (!granted) {
      print('Aktivitätserkennung-Berechtigung verweigert');
      return;
    }
    
    // Initiale Schritte beim Start abrufen
    await _getInitialSteps();
    
    // Kontinuierlicher Stream für Schritte
    try {
      Pedometer.stepCountStream.listen(
        (StepCount event) {
          print('Schritt Update: ${event.steps} Schritte');
          if (!_isPaused && mounted) {
            final newSteps = event.steps - _initialStepCount;
            setState(() {
              _stepCount = newSteps;
            });
            
            // Alle 10 Schritte speichern
            if (newSteps % 10 == 0) {
              _saveStepData('UPDATE', event.steps);
            }
          }
        },
        onError: (error) {
          print('Schritt Stream Fehler: $error');
        },
      );
    } catch (e) {
      print('Fehler beim Starten des Schritt-Streams: $e');
    }
  }

  Future<void> _getInitialSteps() async {
    try {
      final stepCount = await Pedometer.stepCountStream.first;
      _initialStepCount = stepCount.steps;
      _lastStepCount = stepCount.steps;
      print('Initiale Schritte: $_initialStepCount');
      
      // Sofort in Etappe speichern
      _saveStepData('START', _initialStepCount);
    } catch (e) {
      print('Fehler beim Abrufen der initialen Schritte: $e');
      _initialStepCount = 0;
      _lastStepCount = 0;
    }
  }

  void _saveStepData(String action, int stepCount) {
    final etappenProvider = Provider.of<EtappenProvider>(context, listen: false);
    if (etappenProvider.aktuelleEtappe != null) {
      final updatedEtappe = etappenProvider.aktuelleEtappe!.copyWith(
        schrittAnzahl: _stepCount,
      );
      etappenProvider.updateAktuelleEtappe(updatedEtappe);
      print('Schritte gespeichert ($action): $_stepCount (Gesamt: $stepCount)');
    }
  }

  Future<void> _updateStepCount() async {
    try {
      final stepCount = await Pedometer.stepCountStream.first;
      final newSteps = stepCount.steps - _initialStepCount;
      print('Aktuelle Schritte: ${stepCount.steps}, Neue Schritte: $newSteps');

      if (mounted) {
        setState(() {
          _stepCount = newSteps;
        });
        _lastStepCount = stepCount.steps;

        // Etappe aktualisieren
        _updateEtappeData();
      }
    } catch (e) {
      print('Fehler beim Aktualisieren der Schritte: $e');
    }
  }

  void _startAlternativeStepCounting() {
    print('Starte alternative Schrittzählung...');
    // Alternative: Schritte basierend auf GPS-Bewegung schätzen
    Timer.periodic(Duration(seconds: 5), (timer) {
      if (!_isPaused && mounted && _distance > 0) {
        // Schätze Schritte basierend auf zurückgelegter Distanz
        final estimatedSteps = (_distance / 0.7).round(); // ~0.7m pro Schritt
        setState(() {
          _stepCount = estimatedSteps;
        });
        print('Geschätzte Schritte: $_stepCount (basierend auf ${_distance}m)');
      }
    });
  }

  void _startManualStepCounting() {
    print('Starte manuelle Schrittzählung...');
    // Einfache Schrittzählung basierend auf GPS-Bewegung
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!_isPaused && mounted && _currentPosition != null) {
        // Schätze Schritte basierend auf Bewegung
        if (_distance > 0) {
          setState(() {
            _stepCount = (_distance / 0.7).round(); // ~0.7m pro Schritt
          });
        }
      }
    });
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

  void _calculateDistance() {
    if (_gpsPoints.length < 2) return;

    double totalDistance = 0.0;
    for (int i = 1; i < _gpsPoints.length; i++) {
      totalDistance += Geolocator.distanceBetween(
        _gpsPoints[i - 1].latitude,
        _gpsPoints[i - 1].longitude,
        _gpsPoints[i].latitude,
        _gpsPoints[i].longitude,
      );
    }

    setState(() {
      _distance = totalDistance;
    });
  }

  void _togglePause() async {
    setState(() {
      _isPaused = !_isPaused;
    });

    if (_isPaused) {
      // Tracking pausieren - aktuelle Schritte speichern
      await _saveCurrentSteps('PAUSE');
    } else {
      // Tracking fortsetzen - neue Startschritte setzen
      await _getCurrentStepsForResume();
    }
  }

  Future<void> _saveCurrentSteps(String action) async {
    try {
      final currentStepCount = await Pedometer.stepCountStream.first;
      final newSteps = currentStepCount.steps - _initialStepCount;
      setState(() {
        _stepCount = newSteps;
      });
      _saveStepData(action, currentStepCount.steps);
    } catch (e) {
      print('Fehler beim Speichern der aktuellen Schritte: $e');
    }
  }

  Future<void> _getCurrentStepsForResume() async {
    try {
      final currentStepCount = await Pedometer.stepCountStream.first;
      _initialStepCount = currentStepCount.steps - _stepCount; // Neue Basis setzen
      print('Neue Basis-Schritte nach Resume: $_initialStepCount');
    } catch (e) {
      print('Fehler beim Setzen der neuen Basis-Schritte: $e');
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
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF00847E)),
            child: Text('Beenden'),
          ),
        ],
      ),
    );
  }

    void _finishEtappe(EtappenProvider provider) async {
    print('Beende Etappe...');
    
    // Finale Schritte abrufen und speichern
    try {
      final finalStepCount = await Pedometer.stepCountStream.first;
      final totalSteps = finalStepCount.steps - _initialStepCount;
      print(
          'Finale Schritte: $totalSteps (Gesamt: ${finalStepCount.steps}, Start: $_initialStepCount)');
      
      setState(() {
        _stepCount = totalSteps;
      });
      
      // Finale Schritte speichern
      _saveStepData('STOP', finalStepCount.steps);
      
      // Finale Daten speichern
      _updateEtappeData();
    } catch (e) {
      print('Fehler beim Abrufen der finalen Schritte: $e');
    }
    
    // Timer stoppen
    _stepUpdateTimer?.cancel();
    
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

  void _showMap() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Karten-Funktion wird implementiert...')),
    );
  }
}

import 'dart:async';
import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/etappe.dart';

class TrackingServiceV2 {
  static final TrackingServiceV2 _instance = TrackingServiceV2._internal();
  factory TrackingServiceV2() => _instance;
  TrackingServiceV2._internal();

  // Streams und Subscriptions
  StreamSubscription<Position>? _positionSubscription;
  StreamSubscription<StepCount>? _stepCountSubscription;
  Timer? _trackingTimer;

  // Tracking-Status
  bool _isTracking = false;
  bool _isPaused = false;
  DateTime? _trackingStartTime;
  DateTime? _pausedAt;
  Duration _pausedDuration = Duration.zero;

  // GPS-Daten
  Position? _currentPosition;
  Position? _lastValidPosition;
  List<GPSPunkt> _gpsPoints = [];
  double _totalDistance = 0.0;
  double _currentSpeed = 0.0;

  // Schritt-Daten
  int _totalSteps = 0;
  int? _initialStepCount;
  bool _stepTrackingEnabled = false;
  bool _useGPSStepEstimation = false;

  // Callbacks
  Function(TrackingData)? _onTrackingUpdate;
  Function(String)? _onError;

  // Getter
  bool get isTracking => _isTracking;
  bool get isPaused => _isPaused;
  TrackingData get currentData => TrackingData(
        isTracking: _isTracking,
        isPaused: _isPaused,
        elapsedTime: _getElapsedTime(),
        totalSteps: _totalSteps,
        totalDistance: _totalDistance,
        currentSpeed: _currentSpeed,
        currentPosition: _currentPosition,
        gpsPoints: List.unmodifiable(_gpsPoints),
      );

  Duration _getElapsedTime() {
    if (_trackingStartTime == null) return Duration.zero;

    final now = DateTime.now();
    final totalElapsed = now.difference(_trackingStartTime!);

    // Pausierte Zeit abziehen
    Duration currentPauseDuration = _pausedDuration;
    if (_isPaused && _pausedAt != null) {
      currentPauseDuration += now.difference(_pausedAt!);
    }

    return totalElapsed - currentPauseDuration;
  }

  // Tracking starten
  Future<bool> startTracking({
    Function(TrackingData)? onUpdate,
    Function(String)? onError,
  }) async {
    if (_isTracking) return false;

    print('TrackingServiceV2: Starte Tracking...');

    _onTrackingUpdate = onUpdate;
    _onError = onError;

    // Berechtigungen prüfen
    if (!await _checkPermissions()) {
      _onError?.call('Erforderliche Berechtigungen nicht erteilt');
      return false;
    }

    // Tracking initialisieren
    _isTracking = true;
    _isPaused = false;
    _trackingStartTime = DateTime.now();
    _pausedAt = null;
    _pausedDuration = Duration.zero;

    // GPS-Tracking starten
    await _startGPSTracking();

    // Schritt-Tracking starten
    await _startStepTracking();

    // Update-Timer starten
    _startUpdateTimer();

    print('TrackingServiceV2: Tracking erfolgreich gestartet');
    _notifyUpdate();
    return true;
  }

  // Tracking pausieren/fortsetzen
  void togglePause() {
    if (!_isTracking) return;

    if (_isPaused) {
      // Fortsetzen
      if (_pausedAt != null) {
        _pausedDuration += DateTime.now().difference(_pausedAt!);
      }
      _isPaused = false;
      _pausedAt = null;
      print('TrackingServiceV2: Tracking fortgesetzt');
    } else {
      // Pausieren
      _isPaused = true;
      _pausedAt = DateTime.now();
      print('TrackingServiceV2: Tracking pausiert');
    }

    _notifyUpdate();
  }

  // Tracking stoppen
  Future<TrackingData> stopTracking() async {
    if (!_isTracking) return currentData;

    print('TrackingServiceV2: Stoppe Tracking...');

    _isTracking = false;
    _isPaused = false;

    // Alle Subscriptions beenden
    await _positionSubscription?.cancel();
    await _stepCountSubscription?.cancel();
    _trackingTimer?.cancel();

    _positionSubscription = null;
    _stepCountSubscription = null;
    _trackingTimer = null;

    final finalData = currentData;

    // Daten zurücksetzen
    _reset();

    print('TrackingServiceV2: Tracking gestoppt');
    return finalData;
  }

  // GPS-Tracking starten
  Future<void> _startGPSTracking() async {
    print('TrackingServiceV2: Starte GPS-Tracking...');

    try {
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 1, // Meter
        ),
      ).listen(
        _onPositionUpdate,
        onError: (error) {
          print('TrackingServiceV2: GPS-Fehler: $error');
          _onError?.call('GPS-Fehler: $error');
        },
      );
    } catch (e) {
      print('TrackingServiceV2: Fehler beim Starten des GPS-Trackings: $e');
      _onError?.call('GPS-Tracking konnte nicht gestartet werden: $e');
    }
  }

  // GPS-Position Update
  void _onPositionUpdate(Position position) {
    if (!_isTracking || _isPaused) return;

    _currentPosition = position;

    // Geschwindigkeit berechnen (m/s zu km/h)
    _currentSpeed = (position.speed * 3.6).clamp(0.0, 50.0);

    // Distanz berechnen
    if (_lastValidPosition != null) {
      final distance = Geolocator.distanceBetween(
        _lastValidPosition!.latitude,
        _lastValidPosition!.longitude,
        position.latitude,
        position.longitude,
      );

      // Filter für realistische Bewegung
      if (_isRealisticMovement(distance, position)) {
        _totalDistance += distance;
        _lastValidPosition = position;

        // GPS-Punkt hinzufügen
        _gpsPoints.add(GPSPunkt(
          latitude: position.latitude,
          longitude: position.longitude,
          altitude: position.altitude,
          timestamp: DateTime.now(),
          accuracy: position.accuracy,
        ));

        // GPS-basierte Schritt-Schätzung falls Pedometer nicht funktioniert
        if (_useGPSStepEstimation) {
          _estimateStepsFromGPS(distance);
        }
      }
    } else {
      // Erste Position
      _lastValidPosition = position;
      _gpsPoints.add(GPSPunkt(
        latitude: position.latitude,
        longitude: position.longitude,
        altitude: position.altitude,
        timestamp: DateTime.now(),
        accuracy: position.accuracy,
      ));
    }

    _notifyUpdate();
  }

  // Prüfe ob Bewegung realistisch ist
  bool _isRealisticMovement(double distance, Position position) {
    // Genauigkeitsfilter: verwerfe ungenaue Messungen
    if (position.accuracy > 20.0) return false;

    // Distanzfilter: verwerfe zu große Sprünge
    if (distance > 50.0) return false;

    // Geschwindigkeitsfilter: verwerfe unrealistische Geschwindigkeiten
    if (position.speed > 15.0) return false; // > 54 km/h

    // Minimale Bewegung erforderlich
    if (distance < 0.5) return false;

    return true;
  }

  // Schritt-Tracking starten
  Future<void> _startStepTracking() async {
    print('TrackingServiceV2: Starte Schritt-Tracking...');

    try {
      // Aktivitätserkennung-Berechtigung explizit prüfen
      Permission activityPermission =
          Platform.isIOS ? Permission.sensors : Permission.activityRecognition;

      PermissionStatus status = await activityPermission.status;
      print('TrackingServiceV2: Aktivitäts-Berechtigung Status: $status');

      if (!status.isGranted) {
        print('TrackingServiceV2: Fordere Aktivitäts-Berechtigung an...');
        status = await activityPermission.request();
        print('TrackingServiceV2: Neue Aktivitäts-Berechtigung: $status');
      }

      if (!status.isGranted) {
        print(
            'TrackingServiceV2: Aktivitäts-Berechtigung verweigert - verwende GPS-basierte Schätzung');
        _useGPSStepEstimation = true;
        _stepTrackingEnabled = false;
        return;
      }

      print('TrackingServiceV2: Versuche Pedometer-Stream zu starten...');

      // Test: Erst einmal versuchen, einen einzelnen Wert zu bekommen
      try {
        final testStep =
            await Pedometer.stepCountStream.first.timeout(Duration(seconds: 5));
        print(
            'TrackingServiceV2: Pedometer Test erfolgreich: ${testStep.steps} Schritte');

        // Initiale Schritte setzen
        _initialStepCount = testStep.steps;
        _totalSteps = 0;
        _stepTrackingEnabled = true;

        // Schritt-Stream starten
        _stepCountSubscription = Pedometer.stepCountStream.listen(
          (stepCount) {
            print(
                'TrackingServiceV2: Schritt-Update: ${stepCount.steps} (Basis: $_initialStepCount)');
            _onStepCountUpdate(stepCount);
          },
          onError: (error) {
            print('TrackingServiceV2: Schritt-Stream Fehler: $error');
            _stepTrackingEnabled = false;
            _useGPSStepEstimation = true;
          },
        );

        print('TrackingServiceV2: Pedometer erfolgreich gestartet');
      } catch (e) {
        print('TrackingServiceV2: Pedometer Test fehlgeschlagen: $e');
        _stepTrackingEnabled = false;
        _useGPSStepEstimation = true;
      }
    } catch (e) {
      print(
          'TrackingServiceV2: Kritischer Fehler beim Starten des Schritt-Trackings: $e');
      _stepTrackingEnabled = false;
      _useGPSStepEstimation = true;
    }
  }

  // Schritt-Count Update
  void _onStepCountUpdate(StepCount stepCount) {
    if (!_isTracking || _isPaused || !_stepTrackingEnabled) return;
    if (_initialStepCount == null) return;

    // Berechne neue Schritte seit Tracking-Start
    final newSteps = stepCount.steps - _initialStepCount!;

    // Validierung: Schritte können nur steigen
    if (newSteps >= _totalSteps && newSteps >= 0) {
      _totalSteps = newSteps;
      print('TrackingServiceV2: Schritte aktualisiert: $_totalSteps');
      _notifyUpdate();
    }
  }

  // GPS-basierte Schritt-Schätzung
  void _estimateStepsFromGPS(double distance) {
    // Durchschnittliche Schrittlänge: ca. 0.7 Meter
    final estimatedSteps = (distance / 0.7).round();
    _totalSteps += estimatedSteps;

    if (estimatedSteps > 0) {
      print(
          'TrackingServiceV2: GPS-Schätzung: +$estimatedSteps Schritte (${distance.toStringAsFixed(1)}m)');
    }
  }

  // Update-Timer starten
  void _startUpdateTimer() {
    _trackingTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_isTracking) {
        _notifyUpdate();
      }
    });
  }

  // Update-Benachrichtigung senden
  void _notifyUpdate() {
    _onTrackingUpdate?.call(currentData);
  }

  // Berechtigungen prüfen
  Future<bool> _checkPermissions() async {
    // Standort-Berechtigung
    LocationPermission locationPermission = await Geolocator.checkPermission();
    if (locationPermission == LocationPermission.denied) {
      locationPermission = await Geolocator.requestPermission();
    }

    if (locationPermission == LocationPermission.deniedForever) {
      return false;
    }

    return locationPermission == LocationPermission.whileInUse ||
        locationPermission == LocationPermission.always;
  }

  // Daten zurücksetzen
  void _reset() {
    _trackingStartTime = null;
    _pausedAt = null;
    _pausedDuration = Duration.zero;
    _currentPosition = null;
    _lastValidPosition = null;
    _gpsPoints.clear();
    _totalDistance = 0.0;
    _currentSpeed = 0.0;
    _totalSteps = 0;
    _initialStepCount = null;
    _stepTrackingEnabled = false;
    _useGPSStepEstimation = false;
  }

  // Bestehende Etappe fortsetzen
  void resumeFromEtappe(Etappe etappe) {
    _trackingStartTime = etappe.startzeit;
    _totalSteps = etappe.schrittAnzahl;
    _totalDistance = etappe.gesamtDistanz;
    _gpsPoints = List.from(etappe.gpsPunkte);

    if (_gpsPoints.isNotEmpty) {
      final lastPoint = _gpsPoints.last;
      _lastValidPosition = Position(
        latitude: lastPoint.latitude,
        longitude: lastPoint.longitude,
        timestamp: lastPoint.timestamp,
        accuracy: lastPoint.accuracy ?? 0.0,
        altitude: lastPoint.altitude ?? 0.0,
        altitudeAccuracy: 0.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
      );
    }
  }
}

// Tracking-Daten Klasse
class TrackingData {
  final bool isTracking;
  final bool isPaused;
  final Duration elapsedTime;
  final int totalSteps;
  final double totalDistance;
  final double currentSpeed;
  final Position? currentPosition;
  final List<GPSPunkt> gpsPoints;

  TrackingData({
    required this.isTracking,
    required this.isPaused,
    required this.elapsedTime,
    required this.totalSteps,
    required this.totalDistance,
    required this.currentSpeed,
    this.currentPosition,
    required this.gpsPoints,
  });

  String get formattedElapsedTime {
    final hours = elapsedTime.inHours;
    final minutes = elapsedTime.inMinutes.remainder(60);
    final seconds = elapsedTime.inSeconds.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  String get formattedDistance {
    if (totalDistance < 1000) {
      return '${totalDistance.toStringAsFixed(0)} m';
    } else {
      return '${(totalDistance / 1000).toStringAsFixed(2)} km';
    }
  }

  String get formattedSpeed {
    return '${currentSpeed.toStringAsFixed(1)} km/h';
  }
}

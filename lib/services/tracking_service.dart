import 'dart:async';
import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/etappe.dart';
import 'background_location_service.dart';

class TrackingService {
  static final TrackingService _instance = TrackingService._internal();
  factory TrackingService() => _instance;
  TrackingService._internal();

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

  // Background Service
  final BackgroundLocationService _backgroundService =
      BackgroundLocationService();
  bool _backgroundTrackingEnabled = false;

  // Callbacks
  Function(TrackingData)? _onTrackingUpdate;
  Function(String)? _onError;

  // Getter
  bool get isTracking => _isTracking;
  bool get isPaused => _isPaused;
  bool get backgroundTrackingEnabled => _backgroundTrackingEnabled;
  bool get hasBackgroundPermission =>
      _backgroundService.hasBackgroundPermission;
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
    bool enableBackgroundTracking = true,
  }) async {
    if (_isTracking) return false;

    print('TrackingService: Starte Tracking...');

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

    // Background-Tracking starten falls aktiviert
    if (enableBackgroundTracking) {
      await _startBackgroundTracking();
    }

    // Schritt-Tracking starten
    await _startStepTracking();

    // Update-Timer starten
    _startUpdateTimer();

    print('TrackingService: Tracking erfolgreich gestartet');
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
      print('TrackingService: Tracking fortgesetzt');
    } else {
      // Pausieren
      _isPaused = true;
      _pausedAt = DateTime.now();
      print('TrackingService: Tracking pausiert');
    }

    _notifyUpdate();
  }

  // Tracking stoppen
  Future<TrackingData> stopTracking() async {
    if (!_isTracking) return currentData;

    print('TrackingService: Stoppe Tracking...');

    _isTracking = false;
    _isPaused = false;

    // Alle Subscriptions beenden
    await _positionSubscription?.cancel();
    await _stepCountSubscription?.cancel();
    _trackingTimer?.cancel();

    // Background-Tracking stoppen
    await _stopBackgroundTracking();

    _positionSubscription = null;
    _stepCountSubscription = null;
    _trackingTimer = null;

    final finalData = currentData;

    // Daten zurücksetzen
    _reset();

    print('TrackingService: Tracking gestoppt');
    return finalData;
  }

  // GPS-Tracking starten
  Future<void> _startGPSTracking() async {
    print('TrackingService: Starte GPS-Tracking...');

    try {
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 1, // Meter
        ),
      ).listen(
        _onPositionUpdate,
        onError: (error) {
          print('TrackingService: GPS-Fehler: $error');
          _onError?.call('GPS-Fehler: $error');
        },
      );
    } catch (e) {
      print('TrackingService: Fehler beim Starten des GPS-Trackings: $e');
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
    print('TrackingService: Starte Schritt-Tracking...');

    try {
      // Initiale Schritte abrufen
      final initialSteps = await Pedometer.stepCountStream.first;
      _initialStepCount = initialSteps.steps;

      _totalSteps = 0;

      print('TrackingService: Initiale Schritte: ${_initialStepCount}');

      // Schritt-Stream starten
      _stepCountSubscription = Pedometer.stepCountStream.listen(
        _onStepCountUpdate,
        onError: (error) {
          print('TrackingService: Schritt-Fehler: $error');
          // Schrittzähler-Fehler sind nicht kritisch
        },
      );
    } catch (e) {
      print('TrackingService: Fehler beim Starten des Schritt-Trackings: $e');
      // Schrittzähler ist optional, Tracking kann ohne fortgesetzt werden
    }
  }

  // Schritt-Count Update
  void _onStepCountUpdate(StepCount stepCount) {
    if (!_isTracking || _isPaused) return;
    if (_initialStepCount == null) return;

    // Berechne neue Schritte seit Tracking-Start
    final newSteps = stepCount.steps - _initialStepCount!;

    // Validierung: Schritte können nur steigen
    if (newSteps >= _totalSteps) {
      _totalSteps = newSteps;
      _notifyUpdate();
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

    // Aktivitätserkennung (optional)
    Permission activityPermission =
        Platform.isIOS ? Permission.sensors : Permission.activityRecognition;

    if (!await activityPermission.isGranted) {
      await activityPermission.request();
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

  // Background-Tracking starten
  Future<void> _startBackgroundTracking() async {
    print('TrackingService: Starte Background-Tracking...');

    final success = await _backgroundService.startBackgroundTracking(
      onUpdate: _onBackgroundUpdate,
      onError: _onError,
    );

    _backgroundTrackingEnabled = success;

    if (success) {
      print('TrackingService: Background-Tracking erfolgreich gestartet');
    } else {
      print(
          'TrackingService: Background-Tracking konnte nicht gestartet werden');
    }
  }

  // Background-Tracking stoppen
  Future<void> _stopBackgroundTracking() async {
    if (!_backgroundTrackingEnabled) return;

    print('TrackingService: Stoppe Background-Tracking...');

    // Sammle noch offene Background-Punkte
    final backgroundPoints = _backgroundService.getAndClearBackgroundPoints();
    if (backgroundPoints.isNotEmpty) {
      _gpsPoints.addAll(backgroundPoints);
      print(
          'TrackingService: ${backgroundPoints.length} Background-Punkte hinzugefügt');
    }

    await _backgroundService.stopBackgroundTracking();
    _backgroundTrackingEnabled = false;

    print('TrackingService: Background-Tracking gestoppt');
  }

  // Background GPS-Update Callback
  void _onBackgroundUpdate(List<GPSPunkt> backgroundPoints) {
    if (!_isTracking || backgroundPoints.isEmpty) return;

    print(
        'TrackingService: Background-Update mit ${backgroundPoints.length} Punkten');

    // Neue Background-Punkte zur Hauptliste hinzufügen
    final newPoints = backgroundPoints
        .where((point) => !_gpsPoints.any(
            (existing) => existing.timestamp.isAtSameMomentAs(point.timestamp)))
        .toList();

    if (newPoints.isNotEmpty) {
      _gpsPoints.addAll(newPoints);

      // Distanz neu berechnen
      _recalculateDistance();

      print(
          'TrackingService: ${newPoints.length} neue Background-Punkte hinzugefügt');
      _notifyUpdate();
    }
  }

  // Distanz neu berechnen
  void _recalculateDistance() {
    if (_gpsPoints.length < 2) return;

    double totalDistance = 0.0;
    for (int i = 1; i < _gpsPoints.length; i++) {
      final prev = _gpsPoints[i - 1];
      final current = _gpsPoints[i];

      final distance = Geolocator.distanceBetween(
        prev.latitude,
        prev.longitude,
        current.latitude,
        current.longitude,
      );

      totalDistance += distance;
    }

    _totalDistance = totalDistance;
  }

  // Background-Berechtigung prüfen
  Future<bool> checkBackgroundPermission() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always;
  }

  // Background-Berechtigung anfordern
  Future<bool> requestBackgroundPermission() async {
    final permission = await Geolocator.requestPermission();
    return permission == LocationPermission.always;
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

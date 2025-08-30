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
  Timer? _watchdogTimer;

  // Tracking-Status
  bool _isTracking = false;
  bool _isPaused = false;
  bool _isPausedBySpeed = false; // Pausiert wegen zu hoher Geschwindigkeit
  DateTime? _trackingStartTime;
  DateTime? _pausedAt;
  Duration _pausedDuration = Duration.zero;

  // GPS-Daten
  Position? _currentPosition;
  Position? _lastValidPosition;
  List<GPSPunkt> _gpsPoints = [];
  double _currentSpeed = 0.0;
  DateTime? _lastPositionUpdate;

  // Schritt-Daten
  int _totalSteps = 0;
  int? _initialStepCount;
  bool _stepTrackingEnabled = false;
  bool _useGPSStepEstimation = false;

  // Hybrid-Distanzberechnung
  double _stepBasedDistance = 0.0;
  double _averageStepLength = 0.7; // Startwert: 70cm
  List<double> _recentStepLengths = [];
  int _lastStepCountForDistance = 0;

  // Geschwindigkeits-Überwachung
  static const double _maxWalkingSpeed =
      12.0; // km/h - Grenzwert für Laufen/Wandern
  Function(String, double)?
      _onSpeedWarning; // Callback für Geschwindigkeits-Warnung

  // Callbacks
  Function(TrackingData)? _onTrackingUpdate;
  Function(String)? _onError;

  // Getter
  bool get isTracking => _isTracking;
  bool get isPaused => _isPaused;
  bool get isPausedBySpeed => _isPausedBySpeed;
  TrackingData get currentData => TrackingData(
        isTracking: _isTracking,
        isPaused: _isPaused,
        isPausedBySpeed: _isPausedBySpeed,
        elapsedTime: _getElapsedTime(),
        totalSteps: _totalSteps,
        totalDistance: _stepBasedDistance, // Verwende Schritt-basierte Distanz
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
    Function(String, double)? onSpeedWarning,
  }) async {
    if (_isTracking) return false;

    print('TrackingServiceV2: Starte Tracking...');

    _onTrackingUpdate = onUpdate;
    _onError = onError;
    _onSpeedWarning = onSpeedWarning;

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

    // Watchdog-Timer starten
    _startWatchdogTimer();

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
    _watchdogTimer?.cancel();

    _positionSubscription = null;
    _stepCountSubscription = null;
    _trackingTimer = null;
    _watchdogTimer = null;

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
    if (!_isTracking) return;

    _currentPosition = position;
    _lastPositionUpdate = DateTime.now(); // Watchdog-Zeitstempel

    // Geschwindigkeit berechnen (m/s zu km/h)
    _currentSpeed = (position.speed * 3.6).clamp(0.0, 50.0);

    // Geschwindigkeits-Überwachung
    _checkSpeedAndPause();

    // Wenn pausiert (manuell oder durch Geschwindigkeit), keine GPS-Punkte aufzeichnen
    if (_isPaused) return;

    // GPS-Distanz berechnen für Validierung
    if (_lastValidPosition != null) {
      final gpsDistance = Geolocator.distanceBetween(
        _lastValidPosition!.latitude,
        _lastValidPosition!.longitude,
        position.latitude,
        position.longitude,
      );

      // Filter für realistische Bewegung
      if (_isRealisticMovement(gpsDistance, position)) {
        // Prüfe auf GPS-Lücke und interpoliere falls nötig
        _handleGPSGapAndInterpolation(position, gpsDistance);

        // Hybrid-Distanzberechnung: GPS zur Schrittlängen-Kalibrierung nutzen
        _validateAndCalibrateWithGPS(gpsDistance);

        _lastValidPosition = position;

        // GPS-basierte Schritt-Schätzung falls Pedometer nicht funktioniert
        if (_useGPSStepEstimation) {
          _estimateStepsFromGPS(gpsDistance);
        }
      } else {
        // GPS-Punkt verworfen - prüfe auf längere Lücke
        _handlePoorGPSSignal(position);
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

  // Geschwindigkeits-Überwachung und automatisches Pausieren
  void _checkSpeedAndPause() {
    if (_currentSpeed > _maxWalkingSpeed) {
      // Zu schnell - automatisch pausieren
      if (!_isPausedBySpeed) {
        _isPausedBySpeed = true;
        _isPaused = true;
        _pausedAt = DateTime.now();

        // Warnung senden
        _onSpeedWarning?.call(
            'Achtung: Du bewegst dich zu schnell (${_currentSpeed.toStringAsFixed(1)} km/h). '
            'Tracking wird pausiert - Fahrzeug erkannt.',
            _currentSpeed);

        print(
            'TrackingServiceV2: Tracking pausiert - zu hohe Geschwindigkeit: ${_currentSpeed.toStringAsFixed(1)} km/h');
      }
    } else {
      // Normale Geschwindigkeit - automatisch fortsetzen wenn durch Geschwindigkeit pausiert
      if (_isPausedBySpeed) {
        _isPausedBySpeed = false;
        _isPaused = false;

        // Pausierte Zeit hinzufügen
        if (_pausedAt != null) {
          _pausedDuration += DateTime.now().difference(_pausedAt!);
          _pausedAt = null;
        }

        print(
            'TrackingServiceV2: Tracking fortgesetzt - normale Geschwindigkeit: ${_currentSpeed.toStringAsFixed(1)} km/h');
      }
    }
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
      final stepDifference = newSteps - _totalSteps;
      _totalSteps = newSteps;

      // Schritt-basierte Distanz aktualisieren
      if (stepDifference > 0) {
        _updateStepBasedDistance(stepDifference);
      }

      print(
          'TrackingServiceV2: Schritte aktualisiert: $_totalSteps, Distanz: ${_stepBasedDistance.toStringAsFixed(1)}m');
      _notifyUpdate();
    }
  }

  // GPS-basierte Schritt-Schätzung
  void _estimateStepsFromGPS(double distance) {
    // Durchschnittliche Schrittlänge: ca. 0.7 Meter
    final estimatedSteps = (distance / _averageStepLength).round();
    final stepDifference = estimatedSteps;
    _totalSteps += estimatedSteps;

    // Schritt-basierte Distanz auch bei GPS-Schätzung aktualisieren
    if (stepDifference > 0) {
      _updateStepBasedDistance(stepDifference);
    }

    if (estimatedSteps > 0) {
      print(
          'TrackingServiceV2: GPS-Schätzung: +$estimatedSteps Schritte (${distance.toStringAsFixed(1)}m)');
    }
  }

  // Schritt-basierte Distanz aktualisieren
  void _updateStepBasedDistance(int newSteps) {
    final additionalDistance = newSteps * _averageStepLength;
    _stepBasedDistance += additionalDistance;
    _lastStepCountForDistance = _totalSteps;
  }

  // GPS-Lücken-Behandlung und Interpolation
  DateTime? _lastGPSTime;
  int _poorGPSCount = 0;

  void _handleGPSGapAndInterpolation(Position position, double gpsDistance) {
    final now = DateTime.now();

    // Prüfe auf zeitliche Lücke seit letztem GPS-Punkt
    if (_lastGPSTime != null) {
      final timeSinceLastGPS = now.difference(_lastGPSTime!);

      // Wenn mehr als 30 Sekunden ohne GPS-Punkt und Distanz > 20m
      if (timeSinceLastGPS.inSeconds > 30 && gpsDistance > 20) {
        print(
            'TrackingServiceV2: GPS-Lücke erkannt (${timeSinceLastGPS.inSeconds}s, ${gpsDistance.toStringAsFixed(1)}m)');
        _interpolateGPSGap(position, gpsDistance, timeSinceLastGPS);
      }
    }

    // GPS-Punkt hinzufügen
    _gpsPoints.add(GPSPunkt(
      latitude: position.latitude,
      longitude: position.longitude,
      altitude: position.altitude,
      timestamp: now,
      accuracy: position.accuracy,
    ));

    _lastGPSTime = now;
    _poorGPSCount = 0; // Reset bei erfolgreichem GPS-Punkt
  }

  void _handlePoorGPSSignal(Position position) {
    _poorGPSCount++;

    // Nach 10 verworfenen GPS-Punkten: lockere Filter für Wald-Bedingungen
    if (_poorGPSCount >= 10) {
      print(
          'TrackingServiceV2: Schlechtes GPS-Signal - verwende lockere Filter');

      // Lockere Genauigkeitsfilter für Wald
      if (position.accuracy <= 50.0) {
        // Statt 20m nun 50m
        final distance = _lastValidPosition != null
            ? Geolocator.distanceBetween(
                _lastValidPosition!.latitude,
                _lastValidPosition!.longitude,
                position.latitude,
                position.longitude,
              )
            : 0.0;

        // Lockere Distanzfilter
        if (distance <= 100.0) {
          // Statt 50m nun 100m
          print('TrackingServiceV2: GPS-Punkt mit lockeren Filtern akzeptiert');
          _handleGPSGapAndInterpolation(position, distance);
          _lastValidPosition = position;
          _poorGPSCount = 0;
        }
      }
    }
  }

  void _interpolateGPSGap(
      Position currentPosition, double totalDistance, Duration timeDiff) {
    if (_lastValidPosition == null) return;

    // Berechne Anzahl Interpolationspunkte basierend auf Distanz
    final interpolationPoints =
        (totalDistance / 25).ceil().clamp(1, 5); // Alle 25m ein Punkt, max 5

    print(
        'TrackingServiceV2: Interpoliere ${interpolationPoints} Punkte über ${totalDistance.toStringAsFixed(1)}m');

    for (int i = 1; i < interpolationPoints; i++) {
      final ratio = i / interpolationPoints;

      // Lineare Interpolation zwischen letzter und aktueller Position
      final interpolatedLat = _lastValidPosition!.latitude +
          (currentPosition.latitude - _lastValidPosition!.latitude) * ratio;
      final interpolatedLng = _lastValidPosition!.longitude +
          (currentPosition.longitude - _lastValidPosition!.longitude) * ratio;
      final interpolatedAlt = (_lastValidPosition!.altitude +
          (currentPosition.altitude - _lastValidPosition!.altitude) * ratio);

      // Zeitstempel interpolieren
      final interpolatedTime = _lastGPSTime!.add(
          Duration(milliseconds: (timeDiff.inMilliseconds * ratio).round()));

      // Interpolierten Punkt hinzufügen (markiert als interpoliert)
      _gpsPoints.add(GPSPunkt(
        latitude: interpolatedLat,
        longitude: interpolatedLng,
        altitude: interpolatedAlt,
        timestamp: interpolatedTime,
        accuracy: 999.0, // Spezielle Markierung für interpolierte Punkte
      ));
    }
  }

  // GPS-Validierung und Schrittlängen-Kalibrierung
  void _validateAndCalibrateWithGPS(double gpsDistance) {
    // Nur kalibrieren wenn wir echte Schritte haben (nicht GPS-geschätzt)
    if (!_stepTrackingEnabled || _useGPSStepEstimation) return;

    // Berechne erwartete Distanz basierend auf aktuellen Schritten
    final stepsSinceLastGPS = _totalSteps - _lastStepCountForDistance;
    if (stepsSinceLastGPS <= 0) return;

    final expectedStepDistance = stepsSinceLastGPS * _averageStepLength;

    // Plausibilitätsprüfung: GPS vs Schritt-Distanz
    final deviation = (gpsDistance - expectedStepDistance).abs();
    final deviationPercent = expectedStepDistance > 0
        ? (deviation / expectedStepDistance) * 100
        : 100;

    print(
        'TrackingServiceV2: GPS: ${gpsDistance.toStringAsFixed(1)}m, Schritte: ${expectedStepDistance.toStringAsFixed(1)}m, Abweichung: ${deviationPercent.toStringAsFixed(1)}%');

    if (deviationPercent <= 30.0 && expectedStepDistance > 0) {
      // GPS ist plausibel - zur Schrittlängen-Kalibrierung nutzen
      final measuredStepLength = gpsDistance / stepsSinceLastGPS;

      // Nur realistische Schrittlängen akzeptieren (40cm - 120cm)
      if (measuredStepLength >= 0.4 && measuredStepLength <= 1.2) {
        _calibrateStepLength(measuredStepLength);
        print(
            'TrackingServiceV2: Schrittlänge kalibriert: ${_averageStepLength.toStringAsFixed(2)}m');
      }
    } else {
      print(
          'TrackingServiceV2: GPS verworfen - zu große Abweichung (${deviationPercent.toStringAsFixed(1)}%)');
    }
  }

  // Schrittlängen-Kalibrierung
  void _calibrateStepLength(double measuredStepLength) {
    _recentStepLengths.add(measuredStepLength);

    // Nur die letzten 10 Messungen behalten
    if (_recentStepLengths.length > 10) {
      _recentStepLengths.removeAt(0);
    }

    // Gleitender Durchschnitt für stabilere Kalibrierung
    if (_recentStepLengths.length >= 3) {
      final sum = _recentStepLengths.reduce((a, b) => a + b);
      final newAverage = sum / _recentStepLengths.length;

      // Sanfte Anpassung: 70% alter Wert + 30% neuer Wert
      _averageStepLength = (_averageStepLength * 0.7) + (newAverage * 0.3);
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
    _isPausedBySpeed = false;
    _currentPosition = null;
    _lastValidPosition = null;
    _gpsPoints.clear();
    _currentSpeed = 0.0;
    _totalSteps = 0;
    _initialStepCount = null;
    _stepTrackingEnabled = false;
    _useGPSStepEstimation = false;

    // Hybrid-Distanzberechnung zurücksetzen
    _stepBasedDistance = 0.0;
    _averageStepLength = 0.7; // Zurück zum Standardwert
    _recentStepLengths.clear();
    _lastStepCountForDistance = 0;
  }

  // Bestehende Etappe fortsetzen
  void resumeFromEtappe(Etappe etappe) {
    _trackingStartTime = etappe.startzeit;
    _totalSteps = etappe.schrittAnzahl;
    _gpsPoints = List.from(etappe.gpsPunkte);

    // Schritt-basierte Distanz aus gespeicherten Daten berechnen
    _stepBasedDistance = _totalSteps * _averageStepLength;
    _lastStepCountForDistance = _totalSteps;

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

  // Watchdog-Timer starten
  void _startWatchdogTimer() {
    _watchdogTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      if (!_isTracking) {
        timer.cancel();
        return;
      }

      _checkGPSWatchdog();
    });
  }

  // GPS-Watchdog: Prüft ob GPS-Updates noch ankommen
  void _checkGPSWatchdog() {
    if (_lastPositionUpdate != null) {
      final timeSinceLastUpdate =
          DateTime.now().difference(_lastPositionUpdate!);

      // Wenn länger als 5 Minuten keine GPS-Updates
      if (timeSinceLastUpdate.inMinutes > 5) {
        print(
            'TrackingServiceV2: GPS-Watchdog - Keine Updates seit ${timeSinceLastUpdate.inMinutes} Minuten');
        _onError?.call('GPS-Tracking unterbrochen - versuche Neustart');

        // GPS-Stream neu starten
        _restartGPSStreamInternal();
      }
    }
  }

  // GPS-Stream neu starten (interne Methode)
  Future<void> _restartGPSStreamInternal() async {
    if (!_isTracking) return;

    try {
      print('TrackingServiceV2: Starte GPS-Stream neu...');

      // Alten Stream stoppen
      await _positionSubscription?.cancel();
      _positionSubscription = null;

      // Kurze Pause
      await Future.delayed(Duration(milliseconds: 2000));

      // GPS-Stream neu starten
      await _startGPSTracking();

      print('TrackingServiceV2: GPS-Stream erfolgreich neu gestartet');
    } catch (e) {
      print('TrackingServiceV2: Fehler beim Neustart des GPS-Streams: $e');
      _onError?.call('GPS-Stream konnte nicht neu gestartet werden: $e');
    }
  }
}

// Tracking-Daten Klasse
class TrackingData {
  final bool isTracking;
  final bool isPaused;
  final bool isPausedBySpeed;
  final Duration elapsedTime;
  final int totalSteps;
  final double totalDistance;
  final double currentSpeed;
  final Position? currentPosition;
  final List<GPSPunkt> gpsPoints;

  TrackingData({
    required this.isTracking,
    required this.isPaused,
    this.isPausedBySpeed = false,
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

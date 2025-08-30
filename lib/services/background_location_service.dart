import 'dart:async';
import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/etappe.dart';

class BackgroundLocationService {
  static final BackgroundLocationService _instance =
      BackgroundLocationService._internal();
  factory BackgroundLocationService() => _instance;
  BackgroundLocationService._internal();

  // Streams und Subscriptions
  StreamSubscription<Position>? _positionSubscription;
  Timer? _backgroundTimer;

  // Tracking-Status
  bool _isBackgroundTracking = false;
  bool _hasBackgroundPermission = false;

  // GPS-Daten
  Position? _lastPosition;
  List<GPSPunkt> _backgroundGpsPoints = [];
  DateTime? _lastPositionUpdate;

  // Callbacks
  Function(List<GPSPunkt>)? _onBackgroundUpdate;
  Function(String)? _onError;

  // Getter
  bool get isBackgroundTracking => _isBackgroundTracking;
  bool get hasBackgroundPermission => _hasBackgroundPermission;
  List<GPSPunkt> get backgroundGpsPoints =>
      List.unmodifiable(_backgroundGpsPoints);

  // Background-Tracking starten
  Future<bool> startBackgroundTracking({
    Function(List<GPSPunkt>)? onUpdate,
    Function(String)? onError,
  }) async {
    print('BackgroundLocationService: Starte Background-Tracking...');

    _onBackgroundUpdate = onUpdate;
    _onError = onError;

    // Berechtigungen prüfen
    if (!await _checkBackgroundPermissions()) {
      _onError?.call('Background-Location-Berechtigungen nicht verfügbar');
      return false;
    }

    _isBackgroundTracking = true;

    // GPS-Stream für Background-Tracking starten
    await _startBackgroundGPSTracking();

    // Zusätzlicher Timer für regelmäßige Updates
    _startBackgroundTimer();

    print('BackgroundLocationService: Background-Tracking gestartet');
    return true;
  }

  // Background-Tracking stoppen
  Future<void> stopBackgroundTracking() async {
    if (!_isBackgroundTracking) return;

    print('BackgroundLocationService: Stoppe Background-Tracking...');

    _isBackgroundTracking = false;

    // Alle Subscriptions beenden
    await _positionSubscription?.cancel();
    _backgroundTimer?.cancel();

    _positionSubscription = null;
    _backgroundTimer = null;

    print('BackgroundLocationService: Background-Tracking gestoppt');
  }

  // Background GPS-Tracking starten
  Future<void> _startBackgroundGPSTracking() async {
    try {
      // Spezielle Einstellungen für Background-Tracking
      LocationSettings locationSettings;

      if (Platform.isIOS) {
        locationSettings = AppleSettings(
          accuracy: LocationAccuracy.high,
          activityType: ActivityType.fitness,
          distanceFilter: 5,
          pauseLocationUpdatesAutomatically: false,
          showBackgroundLocationIndicator: true,
        );
      } else {
        locationSettings = AndroidSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
          forceLocationManager: false,
          intervalDuration: const Duration(seconds: 10),
          foregroundNotificationConfig: const ForegroundNotificationConfig(
            notificationText: "Mein Weg verfolgt Ihre Etappe im Hintergrund",
            notificationTitle: "GPS-Tracking aktiv",
            enableWakeLock: true,
          ),
        );
      }

      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        _onBackgroundPositionUpdate,
        onError: (error) {
          print('BackgroundLocationService: GPS-Fehler: $error');
          _onError?.call('Background GPS-Fehler: $error');
        },
      );
    } catch (e) {
      print('BackgroundLocationService: Fehler beim Starten: $e');
      _onError
          ?.call('Background GPS-Tracking konnte nicht gestartet werden: $e');
    }
  }

  // Background GPS-Position Update
  void _onBackgroundPositionUpdate(Position position) {
    if (!_isBackgroundTracking) return;

    print(
        'BackgroundLocationService: Neue Position - Lat: ${position.latitude}, Lng: ${position.longitude}, Accuracy: ${position.accuracy}');

    // Erweiterte Filter für bessere Robustheit
    if (!_isValidPosition(position)) {
      return;
    }

    // Prüfe realistische Bewegung
    if (_lastPosition != null) {
      final distance = Geolocator.distanceBetween(
        _lastPosition!.latitude,
        _lastPosition!.longitude,
        position.latitude,
        position.longitude,
      );

      // Dynamische Filter basierend auf Zeit seit letztem Update
      if (!_isRealisticMovement(distance, position)) {
        return;
      }
    }

    // GPS-Punkt hinzufügen
    final gpsPoint = GPSPunkt(
      latitude: position.latitude,
      longitude: position.longitude,
      altitude: position.altitude,
      timestamp: DateTime.now(),
      accuracy: position.accuracy,
    );

    _backgroundGpsPoints.add(gpsPoint);
    _lastPosition = position;
    _lastPositionUpdate = DateTime.now(); // Watchdog-Zeitstempel

    // Callback aufrufen
    _onBackgroundUpdate?.call(_backgroundGpsPoints);

    print(
        'BackgroundLocationService: GPS-Punkt hinzugefügt - Total: ${_backgroundGpsPoints.length}');
  }

  // Validiere GPS-Position
  bool _isValidPosition(Position position) {
    // Basis-Genauigkeitsfilter (weniger strikt für Background)
    if (position.accuracy > 50.0) {
      print(
          'BackgroundLocationService: Position verworfen - schlechte Genauigkeit: ${position.accuracy}m');
      return false;
    }

    // Prüfe auf gültige Koordinaten
    if (position.latitude.abs() > 90.0 || position.longitude.abs() > 180.0) {
      print(
          'BackgroundLocationService: Position verworfen - ungültige Koordinaten');
      return false;
    }

    return true;
  }

  // Prüfe realistische Bewegung (erweiterte Logik)
  bool _isRealisticMovement(double distance, Position position) {
    if (_lastPosition == null) return true;

    final lastTimestamp = _lastPosition!.timestamp ?? DateTime.now();
    final timeDiff = DateTime.now().difference(lastTimestamp);
    final timeDiffSeconds = timeDiff.inSeconds.clamp(1, 3600); // Min 1s, Max 1h

    // Berechne maximale realistische Geschwindigkeit (m/s)
    final maxSpeedMps = 20.0; // 72 km/h - großzügiger für Background
    final maxDistanceForTime = maxSpeedMps * timeDiffSeconds;

    // Filter für unrealistische Sprünge (basierend auf Zeit)
    if (distance > maxDistanceForTime) {
      print(
          'BackgroundLocationService: Position verworfen - zu großer Sprung: ${distance}m in ${timeDiffSeconds}s (max: ${maxDistanceForTime}m)');
      return false;
    }

    // Minimale Bewegung erforderlich (weniger strikt für Background)
    if (distance < 1.0 && timeDiffSeconds < 30) {
      print(
          'BackgroundLocationService: Position verworfen - zu kleine Bewegung: ${distance}m in ${timeDiffSeconds}s');
      return false;
    }

    return true;
  }

  // Background Timer für regelmäßige Updates und Watchdog
  void _startBackgroundTimer() {
    _backgroundTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (!_isBackgroundTracking) {
        timer.cancel();
        return;
      }

      print(
          'BackgroundLocationService: Timer-Update - ${_backgroundGpsPoints.length} Punkte gesammelt');

      // Watchdog: Prüfe ob GPS-Updates noch ankommen
      _checkGPSWatchdog();

      // Regelmäßige Position abfragen falls Stream nicht funktioniert
      _getCurrentPositionFallback();
    });
  }

  // GPS-Watchdog: Prüft ob GPS-Updates noch ankommen
  void _checkGPSWatchdog() {
    if (_lastPositionUpdate != null) {
      final timeSinceLastUpdate =
          DateTime.now().difference(_lastPositionUpdate!);

      // Wenn länger als 3 Minuten keine GPS-Updates
      if (timeSinceLastUpdate.inMinutes > 3) {
        print(
            'BackgroundLocationService: GPS-Watchdog - Keine Updates seit ${timeSinceLastUpdate.inMinutes} Minuten');
        _onError?.call('GPS-Tracking unterbrochen - versuche Neustart');

        // GPS-Stream neu starten
        _restartGPSStream();
      }
    }
  }

  // GPS-Stream neu starten
  Future<void> _restartGPSStream() async {
    try {
      print('BackgroundLocationService: Starte GPS-Stream neu...');

      // Alten Stream stoppen
      await _positionSubscription?.cancel();
      _positionSubscription = null;

      // Kurze Pause
      await Future.delayed(Duration(milliseconds: 2000));

      // GPS-Stream neu starten
      await _startBackgroundGPSTracking();

      print('BackgroundLocationService: GPS-Stream erfolgreich neu gestartet');
    } catch (e) {
      print(
          'BackgroundLocationService: Fehler beim Neustart des GPS-Streams: $e');
      _onError?.call('GPS-Stream konnte nicht neu gestartet werden: $e');
    }
  }

  // Fallback für Position abrufen
  Future<void> _getCurrentPositionFallback() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      _onBackgroundPositionUpdate(position);
    } catch (e) {
      print('BackgroundLocationService: Fallback Position-Fehler: $e');
    }
  }

  // Background-Berechtigungen prüfen
  Future<bool> _checkBackgroundPermissions() async {
    // Basis Location-Berechtigung
    LocationPermission locationPermission = await Geolocator.checkPermission();

    if (locationPermission == LocationPermission.denied) {
      locationPermission = await Geolocator.requestPermission();
    }

    if (locationPermission == LocationPermission.deniedForever) {
      print(
          'BackgroundLocationService: Location-Berechtigung dauerhaft verweigert');
      return false;
    }

    // Für Background-Tracking benötigen wir "Always" Permission
    if (locationPermission != LocationPermission.always) {
      print(
          'BackgroundLocationService: Versuche Always-Permission zu erhalten...');

      // Auf Android müssen wir zuerst "When in Use" haben, dann "Always" anfragen
      if (Platform.isAndroid &&
          locationPermission == LocationPermission.whileInUse) {
        final backgroundPermission = await Permission.locationAlways.request();
        _hasBackgroundPermission = backgroundPermission.isGranted;
      } else if (Platform.isIOS) {
        // Auf iOS automatisch nach Always fragen
        locationPermission = await Geolocator.requestPermission();
        _hasBackgroundPermission =
            locationPermission == LocationPermission.always;
      }
    } else {
      _hasBackgroundPermission = true;
    }

    print(
        'BackgroundLocationService: Background-Permission: $_hasBackgroundPermission');
    return _hasBackgroundPermission;
  }

  // GPS-Punkte abrufen und zurücksetzen
  List<GPSPunkt> getAndClearBackgroundPoints() {
    final points = List<GPSPunkt>.from(_backgroundGpsPoints);
    _backgroundGpsPoints.clear();
    print(
        'BackgroundLocationService: ${points.length} Punkte abgerufen und gelöscht');
    return points;
  }

  // Service-Status prüfen
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  // Berechtigung-Status abrufen
  Future<LocationPermission> getPermissionStatus() async {
    return await Geolocator.checkPermission();
  }
}

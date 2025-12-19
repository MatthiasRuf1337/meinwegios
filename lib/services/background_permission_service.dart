import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class BackgroundPermissionService {
  static final BackgroundPermissionService _instance =
      BackgroundPermissionService._internal();
  factory BackgroundPermissionService() => _instance;
  BackgroundPermissionService._internal();

  // Prüft ob Background-Location-Berechtigung verfügbar ist
  Future<bool> hasBackgroundLocationPermission() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always;
  }

  // Zeigt Dialog für Background-Berechtigung an
  Future<bool> requestBackgroundLocationWithDialog(BuildContext context) async {
    // Erst prüfen ob schon vorhanden
    if (await hasBackgroundLocationPermission()) {
      return true;
    }

    // Dialog anzeigen
    final shouldRequest = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildPermissionDialog(context),
    );

    if (shouldRequest == true) {
      return await _requestBackgroundPermission();
    }

    return false;
  }

  // Dialog für Background-Berechtigung
  Widget _buildPermissionDialog(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.location_on, color: Color(0xFF5A7D7D)),
          SizedBox(width: 8),
          Text('Live-Aufzeichnung aktivieren'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Für die Live-Aufzeichnung Ihrer Route benötigt die App Zugriff auf Ihren Standort, auch wenn die App im Hintergrund läuft.',
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📱 Was passiert als nächstes:',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.blue.shade700),
                ),
                SizedBox(height: 8),
                Text(
                  '1. Wählen Sie "Immer" in den Einstellungen\n'
                  '2. Dies ermöglicht Live-Tracking auch bei Telefonaten\n'
                  '3. Ihre Route wird kontinuierlich aufgezeichnet',
                  style: TextStyle(color: Colors.blue.shade700),
                ),
              ],
            ),
          ),
          SizedBox(height: 12),
          Text(
            '🔒 Ihre Daten bleiben privat und werden nur lokal auf Ihrem Gerät gespeichert.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text('Später'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF5A7D7D),
            foregroundColor: Colors.white,
          ),
          child: Text('Berechtigung erteilen'),
        ),
      ],
    );
  }

  // Berechtigung anfordern
  Future<bool> _requestBackgroundPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();

      // Schritt 1: "When in Use" Berechtigung
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        print('Location-Berechtigung dauerhaft verweigert');
        return false;
      }

      // Schritt 2: "Always" Berechtigung anfordern
      if (permission == LocationPermission.whileInUse) {
        if (Platform.isAndroid) {
          // Android: Explizit "Always" anfordern
          final backgroundPermission =
              await Permission.locationAlways.request();
          return backgroundPermission.isGranted;
        } else if (Platform.isIOS) {
          // iOS: Nochmal anfordern - iOS zeigt dann "Always" Option
          permission = await Geolocator.requestPermission();
          return permission == LocationPermission.always;
        }
      }

      return permission == LocationPermission.always;
    } catch (e) {
      print('Fehler beim Anfordern der Background-Berechtigung: $e');
      return false;
    }
  }

  // Status-Text für UI
  String getPermissionStatusText() {
    return 'Für Live-Aufzeichnung auch bei Telefonaten benötigt die App Hintergrund-Standort-Zugriff.';
  }

  // Zeigt Einstellungen-Dialog wenn Berechtigung verweigert
  Future<void> showSettingsDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.location_on, color: Color(0xFF5A7D7D)),
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
          'Bitte aktivieren Sie in den Einstellungen die Standort-Berechtigung "Immer" für die Live-Aufzeichnung.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: Text('Einstellungen öffnen'),
          ),
        ],
      ),
    );
  }
}

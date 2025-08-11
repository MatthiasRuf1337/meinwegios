import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'dart:async';
import '../providers/etappen_provider.dart';
import '../models/etappe.dart';
import '../services/permission_service.dart';
import 'etappe_tracking_screen.dart';

class EtappeStartScreen extends StatefulWidget {
  @override
  _EtappeStartScreenState createState() => _EtappeStartScreenState();
}

class _EtappeStartScreenState extends State<EtappeStartScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _notizenController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Etappe starten'),
        backgroundColor: Color(0xFF00847E),
        foregroundColor: Colors.white,
      ),
      body: Consumer<EtappenProvider>(
        builder: (context, etappenProvider, child) {
          // Wenn bereits eine Etappe aktiv ist, zeige Tracking-Screen
          if (etappenProvider.hatAktuelleEtappe) {
            return EtappeTrackingScreen(
                etappe: etappenProvider.aktuelleEtappe!);
          }

          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                _buildHeader(),
                SizedBox(height: 24),

                // Formular
                _buildForm(),
                SizedBox(height: 24),

                // Buttons
                _buildButtons(etappenProvider),
                SizedBox(height: 24),

                // Letzte Etappen
                _buildRecentEtappen(etappenProvider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF00847E).withOpacity(0.1),
            Color(0xFF00847E).withOpacity(0.2)
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            Icons.directions_walk,
            size: 48,
            color: Color(0xFF00847E),
          ),
          SizedBox(height: 12),
          Text(
            'Neue Etappe starten',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF00847E),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Erstelle eine neue Etappe und beginne mit dem Tracking',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF00847E).withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Etappen-Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16),

        // Name
        TextField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Etappen-Name *',
            hintText: 'z.B. Wanderung zum Gipfel',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.edit),
          ),
        ),
        SizedBox(height: 16),

        // Notizen
        TextField(
          controller: _notizenController,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Notizen (optional)',
            hintText: 'Zusätzliche Informationen zur Etappe...',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.note),
          ),
        ),
      ],
    );
  }

  Widget _buildButtons(EtappenProvider provider) {
    return Column(
      children: [
        // Live-Tracking starten
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : () => _startLiveTracking(provider),
            icon: Icon(Icons.play_arrow),
            label: Text(
              'Live-Tracking starten',
              style: TextStyle(fontSize: 16),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF00847E),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        SizedBox(height: 12),

        // Manuelle Etappe erstellen
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isLoading ? null : () => _createManualEtappe(provider),
            icon: Icon(Icons.add),
            label: Text(
              'Manuelle Etappe erstellen',
              style: TextStyle(fontSize: 16),
            ),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        SizedBox(height: 12),

        // Berechtigungen zurücksetzen (für permanent verweigerte)
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : () => _resetAndRequestPermissions(),
            icon: Icon(Icons.refresh),
            label: Text(
              'Berechtigungen zurücksetzen',
              style: TextStyle(fontSize: 16),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        SizedBox(height: 12),

        // Berechtigungen anfordern
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed:
                _isLoading ? null : () => _requestMissingPermissionsFirst(),
            icon: Icon(Icons.security),
            label: Text(
              'Berechtigungen anfordern (iOS-Dialoge)',
              style: TextStyle(fontSize: 16),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        SizedBox(height: 12),

        // Einstellungen öffnen
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isLoading ? null : () => _enablePermissionsInSettings(),
            icon: Icon(Icons.settings),
            label: Text(
              'Einstellungen öffnen',
              style: TextStyle(fontSize: 16),
            ),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        SizedBox(height: 12),
      ],
    );
  }

  Widget _buildRecentEtappen(EtappenProvider provider) {
    final recentEtappen = provider.etappen.take(3).toList();

    if (recentEtappen.isEmpty) {
      return SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Letzte Etappen',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12),
        ...recentEtappen.map((etappe) => _buildRecentEtappeCard(etappe)),
      ],
    );
  }

  Widget _buildRecentEtappeCard(Etappe etappe) {
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Color(0xFF00847E).withOpacity(0.2),
          child: Icon(Icons.directions_walk, color: Color(0xFF00847E)),
        ),
        title: Text(etappe.name),
        subtitle: Text(
          '${etappe.formatierteDistanz} • ${etappe.formatierteDauer} • ${etappe.schrittAnzahl} Schritte',
          style: TextStyle(fontSize: 12),
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => _openEtappeDetail(etappe),
      ),
    );
  }

  Future<void> _startLiveTracking(EtappenProvider provider) async {
    if (_nameController.text.trim().isEmpty) {
      _showErrorDialog('Bitte gib einen Namen für die Etappe ein.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Berechtigungen prüfen
      bool locationPermission =
          await PermissionService.checkLocationPermission();
      bool activityPermission =
          await PermissionService.checkActivityRecognitionPermission();

      if (!locationPermission || !activityPermission) {
        await _requestMissingPermissions();
        return;
      }

      // Neue Etappe erstellen
      final etappe = Etappe(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        startzeit: DateTime.now(),
        status: EtappenStatus.aktiv,
        notizen: _notizenController.text.trim().isEmpty
            ? null
            : _notizenController.text.trim(),
        erstellungsDatum: DateTime.now(),
      );

      await provider.addEtappe(etappe);
      provider.startEtappe(etappe);

      // Formular zurücksetzen
      _nameController.clear();
      _notizenController.clear();
    } catch (e) {
      _showErrorDialog('Fehler beim Starten der Etappe: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createManualEtappe(EtappenProvider provider) async {
    if (_nameController.text.trim().isEmpty) {
      _showErrorDialog('Bitte gib einen Namen für die Etappe ein.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final etappe = Etappe(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        startzeit: DateTime.now(),
        endzeit: DateTime.now(),
        status: EtappenStatus.abgeschlossen,
        notizen: _notizenController.text.trim().isEmpty
            ? null
            : _notizenController.text.trim(),
        erstellungsDatum: DateTime.now(),
      );

      await provider.addEtappe(etappe);

      // Formular zurücksetzen
      _nameController.clear();
      _notizenController.clear();

      _showSuccessDialog('Etappe erfolgreich erstellt!');
    } catch (e) {
      _showErrorDialog('Fehler beim Erstellen der Etappe: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _requestMissingPermissions() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Berechtigungen erforderlich'),
        content: Text(
          'Für das Live-Tracking werden Standort- und Aktivitätsberechtigungen benötigt. '
          'Bitte erlaube diese in den App-Einstellungen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: Text('Einstellungen öffnen'),
          ),
        ],
      ),
    );
  }

  // Force request permissions (ignores permanently denied status)
  Future<void> _forceRequestPermissions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('Force request permissions...');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Berechtigungen werden angefordert...'),
          duration: Duration(seconds: 3),
        ),
      );

      final locPerm =
          Platform.isIOS ? Permission.locationWhenInUse : Permission.location;
      final fitnessPerm =
          Platform.isIOS ? Permission.sensors : Permission.activityRecognition;

      print('Force request Standort...');
      await locPerm.request();
      await Future.delayed(Duration(milliseconds: 1000));

      print('Force request Aktivität/Bewegung...');
      await fitnessPerm.request();
      await Future.delayed(Duration(milliseconds: 1000));

      print('Force request Kamera...');
      await Permission.camera.request();
      await Future.delayed(Duration(milliseconds: 1000));

      if (!Platform.isIOS) {
        print('Force request Speicher...');
        await Permission.storage.request();
        await Future.delayed(Duration(milliseconds: 1000));
      }

      print('Force request Fotos...');
      await Permission.photos.request();

      // Prüfe Status nach Anfrage
      PermissionStatus locationStatus = await locPerm.status;
      PermissionStatus activityStatus = await fitnessPerm.status;
      PermissionStatus cameraStatus = await Permission.camera.status;

      String resultMessage = 'Berechtigungsstatus nach Anfrage:\n\n';
      resultMessage +=
          '📍 Standort: ${locationStatus.isGranted ? "✓" : "✗"} (${locationStatus})\n';
      resultMessage +=
          '🚶 Aktivität/Bewegung: ${activityStatus.isGranted ? "✓" : "✗"} (${activityStatus})\n';
      resultMessage +=
          '📷 Kamera: ${cameraStatus.isGranted ? "✓" : "✗"} (${cameraStatus})\n\n';

      if (locationStatus.isGranted ||
          activityStatus.isGranted ||
          cameraStatus.isGranted) {
        resultMessage += 'Gut! Einige Berechtigungen wurden erteilt.';
      } else {
        resultMessage +=
            'Keine Berechtigungen erteilt. Die App funktioniert mit eingeschränkter Funktionalität.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Berechtigungsanfrage abgeschlossen'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Berechtigungen'),
            content: Text(resultMessage),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Verstanden'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print('Fehler bei Force Request: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Manuelle Berechtigungsaktivierung in iOS-Einstellungen
  Future<void> _enablePermissionsInSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('Führe zu iOS-Einstellungen...');

      // Zeige Anleitung
      bool shouldOpenSettings = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: Text('Berechtigungen aktivieren'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Die Berechtigungen müssen manuell in den iOS-Einstellungen aktiviert werden:\n',
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 12),
                  Text(
                    '1. Öffne die Einstellungen\n'
                    '2. Scrolle zu "MeinWeg"\n'
                    '3. Aktiviere die Berechtigungen:\n'
                    '   • Standort: "Während der Nutzung"\n'
                    '   • Aktivitätserkennung: Aktivieren\n'
                    '   • Kamera: Aktivieren\n'
                    '   • Fotos: "Alle Fotos"\n'
                    '4. Starte die App neu',
                    style: TextStyle(fontSize: 14),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Möchtest du jetzt zu den Einstellungen?',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text('Später'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF00847E),
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Einstellungen öffnen'),
                ),
              ],
            ),
          ) ??
          false;

      if (shouldOpenSettings) {
        print('Öffne iOS-Einstellungen...');
        await openAppSettings();

        // Zeige Nachricht nach Rückkehr
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Nach der Aktivierung: App neu starten'),
              backgroundColor: Colors.blue,
              duration: Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      print('Fehler beim Öffnen der Einstellungen: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Berechtigungen wirklich anfordern (vor Einstellungen)
  Future<void> _requestMissingPermissionsFirst() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('Fordere fehlende Berechtigungen an...');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Berechtigungen werden angefordert...'),
          duration: Duration(seconds: 3),
        ),
      );

      final locPerm =
          Platform.isIOS ? Permission.locationWhenInUse : Permission.location;
      final fitnessPerm =
          Platform.isIOS ? Permission.sensors : Permission.activityRecognition;

      print('Fordere Standort-Berechtigung an...');
      PermissionStatus locationStatus = await locPerm.request();
      print('Standort-Status: $locationStatus');

      await Future.delayed(Duration(milliseconds: 1000));

      print('Fordere Aktivität/Bewegung-Berechtigung an...');
      PermissionStatus activityStatus = await fitnessPerm.request();
      print('Aktivität/Bewegung-Status: $activityStatus');

      await Future.delayed(Duration(milliseconds: 1000));

      print('Fordere Kamera-Berechtigung an...');
      PermissionStatus cameraStatus = await Permission.camera.request();
      print('Kamera-Status: $cameraStatus');

      await Future.delayed(Duration(milliseconds: 1000));

      if (!Platform.isIOS) {
        print('Fordere Speicher-Berechtigung an...');
        await Permission.storage.request();
        await Future.delayed(Duration(milliseconds: 1000));
      }

      print('Fordere Fotos-Berechtigung an...');
      PermissionStatus photosStatus = await Permission.photos.request();
      print('Fotos-Status: $photosStatus');

      // iOS: Falls weiterhin keine Dialoge kamen, triggere die System-Dialoge durch echte API-Zugriffe
      if (Platform.isIOS &&
          (!locationStatus.isGranted || !activityStatus.isGranted)) {
        try {
          print('Versuche iOS-Dialoge durch echte API-Aufrufe zu triggern...');
          // Standort durch echten Positionsabruf triggern
          if (!locationStatus.isGranted) {
            try {
              await Geolocator.getCurrentPosition(
                      desiredAccuracy: LocationAccuracy.high)
                  .timeout(Duration(seconds: 5));
            } catch (_) {}
            locationStatus = await locPerm.status;
            print('Standort-Status nach API-Trigger: $locationStatus');
          }
          // Bewegung & Fitness durch Pedometer-Stream triggern
          if (!activityStatus.isGranted) {
            StreamSubscription<StepCount>? sub;
            try {
              sub = Pedometer.stepCountStream.listen((_) {});
              await Future.delayed(Duration(seconds: 2));
            } catch (_) {
            } finally {
              await sub?.cancel();
            }
            activityStatus = await fitnessPerm.status;
            print(
                'Aktivität/Bewegung-Status nach API-Trigger: $activityStatus');
          }
        } catch (e) {
          print('Fehler beim Triggern der System-Dialoge: $e');
        }
      }

      // Zeige Ergebnis
      String resultMessage = 'Berechtigungsanfrage abgeschlossen:\n\n';
      resultMessage +=
          '📍 Standort: ${locationStatus.isGranted ? "✓" : "✗"} (${locationStatus})\n';
      resultMessage +=
          '🚶 Aktivität/Bewegung: ${activityStatus.isGranted ? "✓" : "✗"} (${activityStatus})\n';
      resultMessage +=
          '📷 Kamera: ${cameraStatus.isGranted ? "✓" : "✗"} (${cameraStatus})\n';
      resultMessage +=
          '🖼️ Fotos: ${photosStatus.isGranted ? "✓" : "✗"} (${photosStatus})\n\n';

      if (locationStatus.isGranted && activityStatus.isGranted) {
        resultMessage +=
            'Perfekt! Alle wichtigen Berechtigungen wurden erteilt.';
      } else {
        resultMessage += 'Einige Berechtigungen wurden verweigert.\n\n';
        resultMessage +=
            'Jetzt sollten alle Berechtigungen in den iOS-Einstellungen unter "MeinWeg" erscheinen.\n\n';
        resultMessage +=
            'Möchtest du zu den Einstellungen, um die verweigerten Berechtigungen zu aktivieren?';
      }

      if (mounted) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Berechtigungen'),
            content: SingleChildScrollView(
              child: Text(resultMessage),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Schließen'),
              ),
              if (!locationStatus.isGranted || !activityStatus.isGranted)
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    openAppSettings();
                  },
                  child: Text('Einstellungen öffnen'),
                ),
            ],
          ),
        );
      }
    } catch (e) {
      print('Fehler bei Berechtigungsanfrage: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Berechtigungen zurücksetzen und neu anfordern
  Future<void> _resetAndRequestPermissions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('Setze Berechtigungen zurück und fordere neu an...');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Berechtigungen werden zurückgesetzt...'),
          duration: Duration(seconds: 3),
        ),
      );

      // Versuche Berechtigungen zurückzusetzen
      print('Versuche Berechtigungen zurückzusetzen...');

      // Für iOS: Versuche openAppSettings() um manuell zurückzusetzen
      bool shouldReset = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: Text('Berechtigungen zurücksetzen'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Die Berechtigungen sind als "permanent verweigert" markiert.\n\n',
                    style: TextStyle(fontSize: 16),
                  ),
                  Text(
                    'Um sie zurückzusetzen:\n\n'
                    '1. Öffne die Einstellungen\n'
                    '2. Gehe zu "MeinWeg"\n'
                    '3. Setze alle Berechtigungen auf "Nie" zurück\n'
                    '4. Komme zurück zur App\n'
                    '5. Klicke "Berechtigungen neu anfordern"\n\n'
                    'Möchtest du jetzt zu den Einstellungen?',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text('Abbrechen'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Einstellungen öffnen'),
                ),
              ],
            ),
          ) ??
          false;

      if (shouldReset) {
        print('Öffne Einstellungen zum Zurücksetzen...');
        await openAppSettings();

        // Warte auf Rückkehr und fordere dann neu an
        if (mounted) {
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Berechtigungen zurücksetzen'),
              content: Text(
                'Nach dem Zurücksetzen in den Einstellungen:\n\n'
                '1. Komme zurück zur App\n'
                '2. Klicke "Berechtigungen neu anfordern"\n'
                '3. Bestätige die iOS-Dialoge\n\n'
                'Bist du zurück aus den Einstellungen?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Nein, noch nicht'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _requestPermissionsAfterReset();
                  },
                  child: Text('Ja, jetzt anfordern'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      print('Fehler beim Zurücksetzen: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Berechtigungen nach Reset anfordern
  Future<void> _requestPermissionsAfterReset() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('Fordere Berechtigungen nach Reset an...');

      // Prüfe zuerst den aktuellen Status
      print('Prüfe aktuellen Berechtigungsstatus...');
      final locPerm =
          Platform.isIOS ? Permission.locationWhenInUse : Permission.location;
      final fitnessPerm =
          Platform.isIOS ? Permission.sensors : Permission.activityRecognition;
      PermissionStatus locationStatus = await locPerm.status;
      PermissionStatus activityStatus = await fitnessPerm.status;
      PermissionStatus cameraStatus = await Permission.camera.status;
      PermissionStatus photosStatus = await Permission.photos.status;

      print('Aktueller Status:');
      print('- Standort: $locationStatus');
      print('- Aktivität/Bewegung: $activityStatus');
      print('- Kamera: $cameraStatus');
      print('- Fotos: $photosStatus');

      // Wenn noch permanent verweigert, versuche direkte Anfrage
      if (locationStatus == PermissionStatus.permanentlyDenied ||
          locationStatus.isDenied) {
        print('Standort ist verweigert - versuche direkte Anfrage...');
        locationStatus = await locPerm.request();
        print('Neuer Standort-Status: $locationStatus');
      }

      if (activityStatus == PermissionStatus.permanentlyDenied ||
          activityStatus.isDenied) {
        print(
            'Aktivität/Bewegung ist verweigert - versuche direkte Anfrage...');
        activityStatus = await fitnessPerm.request();
        print('Neuer Aktivität/Bewegung-Status: $activityStatus');
      }

      if (cameraStatus == PermissionStatus.permanentlyDenied ||
          cameraStatus.isDenied) {
        print('Kamera ist verweigert - versuche direkte Anfrage...');
        cameraStatus = await Permission.camera.request();
        print('Neuer Kamera-Status: $cameraStatus');
      }

      if (photosStatus == PermissionStatus.permanentlyDenied ||
          photosStatus.isDenied) {
        print('Fotos ist verweigert - versuche direkte Anfrage...');
        photosStatus = await Permission.photos.request();
        print('Neuer Fotos-Status: $photosStatus');
      }

      // Zeige Ergebnis
      String resultMessage = 'Berechtigungsstatus nach Reset:\n\n';
      resultMessage +=
          '📍 Standort: ${locationStatus.isGranted ? "✓" : "✗"} (${locationStatus})\n';
      resultMessage +=
          '🚶 Aktivität/Bewegung: ${activityStatus.isGranted ? "✓" : "✗"} (${activityStatus})\n';
      resultMessage +=
          '📷 Kamera: ${cameraStatus.isGranted ? "✓" : "✗"} (${cameraStatus})\n';
      resultMessage +=
          '🖼️ Fotos: ${photosStatus.isGranted ? "✓" : "✗"} (${photosStatus})\n\n';

      if (locationStatus.isGranted && activityStatus.isGranted) {
        resultMessage +=
            '✅ Perfekt! Alle wichtigen Berechtigungen wurden erteilt.';
      } else if (locationStatus == PermissionStatus.denied ||
          activityStatus == PermissionStatus.denied) {
        resultMessage +=
            '⚠️ Einige Berechtigungen wurden verweigert, aber nicht permanent.\n\n';
        resultMessage += 'Versuche es erneut mit "Berechtigungen anfordern".';
      } else {
        resultMessage +=
            '❌ Berechtigungen sind immer noch permanent verweigert.\n\n';
        resultMessage += 'Mögliche Lösungen:\n';
        resultMessage += '• App komplett neu installieren\n';
        resultMessage += '• iOS-Gerät neu starten\n';
        resultMessage += '• Anderes iOS-Gerät testen';
      }

      if (mounted) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Berechtigungen nach Reset'),
            content: SingleChildScrollView(
              child: Text(resultMessage),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Schließen'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print('Fehler bei Berechtigungsanfrage nach Reset: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Zeige iOS-Hilfe
  Future<void> _showIOSPermissionHelp() async {
    String helpText = 'iOS-Berechtigungen aktivieren:\n\n';
    helpText += '1. Öffne die Einstellungen auf deinem iPhone\n';
    helpText += '2. Scrolle ganz nach unten zu "MeinWeg"\n';
    helpText += '3. Tippe auf "MeinWeg"\n';
    helpText += '4. Aktiviere die gewünschten Berechtigungen:\n';
    helpText += '   • Standort: "Während der Nutzung"\n';
    helpText += '   • Aktivitätserkennung: Aktivieren\n';
    helpText += '   • Kamera: Aktivieren\n';
    helpText += '   • Fotos: "Alle Fotos" oder "Ausgewählte Fotos"\n';
    helpText += '5. Starte die App neu\n\n';
    helpText += 'Falls "MeinWeg" nicht in den Einstellungen erscheint:\n';
    helpText += '• Starte die App neu\n';
    helpText += '• Verwende den "Berechtigungen anfordern" Button\n';
    helpText += '• Warte auf die iOS-Dialoge';

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('iOS-Berechtigungen Hilfe'),
        content: SingleChildScrollView(
          child: Text(helpText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Schließen'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: Text('Einstellungen öffnen'),
          ),
        ],
      ),
    );
  }

  void _openEtappeDetail(Etappe etappe) {
    // Navigation zum Etappen-Detail-Screen
    // (wird später implementiert)
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Fehler'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Erfolg'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}

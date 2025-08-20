import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/etappen_provider.dart';
import '../models/etappe.dart';
import '../services/permission_service.dart';
import 'etappe_tracking_screen_new.dart';
import 'etappe_detail_screen.dart';

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
            return EtappeTrackingScreenNew(
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

        // Beschreibung
        TextField(
          controller: _notizenController,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Beschreibung (optional)',
            hintText: 'Zusätzliche Informationen zur Etappe...',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.description),
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
      ],
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

      // Direkt zu den Etappen-Details navigieren
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EtappeDetailScreen(
            etappe: etappe,
            fromCompletedScreen: false,
          ),
        ),
      );
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

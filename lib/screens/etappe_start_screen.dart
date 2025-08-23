import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import '../providers/etappen_provider.dart';
import '../models/etappe.dart';
import '../models/wetter_daten.dart';
import '../services/permission_service.dart';
import '../services/wetter_service.dart';
import '../widgets/wetter_widget.dart';
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

  // Wetter-Daten
  WetterDaten? _aktuellesWetter;
  bool _wetterLoading = false;
  String? _wetterError;

  @override
  void initState() {
    super.initState();
    _loadCurrentWeather();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Neue Etappe starten'),
        backgroundColor: Color(0xFF5A7D7D),
        foregroundColor: Colors.white,
        centerTitle: false,
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
                // Wetter-Widget
                _buildWetterSection(),
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
            Color(0xFF5A7D7D).withOpacity(0.1),
            Color(0xFF5A7D7D).withOpacity(0.2)
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.directions_walk,
                size: 24,
                color: Color(0xFF5A7D7D),
              ),
              SizedBox(width: 8),
              Text(
                'Neue Etappe starten',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5A7D7D),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Erstelle eine neue Etappe und beginne mit dem Tracking',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF5A7D7D).withOpacity(0.8),
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
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF5A7D7D),
          ),
        ),
        SizedBox(height: 16),

        // Name
        TextField(
          controller: _nameController,
          style: TextStyle(fontSize: 14),
          decoration: InputDecoration(
            labelText: 'Bezeichnung (von -- nach) *',
            hintText: 'z.B. Wanderung zum Gipfel',
            border: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF5A7D7D)),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF5A7D7D), width: 2),
            ),
            labelStyle: TextStyle(color: Color(0xFF5A7D7D)),
            prefixIcon: Icon(Icons.edit, color: Color(0xFF5A7D7D)),
          ),
        ),
        SizedBox(height: 16),

        // Beschreibung
        TextField(
          controller: _notizenController,
          maxLines: 1,
          style: TextStyle(fontSize: 14),
          decoration: InputDecoration(
            labelText: 'Beschreibung (optional)',
            hintText: 'Zusätzliche Informationen zur Etappe...',
            border: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF5A7D7D)),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF5A7D7D), width: 2),
            ),
            labelStyle: TextStyle(color: Color(0xFF5A7D7D)),
            prefixIcon: Icon(Icons.description, color: Color(0xFF5A7D7D)),
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
              style: TextStyle(fontSize: 14),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF5A7D7D),
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
              'Manuell eine Etappe anlegen',
              style: TextStyle(fontSize: 14),
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
        startWetter: _aktuellesWetter,
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

  Widget _buildWetterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Aktuelle Wetterbedingungen',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF5A7D7D),
          ),
        ),
        SizedBox(height: 12),
        WetterWidget(
          wetterDaten: _aktuellesWetter,
          isLoading: _wetterLoading,
          errorMessage: _wetterError,
          onRefresh: _loadCurrentWeather,
        ),
        if (_aktuellesWetter != null) ...[
          SizedBox(height: 12),
          _buildWetterWarnung(),
        ],
      ],
    );
  }

  Widget _buildWetterWarnung() {
    if (_aktuellesWetter == null) return SizedBox.shrink();

    final warnung = WetterService.getWetterWarnung(_aktuellesWetter!);
    if (warnung == null) return SizedBox.shrink();

    return WetterWarnungWidget(warnung: warnung);
  }

  Future<void> _loadCurrentWeather() async {
    setState(() {
      _wetterLoading = true;
      _wetterError = null;
    });

    try {
      WetterDaten? wetter;

      if (WetterService.isConfigured) {
        // Versuche echte Wetterdaten zu laden
        Position? position = await _getCurrentPosition();
        if (position != null) {
          wetter = await WetterService.getAktuellesWetter(
            position.latitude,
            position.longitude,
          );
        }
      }

      // Fallback auf Demo-Daten wenn nötig
      wetter ??= WetterService.getDemoWetter();

      setState(() {
        _aktuellesWetter = wetter;
        _wetterLoading = false;
        _wetterError = null;
      });
    } catch (e) {
      setState(() {
        _wetterLoading = false;
        _wetterError =
            null; // Keine Fehleranzeige, da Demo-Daten verwendet werden
        _aktuellesWetter = WetterService.getDemoWetter();
      });
    }
  }

  Future<Position?> _getCurrentPosition() async {
    try {
      // Standort-Berechtigung prüfen
      bool hasPermission = await PermissionService.checkLocationPermission();
      if (!hasPermission) {
        hasPermission = await PermissionService.requestLocationPermission();
        if (!hasPermission) {
          throw Exception('Standort-Berechtigung erforderlich');
        }
      }

      // Standort-Service prüfen
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Standort-Service ist deaktiviert');
      }

      // Aktuelle Position abrufen
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      );
    } catch (e) {
      print('Fehler beim Abrufen der Position: $e');
      return null;
    }
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../services/permission_service.dart';

class OnboardingScreen extends StatefulWidget {
  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentStep = 0;
  final List<String> _permissions = [
    'Standort',
    'Kamera',
    'Speicher',
    'Aktivitätserkennung',
    'Fotos',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF00847E).withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // App Icon
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Color(0xFF00847E),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.directions_walk,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 32),

                      // Titel
                      Text(
                        'Willkommen bei MeinWeg!',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00847E),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16),

                      // Beschreibung
                      Text(
                        'Dein persönlicher Etappen-Tracker für Wanderungen und Touren',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 32),

                      // Features
                      _buildFeatureItem(
                          Icons.gps_fixed, 'GPS-Tracking für präzise Routen'),
                      _buildFeatureItem(
                          Icons.directions_walk, 'Automatische Schrittzählung'),
                      _buildFeatureItem(
                          Icons.camera_alt, 'Bilder zu deinen Touren'),
                      _buildFeatureItem(
                          Icons.library_books, 'Multimedia-Verwaltung'),
                      SizedBox(height: 32),

                      // Berechtigungen
                      if (_currentStep == 0) ...[
                        Text(
                          'Für die volle Funktionalität benötigt die App folgende Berechtigungen:',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 16),
                        ..._permissions.map(
                            (permission) => _buildPermissionItem(permission)),
                      ],
                    ],
                  ),
                ),

                // Buttons
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _handleNextStep(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF00847E),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          _currentStep == 0 ? 'Verstanden' : 'Los geht\'s!',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                    if (_currentStep == 0)
                      TextButton(
                        onPressed: () => _skipOnboarding(),
                        child: Text(
                          'Überspringen (nur für Tests)',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(
            icon,
            color: Color(0xFF00847E),
            size: 20,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionItem(String permission) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: Color(0xFF00847E),
            size: 16,
          ),
          SizedBox(width: 8),
          Text(
            permission,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  void _handleNextStep() async {
    if (_currentStep == 0) {
      // Berechtigungen anfordern
      await _requestPermissions();
      setState(() {
        _currentStep = 1;
      });
    } else {
      // Onboarding abschließen
      await _completeOnboarding();
    }
  }

  Future<void> _requestPermissions() async {
    await PermissionService.requestLocationPermission();
    await PermissionService.requestCameraPermission();
    await PermissionService.requestStoragePermission();
    await PermissionService.requestActivityRecognitionPermission();
    await PermissionService.requestPhotosPermission();
  }

  Future<void> _completeOnboarding() async {
    final settingsProvider =
        Provider.of<SettingsProvider>(context, listen: false);
    await settingsProvider.setFirstAppUsage(false);
    await settingsProvider.setOnboardingCompleted(true);

    Navigator.of(context).pushReplacementNamed('/main');
  }

  void _skipOnboarding() async {
    final settingsProvider =
        Provider.of<SettingsProvider>(context, listen: false);
    await settingsProvider.setFirstAppUsage(false);
    await settingsProvider.setOnboardingCompleted(true);

    Navigator.of(context).pushReplacementNamed('/main');
  }
}

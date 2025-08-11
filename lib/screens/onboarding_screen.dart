import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../services/permission_service.dart';

class OnboardingScreen extends StatefulWidget {
  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
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
          child: Column(
            children: [
              // Grüner Header-Balken mit Logo
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                decoration: BoxDecoration(
                  color: Color(0xFF00847E),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // App Logo
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          'icon.png',
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.directions_walk,
                              size: 30,
                              color: Color(0xFF00847E),
                            );
                          },
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    // App Name
                    Text(
                      'Mein Weg',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // Hauptinhalt
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Titel
                      Text(
                        'Willkommen bei Mein Weg!',
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
                  ),
                ),
              ),

              // Buttons
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _handleStart(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF00847E),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Verstanden',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
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
              ),
            ],
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

  void _handleStart() async {
    // Berechtigungen anfordern und Onboarding direkt abschließen
    await _requestPermissions();
    await _completeOnboarding();
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

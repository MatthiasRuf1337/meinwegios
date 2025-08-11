import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    return GestureDetector(
      onTap: () {
        // Tastatur schließen wenn außerhalb eines Textfeldes getippt wird
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
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
                        'Mein Weg – Meine Reise',
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
                          'Die App zu deinem Buch',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF00847E),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 16),

                        // Einleitungstexte
                        Text(
                          'Diese App ist kein Ersatz für das Buch „Mein Weg – Meine Reise“.\nSie ist deine Begleitung unterwegs – digital, praktisch und persönlich.',
                          style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Um sie vollständig zu nutzen, brauchst du das Pilgertagebuch in gedruckter Form.\nDort findest du alle Texte, Reflexionsseiten, thematischen Impulse und Zitate.',
                          style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 24),

                        // Funktionen
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Die App ergänzt dein Buch um wertvolle digitale Funktionen:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ),
                        SizedBox(height: 12),
                        _buildEmojiBullet('🗺', 'Strecke aufzeichnen oder Schritte zählen'),
                        _buildEmojiBullet('📷', 'Bilder zu jeder Etappe festhalten'),
                        _buildEmojiBullet('🎙', 'Gedanken als Audio aufnehmen'),
                        _buildEmojiBullet('📖', 'E-Paper und Meditationen direkt in der App nutzen'),
                        SizedBox(height: 32),

                        // Berechtigungen
                        Text(
                          'Wichtiger Hinweis zur Nutzung',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Damit alle Funktionen reibungslos arbeiten, fragt die App beim Start den Zugriff auf Standort, Kamera, Fotos, Aktivitätserkennung und Schrittzähler ab.\n\nDeine Privatsphäre hat oberste Priorität: Alle Daten bleiben ausschließlich auf deinem Handy – keine Weitergabe, kein Upload.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Benötigte Berechtigungen:',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w600,
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
      ),
    );
  }

  // Vorherige Feature-Liste wird jetzt durch Emoji-Bullets ersetzt

  Widget _buildEmojiBullet(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: TextStyle(fontSize: 18)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade800),
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

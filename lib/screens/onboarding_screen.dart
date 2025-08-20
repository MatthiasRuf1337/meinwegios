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
  final ScrollController _scrollController = ScrollController();
  final PageController _pageController = PageController();
  bool _showScrollHint = true;
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_showScrollHint && _scrollController.offset > 10) {
        setState(() {
          _showScrollHint = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
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
                // Header mit Step-Indikator
                _buildHeader(),

                // PageView für 2 Steps
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentStep = index;
                      });
                    },
                    children: [
                      _buildStep1(),
                      _buildStep2(),
                    ],
                  ),
                ),

                // Navigation Buttons
                _buildNavigationButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
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
      child: Column(
        children: [
          Row(
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
          SizedBox(height: 16),
          // Step Indikator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStepIndicator(0),
              Container(
                width: 40,
                height: 2,
                color: Colors.white.withOpacity(0.3),
                margin: EdgeInsets.symmetric(horizontal: 8),
              ),
              _buildStepIndicator(1),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int step) {
    bool isActive = step <= _currentStep;
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.white.withOpacity(0.3),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '${step + 1}',
          style: TextStyle(
            color: isActive ? Color(0xFF00847E) : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Bild
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.asset(
                  'assets/images/Marco_Bach_2025.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey.shade200,
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.image_not_supported,
                        color: Colors.grey.shade500,
                        size: 48,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Titel
          const Text(
            'Die App zu deinem Buch',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF00847E),
            ),
          ),
          const SizedBox(height: 16),
          // Einleitungstexte
          Text(
            'Diese App ist kein Ersatz für das Buch „Mein Weg – Meine Reise".\nSie ist deine Begleitung unterwegs – digital, praktisch und persönlich.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Um sie vollständig zu nutzen, brauchst du das Pilgertagebuch in gedruckter Form.\nDort findest du alle Texte, Reflexionsseiten, thematischen Impulse und Zitate.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
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
          const SizedBox(height: 12),
          _buildEmojiBullet('🗺', 'Strecke aufzeichnen oder Schritte zählen'),
          _buildEmojiBullet('📷', 'Bilder zu jeder Etappe festhalten'),
          _buildEmojiBullet('🎙', 'Gedanken als Audio aufnehmen'),
          _buildEmojiBullet(
              '📖', 'E-Paper und Meditationen direkt in der App nutzen'),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Icon(
            Icons.security,
            size: 80,
            color: Color(0xFF00847E),
          ),
          const SizedBox(height: 24),
          const Text(
            'Datenschutz & Berechtigungen',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF00847E),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Damit alle Funktionen reibungslos arbeiten, fragt die App beim Start den Zugriff auf verschiedene Bereiche ab.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFF00847E).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Color(0xFF00847E).withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.lock,
                  color: Color(0xFF00847E),
                  size: 32,
                ),
                SizedBox(height: 8),
                Text(
                  'Deine Privatsphäre hat oberste Priorität',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00847E),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  'Alle Daten bleiben ausschließlich auf deinem Handy – keine Weitergabe, kein Upload.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Benötigte Berechtigungen:',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade800,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ..._permissions.map((permission) => _buildPermissionItem(permission)),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          if (_currentStep == 0) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  _pageController.nextPage(
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF00847E),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Weiter',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ] else ...[
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
                  'App starten',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(height: 12),
            TextButton(
              onPressed: () {
                _pageController.previousPage(
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              child: Text(
                'Zurück',
                style: TextStyle(
                  color: Color(0xFF00847E),
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScrollHintOverlay() {
    return Positioned(
      bottom: 8,
      left: 0,
      right: 0,
      child: IgnorePointer(
        ignoring: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.keyboard_arrow_down, color: Color(0x8000847E), size: 28),
            Text(
              'Nach unten scrollen',
              style: TextStyle(color: Color(0x8000847E), fontSize: 12),
            ),
          ],
        ),
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
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
              ),
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
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/zitat.dart';
import '../providers/settings_provider.dart';
import 'main_navigation.dart';

class ZitatScreen extends StatefulWidget {
  @override
  _ZitatScreenState createState() => _ZitatScreenState();
}

class _ZitatScreenState extends State<ZitatScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  Zitat? _zitat;
  bool _isLoading = true;

  // Drei verschiedene Farben aus dem Buch-Design
  final List<Color> _backgroundColors = [
    Color(0xFF5A7D7D), // Hauptfarbe
    Color(0xFF7B9B9B), // Hellere Variante
    Color(0xFF4A6D6D), // Dunklere Variante
  ];

  late Color _selectedColor;

  @override
  void initState() {
    super.initState();

    // Zufällige Farbe auswählen
    _selectedColor = _backgroundColors[
        DateTime.now().millisecondsSinceEpoch % _backgroundColors.length];

    _animationController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Interval(0.0, 0.8, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Interval(0.2, 1.0, curve: Curves.easeOut),
    ));

    _loadZitat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadZitat() async {
    try {
      final settingsProvider =
          Provider.of<SettingsProvider>(context, listen: false);
      final zitat = await settingsProvider.getHeutigesZitat();

      setState(() {
        _zitat = zitat;
        _isLoading = false;
      });

      _animationController.forward();
    } catch (e) {
      print('Fehler beim Laden des Zitats: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToMain() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            MainNavigation(),
        transitionDuration: Duration(milliseconds: 500),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _selectedColor,
              _selectedColor.withOpacity(0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : _buildZitatContent(),
        ),
      ),
    );
  }

  Widget _buildZitatContent() {
    if (_zitat == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.white,
              size: 48,
            ),
            SizedBox(height: 16),
            Text(
              'Zitat konnte nicht geladen werden',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
            SizedBox(height: 24),
            _buildContinueButton(),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.all(24.0),
      child: Column(
        children: [
          // Header mit Logo
          _buildHeader(),

          // Zitat-Inhalt
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildZitatText(),
                    SizedBox(height: 32),
                    _buildAutor(),
                  ],
                ),
              ),
            ),
          ),

          // Continue Button
          _buildContinueButton(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: EdgeInsets.only(top: 16, bottom: 32),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  'icon.png',
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.directions_walk,
                      size: 24,
                      color: _selectedColor,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZitatText() {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Text(
            '"${_zitat!.text}"',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w300,
              height: 1.4,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildAutor() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Text(
        '— ${_zitat!.autor}',
        style: TextStyle(
          color: Colors.white.withOpacity(0.9),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildContinueButton() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.only(top: 32),
        child: ElevatedButton(
          onPressed: _navigateToMain,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: _selectedColor,
            padding: EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
          ),
          child: Text(
            'Weiter',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

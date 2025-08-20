import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';
import '../models/etappe.dart';
import 'etappe_detail_screen.dart';
import 'main_navigation.dart'; // For navigating back to main tabs

class EtappeCompletedScreen extends StatefulWidget {
  final Etappe etappe;

  const EtappeCompletedScreen({Key? key, required this.etappe})
      : super(key: key);

  @override
  _EtappeCompletedScreenState createState() => _EtappeCompletedScreenState();
}

class _EtappeCompletedScreenState extends State<EtappeCompletedScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
    // Verzögerung vor dem Konfetti-Start, um Flackern zu vermeiden
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(Duration(milliseconds: 800), () {
        if (mounted) {
          _confettiController.play();
        }
      });
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50, // Helles Grau als Hintergrund
      body: SafeArea(
        child: Stack(
          children: [
            // Hauptinhalt
            SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  SizedBox(height: 40),

                  // Erfolgs-Icon
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFF00847E), Color(0xFF00A09A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          spreadRadius: 2,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 80,
                    ),
                  ),
                  SizedBox(height: 24),

                  Text(
                    'Etappe erfolgreich beendet!',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00847E),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),

                  Text(
                    'Herzlichen Glückwunsch! Du hast deine Etappe erfolgreich abgeschlossen.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 32),

                  // Statistiken
                  _buildStatCard(
                    'Distanz',
                    widget.etappe.formatierteDistanz,
                    Icons.straighten,
                    Colors.blue.shade700,
                  ),
                  _buildStatCard(
                    'Schritte',
                    '${widget.etappe.schrittAnzahl} Schritte',
                    Icons.directions_walk,
                    Colors.green.shade700,
                  ),
                  _buildStatCard(
                    'Dauer',
                    widget.etappe.formatierteDauer,
                    Icons.timer,
                    Colors.orange.shade700,
                  ),
                  _buildStatCard(
                    'Datum',
                    '${widget.etappe.startzeit.day}.${widget.etappe.startzeit.month}.${widget.etappe.startzeit.year}',
                    Icons.calendar_today,
                    Colors.purple.shade700,
                  ),
                  SizedBox(height: 32),

                  // Aktionen
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MainNavigation(
                            initialTab: 0,
                            etappeToShow: widget.etappe,
                          ),
                        ),
                      );
                    },
                    icon: Icon(Icons.photo_library),
                    label: Text('Bilder & Audio hinzufügen'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF00847E),
                      foregroundColor: Colors.white,
                      padding:
                          EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      textStyle: TextStyle(fontSize: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: () {
                      _confettiController.play();
                    },
                    icon: Icon(Icons.celebration),
                    label: Text('Nochmal feiern!'),
                    style: TextButton.styleFrom(
                      foregroundColor: Color(0xFF00847E),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      // Direkt zur MainNavigation mit Archiv-Tab navigieren
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MainNavigation(),
                        ),
                        (route) => false, // Alle vorherigen Routen entfernen
                      );
                      // Sicherstellen, dass Archiv-Tab aktiv ist
                      Future.delayed(Duration(milliseconds: 100), () {
                        MainNavigationController.switchToTab(0);
                      });
                    },
                    child: Text('Zur Übersicht'),
                  ),
                ],
              ),
            ),

            // Konfetti-Animation
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirection: pi / 2, // Nach unten
                particleDrag: 0.08,
                emissionFrequency: 0.03,
                numberOfParticles: 25,
                gravity: 0.08,
                shouldLoop: false,
                minBlastForce: 5,
                maxBlastForce: 15,
                colors: const [
                  Colors.green,
                  Colors.blue,
                  Colors.pink,
                  Colors.orange,
                  Colors.purple,
                  Color(0xFF00847E),
                  Colors.red,
                  Colors.yellow,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 30, color: color),
            SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

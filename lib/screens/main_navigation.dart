import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'archiv_screen.dart';
import 'etappe_start_screen.dart';
import 'galerie_screen.dart';
import 'mediathek_screen.dart';

class MainNavigation extends StatefulWidget {
  @override
  _MainNavigationState createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    ArchivScreen(),
    EtappeStartScreen(),
    GalerieScreen(),
    MediathekScreen(),
  ];

  final List<BottomNavigationBarItem> _navigationItems = [
    BottomNavigationBarItem(
      icon: Icon(Icons.archive),
      label: 'Etappen',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.play_arrow),
      label: 'Etappe',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.photo_library),
      label: 'Galerie',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.library_books),
      label: 'Mediathek',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Tastatur schließen wenn außerhalb eines Textfeldes getippt wird
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          selectedItemColor: Color(0xFF00847E),
          unselectedItemColor: Colors.grey,
          items: _navigationItems,
        ),
      ),
    );
  }
}

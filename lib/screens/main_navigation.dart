import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'archiv_screen.dart';
import 'etappe_start_screen.dart';
import 'galerie_screen.dart';
import 'mediathek_screen.dart';
import 'etappe_detail_screen.dart';
import '../models/etappe.dart';
import '../widgets/etappe_recovery_dialog.dart';

// Globaler Controller für Tab-Navigation
class MainNavigationController {
  static _MainNavigationState? _instance;

  static void _setInstance(_MainNavigationState instance) {
    _instance = instance;
  }

  static void switchToTab(int index) {
    _instance?.switchToTab(index);
  }
}

class MainNavigation extends StatefulWidget {
  final int? initialTab;
  final Etappe? etappeToShow;

  const MainNavigation({Key? key, this.initialTab, this.etappeToShow})
      : super(key: key);

  @override
  _MainNavigationState createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    MainNavigationController._setInstance(this);
    _currentIndex = widget.initialTab ?? 0;

    // Nach dem ersten Frame prüfen ob verwaiste Etappen vorhanden sind
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForOrphanedEtappen();
    });
  }

  void _checkForOrphanedEtappen() async {
    // Kurz warten damit der EtappenProvider vollständig geladen ist
    await Future.delayed(Duration(milliseconds: 500));

    if (mounted) {
      await EtappeRecoveryDialog.showIfNeeded(context);
    }
  }

  void switchToTab(int index) {
    if (mounted) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  List<Widget> get _screens {
    // Wenn eine spezielle Etappe angezeigt werden soll, ersetze das Archiv
    if (widget.etappeToShow != null) {
      return [
        EtappeDetailScreen(
            etappe: widget.etappeToShow!, fromCompletedScreen: true),
        EtappeStartScreen(),
        GalerieScreen(),
        MediathekScreen(),
      ];
    }

    return [
      ArchivScreen(),
      EtappeStartScreen(),
      GalerieScreen(),
      MediathekScreen(),
    ];
  }

  List<BottomNavigationBarItem> get _navigationItems {
    return [
      BottomNavigationBarItem(
        icon: Icon(Icons.archive),
        label: 'Etappen',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.add_circle_outline),
        activeIcon: Icon(Icons.add_circle),
        label: 'Neue Etappe',
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
  }

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
            // Wenn auf Etappen-Tab geklickt wird und eine spezielle Etappe angezeigt wird,
            // zurück zum normalen Archiv navigieren
            if (index == 0 && widget.etappeToShow != null) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => MainNavigation(),
                ),
              );
            } else {
              setState(() {
                _currentIndex = index;
              });
            }
          },
          selectedItemColor: Color(0xFF5A7D7D),
          unselectedItemColor: Colors.grey,
          items: _navigationItems,
        ),
      ),
    );
  }
}

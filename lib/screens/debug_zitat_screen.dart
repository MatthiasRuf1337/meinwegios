import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../models/zitat.dart';
import 'zitat_screen.dart';

class DebugZitatScreen extends StatefulWidget {
  @override
  _DebugZitatScreenState createState() => _DebugZitatScreenState();
}

class _DebugZitatScreenState extends State<DebugZitatScreen> {
  String _debugInfo = '';

  @override
  void initState() {
    super.initState();
    _loadDebugInfo();
  }

  void _loadDebugInfo() {
    final settingsProvider =
        Provider.of<SettingsProvider>(context, listen: false);
    final settings = settingsProvider.settings;

    setState(() {
      _debugInfo = '''
Erste App Nutzung: ${settings.ersteAppNutzung}
Onboarding abgeschlossen: ${settings.onboardingAbgeschlossen}
Aktueller Zitat-Index: ${settings.aktuellerZitatIndex}
Letztes Zitat Datum: ${settings.letztesZitatDatum}
Sollte Zitat anzeigen: ${settingsProvider.shouldShowZitat()}
      ''';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Zitat Debug'),
        backgroundColor: Color(0xFF5A7D7D),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Debug Informationen:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _debugInfo,
                style: TextStyle(fontFamily: 'monospace'),
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Test-Aktionen:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final settingsProvider =
                    Provider.of<SettingsProvider>(context, listen: false);
                await settingsProvider.resetZitatDatum();
                _loadDebugInfo();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Zitat-Datum zurückgesetzt')),
                );
              },
              child: Text('Zitat-Datum zurücksetzen'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF5A7D7D),
                foregroundColor: Colors.white,
              ),
            ),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: () async {
                final settingsProvider =
                    Provider.of<SettingsProvider>(context, listen: false);
                await settingsProvider.forceShowZitat();
                _loadDebugInfo();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content:
                          Text('Zitat wird beim nächsten Start angezeigt')),
                );
              },
              child: Text('Zitat für nächsten Start aktivieren'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF7B9B9B),
                foregroundColor: Colors.white,
              ),
            ),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => ZitatScreen()),
                );
              },
              child: Text('Zitat-Screen direkt anzeigen'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF4A6D6D),
                foregroundColor: Colors.white,
              ),
            ),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                _loadDebugInfo();
              },
              child: Text('Debug-Info aktualisieren'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade600,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/medien_provider.dart';
import '../providers/settings_provider.dart';
import '../models/medien_datei.dart';
import 'mediathek_login_screen.dart';
import 'pdf_viewer_screen.dart';
import 'audio_player_screen.dart';

class MediathekScreen extends StatefulWidget {
  @override
  _MediathekScreenState createState() => _MediathekScreenState();
}

class _MediathekScreenState extends State<MediathekScreen> {
  String _searchQuery = '';
  MedienTyp? _selectedType;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MedienProvider>(context, listen: false).loadMedienDateien();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        // Prüfen ob Mediathek-Session gültig ist
        if (!settingsProvider.isMediathekSessionValid) {
          return MediathekLoginScreen();
        }

        return Scaffold(
          appBar: AppBar(
            title: Text('Mediathek'),
            backgroundColor: Color(0xFF00847E),
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: Icon(Icons.settings),
                onPressed: () => _showSettings(context),
              ),
            ],
          ),
          body: Column(
            children: [
              _buildSearchBar(),
              _buildFilterChips(),
              _buildStatistics(),
              Expanded(
                child: Consumer<MedienProvider>(
                  builder: (context, medienProvider, child) {
                    final medien = medienProvider.medienDateien
                        .where((medien) {
                          final matchesSearch = medien.dateiname.toLowerCase().contains(_searchQuery.toLowerCase());
                          final matchesType = _selectedType == null || medien.typ == _selectedType;
                          return matchesSearch && matchesType;
                        })
                        .toList();

                    if (medien.isEmpty) {
                      return _buildEmptyState();
                    }

                    return _buildMedienList(medien);
                  },
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _importMedia(context),
            backgroundColor: Color(0xFF00847E),
            child: Icon(Icons.add, color: Colors.white),
            tooltip: 'Medien importieren',
          ),
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Medien durchsuchen...',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.grey.shade100,
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.0),
        children: [
          FilterChip(
            label: Text('Alle'),
            selected: _selectedType == null,
            onSelected: (selected) {
              setState(() {
                _selectedType = null;
              });
            },
            selectedColor: Color(0xFF00847E).withOpacity(0.2),
            checkmarkColor: Color(0xFF00847E),
          ),
          SizedBox(width: 8),
          FilterChip(
            label: Text('PDF'),
            selected: _selectedType == MedienTyp.pdf,
            onSelected: (selected) {
              setState(() {
                _selectedType = selected ? MedienTyp.pdf : null;
              });
            },
            selectedColor: Color(0xFF00847E).withOpacity(0.2),
            checkmarkColor: Color(0xFF00847E),
          ),
          SizedBox(width: 8),
          FilterChip(
            label: Text('MP3'),
            selected: _selectedType == MedienTyp.mp3,
            onSelected: (selected) {
              setState(() {
                _selectedType = selected ? MedienTyp.mp3 : null;
              });
            },
            selectedColor: Color(0xFF00847E).withOpacity(0.2),
            checkmarkColor: Color(0xFF00847E),
          ),
        ],
      ),
    );
  }

  Widget _buildStatistics() {
    return Consumer<MedienProvider>(
      builder: (context, medienProvider, child) {
        final totalMedien = medienProvider.medienDateien.length;
                 final pdfCount = medienProvider.medienDateien.where((m) => m.typ == MedienTyp.pdf).length;
         final mp3Count = medienProvider.medienDateien.where((m) => m.typ == MedienTyp.mp3).length;

        return Container(
          padding: EdgeInsets.all(16.0),
          margin: EdgeInsets.symmetric(horizontal: 16.0),
          decoration: BoxDecoration(
            color: Color(0xFF00847E).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Color(0xFF00847E).withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Gesamt', totalMedien.toString(), Icons.library_books),
              _buildStatItem('PDF', pdfCount.toString(), Icons.picture_as_pdf),
              _buildStatItem('MP3', mp3Count.toString(), Icons.audiotrack),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Color(0xFF00847E), size: 20),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF00847E),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.library_books_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 16),
          Text(
            'Keine Medien gefunden',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Importieren Sie PDFs und MP3s',
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedienList(List<MedienDatei> medien) {
    return ListView.builder(
      padding: EdgeInsets.all(16.0),
      itemCount: medien.length,
      itemBuilder: (context, index) {
        final medienDatei = medien[index];
        return _buildMedienTile(medienDatei);
      },
    );
  }

  Widget _buildMedienTile(MedienDatei medienDatei) {
    return Card(
      margin: EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: medienDatei.typ == MedienTyp.pdf 
                ? Colors.red.shade100 
                : Colors.blue.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            medienDatei.typ == MedienTyp.pdf 
                ? Icons.picture_as_pdf 
                : Icons.audiotrack,
            color: medienDatei.typ == MedienTyp.pdf 
                ? Colors.red.shade600 
                : Colors.blue.shade600,
          ),
        ),
        title: Text(
          medienDatei.dateiname,
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              medienDatei.formatierteGroesse,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            Text(
              medienDatei.formatiertesImportDatum,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleMedienAction(value, medienDatei),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'open',
              child: Row(
                children: [
                  Icon(Icons.open_in_new),
                  SizedBox(width: 8),
                  Text('Öffnen'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'share',
              child: Row(
                children: [
                  Icon(Icons.share),
                  SizedBox(width: 8),
                  Text('Teilen'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Löschen', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        onTap: () => _openMedien(medienDatei),
      ),
    );
  }

  void _openMedien(MedienDatei medienDatei) {
    if (medienDatei.typ == MedienTyp.pdf) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PDFViewerScreen(medienDatei: medienDatei),
        ),
      );
    } else if (medienDatei.typ == MedienTyp.mp3) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AudioPlayerScreen(medienDatei: medienDatei),
        ),
      );
    }
  }

  void _handleMedienAction(String action, MedienDatei medienDatei) {
    switch (action) {
      case 'open':
        _openMedien(medienDatei);
        break;
      case 'share':
        _shareMedien(medienDatei);
        break;
      case 'delete':
        _deleteMedien(medienDatei);
        break;
    }
  }

  void _shareMedien(MedienDatei medienDatei) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Teilen-Funktion wird implementiert...'),
        backgroundColor: Color(0xFF00847E),
      ),
    );
  }

  void _deleteMedien(MedienDatei medienDatei) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Medien löschen'),
        content: Text('Möchten Sie "${medienDatei.dateiname}" wirklich löschen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Provider.of<MedienProvider>(context, listen: false)
                  .deleteMedienDatei(medienDatei.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Löschen'),
          ),
        ],
      ),
    );
  }

  void _importMedia(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Import-Funktion wird implementiert...'),
        backgroundColor: Color(0xFF00847E),
      ),
    );
  }

  void _showSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Mediathek-Einstellungen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.lock),
              title: Text('PIN ändern'),
              onTap: () {
                Navigator.pop(context);
                _showChangePINDialog(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Abmelden'),
              onTap: () {
                Navigator.pop(context);
                _logout(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Schließen'),
          ),
        ],
      ),
    );
  }

  void _showChangePINDialog(BuildContext context) {
    final TextEditingController oldPinController = TextEditingController();
    final TextEditingController newPinController = TextEditingController();
    final TextEditingController confirmPinController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('PIN ändern'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPinController,
              decoration: InputDecoration(
                labelText: 'Aktuelle PIN',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              obscureText: true,
            ),
            SizedBox(height: 16),
            TextField(
              controller: newPinController,
              decoration: InputDecoration(
                labelText: 'Neue PIN',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              obscureText: true,
            ),
            SizedBox(height: 16),
            TextField(
              controller: confirmPinController,
              decoration: InputDecoration(
                labelText: 'Neue PIN bestätigen',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () {
              final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
              final oldPin = oldPinController.text;
              final newPin = newPinController.text;
              final confirmPin = confirmPinController.text;

              if (oldPin != settingsProvider.mediathekPIN) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Aktuelle PIN ist falsch'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              if (newPin != confirmPin) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('PINs stimmen nicht überein'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              if (newPin.length != 4) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('PIN muss 4 Ziffern haben'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              settingsProvider.setMediathekPIN(newPin);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('PIN erfolgreich geändert'),
                  backgroundColor: Color(0xFF00847E),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF00847E),
              foregroundColor: Colors.white,
            ),
            child: Text('Ändern'),
          ),
        ],
      ),
    );
  }

  void _logout(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    settingsProvider.logoutMediathek();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Erfolgreich abgemeldet'),
        backgroundColor: Color(0xFF00847E),
      ),
    );
  }
} 
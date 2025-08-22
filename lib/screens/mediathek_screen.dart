import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:open_file/open_file.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../providers/medien_provider.dart';
import '../providers/settings_provider.dart';
import '../models/medien_datei.dart';
import '../services/thumbnail_service.dart';
import 'mediathek_login_screen.dart';
import 'pdf_viewer_screen.dart';
import 'pdf_viewer_screen_alternative.dart';
import 'pdf_viewer_simple.dart';
import 'audio_player_screen.dart';

class MediathekScreen extends StatefulWidget {
  @override
  _MediathekScreenState createState() => _MediathekScreenState();
}

class _MediathekScreenState extends State<MediathekScreen> {
  String _searchQuery = '';
  MedienTyp? _selectedType;
  bool _showOnlyVerlagsdateien = false;

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
            backgroundColor: Color(0xFF5A7D7D),
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
              Expanded(
                child: Consumer<MedienProvider>(
                  builder: (context, medienProvider, child) {
                    final medien = medienProvider.medienDateien.where((medien) {
                      final matchesSearch = medien.dateiname
                          .toLowerCase()
                          .contains(_searchQuery.toLowerCase());
                      final matchesType =
                          _selectedType == null || medien.typ == _selectedType;
                      final matchesVerlagsdateien =
                          !_showOnlyVerlagsdateien || medien.istVerlagsdatei;
                      return matchesSearch &&
                          matchesType &&
                          matchesVerlagsdateien;
                    }).toList();

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
            backgroundColor: Color(0xFF5A7D7D),
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
            selectedColor: Color(0xFF5A7D7D).withOpacity(0.2),
            checkmarkColor: Color(0xFF5A7D7D),
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
            selectedColor: Color(0xFF5A7D7D).withOpacity(0.2),
            checkmarkColor: Color(0xFF5A7D7D),
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
            selectedColor: Color(0xFF5A7D7D).withOpacity(0.2),
            checkmarkColor: Color(0xFF5A7D7D),
          ),
          SizedBox(width: 8),
          FilterChip(
            label: Text('Aus dem Buch'),
            selected: _showOnlyVerlagsdateien,
            onSelected: (selected) {
              setState(() {
                _showOnlyVerlagsdateien = selected;
                if (selected) {
                  _selectedType =
                      null; // Reset type filter when showing only verlagsdateien
                }
              });
            },
            selectedColor: Color(0xFF5A7D7D).withOpacity(0.2),
            checkmarkColor: Color(0xFF5A7D7D),
          ),
        ],
      ),
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
              fontSize: 20,
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
        leading: ThumbnailService.loadListThumbnail(medienDatei),
        title: Text(
          medienDatei.anzeigeName,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              medienDatei.formatierteGroesse,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
            Text(
              medienDatei.formatiertesImportDatum,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
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

  void _openMedien(MedienDatei medienDatei) async {
    if (medienDatei.typ == MedienTyp.pdf) {
      try {
        final file = File(medienDatei.dateipfad);
        if (file.existsSync()) {
          final result = await OpenFile.open(medienDatei.dateipfad);
          if (result.type != ResultType.done) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Fehler beim Öffnen der PDF: ${result.message}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('PDF-Datei nicht gefunden'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Öffnen der PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
        backgroundColor: Color(0xFF5A7D7D),
      ),
    );
  }

  void _deleteMedien(MedienDatei medienDatei) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Medien löschen'),
        content:
            Text('Möchten Sie "${medienDatei.anzeigeName}" wirklich löschen?'),
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
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Medien hinzufügen',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.photo_camera, color: Color(0xFF5A7D7D)),
              title: Text('Kamera'),
              subtitle: Text('Foto aufnehmen'),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromCamera();
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library, color: Color(0xFF5A7D7D)),
              title: Text('Galerie'),
              subtitle: Text('Foto aus Galerie wählen'),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromGallery();
              },
            ),
            ListTile(
              leading: Icon(Icons.folder_open, color: Color(0xFF5A7D7D)),
              title: Text('Datei auswählen'),
              subtitle: Text('PDF, MP3, Bilder oder andere Dateien'),
              onTap: () {
                Navigator.pop(context);
                _pickFile();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _pickImageFromCamera() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (image != null) {
        await _importFile(File(image.path));
      }
    } catch (e) {
      _showErrorSnackBar('Fehler beim Aufnehmen des Fotos: $e');
    }
  }

  void _pickImageFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        await _importFile(File(image.path));
      }
    } catch (e) {
      _showErrorSnackBar('Fehler beim Auswählen des Fotos: $e');
    }
  }

  void _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'pdf',
          'mp3',
          'wav',
          'm4a',
          'aac',
          'jpg',
          'jpeg',
          'png',
          'gif',
          'bmp',
          'txt',
          'doc',
          'docx',
          'xls',
          'xlsx',
          'ppt',
          'pptx',
          'zip',
          'rar'
        ],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        await _importFile(File(result.files.single.path!));
      }
    } catch (e) {
      _showErrorSnackBar('Fehler beim Auswählen der Datei: $e');
    }
  }

  Future<void> _importFile(File file) async {
    try {
      if (!file.existsSync()) {
        _showErrorSnackBar('Datei existiert nicht');
        return;
      }

      final medienProvider =
          Provider.of<MedienProvider>(context, listen: false);
      final success = await medienProvider.importFile(file);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Datei erfolgreich importiert: ${file.path.split('/').last}'),
            backgroundColor: Color(0xFF5A7D7D),
          ),
        );
      } else {
        _showErrorSnackBar('Fehler beim Importieren der Datei');
      }
    } catch (e) {
      _showErrorSnackBar('Fehler beim Importieren: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
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
              final settingsProvider =
                  Provider.of<SettingsProvider>(context, listen: false);
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
                  backgroundColor: Color(0xFF5A7D7D),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF5A7D7D),
              foregroundColor: Colors.white,
            ),
            child: Text('Ändern'),
          ),
        ],
      ),
    );
  }

  void _logout(BuildContext context) {
    final settingsProvider =
        Provider.of<SettingsProvider>(context, listen: false);
    settingsProvider.logoutMediathek();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Erfolgreich abgemeldet'),
        backgroundColor: Color(0xFF5A7D7D),
      ),
    );
  }
}

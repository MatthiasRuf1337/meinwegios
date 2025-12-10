import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../providers/bilder_provider.dart';
import '../models/bild.dart';
import 'bild_detail_screen.dart';
import '../widgets/legal_menu_widget.dart';
import '../services/permission_service.dart';
import 'dart:io';

class GalerieScreen extends StatefulWidget {
  @override
  _GalerieScreenState createState() => _GalerieScreenState();
}

class _GalerieScreenState extends State<GalerieScreen> {
  bool _isGridView = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BilderProvider>(context, listen: false).loadBilder();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bilder-Galerie'),
        backgroundColor: Color(0xFF5A7D7D),
        foregroundColor: Colors.white,
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.list : Icons.grid_view),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
          ),
          LegalMenuWidget(),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildStatistics(),
          Expanded(
            child: Consumer<BilderProvider>(
              builder: (context, bilderProvider, child) {
                final bilder = bilderProvider.bilder
                    .where((bild) => bild.dateiname
                        .toLowerCase()
                        .contains(_searchQuery.toLowerCase()))
                    .toList();

                if (bilder.isEmpty) {
                  return _buildEmptyState();
                }

                return _isGridView
                    ? _buildGridView(bilder)
                    : _buildListView(bilder);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addImage(context),
        backgroundColor: Color(0xFF5A7D7D),
        child: Icon(Icons.add_a_photo, color: Colors.white),
        tooltip: 'Bild hinzufügen',
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: TextField(
        style: TextStyle(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.black
              : Colors.black,
        ),
        decoration: InputDecoration(
          hintText: 'Bilder durchsuchen...',
          hintStyle: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey.shade600
                : Colors.grey.shade500,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey.shade600
                : Colors.grey.shade500,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey.shade200
              : Colors.grey.shade100,
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  Widget _buildStatistics() {
    return Consumer<BilderProvider>(
      builder: (context, bilderProvider, child) {
        final totalBilder = bilderProvider.bilder.length;
        final bilderHeute = bilderProvider.bilder
            .where((b) => b.aufnahmeZeit
                .isAfter(DateTime.now().subtract(Duration(days: 1))))
            .length;

        return Container(
          padding: EdgeInsets.all(16.0),
          margin: EdgeInsets.symmetric(horizontal: 16.0),
          decoration: BoxDecoration(
            color: Color(0xFF5A7D7D).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Color(0xFF5A7D7D).withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                  'Gesamt', totalBilder.toString(), Icons.photo_library),
              _buildStatItem('Heute', bilderHeute.toString(), Icons.today),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Color(0xFF5A7D7D), size: 20),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF5A7D7D),
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
            Icons.photo_library_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 16),
          Text(
            'Keine Bilder gefunden',
            style: TextStyle(
              fontSize: 20,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Nehmen Sie Fotos während Ihrer Etappen auf',
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridView(List<Bild> bilder) {
    return GridView.builder(
      padding: EdgeInsets.all(16.0),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: bilder.length,
      itemBuilder: (context, index) {
        final bild = bilder[index];
        return _buildImageTile(bild);
      },
    );
  }

  Widget _buildListView(List<Bild> bilder) {
    return ListView.builder(
      padding: EdgeInsets.all(16.0),
      itemCount: bilder.length,
      itemBuilder: (context, index) {
        final bild = bilder[index];
        return _buildImageListTile(bild);
      },
    );
  }

  Widget _buildImageTile(Bild bild) {
    return GestureDetector(
      onTap: () => _openImageDetail(bild),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: _buildImageWidget(bild),
        ),
      ),
    );
  }

  Widget _buildImageListTile(Bild bild) {
    return Card(
      margin: EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        leading: Container(
          width: 60,
          height: 60,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _buildImageWidget(bild),
          ),
        ),
        title: Text(
          bild.dateiname,
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          bild.formatierteAufnahmeZeit,
          style: TextStyle(color: Colors.grey.shade600),
        ),
        trailing: bild.hatGPS
            ? Icon(Icons.location_on, color: Color(0xFF5A7D7D))
            : null,
        onTap: () => _openImageDetail(bild),
      ),
    );
  }

  Widget _buildImageWidget(Bild bild) {
    try {
      final file = File(bild.dateipfad);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildPlaceholderImage();
          },
        );
      } else {
        return _buildPlaceholderImage();
      }
    } catch (e) {
      return _buildPlaceholderImage();
    }
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: Colors.grey.shade200,
      child: Icon(
        Icons.image,
        color: Colors.grey.shade400,
        size: 32,
      ),
    );
  }

  void _openImageDetail(Bild bild) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BildDetailScreen(bild: bild),
      ),
    );
  }

  void _addImage(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Bild hinzufügen',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.camera_alt, color: Color(0xFF5A7D7D)),
              title: Text('Foto aufnehmen'),
              subtitle: Text('Mit der Kamera fotografieren'),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromCamera();
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library, color: Color(0xFF5A7D7D)),
              title: Text('Aus Galerie wählen'),
              subtitle: Text('Vorhandenes Foto auswählen'),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromGallery();
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
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        await _importImage(File(image.path));

        // Prüfen, ob Foto-Galerie-Berechtigung vorhanden ist
        final hasPhotosPermission =
            await PermissionService.checkPhotosPermission();
        if (!hasPhotosPermission) {
          // Dialog mit Warnmeldung anzeigen
          _showPhotoPermissionWarningDialog();
        }
      }
    } catch (e) {
      // Prüfen, ob es ein Berechtigungsfehler war
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('permission') ||
          errorString.contains('denied') ||
          errorString.contains('camera_access_denied') ||
          errorString.contains('access_denied')) {
        // Prüfen, ob die Kamera-Berechtigung tatsächlich verweigert wurde
        final hasPermission = await PermissionService.checkCameraPermission();
        if (!hasPermission) {
          _showCameraPermissionDialog();
          return;
        }
      }

      _showErrorSnackBar('Fehler beim Aufnehmen des Fotos: $e');
    }
  }

  void _pickImageFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        await _importImage(File(image.path));
      }
    } catch (e) {
      // Prüfen, ob es ein Berechtigungsfehler war
      if (e.toString().contains('permission') ||
          e.toString().contains('denied')) {
        // Prüfen, ob die Foto-Berechtigung tatsächlich verweigert wurde
        final hasPermission = await PermissionService.checkPhotosPermission();
        if (!hasPermission) {
          _showPhotoPermissionDialog();
          return;
        }
      }

      _showErrorSnackBar('Fehler beim Auswählen des Bildes: $e');
    }
  }

  void _showPhotoPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.photo_library, color: Color(0xFF5A7D7D)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Berechtigung erforderlich',
                softWrap: true,
              ),
            ),
          ],
        ),
        content: Text(
          'Für den Zugriff auf Ihre Fotos benötigt die App die Foto-Berechtigung. '
          'Bitte aktivieren Sie diese in den Einstellungen.\n\n'
          'Achtung: Bei Nicht-Aktivierung werden Fotos ausschließlich in der App gespeichert und beim Löschen der App ebenfalls gelöscht.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              PermissionService.openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF5A7D7D),
              foregroundColor: Colors.white,
            ),
            child: Text('Einstellungen öffnen'),
          ),
        ],
      ),
    );
  }

  void _showCameraPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.camera_alt, color: Color(0xFF5A7D7D)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Berechtigung erforderlich',
                softWrap: true,
              ),
            ),
          ],
        ),
        content: Text(
          'Für das Aufnehmen von Fotos benötigt die App die Kamera-Berechtigung. '
          'Bitte aktivieren Sie diese in den Einstellungen.\n\n'
          'Achtung: Bei Nicht-Aktivierung werden Fotos ausschließlich in der App gespeichert und beim Löschen der App ebenfalls gelöscht.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              PermissionService.openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF5A7D7D),
              foregroundColor: Colors.white,
            ),
            child: Text('Einstellungen öffnen'),
          ),
        ],
      ),
    );
  }

  void _showPhotoPermissionWarningDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.photo_library, color: Color(0xFF5A7D7D)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Berechtigung erforderlich',
                softWrap: true,
              ),
            ),
          ],
        ),
        content: Text(
          'Achtung: Bei Nicht-Aktivierung werden Fotos ausschließlich in der App gespeichert und beim Löschen der App ebenfalls gelöscht.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              PermissionService.openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF5A7D7D),
              foregroundColor: Colors.white,
            ),
            child: Text('Einstellungen öffnen'),
          ),
        ],
      ),
    );
  }

  Future<void> _importImage(File imageFile) async {
    try {
      if (!imageFile.existsSync()) {
        _showErrorSnackBar('Bild-Datei existiert nicht');
        return;
      }

      // Zielverzeichnis für Bilder erstellen
      final appDir = await getApplicationDocumentsDirectory();
      final bilderDir = Directory('${appDir.path}/bilder');
      if (!bilderDir.existsSync()) {
        await bilderDir.create(recursive: true);
      }

      // Eindeutigen Dateinamen generieren
      final uuid = Uuid();
      final fileExtension = imageFile.path.split('.').last.toLowerCase();
      final newFileName = '${uuid.v4()}.$fileExtension';
      final newFilePath = '${bilderDir.path}/$newFileName';

      // Datei kopieren
      final newFile = await imageFile.copy(newFilePath);

      // Bild-Objekt erstellen
      final bild = Bild(
        id: uuid.v4(),
        dateiname: newFileName,
        dateipfad: newFile.path,
        aufnahmeZeit: DateTime.now(),
        etappenId: null, // Kein Etappen-Bezug bei manuell hinzugefügten Bildern
      );

      // Bild zum Provider hinzufügen
      final bilderProvider =
          Provider.of<BilderProvider>(context, listen: false);
      await bilderProvider.addBild(bild);
    } catch (e) {
      _showErrorSnackBar('Fehler beim Importieren des Bildes: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Color(0xFF8C0A28),
      ),
    );
  }
}

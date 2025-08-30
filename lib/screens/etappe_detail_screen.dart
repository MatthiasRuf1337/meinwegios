import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import '../models/etappe.dart';
import '../models/bild.dart';
import '../models/notiz.dart';
import '../providers/etappen_provider.dart';
import '../providers/bilder_provider.dart';
import '../providers/notiz_provider.dart';
import '../providers/audio_provider.dart';
import '../services/database_service.dart';
import '../services/permission_service.dart';
import 'bild_detail_screen.dart';

import '../widgets/audio_recording_widget.dart';
import '../widgets/static_route_map_widget.dart';
import '../widgets/wetter_widget.dart';
import '../widgets/impulsfrage_widget.dart';
import '../widgets/impulsfrage_audio_widget.dart';
import '../services/impulsfragen_service.dart';
import 'main_navigation.dart';
import 'dart:io';

class EtappeDetailScreen extends StatefulWidget {
  final Etappe etappe;
  final bool fromCompletedScreen;

  const EtappeDetailScreen({
    Key? key,
    required this.etappe,
    this.fromCompletedScreen = false,
  }) : super(key: key);

  @override
  _EtappeDetailScreenState createState() => _EtappeDetailScreenState();
}

class _EtappeDetailScreenState extends State<EtappeDetailScreen>
    with WidgetsBindingObserver {
  final ImagePicker _picker = ImagePicker();
  final ImpulsfrageService _impulsfrageService = ImpulsfrageService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeImpulsfragen();

    // Provider laden
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BilderProvider>(context, listen: false).loadBilder();
      Provider.of<AudioProvider>(context, listen: false).loadAudioAufnahmen();
      Provider.of<NotizProvider>(context, listen: false).loadNotizen();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        print('App wieder aufgenommen - lade Provider neu');
        // Provider neu laden um sicherzustellen, dass alle Daten aktuell sind
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Provider.of<BilderProvider>(context, listen: false).loadBilder();
          Provider.of<AudioProvider>(context, listen: false)
              .loadAudioAufnahmen();
          Provider.of<NotizProvider>(context, listen: false).loadNotizen();
        });
        break;
      default:
        break;
    }
  }

  Future<void> _initializeImpulsfragen() async {
    await _impulsfrageService.loadImpulsfragen();
  }

  @override
  Widget build(BuildContext context) {
    return _buildEtappeDetailsContent();
  }

  Widget _buildEtappeDetailsContent() {
    return Scaffold(
      appBar: AppBar(
        title: Text('Etappen-Details'),
        backgroundColor: Color(0xFF5A7D7D),
        foregroundColor: Colors.white,
        leading: widget.fromCompletedScreen
            ? IconButton(
                icon: Icon(Icons.home),
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                  MainNavigationController.switchToTab(
                      0); // Zum Archiv-Tab wechseln
                },
              )
            : null,
        actions: [
          if (widget.fromCompletedScreen)
            IconButton(
              icon: Icon(Icons.list),
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
                // Wechsle zum Etappen-Tab (Index 0)
                MainNavigationController.switchToTab(0);
              },
              tooltip: 'Zur Etappen-Übersicht',
            ),
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () => _editEtappe(context),
          ),
          // Löschen-Button nur anzeigen wenn nicht von completed screen
          if (!widget.fromCompletedScreen)
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: () => _deleteEtappe(context),
            ),
        ],
      ),
      body: Consumer4<EtappenProvider, BilderProvider, NotizProvider,
          AudioProvider>(
        builder: (context, etappenProvider, bilderProvider, notizProvider,
            audioProvider, child) {
          // Verwende die aktualisierte Etappe aus dem Provider, falls verfügbar
          final etappe = etappenProvider.etappen.firstWhere(
              (e) => e.id == widget.etappe.id,
              orElse: () => widget.etappe);
          final bilder = bilderProvider.getBilderByEtappe(widget.etappe.id);

          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Etappen-Header
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                etappe.name,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                            _buildStatusChip(etappe.status),
                          ],
                        ),
                        SizedBox(height: 8),
                        if (etappe.notizen != null &&
                            etappe.notizen!.isNotEmpty)
                          Text(
                            etappe.notizen!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),

                // Statistiken
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Statistiken',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            SizedBox(
                                width:
                                    24), // Platzhalter für konsistenten Abstand
                          ],
                        ),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatItem(
                                'Distanz',
                                etappe.formatierteDistanz,
                                Icons.straighten,
                              ),
                            ),
                            Expanded(
                              child: _buildStatItem(
                                'Schritte',
                                '${etappe.schrittAnzahl}',
                                Icons.directions_walk,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatItem(
                                'Dauer',
                                _formatDuration(etappe.dauer),
                                Icons.timer,
                              ),
                            ),
                            Expanded(
                              child: _buildStatItem(
                                'Bilder',
                                '${bilder.length}',
                                Icons.photo_camera,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),

                // Wetter-Informationen (wenn vorhanden)
                if (etappe.startWetter != null ||
                    etappe.wetterVerlauf.isNotEmpty)
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Wetterbedingungen',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              SizedBox(
                                  width:
                                      24), // Platzhalter für konsistenten Abstand
                            ],
                          ),
                          SizedBox(height: 16),

                          // Start-Wetter
                          if (etappe.startWetter != null) ...[
                            Text(
                              'Wetter beim Start',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                            SizedBox(height: 8),
                            WetterWidget(
                              wetterDaten: etappe.startWetter,
                              compact: false,
                            ),
                          ],

                          // Wetter-Verlauf
                          if (etappe.wetterVerlauf.isNotEmpty) ...[
                            if (etappe.startWetter != null)
                              SizedBox(height: 16),
                            Text(
                              'Wetter-Verlauf (${etappe.wetterVerlauf.length} Updates)',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                            SizedBox(height: 8),
                            _buildWetterVerlauf(etappe.wetterVerlauf),
                          ],
                        ],
                      ),
                    ),
                  ),
                if (etappe.startWetter != null ||
                    etappe.wetterVerlauf.isNotEmpty)
                  SizedBox(height: 16),

                // Route-Karte (nur wenn GPS-Daten vorhanden)
                if (etappe.gpsPunkte.isNotEmpty)
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Gelaufene Route',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              SizedBox(
                                  width:
                                      24), // Platzhalter für konsistenten Abstand
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Deine aufgezeichnete Strecke auf der Karte',
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 16),
                          StaticRouteMapWidget(
                            etappe: etappe,
                            height: 300,
                          ),
                        ],
                      ),
                    ),
                  ),
                if (etappe.gpsPunkte.isNotEmpty) SizedBox(height: 16),

                // Impulsfragen-Sektion
                _buildImpulsfrageSection(),
                SizedBox(height: 16),

                // Bilder-Sektion
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Bilder',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.camera_alt,
                                  color: Color(0xFF5A7D7D)),
                              onPressed: _showImageSourceDialog,
                              tooltip: 'Bild hinzufügen',
                              padding: EdgeInsets.zero,
                              constraints: BoxConstraints(),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        if (bilder.isEmpty)
                          Center(
                            child: Text(
                              'Noch keine Bilder vorhanden',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          )
                        else
                          GridView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                            itemCount: bilder.length,
                            itemBuilder: (context, index) {
                              final bild = bilder[index];
                              return GestureDetector(
                                onTap: () => _openBildDetail(bild),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Stack(
                                      children: [
                                        Positioned.fill(
                                          child: Image.file(
                                            File(bild.dateipfad),
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return Container(
                                                color: Colors.grey[300],
                                                child: Icon(
                                                  Icons.broken_image,
                                                  color: Colors.grey[600],
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                        Positioned(
                                          top: 4,
                                          right: 4,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.black.withOpacity(0.4),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  icon: Icon(Icons.delete,
                                                      color: Colors.white,
                                                      size: 18),
                                                  padding: EdgeInsets.zero,
                                                  constraints: BoxConstraints(),
                                                  tooltip: 'Bild löschen',
                                                  onPressed: () =>
                                                      _confirmDeleteBild(bild),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),

                // Notizen-Sektion
                Builder(
                  builder: (context) {
                    final notizen =
                        notizProvider.getNotizenByEtappe(widget.etappe.id);
                    return Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Notizen',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                IconButton(
                                  icon:
                                      Icon(Icons.add, color: Color(0xFF5A7D7D)),
                                  onPressed: () => _showNotizDialog(),
                                  tooltip: 'Notiz hinzufügen',
                                  padding: EdgeInsets.zero,
                                  constraints: BoxConstraints(),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            if (notizen.isEmpty)
                              Center(
                                child: Text(
                                  'Noch keine Notizen vorhanden',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              )
                            else
                              ListView.separated(
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                itemCount: notizen.length,
                                separatorBuilder: (context, index) => Divider(),
                                itemBuilder: (context, index) {
                                  final notiz = notizen[index];
                                  return ListTile(
                                    title: Text(
                                      notiz.titel.isNotEmpty
                                          ? notiz.titel
                                          : 'Ohne Titel',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(height: 4),
                                        Text(
                                          notiz.inhalt,
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'Erstellt: ${notiz.formatierteErstellungszeit}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        if (notiz.bearbeitetAm != null)
                                          Text(
                                            'Bearbeitet: ${DateFormat('dd.MM.yyyy HH:mm').format(notiz.bearbeitetAm!)}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                      ],
                                    ),
                                    trailing: PopupMenuButton<String>(
                                      onSelected: (value) {
                                        if (value == 'edit') {
                                          _showNotizDialog(
                                              existingNotiz: notiz);
                                        } else if (value == 'delete') {
                                          _confirmDeleteNotiz(notiz);
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        PopupMenuItem(
                                          value: 'edit',
                                          child: Row(
                                            children: [
                                              Icon(Icons.edit, size: 18),
                                              SizedBox(width: 8),
                                              Text('Bearbeiten'),
                                            ],
                                          ),
                                        ),
                                        PopupMenuItem(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              Icon(Icons.delete,
                                                  size: 18,
                                                  color: Color(0xFF8C0A28)),
                                              SizedBox(width: 8),
                                              Text('Löschen',
                                                  style: TextStyle(
                                                      color:
                                                          Color(0xFF8C0A28))),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: 16),

                // Audio-Aufnahmen Sektion
                AudioRecordingWidget(etappenId: widget.etappe.id),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildImpulsfrageSection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header für die gesamte Sektion - nur Text, kein Icon
          Text(
            'Impulsfrage & Audio-Notiz',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF8C0A28),
            ),
          ),

          SizedBox(height: 16),

          // Impulsfrage Widget (ohne eigene Box)
          ImpulsfrageWidget(etappenId: widget.etappe.id),

          SizedBox(height: 16),

          // Audio-Aufnahme Widget (ohne eigene Box)
          ImpulsfrageAudioWidget(etappenId: widget.etappe.id),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Color(0xFF5A7D7D), size: 24),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
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

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  Widget _buildStatusChip(EtappenStatus status) {
    Color color;
    String text;

    switch (status) {
      case EtappenStatus.aktiv:
        color = Colors.orange;
        text = 'Aktiv';
        break;
      case EtappenStatus.pausiert:
        color = Colors.blue;
        text = 'Pausiert';
        break;
      case EtappenStatus.abgeschlossen:
        color = Color(0xFF5A7D7D);
        text = 'Abgeschlossen';
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Bild hinzufügen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt, color: Color(0xFF5A7D7D)),
              title: Text('Kamera'),
              subtitle: Text('Neues Foto aufnehmen'),
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library, color: Color(0xFF5A7D7D)),
              title: Text('Galerie'),
              subtitle: Text('Bild aus Galerie auswählen'),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromGallery();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Abbrechen'),
          ),
        ],
      ),
    );
  }

  Future<void> _takePhoto() async {
    try {
      // Direkt versuchen, die Kamera zu öffnen (Image Picker fragt automatisch nach Berechtigung)
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (photo != null) {
        await _saveImage(photo, 'camera');
      }
    } catch (e) {
      // Spezifische Fehlermeldung für Kamera-Fehler
      String errorMessage = 'Fehler beim Aufnehmen des Fotos';
      if (e.toString().contains('permission') ||
          e.toString().contains('denied')) {
        errorMessage =
            'Kamera-Berechtigung verweigert. Bitte erlauben Sie den Zugriff in den Einstellungen.';
      } else if (e.toString().contains('camera') ||
          e.toString().contains('unavailable')) {
        errorMessage =
            'Kamera nicht verfügbar. Bitte überprüfen Sie, ob die Kamera von einer anderen App verwendet wird.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Color(0xFF8C0A28),
          duration: Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Einstellungen',
            textColor: Colors.white,
            onPressed: () => PermissionService.openAppSettings(),
          ),
        ),
      );
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      // Direkt versuchen, die Galerie zu öffnen (Image Picker fragt automatisch nach Berechtigung)
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        await _saveImage(image, 'gallery');
      }
    } catch (e) {
      // Spezifische Fehlermeldung für Galerie-Fehler
      String errorMessage = 'Fehler beim Auswählen des Bildes';
      if (e.toString().contains('permission') ||
          e.toString().contains('denied')) {
        errorMessage =
            'Galerie-Berechtigung verweigert. Bitte erlauben Sie den Zugriff in den Einstellungen.';
      } else if (e.toString().contains('gallery') ||
          e.toString().contains('unavailable')) {
        errorMessage =
            'Galerie nicht verfügbar. Bitte überprüfen Sie, ob Bilder in der Galerie vorhanden sind.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Color(0xFF8C0A28),
          duration: Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Einstellungen',
            textColor: Colors.white,
            onPressed: () => PermissionService.openAppSettings(),
          ),
        ),
      );
    }
  }

  Future<void> _saveImage(XFile image, String source) async {
    try {
      // Position abrufen
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
      } catch (e) {
        print('Fehler beim Abrufen der Position: $e');
      }

      // Bild dauerhaft in das App-Dokumente-Verzeichnis kopieren
      final appDocsDir = await getApplicationDocumentsDirectory();
      final bilderDir = Directory(p.join(appDocsDir.path, 'bilder'));
      if (!bilderDir.existsSync()) {
        await bilderDir.create(recursive: true);
      }
      final newFileName = 'IMG_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final newPath = p.join(bilderDir.path, newFileName);
      final savedFile = await File(image.path).copy(newPath);

      // Bild in Datenbank speichern
      final bild = Bild(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        dateiname: newFileName,
        dateipfad: savedFile.path,
        latitude: position?.latitude,
        longitude: position?.longitude,
        aufnahmeZeit: DateTime.now(),
        etappenId: widget.etappe.id,
        metadaten: {
          'quelle': source,
          'qualitaet': '80%',
        },
      );

      await DatabaseService.instance.insertBild(bild);

      // Bild auch in die Galerie speichern
      try {
        await ImageGallerySaver.saveFile(savedFile.path);
      } catch (e) {
        print('Fehler beim Speichern in die Galerie: $e');
        // Galerie-Fehler nicht als kritisch behandeln
      }

      // Provider aktualisieren
      final bilderProvider =
          Provider.of<BilderProvider>(context, listen: false);
      await bilderProvider.loadBilder();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Bild erfolgreich hinzugefügt und in Galerie gespeichert!'),
          backgroundColor: Color(0xFF8C0A28),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Speichern des Bildes: $e'),
          backgroundColor: Color(0xFF8C0A28),
        ),
      );
    }
  }

  void _openBildDetail(Bild bild) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BildDetailScreen(bild: bild),
      ),
    );
  }

  void _confirmDeleteBild(Bild bild) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Bild löschen'),
        content: Text('Möchtest du dieses Bild wirklich löschen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Abbrechen'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF8C0A28),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(context);
              final bilderProvider =
                  Provider.of<BilderProvider>(context, listen: false);
              await bilderProvider.deleteBild(bild.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Bild gelöscht'),
                  backgroundColor: Color(0xFF8C0A28),
                ),
              );
            },
            child: Text('Löschen'),
          ),
        ],
      ),
    );
  }

  void _editEtappe(BuildContext context) {
    _showEditEtappeDialog();
  }

  void _showEditEtappeDialog() {
    final nameController = TextEditingController(text: widget.etappe.name);
    final notizenController =
        TextEditingController(text: widget.etappe.notizen ?? '');
    final distanzController = TextEditingController(
        text: widget.etappe.gesamtDistanz.toStringAsFixed(0));
    final schritteController =
        TextEditingController(text: widget.etappe.schrittAnzahl.toString());

    // Dauer in Minuten für einfachere Bearbeitung
    final dauerInMinuten = widget.etappe.dauer.inMinutes;
    final dauerController =
        TextEditingController(text: dauerInMinuten.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Etappe bearbeiten'),
        contentPadding: EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 0.0),
        content: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Name/Bezeichnung
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Bezeichnung *',
                    hintText: 'z.B. Morgenspaziergang',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: Color(0xFF5A7D7D), width: 2),
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    prefixIcon: Icon(Icons.label),
                  ),
                ),
                SizedBox(height: 16),

                // Beschreibung/Notizen
                TextField(
                  controller: notizenController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Beschreibung',
                    hintText: 'Zusätzliche Notizen zur Etappe...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: Color(0xFF5A7D7D), width: 2),
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    prefixIcon: Icon(Icons.description),
                  ),
                ),
                SizedBox(height: 16),

                // Statistiken-Sektion
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.analytics, color: Color(0xFF5A7D7D)),
                          SizedBox(width: 8),
                          Text(
                            'Statistiken bearbeiten',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF5A7D7D),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),

                      // Distanz
                      TextField(
                        controller: distanzController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Distanz (Meter)',
                          hintText: 'z.B. 1500',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                BorderSide(color: Color(0xFF5A7D7D), width: 2),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          prefixIcon: Icon(Icons.straighten, size: 20),
                          suffixText: 'm',
                        ),
                      ),
                      SizedBox(height: 12),

                      // Schritte
                      TextField(
                        controller: schritteController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Schritte',
                          hintText: 'z.B. 2000',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                BorderSide(color: Color(0xFF5A7D7D), width: 2),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          prefixIcon: Icon(Icons.trending_up, size: 20),
                        ),
                      ),
                      SizedBox(height: 12),

                      // Dauer
                      TextField(
                        controller: dauerController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Dauer (Minuten)',
                          hintText: 'z.B. 30',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                BorderSide(color: Color(0xFF5A7D7D), width: 2),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          prefixIcon: Icon(Icons.timer, size: 20),
                          suffixText: 'min',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('Bitte geben Sie eine Bezeichnung ein')),
                );
                return;
              }

              try {
                // Eingaben validieren und parsen
                final newName = nameController.text.trim();
                final newNotizen = notizenController.text.trim().isEmpty
                    ? null
                    : notizenController.text.trim();

                final newDistanz = double.tryParse(distanzController.text) ??
                    widget.etappe.gesamtDistanz;
                final newSchritte = int.tryParse(schritteController.text) ??
                    widget.etappe.schrittAnzahl;
                final newDauerMinuten = int.tryParse(dauerController.text) ??
                    widget.etappe.dauer.inMinutes;

                // Neue Endzeit basierend auf der bearbeiteten Dauer berechnen
                final newEndzeit = widget.etappe.startzeit
                    .add(Duration(minutes: newDauerMinuten));

                // Aktualisierte Etappe erstellen
                final updatedEtappe = widget.etappe.copyWith(
                  name: newName,
                  notizen: newNotizen,
                  gesamtDistanz: newDistanz,
                  schrittAnzahl: newSchritte,
                  endzeit: newEndzeit,
                );

                // Etappe in der Datenbank aktualisieren
                final etappenProvider =
                    Provider.of<EtappenProvider>(context, listen: false);
                await etappenProvider.updateEtappe(updatedEtappe);

                Navigator.pop(context);

                // Erfolgreiche Aktualisierung
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Etappe erfolgreich aktualisiert!'),
                    backgroundColor: Color(0xFF8C0A28),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Fehler beim Speichern: $e'),
                    backgroundColor: Color(0xFF8C0A28),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF8C0A28),
              foregroundColor: Colors.white,
            ),
            child: Text('Speichern'),
          ),
        ],
      ),
    );
  }

  void _deleteEtappe(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Etappe löschen'),
        content: Text('Möchtest du diese Etappe wirklich löschen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Dialog schließen

              try {
                // Etappe löschen
                await Provider.of<EtappenProvider>(context, listen: false)
                    .deleteEtappe(widget.etappe.id);

                // Erfolgreiche Löschung - zur Hauptnavigation zurückkehren
                if (widget.fromCompletedScreen) {
                  // Wenn von completed screen: Zur Hauptnavigation mit Archiv-Tab
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MainNavigation(initialTab: 0),
                    ),
                    (route) => false, // Alle vorherigen Routen entfernen
                  );
                } else {
                  // Normale Navigation zurück
                  Navigator.pop(context);
                }

                // Erfolgsmeldung anzeigen
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text('Etappe "${widget.etappe.name}" wurde gelöscht'),
                    backgroundColor: Color(0xFF8C0A28),
                  ),
                );
              } catch (e) {
                // Fehlermeldung anzeigen
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Fehler beim Löschen der Etappe: $e'),
                    backgroundColor: Color(0xFF8C0A28),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF8C0A28),
              foregroundColor: Colors.white,
            ),
            child: Text('Löschen'),
          ),
        ],
      ),
    );
  }

  void _showNotizDialog({Notiz? existingNotiz}) {
    final titelController =
        TextEditingController(text: existingNotiz?.titel ?? '');
    final inhaltController =
        TextEditingController(text: existingNotiz?.inhalt ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existingNotiz != null ? 'Notiz bearbeiten' : 'Neue Notiz'),
        contentPadding: EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 0.0),
        content: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titelController,
                  decoration: InputDecoration(
                    labelText: 'Titel (optional)',
                    hintText: 'z.B. Wichtige Beobachtung',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: Color(0xFF5A7D7D), width: 2),
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    prefixIcon: Icon(Icons.title),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: inhaltController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    labelText: 'Notiz *',
                    hintText: 'Ihre Notiz hier eingeben...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: Color(0xFF5A7D7D), width: 2),
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    prefixIcon: Icon(Icons.note),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          if (existingNotiz != null)
            TextButton(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Notiz löschen'),
                    content: Text('Möchten Sie diese Notiz wirklich löschen?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text('Abbrechen'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF8C0A28),
                          foregroundColor: Colors.white,
                        ),
                        child: Text('Löschen'),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  try {
                    final notizProvider =
                        Provider.of<NotizProvider>(context, listen: false);
                    await notizProvider.deleteNotiz(existingNotiz.id);

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Notiz gelöscht!'),
                        backgroundColor: Color(0xFF8C0A28),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Fehler beim Löschen: $e'),
                        backgroundColor: Color(0xFF8C0A28),
                      ),
                    );
                  }
                }
              },
              child:
                  Text('Löschen', style: TextStyle(color: Color(0xFF8C0A28))),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (inhaltController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Bitte geben Sie eine Notiz ein')),
                );
                return;
              }

              try {
                final notizProvider =
                    Provider.of<NotizProvider>(context, listen: false);

                if (existingNotiz != null) {
                  // Bestehende Notiz aktualisieren
                  final updatedNotiz = existingNotiz.copyWith(
                    titel: titelController.text.trim(),
                    inhalt: inhaltController.text.trim(),
                    bearbeitetAm: DateTime.now(),
                  );
                  await notizProvider.updateNotiz(updatedNotiz);

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Notiz aktualisiert!'),
                      backgroundColor: Color(0xFF8C0A28),
                    ),
                  );
                } else {
                  // Neue Notiz erstellen
                  final notiz = Notiz(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    titel: titelController.text.trim(),
                    inhalt: inhaltController.text.trim(),
                    erstelltAm: DateTime.now(),
                    etappenId: widget.etappe.id,
                  );

                  await notizProvider.addNotiz(notiz);

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Notiz hinzugefügt!'),
                      backgroundColor: Color(0xFF8C0A28),
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Fehler beim Speichern: $e'),
                    backgroundColor: Color(0xFF8C0A28),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF8C0A28),
              foregroundColor: Colors.white,
            ),
            child: Text(existingNotiz != null ? 'Aktualisieren' : 'Speichern'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteNotiz(Notiz notiz) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Notiz löschen'),
        content: Text('Möchten Sie diese Notiz wirklich löschen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final notizProvider =
                    Provider.of<NotizProvider>(context, listen: false);
                await notizProvider.deleteNotiz(notiz.id);

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Notiz gelöscht!'),
                    backgroundColor: Color(0xFF8C0A28),
                  ),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Fehler beim Löschen: $e'),
                    backgroundColor: Color(0xFF8C0A28),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF8C0A28),
              foregroundColor: Colors.white,
            ),
            child: Text('Löschen'),
          ),
        ],
      ),
    );
  }

  Widget _buildWetterVerlauf(List wetterVerlauf) {
    if (wetterVerlauf.isEmpty) return SizedBox.shrink();

    return Container(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: wetterVerlauf.length,
        itemBuilder: (context, index) {
          final wetter = wetterVerlauf[index];
          return Container(
            width: 140,
            margin: EdgeInsets.only(right: 8),
            child: Card(
              elevation: 1,
              child: Padding(
                padding: EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          wetter.wetterEmoji,
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            wetter.formatierteTemperatur,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF00847E),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      wetter.beschreibung,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      DateFormat('HH:mm').format(wetter.zeitstempel),
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

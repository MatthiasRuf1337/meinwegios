import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/etappe.dart';
import '../models/bild.dart';
import '../models/notiz.dart';
import '../providers/etappen_provider.dart';
import '../providers/bilder_provider.dart';
import '../providers/notiz_provider.dart';
import '../services/database_service.dart';
import '../services/permission_service.dart';
import 'bild_detail_screen.dart';
import 'galerie_screen.dart';
import 'mediathek_screen.dart';
import 'etappe_start_screen.dart';
import '../widgets/audio_recording_widget.dart';
import '../widgets/static_route_map_widget.dart';
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

class _EtappeDetailScreenState extends State<EtappeDetailScreen> {
  final ImagePicker _picker = ImagePicker();

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
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () => _deleteEtappe(context),
          ),
        ],
      ),
      body: Consumer3<EtappenProvider, BilderProvider, NotizProvider>(
        builder:
            (context, etappenProvider, bilderProvider, notizProvider, child) {
          // Verwende die aktuelle Etappe aus dem Widget
          final etappe = widget.etappe;
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
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
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
                              fontSize: 16,
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
                        Text(
                          'Statistiken',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
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
                                'Distanz',
                                etappe.formatierteDistanz,
                                Icons.straighten,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatItem(
                                'Schritte',
                                '${etappe.schrittAnzahl}',
                                Icons.trending_up,
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

                // Route-Karte (nur wenn GPS-Daten vorhanden)
                if (etappe.gpsPunkte.isNotEmpty)
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Gelaufene Route',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
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
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.camera_alt),
                                  onPressed: _showImageSourceDialog,
                                  tooltip: 'Foto aufnehmen',
                                ),
                                IconButton(
                                  icon: Icon(Icons.photo_library),
                                  onPressed: _pickImageFromGallery,
                                  tooltip: 'Aus Galerie auswählen',
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        if (bilder.isEmpty)
                          Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.photo_library_outlined,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Noch keine Bilder',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                SizedBox(height: 8),
                                ElevatedButton.icon(
                                  onPressed: _showImageSourceDialog,
                                  icon: Icon(Icons.add_a_photo),
                                  label: Text('Bild hinzufügen'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFF5A7D7D),
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
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
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.add),
                                  onPressed: () => _showNotizDialog(),
                                  tooltip: 'Notiz hinzufügen',
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            if (notizen.isEmpty)
                              Container(
                                padding: EdgeInsets.all(20),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.note_add,
                                      size: 48,
                                      color: Colors.grey[400],
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Noch keine Notizen vorhanden',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
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
                                                  size: 18, color: Colors.red),
                                              SizedBox(width: 8),
                                              Text('Löschen',
                                                  style: TextStyle(
                                                      color: Colors.red)),
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

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF5A7D7D).withOpacity(0.1),
            Color(0xFF5A7D7D).withOpacity(0.2)
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.directions_walk, color: Color(0xFF5A7D7D)),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.etappe.name,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5A7D7D),
                  ),
                ),
              ),
              _buildStatusChip(widget.etappe.status),
            ],
          ),
          SizedBox(height: 12),
          Text(
            'Erstellt am ${DateFormat('dd.MM.yyyy HH:mm').format(widget.etappe.erstellungsDatum)}',
            style: TextStyle(
              color: Color(0xFF5A7D7D).withOpacity(0.8),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatistics() {
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
          Text(
            'Statistiken',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                  child: _buildStatItem('Distanz',
                      widget.etappe.formatierteDistanz, Icons.straighten)),
              Expanded(
                  child: _buildStatItem('Schritte',
                      '${widget.etappe.schrittAnzahl}', Icons.directions_walk)),
              Expanded(
                  child: _buildStatItem(
                      'Dauer', widget.etappe.formatierteDauer, Icons.timer)),
            ],
          ),
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
            fontSize: 16,
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

  Widget _buildDetails() {
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
          Text(
            'Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          _buildDetailRow('Startzeit',
              DateFormat('dd.MM.yyyy HH:mm').format(widget.etappe.startzeit)),
          if (widget.etappe.endzeit != null)
            _buildDetailRow('Endzeit',
                DateFormat('dd.MM.yyyy HH:mm').format(widget.etappe.endzeit!)),
          _buildDetailRow('GPS-Punkte', '${widget.etappe.gpsPunkte.length}'),
          _buildDetailRow('Bilder', '${widget.etappe.bildIds.length}'),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBilderSection() {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Bilder',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () => _showImageSourceDialog(),
                    icon: Icon(Icons.add_a_photo, color: Color(0xFF5A7D7D)),
                    tooltip: 'Bild hinzufügen',
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 16),
          Consumer<BilderProvider>(
            builder: (context, bilderProvider, child) {
              final etappenBilder =
                  bilderProvider.getBilderByEtappe(widget.etappe.id);

              if (etappenBilder.isEmpty) {
                return _buildEmptyBilderState();
              }

              return _buildBilderGrid(etappenBilder);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyBilderState() {
    return Container(
      padding: EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 48,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 16),
          Text(
            'Keine Bilder vorhanden',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Fügen Sie Bilder zu dieser Etappe hinzu',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _showImageSourceDialog(),
            icon: Icon(Icons.add_a_photo),
            label: Text('Bild hinzufügen'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF5A7D7D),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBilderGrid(List<Bild> bilder) {
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: bilder.length,
      itemBuilder: (context, index) {
        final bild = bilder[index];
        return _buildBildTile(bild);
      },
    );
  }

  Widget _buildBildTile(Bild bild) {
    return GestureDetector(
      onTap: () => _openBildDetail(bild),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            children: [
              _buildImageWidget(bild),
              if (bild.hatGPS)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(
                      Icons.location_on,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
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

  Widget _buildNotizen() {
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
          Text(
            'Notizen',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          Text(
            widget.etappe.notizen!,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
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
          backgroundColor: Colors.red,
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
          backgroundColor: Colors.red,
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

      // Provider aktualisieren
      final bilderProvider =
          Provider.of<BilderProvider>(context, listen: false);
      await bilderProvider.loadBilder();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bild erfolgreich hinzugefügt!'),
          backgroundColor: Color(0xFF5A7D7D),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Speichern des Bildes: $e'),
          backgroundColor: Colors.red,
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              final bilderProvider =
                  Provider.of<BilderProvider>(context, listen: false);
              await bilderProvider.deleteBild(bild.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Bild gelöscht'),
                  backgroundColor: Colors.red,
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
    // Implementierung für das Bearbeiten der Etappe
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Bearbeiten-Funktion wird implementiert...')),
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
            onPressed: () {
              Navigator.pop(context);
              Provider.of<EtappenProvider>(context, listen: false)
                  .deleteEtappe(widget.etappe.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titelController,
                decoration: InputDecoration(
                  labelText: 'Titel (optional)',
                  hintText: 'z.B. Wichtige Beobachtung',
                  border: OutlineInputBorder(),
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
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note),
                ),
              ),
            ],
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
                          backgroundColor: Colors.red,
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
                        backgroundColor: Color(0xFF5A7D7D),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Fehler beim Löschen: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: Text('Löschen', style: TextStyle(color: Colors.red)),
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
                      backgroundColor: Color(0xFF5A7D7D),
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
                      backgroundColor: Color(0xFF5A7D7D),
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Fehler beim Speichern: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF5A7D7D),
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
                    backgroundColor: Color(0xFF5A7D7D),
                  ),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Fehler beim Löschen: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
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
}

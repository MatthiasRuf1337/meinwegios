import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../providers/etappen_provider.dart';
import '../providers/bilder_provider.dart';
import '../models/etappe.dart';
import '../models/bild.dart';
import 'etappe_detail_screen.dart';
import 'main_navigation.dart';
import '../widgets/wetter_widget.dart';

class ArchivScreen extends StatefulWidget {
  @override
  _ArchivScreenState createState() => _ArchivScreenState();
}

class _ArchivScreenState extends State<ArchivScreen> {
  String _searchQuery = '';
  EtappenStatus? _selectedStatus;
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Übersicht Etappen'),
        backgroundColor: Color(0xFF45A173),
        foregroundColor: Colors.white,
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () => _showSearchDialog(),
          ),
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(),
          ),
        ],
      ),
      body: Consumer2<EtappenProvider, BilderProvider>(
        builder: (context, etappenProvider, bilderProvider, child) {
          if (etappenProvider.isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          List<Etappe> filteredEtappen =
              _getFilteredEtappen(etappenProvider.etappen);

          if (filteredEtappen.isEmpty) {
            return _buildEmptyState();
          }

          return Column(
            children: [
              // Statistiken
              _buildStatistics(etappenProvider),

              // Etappen Liste
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: filteredEtappen.length,
                  itemBuilder: (context, index) {
                    final etappe = filteredEtappen[index];
                    return _buildEtappeCard(etappe, bilderProvider);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatistics(EtappenProvider provider) {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF45A173).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFF45A173).withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            'Gesamt',
            '${provider.etappen.length}',
            Icons.archive,
          ),
          _buildStatItem(
            'Distanz',
            _formatGesamtDistanz(provider.getGesamtDistanz()),
            Icons.straighten,
          ),
          _buildStatItem(
            'Schritte',
            _formatGesamtSchritte(provider.getGesamtSchritte()),
            Icons.directions_walk,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Color(0xFF45A173), size: 24),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF45A173),
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

  Widget _buildEtappeCard(Etappe etappe, BilderProvider bilderProvider) {
    // Letztes Bild der Etappe finden
    List<Bild> etappenBilder = bilderProvider.getBilderByEtappe(etappe.id);
    Bild? letztesBild = etappenBilder.isNotEmpty
        ? etappenBilder
            .reduce((a, b) => a.aufnahmeZeit.isAfter(b.aufnahmeZeit) ? a : b)
        : null;

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _openEtappeDetail(etappe),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bild-Anzeige über die ganze Breite
            if (letztesBild != null) ...[
              Container(
                width: double.infinity,
                height: 200,
                child: ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
                  child: Image.file(
                    File(letztesBild.dateipfad),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey.shade200,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.broken_image,
                                size: 48,
                                color: Colors.grey.shade400,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Bild konnte nicht geladen werden',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],

            // Etappen-Informationen
            Padding(
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
                          ),
                        ),
                      ),
                      _buildStatusChip(etappe.status),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                      SizedBox(width: 4),
                      Text(
                        DateFormat('dd.MM.yyyy').format(etappe.startzeit),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(width: 16),
                      Icon(Icons.access_time, size: 16, color: Colors.grey),
                      SizedBox(width: 4),
                      Text(
                        DateFormat('HH:mm').format(etappe.startzeit),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                      if (etappe.startWetter != null) ...[
                        SizedBox(width: 16),
                        _buildInfoItem(Icons.wb_sunny,
                            '${etappe.startWetter!.formatierteTemperatur}'),
                      ],
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      _buildInfoItem(
                          Icons.straighten, etappe.formatierteDistanz),
                      SizedBox(width: 16),
                      _buildInfoItem(Icons.directions_walk,
                          '${etappe.schrittAnzahl} Schritte'),
                      SizedBox(width: 16),
                      _buildInfoItem(Icons.timer, etappe.formatierteDauer),
                    ],
                  ),
                  if (etappe.notizen != null && etappe.notizen!.isNotEmpty) ...[
                    SizedBox(height: 8),
                    Text(
                      etappe.notizen!,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  // Bild-Anzahl anzeigen
                  if (etappenBilder.isNotEmpty) ...[
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.photo_library, size: 16, color: Colors.grey),
                        SizedBox(width: 4),
                        Text(
                          '${etappenBilder.length} Bild${etappenBilder.length == 1 ? '' : 'er'}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
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
        color = Color(0xFF45A173);
        text = 'Abgeschlossen';
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
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

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
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
            Icons.archive_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 16),
          Text(
            'Noch keine Etappen vorhanden',
            style: TextStyle(
              fontSize: 20,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Starte deine erste Etappe im Etappen-Tab',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  String _formatGesamtDistanz(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.toStringAsFixed(0)} m';
    } else {
      return '${(distanceInMeters / 1000).toStringAsFixed(2)} km';
    }
  }

  String _formatGesamtSchritte(int totalSteps) {
    if (totalSteps >= 1000000) {
      return '${(totalSteps / 1000000).toStringAsFixed(1)}M';
    } else if (totalSteps >= 1000) {
      return '${(totalSteps / 1000).toStringAsFixed(1)}k';
    } else {
      return '$totalSteps';
    }
  }

  List<Etappe> _getFilteredEtappen(List<Etappe> etappen) {
    List<Etappe> filtered = etappen;

    // Suche
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((etappe) =>
              etappe.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              (etappe.notizen
                      ?.toLowerCase()
                      .contains(_searchQuery.toLowerCase()) ??
                  false))
          .toList();
    }

    // Status Filter
    if (_selectedStatus != null) {
      filtered =
          filtered.where((etappe) => etappe.status == _selectedStatus).toList();
    }

    return filtered;
  }

  void _openEtappeDetail(Etappe etappe) {
    // Wenn die Etappe aktiv ist, zum Live-Tracking wechseln
    if (etappe.status == EtappenStatus.aktiv) {
      // Zeige Feedback und wechsle zum Live-Tracking Tab
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Aktive Etappe! Wechsle zum Live-Tracking...'),
          backgroundColor: Color(0xFF8C0A28),
          duration: Duration(seconds: 1),
        ),
      );

      // Verwende einen globalen Key oder Callback zum Tab-Wechsel
      MainNavigationController.switchToTab(1);
    } else {
      // Normale Etappen-Details öffnen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EtappeDetailScreen(etappe: etappe),
        ),
      );
    }
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Suche'),
        content: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Etappen-Name oder Notizen...',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              _searchController.clear();
              setState(() {
                _searchQuery = '';
              });
              Navigator.pop(context);
            },
            child: Text('Löschen'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Schließen'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Filter'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('Alle'),
              leading: Radio<EtappenStatus?>(
                value: null,
                groupValue: _selectedStatus,
                onChanged: (value) {
                  setState(() {
                    _selectedStatus = value;
                  });
                  Navigator.pop(context);
                },
              ),
            ),
            ListTile(
              title: Text('Aktiv'),
              leading: Radio<EtappenStatus?>(
                value: EtappenStatus.aktiv,
                groupValue: _selectedStatus,
                onChanged: (value) {
                  setState(() {
                    _selectedStatus = value;
                  });
                  Navigator.pop(context);
                },
              ),
            ),
            ListTile(
              title: Text('Pausiert'),
              leading: Radio<EtappenStatus?>(
                value: EtappenStatus.pausiert,
                groupValue: _selectedStatus,
                onChanged: (value) {
                  setState(() {
                    _selectedStatus = value;
                  });
                  Navigator.pop(context);
                },
              ),
            ),
            ListTile(
              title: Text('Abgeschlossen'),
              leading: Radio<EtappenStatus?>(
                value: EtappenStatus.abgeschlossen,
                groupValue: _selectedStatus,
                onChanged: (value) {
                  setState(() {
                    _selectedStatus = value;
                  });
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

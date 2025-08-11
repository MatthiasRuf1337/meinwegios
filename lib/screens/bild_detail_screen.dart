import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/bild.dart';
import 'package:provider/provider.dart';
import '../providers/bilder_provider.dart';

class BildDetailScreen extends StatelessWidget {
  final Bild bild;

  const BildDetailScreen({Key? key, required this.bild}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bild Details'),
        backgroundColor: Color(0xFF00847E),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () => _confirmDelete(context),
            tooltip: 'Bild löschen',
          ),
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () => _shareBild(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bild
            _buildImage(),
            SizedBox(height: 24),

            // Details
            _buildDetails(),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    return Container(
      width: double.infinity,
      height: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _buildImageWidget(),
      ),
    );
  }

  Widget _buildImageWidget() {
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
        size: 64,
      ),
    );
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
          _buildDetailRow('Dateiname', bild.dateiname),
          _buildDetailRow('Aufnahmezeit', bild.formatierteAufnahmeZeit),
          if (bild.hatGPS) ...[
            _buildDetailRow('Breitengrad', bild.latitude!.toStringAsFixed(6)),
            _buildDetailRow('Längengrad', bild.longitude!.toStringAsFixed(6)),
          ],
          if (bild.etappenId != null)
            _buildDetailRow('Etappen-ID', bild.etappenId!),
          if (bild.metadaten.isNotEmpty) ...[
            SizedBox(height: 16),
            Text(
              'Metadaten',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            ...bild.metadaten.entries.map(
                (entry) => _buildDetailRow(entry.key, entry.value.toString())),
          ],
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

  void _shareBild(BuildContext context) {
    // Implementierung für das Teilen des Bildes
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Teilen-Funktion wird implementiert...')),
    );
  }

  void _confirmDelete(BuildContext context) {
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
              // delete via provider
              // We cannot access provider in a StatelessWidget without context:
              // use Provider.of here
              // ignore: use_build_context_synchronously
              final bilderProvider =
                  Provider.of<BilderProvider>(context, listen: false);
              await bilderProvider.deleteBild(bild.id);
              // pop back after deletion
              // ignore: use_build_context_synchronously
              Navigator.pop(context);
              // ignore: use_build_context_synchronously
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('Bild gelöscht'),
                    backgroundColor: Colors.red),
              );
            },
            child: Text('Löschen'),
          ),
        ],
      ),
    );
  }
}

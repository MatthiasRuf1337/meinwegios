import 'package:flutter/material.dart';
import '../models/bild.dart';

class BildDetailScreen extends StatelessWidget {
  final Bild bild;

  const BildDetailScreen({Key? key, required this.bild}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bild Details'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
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
        child: Image.asset(
          'assets/images/placeholder.jpg', // Placeholder
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey.shade200,
              child: Icon(
                Icons.image,
                color: Colors.grey.shade400,
                size: 64,
              ),
            );
          },
        ),
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
    // Implementierung für das Teilen von Bildern
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Teilen-Funktion wird implementiert...')),
    );
  }
} 
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import '../models/medien_datei.dart';
import 'dart:io';

class PDFViewerSimple extends StatefulWidget {
  final MedienDatei medienDatei;

  const PDFViewerSimple({Key? key, required this.medienDatei})
      : super(key: key);

  @override
  _PDFViewerSimpleState createState() => _PDFViewerSimpleState();
}

class _PDFViewerSimpleState extends State<PDFViewerSimple> {
  bool _isLoading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.medienDatei.dateiname),
        backgroundColor: Color(0xFF5A7D7D),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () => _sharePDF(context),
          ),
        ],
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_error != null) {
      return _buildErrorState();
    }

    if (_isLoading) {
      return _buildLoadingState();
    }

    return _buildPDFInfo();
  }

  Widget _buildErrorState() {
    return Container(
      color: Colors.grey.shade100,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade400,
            ),
            SizedBox(height: 16),
            Text(
              'Fehler beim Öffnen der PDF',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(height: 8),
            Text(
              _error ?? 'Unbekannter Fehler',
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _openPDF(),
              icon: Icon(Icons.refresh),
              label: Text('Erneut versuchen'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF8C0A28),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      color: Colors.grey.shade100,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5A7D7D)),
            ),
            SizedBox(height: 16),
            Text(
              'PDF wird geöffnet...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPDFInfo() {
    final file = File(widget.medienDatei.dateipfad);
    final exists = file.existsSync();
    final size = exists ? file.lengthSync() : 0;

    return Container(
      color: Colors.grey.shade100,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.picture_as_pdf,
              size: 80,
              color: Color(0xFF5A7D7D),
            ),
            SizedBox(height: 24),
            Text(
              widget.medienDatei.dateiname,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(16),
              margin: EdgeInsets.symmetric(horizontal: 32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade300,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildInfoRow('Dateipfad', widget.medienDatei.dateipfad),
                  _buildInfoRow('Dateigröße',
                      '${(size / 1024 / 1024).toStringAsFixed(1)} MB'),
                  _buildInfoRow('Datei existiert', exists ? 'Ja' : 'Nein'),
                  _buildInfoRow('Import-Datum',
                      widget.medienDatei.formatiertesImportDatum),
                ],
              ),
            ),
            SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _openPDF(),
              icon: Icon(Icons.open_in_new),
              label: Text('PDF in Standard-App öffnen'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF8C0A28),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Die PDF wird in der Standard-PDF-App Ihres Geräts geöffnet',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openPDF() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final file = File(widget.medienDatei.dateipfad);

      if (!file.existsSync()) {
        setState(() {
          _error = 'PDF-Datei nicht gefunden: ${widget.medienDatei.dateipfad}';
          _isLoading = false;
        });
        return;
      }

      print('Öffne PDF: ${widget.medienDatei.dateipfad}');
      print('Datei existiert: ${file.existsSync()}');
      print('Dateigröße: ${file.lengthSync()} bytes');

      final result = await OpenFile.open(widget.medienDatei.dateipfad);

      if (result.type != ResultType.done) {
        setState(() {
          _error = 'Fehler beim Öffnen: ${result.message}';
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        // Erfolgreich geöffnet, zurück zur Mediathek
        Navigator.pop(context);
      }
    } catch (e) {
      print('Fehler beim Öffnen der PDF: $e');
      setState(() {
        _error = 'Fehler: $e';
        _isLoading = false;
      });
    }
  }

  void _sharePDF(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Teilen-Funktion wird implementiert')),
    );
  }
}

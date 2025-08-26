import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../models/medien_datei.dart';
import 'dart:io';

class PDFViewerScreenAlternative extends StatefulWidget {
  final MedienDatei medienDatei;

  const PDFViewerScreenAlternative({Key? key, required this.medienDatei})
      : super(key: key);

  @override
  _PDFViewerScreenAlternativeState createState() =>
      _PDFViewerScreenAlternativeState();
}

class _PDFViewerScreenAlternativeState
    extends State<PDFViewerScreenAlternative> {
  bool _isLoading = true;
  String? _error;
  GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.medienDatei.dateiname),
        backgroundColor: Color(0xFF45A173),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.bookmark),
            onPressed: () => _addBookmark(context),
          ),
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () => _searchInPDF(context),
          ),
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () => _sharePDF(context),
          ),
        ],
      ),
      body: _buildPDFViewer(),
    );
  }

  Widget _buildPDFViewer() {
    if (_error != null) {
      return _buildErrorState();
    }

    if (_isLoading) {
      return _buildLoadingState();
    }

    return _buildPDFContent();
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
              'Fehler beim Laden der PDF',
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
              onPressed: () => _loadPDF(),
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
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF45A173)),
            ),
            SizedBox(height: 16),
            Text(
              'PDF wird geladen...',
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

  Widget _buildPDFContent() {
    // Prüfen ob Datei existiert
    final file = File(widget.medienDatei.dateipfad);
    if (!file.existsSync()) {
      setState(() {
        _error = 'PDF-Datei nicht gefunden: ${widget.medienDatei.dateipfad}';
        _isLoading = false;
      });
      return _buildErrorState();
    }

    print('Lade PDF mit Syncfusion von: ${widget.medienDatei.dateipfad}');
    print('Datei existiert: ${file.existsSync()}');
    print('Dateigröße: ${file.lengthSync()} bytes');

    return SfPdfViewer.file(
      file,
      key: _pdfViewerKey,
      onDocumentLoaded: (PdfDocumentLoadedDetails details) {
        print('PDF erfolgreich geladen mit Syncfusion');
        setState(() {
          _isLoading = false;
        });
      },
      onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
        print('PDF Fehler mit Syncfusion: ${details.error}');
        setState(() {
          _error = 'Fehler beim Laden: ${details.error}';
          _isLoading = false;
        });
      },
    );
  }

  void _loadPDF() {
    setState(() {
      _isLoading = true;
      _error = null;
    });
  }

  void _addBookmark(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Lesezeichen-Funktion wird implementiert')),
    );
  }

  void _searchInPDF(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Such-Funktion wird implementiert')),
    );
  }

  void _sharePDF(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Teilen-Funktion wird implementiert')),
    );
  }
}

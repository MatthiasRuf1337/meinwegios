import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import '../models/medien_datei.dart';
import 'dart:io';

class PDFViewerScreen extends StatefulWidget {
  final MedienDatei medienDatei;

  const PDFViewerScreen({Key? key, required this.medienDatei})
      : super(key: key);

  @override
  _PDFViewerScreenState createState() => _PDFViewerScreenState();
}

class _PDFViewerScreenState extends State<PDFViewerScreen> {
  PDFViewController? _pdfViewController;
  int _currentPage = 1;
  int _totalPages = 0;
  bool _isLoading = true;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.medienDatei.dateiname),
        backgroundColor: Color(0xFF00847E),
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
      bottomNavigationBar: _buildBottomBar(),
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
                fontSize: 18,
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
                backgroundColor: Color(0xFF00847E),
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
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00847E)),
            ),
            SizedBox(height: 16),
            Text(
              'PDF wird geladen...',
              style: TextStyle(
                fontSize: 16,
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

    print('Lade PDF von: ${widget.medienDatei.dateipfad}');
    print('Datei existiert: ${file.existsSync()}');
    print('Dateigröße: ${file.lengthSync()} bytes');

    // Timeout für PDF-Laden hinzufügen
    Future.delayed(Duration(seconds: 10), () {
      if (_isLoading) {
        setState(() {
          _error = 'PDF-Laden hat zu lange gedauert. Versuchen Sie es erneut.';
          _isLoading = false;
        });
      }
    });

    return PDFView(
      filePath: widget.medienDatei.dateipfad,
      enableSwipe: true,
      swipeHorizontal: false,
      autoSpacing: true,
      pageFling: true,
      pageSnap: true,
      defaultPage: 0,
      fitPolicy: FitPolicy.BOTH,
      preventLinkNavigation: false,
      onRender: (pages) {
        print('PDF erfolgreich geladen, Seiten: $pages');
        setState(() {
          _totalPages = pages!;
          _isLoading = false;
        });
      },
      onError: (error) {
        print('PDF Fehler: $error');
        setState(() {
          _error = error.toString();
          _isLoading = false;
        });
      },
      onPageError: (page, error) {
        print('PDF Seitenfehler: Seite $page - $error');
        setState(() {
          _error = 'Fehler auf Seite $page: $error';
        });
      },
      onViewCreated: (PDFViewController pdfViewController) {
        _pdfViewController = pdfViewController;
      },
      onPageChanged: (int? page, int? total) {
        setState(() {
          _currentPage = page ?? 1;
        });
      },
    );
  }

  Widget _buildBottomBar() {
    if (_isLoading || _error != null) {
      return SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios, size: 20),
            onPressed: _currentPage > 1 ? _previousPage : null,
            color: _currentPage > 1 ? Color(0xFF00847E) : Colors.grey,
          ),
          Expanded(
            child: Text(
              'Seite $_currentPage von $_totalPages',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Color(0xFF00847E),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.arrow_forward_ios, size: 20),
            onPressed: _currentPage < _totalPages ? _nextPage : null,
            color: _currentPage < _totalPages ? Color(0xFF00847E) : Colors.grey,
          ),
        ],
      ),
    );
  }

  void _previousPage() {
    if (_currentPage > 1) {
      _pdfViewController?.setPage(_currentPage - 1);
    }
  }

  void _nextPage() {
    if (_currentPage < _totalPages) {
      _pdfViewController?.setPage(_currentPage + 1);
    }
  }

  void _loadPDF() {
    setState(() {
      _isLoading = true;
      _error = null;
    });
  }

  void _addBookmark(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Lesezeichen hinzugefügt!'),
        backgroundColor: Color(0xFF00847E),
      ),
    );
  }

  void _searchInPDF(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('PDF durchsuchen'),
        content: TextField(
          decoration: InputDecoration(
            hintText: 'Suchbegriff eingeben...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Suche wird implementiert...'),
                  backgroundColor: Color(0xFF00847E),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF00847E),
              foregroundColor: Colors.white,
            ),
            child: Text('Suchen'),
          ),
        ],
      ),
    );
  }

  void _sharePDF(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('PDF wird geteilt...'),
        backgroundColor: Color(0xFF00847E),
      ),
    );
  }
}

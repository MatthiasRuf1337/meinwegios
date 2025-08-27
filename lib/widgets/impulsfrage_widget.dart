import 'package:flutter/material.dart';
import '../services/impulsfragen_service.dart';

class ImpulsfrageWidget extends StatefulWidget {
  final String etappenId;

  const ImpulsfrageWidget({
    Key? key,
    required this.etappenId,
  }) : super(key: key);

  @override
  _ImpulsfrageWidgetState createState() => _ImpulsfrageWidgetState();
}

class _ImpulsfrageWidgetState extends State<ImpulsfrageWidget> {
  final ImpulsfrageService _impulsfrageService = ImpulsfrageService();
  Impulsfrage? _aktuelleImpulsfrage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadImpulsfrage();
  }

  Future<void> _loadImpulsfrage() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final impulsfrage = await _impulsfrageService.getNextImpulsfrage();
      setState(() {
        _aktuelleImpulsfrage = impulsfrage;
        _isLoading = false;
      });
    } catch (e) {
      print('Fehler beim Laden der Impulsfrage: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Impulsfrage Content
        if (_isLoading)
          _buildLoadingState()
        else if (_aktuelleImpulsfrage != null)
          _buildImpulsfrageContent()
        else
          _buildErrorState(),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: 60,
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8F116E)),
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Impulsfrage wird geladen...',
              style: TextStyle(
                color: Color(0xFF8F116E),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImpulsfrageContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Frage-Icon und Text
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: EdgeInsets.only(top: 2),
              child: Icon(
                Icons.psychology,
                color: Color(0xFF8F116E),
                size: 20,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: RichText(
                  text: TextSpan(
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF2C2C2C),
                  height: 1.4,
                ),
                children: [
                  // Öffnendes Anführungszeichen (unten)
                  TextSpan(
                    text: '"',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8F116E),
                    ),
                  ),
                  // Haupttext
                  TextSpan(
                    text: _cleanQuoteText(_aktuelleImpulsfrage!.text),
                  ),
                  // Schließendes Anführungszeichen (oben)
                  TextSpan(
                    text: '"',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8F116E),
                    ),
                  ),
                ],
              )),
            ),
          ],
        ),

        SizedBox(height: 16),

        // Hinweis-Text
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Color(0xFF8F116E).withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Color(0xFF8F116E).withOpacity(0.1),
            ),
          ),
          child: Text(
            'Nimm dir einen Moment Zeit für diese Frage während deiner Etappe.',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF8F116E).withOpacity(0.8),
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Container(
      height: 60,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.grey,
              size: 20,
            ),
            SizedBox(height: 4),
            Text(
              'Keine Impulsfrage verfügbar',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _cleanQuoteText(String text) {
    // Remove leading and trailing double quotes if they exist
    if (text.startsWith('"') && text.endsWith('"')) {
      return text.substring(1, text.length - 1);
    }
    return text;
  }
}

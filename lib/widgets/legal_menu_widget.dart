import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class LegalMenuWidget extends StatelessWidget {
  const LegalMenuWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.menu, color: Colors.white),
      onSelected: (String value) => _handleMenuSelection(context, value),
      itemBuilder: (BuildContext context) => [
        PopupMenuItem<String>(
          value: 'impressum',
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 18, color: Color(0xFF5A7D7D)),
              SizedBox(width: 12),
              Text('Impressum'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'datenschutz',
          child: Row(
            children: [
              Icon(Icons.privacy_tip_outlined,
                  size: 18, color: Color(0xFF5A7D7D)),
              SizedBox(width: 12),
              Text('Datenschutz'),
            ],
          ),
        ),
      ],
    );
  }

  void _handleMenuSelection(BuildContext context, String value) async {
    String url;

    switch (value) {
      case 'impressum':
        url = 'https://www.der-pilger.de/impressum/';
        break;
      case 'datenschutz':
        url = 'https://www.der-pilger.de/datenschutz/';
        break;
      default:
        return;
    }

    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        _showErrorDialog(context, 'Link konnte nicht geöffnet werden',
            'Die Webseite $url konnte nicht geöffnet werden.');
      }
    } catch (e) {
      _showErrorDialog(context, 'Fehler',
          'Beim Öffnen der Webseite ist ein Fehler aufgetreten: $e');
    }
  }

  void _showErrorDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }
}

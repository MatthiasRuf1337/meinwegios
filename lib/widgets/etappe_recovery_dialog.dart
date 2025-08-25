import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/etappe.dart';
import '../providers/etappen_provider.dart';

class EtappeRecoveryDialog extends StatelessWidget {
  final List<Etappe> orphanedEtappen;

  const EtappeRecoveryDialog({
    Key? key,
    required this.orphanedEtappen,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.warning, color: Colors.orange, size: 28),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Unterbrochene Etappen gefunden',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: Container(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nach dem App-Update wurden ${orphanedEtappen.length} unterbrochene Etappe(n) gefunden:',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Container(
              constraints: BoxConstraints(maxHeight: 300),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: orphanedEtappen.length,
                itemBuilder: (context, index) {
                  final etappe = orphanedEtappen[index];
                  final timeSinceStart =
                      DateTime.now().difference(etappe.startzeit);

                  return Card(
                    margin: EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            etappe.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Gestartet: ${_formatDateTime(etappe.startzeit)}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'Dauer: ${_formatDuration(timeSinceStart)}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                          if (etappe.schrittAnzahl > 0) ...[
                            SizedBox(height: 4),
                            Text(
                              '${etappe.schrittAnzahl} Schritte • ${_formatDistance(etappe.gesamtDistanz)}',
                              style: TextStyle(
                                color: Color(0xFF5A7D7D),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                          SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () =>
                                      _restoreEtappe(context, etappe),
                                  icon: Icon(Icons.play_arrow, size: 18),
                                  label: Text('Fortsetzen'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFF5A7D7D),
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(vertical: 8),
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () =>
                                      _completeEtappe(context, etappe),
                                  icon: Icon(Icons.stop, size: 18),
                                  label: Text('Beenden'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                    side: BorderSide(color: Colors.red),
                                    padding: EdgeInsets.symmetric(vertical: 8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.blue.shade700, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Du kannst eine Etappe fortsetzen oder beenden. Fortgesetzte Etappen werden mit den bisherigen Daten weitergeführt.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => _completeAllEtappen(context),
          child: Text(
            'Alle beenden',
            style: TextStyle(color: Colors.red),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF5A7D7D),
            foregroundColor: Colors.white,
          ),
          child: Text('Später entscheiden'),
        ),
      ],
    );
  }

  void _restoreEtappe(BuildContext context, Etappe etappe) async {
    try {
      final etappenProvider =
          Provider.of<EtappenProvider>(context, listen: false);
      await etappenProvider.restoreEtappe(etappe);

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Etappe "${etappe.name}" wurde wiederhergestellt'),
          backgroundColor: Color(0xFF5A7D7D),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Wiederherstellen: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _completeEtappe(BuildContext context, Etappe etappe) async {
    try {
      final etappenProvider =
          Provider.of<EtappenProvider>(context, listen: false);
      await etappenProvider.completeOrphanedEtappe(etappe);

      // Dialog aktualisieren oder schließen wenn alle bearbeitet
      final remainingEtappen = etappenProvider.getOrphanedActiveEtappen();
      if (remainingEtappen.isEmpty) {
        Navigator.of(context).pop();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Etappe "${etappe.name}" wurde beendet'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Beenden: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _completeAllEtappen(BuildContext context) async {
    try {
      final etappenProvider =
          Provider.of<EtappenProvider>(context, listen: false);

      for (final etappe in orphanedEtappen) {
        await etappenProvider.completeOrphanedEtappe(etappe);
      }

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Alle ${orphanedEtappen.length} Etappen wurden beendet'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Beenden aller Etappen: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}.${dateTime.month}.${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}min';
    } else {
      return '${minutes}min';
    }
  }

  String _formatDistance(double distance) {
    if (distance < 1000) {
      return '${distance.toStringAsFixed(0)} m';
    } else {
      return '${(distance / 1000).toStringAsFixed(2)} km';
    }
  }

  // Statische Methode zum Anzeigen des Dialogs
  static Future<void> showIfNeeded(BuildContext context) async {
    final etappenProvider =
        Provider.of<EtappenProvider>(context, listen: false);
    final orphanedEtappen = etappenProvider.getOrphanedActiveEtappen();

    if (orphanedEtappen.isNotEmpty) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) =>
            EtappeRecoveryDialog(orphanedEtappen: orphanedEtappen),
      );
    }
  }
}

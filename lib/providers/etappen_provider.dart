import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/etappe.dart';
import '../models/bild.dart';
import '../models/wetter_daten.dart';
import '../services/database_service.dart';

// Globale Referenz für BilderProvider Reload
Function? _globalBilderProviderReload;

// Funktion zum Setzen der globalen BilderProvider Reload Funktion
void setBilderProviderReloadCallback(Function callback) {
  _globalBilderProviderReload = callback;
}

class EtappenProvider with ChangeNotifier {
  List<Etappe> _etappen = [];
  Etappe? _aktuelleEtappe;
  bool _isLoading = false;

  List<Etappe> get etappen => _etappen;
  Etappe? get aktuelleEtappe => _aktuelleEtappe;
  bool get isLoading => _isLoading;
  bool get hatAktuelleEtappe => _aktuelleEtappe != null;

  EtappenProvider() {
    _loadEtappen();
  }

  Future<void> _loadEtappen() async {
    _isLoading = true;
    notifyListeners();

    try {
      _etappen = await DatabaseService.instance.getEtappen();
      _etappen.sort((a, b) => b.erstellungsDatum.compareTo(a.erstellungsDatum));

      // Beispiel-Etappe erstellen falls noch nicht vorhanden
      await _checkAndCreateBeispielEtappe();
    } catch (e) {
      print('Fehler beim Laden der Etappen: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _checkAndCreateBeispielEtappe() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final beispielEtappeCreated =
          prefs.getBool('beispiel_etappe_created_v2') ?? false;

      if (!beispielEtappeCreated) {
        await createBeispielEtappeIfNeeded();
        await prefs.setBool('beispiel_etappe_created_v2', true);

        // BilderProvider über globalen Zugriff neu laden
        _reloadBilderProvider();
      }
    } catch (e) {
      print('Fehler beim Prüfen der Beispiel-Etappe: $e');
    }
  }

  Future<void> addEtappe(Etappe etappe) async {
    try {
      await DatabaseService.instance.insertEtappe(etappe);
      _etappen.add(etappe);
      _etappen.sort((a, b) => b.erstellungsDatum.compareTo(a.erstellungsDatum));
      notifyListeners();
    } catch (e) {
      print('Fehler beim Hinzufügen der Etappe: $e');
    }
  }

  Future<void> updateEtappe(Etappe etappe) async {
    try {
      await DatabaseService.instance.updateEtappe(etappe);
      final index = _etappen.indexWhere((e) => e.id == etappe.id);
      if (index != -1) {
        _etappen[index] = etappe;
        _etappen
            .sort((a, b) => b.erstellungsDatum.compareTo(a.erstellungsDatum));
        notifyListeners();
      }
    } catch (e) {
      print('Fehler beim Aktualisieren der Etappe: $e');
    }
  }

  Future<void> deleteEtappe(String etappenId) async {
    try {
      await DatabaseService.instance.deleteEtappe(etappenId);
      _etappen.removeWhere((e) => e.id == etappenId);
      notifyListeners();
    } catch (e) {
      print('Fehler beim Löschen der Etappe: $e');
    }
  }

  void startEtappe(Etappe etappe) {
    _aktuelleEtappe = etappe;
    notifyListeners();
  }

  void stopEtappe() {
    _aktuelleEtappe = null;
    notifyListeners();
  }

  void updateAktuelleEtappe(Etappe updatedEtappe) {
    _aktuelleEtappe = updatedEtappe;
    notifyListeners();
  }

  List<Etappe> searchEtappen(String query) {
    if (query.isEmpty) return _etappen;

    return _etappen
        .where((etappe) =>
            etappe.name.toLowerCase().contains(query.toLowerCase()) ||
            (etappe.notizen?.toLowerCase().contains(query.toLowerCase()) ??
                false))
        .toList();
  }

  List<Etappe> getEtappenByStatus(EtappenStatus status) {
    return _etappen.where((etappe) => etappe.status == status).toList();
  }

  List<Etappe> getEtappenByDateRange(DateTime start, DateTime end) {
    return _etappen
        .where((etappe) =>
            etappe.erstellungsDatum.isAfter(start) &&
            etappe.erstellungsDatum.isBefore(end))
        .toList();
  }

  double getGesamtDistanz() {
    return _etappen.fold(0.0, (sum, etappe) => sum + etappe.gesamtDistanz);
  }

  int getGesamtSchritte() {
    return _etappen.fold(0, (sum, etappe) => sum + etappe.schrittAnzahl);
  }

  Duration getGesamtDauer() {
    return _etappen.fold(Duration.zero, (sum, etappe) => sum + etappe.dauer);
  }

  // Beispiel-Etappe erstellen (nur beim ersten App-Start)
  Future<void> createBeispielEtappeIfNeeded() async {
    try {
      // Prüfen ob bereits eine Beispiel-Etappe existiert
      final existingBeispiel =
          _etappen.where((e) => e.name == "Beispiel-Etappe").toList();
      if (existingBeispiel.isNotEmpty) {
        print('Beispiel-Etappe bereits vorhanden, überspringe Erstellung');
        return;
      }

      print('Erstelle Beispiel-Etappe...');

      // Etappen-ID für Verknüpfung generieren
      final etappenId =
          'beispiel_etappe_${DateTime.now().millisecondsSinceEpoch}';

      // Beispiel-Bild kopieren und in Datenbank speichern
      String? bildId;
      try {
        bildId = await _createBeispielBild(etappenId);
        print('Beispiel-Bild erstellt mit ID: $bildId');
      } catch (e) {
        print('Fehler beim Erstellen des Beispiel-Bildes: $e');
      }

      // Beispiel-Wetter erstellen
      final beispielWetter = WetterDaten(
        temperatur: 18.5,
        beschreibung: 'Leicht bewölkt',
        hauptKategorie: 'Clouds',
        icon: '02d',
        luftfeuchtigkeit: 65.0,
        windgeschwindigkeit: 12.3,
        windrichtung: 225.0,
        luftdruck: 1013.2,
        gefuehlteTemperatur: 17.8,
        zeitstempel: DateTime(2025, 8, 1, 6, 0),
        ort: 'Beispielort',
      );

      // Beispiel GPS-Punkte für eine 30km Route erstellen
      final beispielGpsPunkte = _createBeispielGpsPunkte();

      // Beispiel-Etappe erstellen
      final beispielEtappe = Etappe(
        id: etappenId,
        name: 'Beispiel-Etappe',
        startzeit: DateTime(2025, 8, 1, 6, 0),
        endzeit: DateTime(2025, 8, 1, 13, 30), // 7.5 Stunden
        status: EtappenStatus.abgeschlossen,
        gesamtDistanz: 30000.0, // 30 km in Metern
        schrittAnzahl: 42000, // Realistische Schrittzahl für 30km
        gpsPunkte: beispielGpsPunkte,
        notizen:
            'Du kannst diese Beispiel-Etappe jederzeit löschen. Tipp: Nutze die Karte um deine Route zu verfolgen!',
        erstellungsDatum: DateTime(2025, 8, 1, 6, 0),
        bildIds: bildId != null ? [bildId] : [],
        startWetter: beispielWetter,
        wetterVerlauf: [beispielWetter], // Vereinfacht nur ein Wetter-Eintrag
      );

      // Etappe zur Datenbank hinzufügen
      await DatabaseService.instance.insertEtappe(beispielEtappe);
      _etappen.add(beispielEtappe);
      _etappen.sort((a, b) => b.erstellungsDatum.compareTo(a.erstellungsDatum));
      notifyListeners();

      print('Beispiel-Etappe erfolgreich erstellt');

      // Debug: Prüfen ob Bild korrekt in Datenbank gespeichert wurde
      if (bildId != null) {
        final alleBilder = await DatabaseService.instance.getBilder();
        final etappenBilder =
            alleBilder.where((b) => b.etappenId == etappenId).toList();
        print('Bilder für Etappe $etappenId gefunden: ${etappenBilder.length}');
        for (final bild in etappenBilder) {
          print(
              'Bild: ${bild.id}, Datei: ${bild.dateipfad}, EtappenId: ${bild.etappenId}');
        }
      }
    } catch (e) {
      print('Fehler beim Erstellen der Beispiel-Etappe: $e');
    }
  }

  Future<String?> _createBeispielBild(String etappenId) async {
    try {
      // Bild aus Assets laden
      ByteData? imageData;

      try {
        imageData = await rootBundle.load('assets/images/beispiel.jpg');
      } catch (e) {
        print(
            'beispiel.jpg nicht in Assets gefunden - Beispiel-Etappe wird ohne Bild erstellt');
        return null;
      }

      // App-Dokumente-Verzeichnis für Bilder erstellen
      final appDir = await getApplicationDocumentsDirectory();
      final bilderDir = Directory('${appDir.path}/bilder');
      if (!bilderDir.existsSync()) {
        await bilderDir.create(recursive: true);
      }

      // Bild in App-Verzeichnis schreiben
      final targetPath = '${bilderDir.path}/beispiel_etappe.jpg';
      final file = File(targetPath);
      await file.writeAsBytes(imageData.buffer.asUint8List());

      // Bild-Objekt erstellen
      final bildId = 'beispiel_bild_${DateTime.now().millisecondsSinceEpoch}';
      final bild = Bild(
        id: bildId,
        dateiname: 'beispiel_etappe.jpg',
        dateipfad: targetPath,
        latitude: 47.3769, // Beispiel-Koordinaten (Schweiz)
        longitude: 8.5417,
        aufnahmeZeit: DateTime(2025, 8, 1, 10, 30),
        etappenId: etappenId, // Korrekte Etappen-ID setzen
        metadaten: {
          'isBeispiel': true,
          'beschreibung': 'Beispiel-Bild für die Beispiel-Etappe',
        },
      );

      // Bild in Datenbank speichern
      await DatabaseService.instance.insertBild(bild);
      print(
          'Bild in Datenbank gespeichert: ${bild.id} für Etappe: ${bild.etappenId}');

      return bildId;
    } catch (e) {
      print('Fehler beim Erstellen des Beispiel-Bildes: $e');
      return null;
    }
  }

  List<GPSPunkt> _createBeispielGpsPunkte() {
    // Erstelle eine realistische GPS-Route für 30km
    final List<GPSPunkt> punkte = [];
    final startLat = 47.3769; // Zürich als Startpunkt
    final startLng = 8.5417;
    final startTime = DateTime(2025, 8, 1, 6, 0);

    // Erstelle GPS-Punkte alle 5 Minuten für 7.5 Stunden
    for (int i = 0; i < 90; i++) {
      // 90 Punkte über 7.5 Stunden
      final zeitOffset = Duration(minutes: i * 5);
      final distanceOffset = (i / 90.0) * 0.27; // Etwa 30km in Grad-Koordinaten

      punkte.add(GPSPunkt(
        latitude: startLat + (distanceOffset * 0.5), // Bewegung nach Norden
        longitude: startLng + (distanceOffset * 0.8), // Bewegung nach Osten
        altitude: 400.0 + (i * 2.0), // Leichte Höhenänderung
        timestamp: startTime.add(zeitOffset),
        accuracy: 5.0 + (i % 3), // Variierende GPS-Genauigkeit
      ));
    }

    return punkte;
  }

  // BilderProvider neu laden
  void _reloadBilderProvider() {
    if (_globalBilderProviderReload != null) {
      print('BilderProvider wird neu geladen...');
      _globalBilderProviderReload!();
    } else {
      print('BilderProvider Reload-Callback nicht verfügbar');
    }
  }
}

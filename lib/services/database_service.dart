import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import '../models/etappe.dart';
import '../models/bild.dart';
import '../models/medien_datei.dart';
import '../models/audio_aufnahme.dart';
import '../models/notiz.dart';
import '../models/wetter_daten.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('meinweg.db');
    return _database!;
  }

  Future<void> initDatabase() async {
    await database; // This will initialize the database
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 5,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Etappen Tabelle
    await db.execute('''
      CREATE TABLE etappen (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        startzeit INTEGER NOT NULL,
        endzeit INTEGER,
        status INTEGER NOT NULL,
        gesamtDistanz REAL DEFAULT 0.0,
        schrittAnzahl INTEGER DEFAULT 0,
        gpsPunkte TEXT,
        notizen TEXT,
        erstellungsDatum INTEGER NOT NULL,
        bildIds TEXT,
        startWetter TEXT,
        wetterVerlauf TEXT
      )
    ''');

    // Bilder Tabelle
    await db.execute('''
      CREATE TABLE bilder (
        id TEXT PRIMARY KEY,
        dateiname TEXT NOT NULL,
        dateipfad TEXT NOT NULL,
        latitude REAL,
        longitude REAL,
        aufnahmeZeit INTEGER NOT NULL,
        etappenId TEXT,
        metadaten TEXT
      )
    ''');

    // Medien-Dateien Tabelle
    await db.execute('''
      CREATE TABLE medien_dateien (
        id TEXT PRIMARY KEY,
        typ INTEGER NOT NULL,
        dateiname TEXT NOT NULL,
        dateipfad TEXT NOT NULL,
        groesse INTEGER NOT NULL,
        importDatum INTEGER NOT NULL,
        metadaten TEXT
      )
    ''');

    // Audio-Aufnahmen Tabelle
    await db.execute('''
      CREATE TABLE audio_aufnahmen (
        id TEXT PRIMARY KEY,
        dateiname TEXT NOT NULL,
        dateipfad TEXT NOT NULL,
        aufnahmeZeit INTEGER NOT NULL,
        dauer INTEGER NOT NULL,
        etappenId TEXT NOT NULL,
        notiz TEXT,
        metadaten TEXT,
        typ TEXT DEFAULT 'allgemein'
      )
    ''');

    // Notizen Tabelle
    await db.execute('''
      CREATE TABLE notizen (
        id TEXT PRIMARY KEY,
        titel TEXT NOT NULL,
        inhalt TEXT NOT NULL,
        erstellt_am INTEGER NOT NULL,
        bearbeitet_am INTEGER,
        etappen_id TEXT NOT NULL
      )
    ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Audio-Aufnahmen Tabelle hinzufügen
      await db.execute('''
        CREATE TABLE audio_aufnahmen (
          id TEXT PRIMARY KEY,
          dateiname TEXT NOT NULL,
          dateipfad TEXT NOT NULL,
          aufnahmeZeit INTEGER NOT NULL,
          dauer INTEGER NOT NULL,
          etappenId TEXT NOT NULL,
          notiz TEXT,
          metadaten TEXT
        )
      ''');
    }

    if (oldVersion < 3) {
      // Notizen Tabelle hinzufügen
      await db.execute('''
        CREATE TABLE notizen (
          id TEXT PRIMARY KEY,
          titel TEXT NOT NULL,
          inhalt TEXT NOT NULL,
          erstellt_am INTEGER NOT NULL,
          bearbeitet_am INTEGER,
          etappen_id TEXT NOT NULL
        )
      ''');
    }

    if (oldVersion < 4) {
      // Wetter-Spalten zur Etappen-Tabelle hinzufügen
      await db.execute('ALTER TABLE etappen ADD COLUMN startWetter TEXT');
      await db.execute('ALTER TABLE etappen ADD COLUMN wetterVerlauf TEXT');
    }

    if (oldVersion < 5) {
      // Typ-Spalte zur Audio-Aufnahmen-Tabelle hinzufügen
      await db.execute(
          'ALTER TABLE audio_aufnahmen ADD COLUMN typ TEXT DEFAULT \'allgemein\'');
    }
  }

  // Etappen Operationen
  Future<void> insertEtappe(Etappe etappe) async {
    final db = await database;
    await db.insert(
      'etappen',
      etappe.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Etappe>> getEtappen() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('etappen');

    return List.generate(maps.length, (i) {
      return Etappe.fromMap(maps[i]);
    });
  }

  Future<void> updateEtappe(Etappe etappe) async {
    final db = await database;
    await db.update(
      'etappen',
      etappe.toMap(),
      where: 'id = ?',
      whereArgs: [etappe.id],
    );
  }

  Future<void> deleteEtappe(String etappenId) async {
    final db = await database;
    await db.delete(
      'etappen',
      where: 'id = ?',
      whereArgs: [etappenId],
    );
  }

  // Bilder Operationen
  Future<void> insertBild(Bild bild) async {
    final db = await database;
    await db.insert(
      'bilder',
      bild.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Bild>> getBilder() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('bilder');

    return List.generate(maps.length, (i) {
      return Bild.fromMap(maps[i]);
    });
  }

  Future<void> deleteBild(String bildId) async {
    final db = await database;
    await db.delete(
      'bilder',
      where: 'id = ?',
      whereArgs: [bildId],
    );
  }

  Future<void> updateBild(Bild bild) async {
    final db = await database;
    await db.update(
      'bilder',
      bild.toMap(),
      where: 'id = ?',
      whereArgs: [bild.id],
    );
  }

  // Medien-Dateien Operationen
  Future<void> insertMedienDatei(MedienDatei medienDatei) async {
    final db = await database;
    await db.insert(
      'medien_dateien',
      medienDatei.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<MedienDatei>> getMedienDateien() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('medien_dateien');

    return List.generate(maps.length, (i) {
      return MedienDatei.fromMap(maps[i]);
    });
  }

  Future<void> deleteMedienDatei(String medienDateiId) async {
    // Prüfe ob es eine Standard-Datei (preloaded) ist
    final medienDateien = await getMedienDateien();
    final medienDatei = medienDateien.firstWhere(
      (m) => m.id == medienDateiId,
      orElse: () => throw Exception('Medien-Datei nicht gefunden'),
    );

    // Standard-Dateien (preloaded) können nicht gelöscht werden
    if (medienDatei.metadaten['isPreloaded'] == true) {
      throw Exception('Standard-Dateien können nicht gelöscht werden');
    }

    final db = await database;
    await db.delete(
      'medien_dateien',
      where: 'id = ?',
      whereArgs: [medienDateiId],
    );
  }

  // Audio-Aufnahmen Operationen
  Future<void> insertAudioAufnahme(AudioAufnahme audioAufnahme) async {
    final db = await database;
    await db.insert(
      'audio_aufnahmen',
      audioAufnahme.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<AudioAufnahme>> getAllAudioAufnahmen() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('audio_aufnahmen');

    return List.generate(maps.length, (i) {
      return AudioAufnahme.fromMap(maps[i]);
    });
  }

  Future<List<AudioAufnahme>> getAudioAufnahmenByEtappe(
      String etappenId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'audio_aufnahmen',
      where: 'etappenId = ?',
      whereArgs: [etappenId],
    );

    return List.generate(maps.length, (i) {
      return AudioAufnahme.fromMap(maps[i]);
    });
  }

  Future<void> deleteAudioAufnahme(String audioId) async {
    final db = await database;
    await db.delete(
      'audio_aufnahmen',
      where: 'id = ?',
      whereArgs: [audioId],
    );
  }

  Future<void> updateAudioAufnahme(AudioAufnahme audioAufnahme) async {
    final db = await database;
    await db.update(
      'audio_aufnahmen',
      audioAufnahme.toMap(),
      where: 'id = ?',
      whereArgs: [audioAufnahme.id],
    );
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }

  // Vorab geladene Medien (PDFs und MP3s) importieren
  Future<void> importPreloadedMedia() async {
    try {
      print('=== Starte Import der vorab geladenen Medien ===');

      // Liste der Standard-Dateien (explizit definiert)
      final standardPDFs = [
        'assets/pdf/Die Magie des Pilgerns.pdf',
        'assets/pdf/Mache dich auf den Weg.pdf',
        'assets/pdf/Packliste Wandern.pdf',
      ];

      final standardMP3s = [
        'assets/audio/3 Minuten Atemraum.mp3',
        'assets/audio/Atem Ruhe Freundlichkeit.mp3',
      ];

      // Setze für alle Standard-Dateien, die importiert wurden
      final Set<String> importedAssets = {};

      // Versuche zuerst über AssetManifest
      try {
        final manifestContent =
            await rootBundle.loadString('AssetManifest.json');
        final Map<String, dynamic> manifestMap = json.decode(manifestContent);
        print(
            'AssetManifest geladen, ${manifestMap.keys.length} Assets gefunden');

        // Debug: Alle Assets ausgeben, die mit assets/pdf/ oder assets/audio/ beginnen
        final allPdfAudioAssets = manifestMap.keys
            .where((String key) =>
                key.startsWith('assets/pdf/') ||
                key.startsWith('assets/audio/'))
            .toList();
        print('Alle PDF/Audio-Assets im Manifest:');
        for (String key in allPdfAudioAssets) {
          print('  - $key');
        }

        // PDFs importieren - prüfe auch case-insensitive
        final pdfAssets = manifestMap.keys
            .where((String key) =>
                key.toLowerCase().startsWith('assets/pdf/') &&
                key.toLowerCase().endsWith('.pdf'))
            .toList();

        print('Gefundene PDF-Assets im Manifest: ${pdfAssets.length}');
        for (String assetPath in pdfAssets) {
          print('  - $assetPath');
          await _importAsset(assetPath, MedienTyp.pdf);
          // Normalisiere den Pfad für Vergleich (case-insensitive)
          importedAssets.add(assetPath.toLowerCase());
        }

        // MP3s importieren - prüfe auch case-insensitive
        final mp3Assets = manifestMap.keys
            .where((String key) =>
                key.toLowerCase().startsWith('assets/audio/') &&
                key.toLowerCase().endsWith('.mp3'))
            .toList();

        print('Gefundene MP3-Assets im Manifest: ${mp3Assets.length}');
        for (String assetPath in mp3Assets) {
          print('  - $assetPath');
          await _importAsset(assetPath, MedienTyp.mp3);
          // Normalisiere den Pfad für Vergleich (case-insensitive)
          importedAssets.add(assetPath.toLowerCase());
        }
      } catch (e) {
        print('Fehler beim Laden über AssetManifest: $e');
        print('Versuche direkten Import der Standard-Dateien...');
      }

      // Fallback: Direkter Import der Standard-Dateien, die nicht über Manifest importiert wurden
      print('Importiere fehlende Standard-PDFs direkt:');
      for (String assetPath in standardPDFs) {
        // Prüfe case-insensitive
        final normalizedPath = assetPath.toLowerCase();

        // Spezial-Behandlung für Packliste: Immer versuchen zu importieren
        // (Fix für Release-Build-Problem in TestFlight)
        if (assetPath.toLowerCase().contains('packliste')) {
          print(
              '  Packliste: Force-Import aufgrund bekannter Release-Build-Probleme');
          try {
            await _importAsset(assetPath, MedienTyp.pdf);
          } catch (e) {
            print('Fehler beim Importieren von Packliste: $e');
          }
        } else if (!importedAssets.contains(normalizedPath)) {
          print('  PDF fehlt im Manifest, importiere direkt: $assetPath');
          try {
            await _importAsset(assetPath, MedienTyp.pdf);
          } catch (e) {
            print('Fehler beim Importieren von $assetPath: $e');
          }
        } else {
          print('  Bereits importiert über Manifest: $assetPath');
        }
      }

      print('Importiere fehlende Standard-MP3s direkt:');
      for (String assetPath in standardMP3s) {
        // Prüfe case-insensitive
        final normalizedPath = assetPath.toLowerCase();
        if (!importedAssets.contains(normalizedPath)) {
          print('  MP3 fehlt im Manifest, importiere direkt: $assetPath');
          try {
            await _importAsset(assetPath, MedienTyp.mp3);
          } catch (e) {
            print('Fehler beim Importieren von $assetPath: $e');
          }
        } else {
          print('  Bereits importiert über Manifest: $assetPath');
        }
      }

      print('=== Import der vorab geladenen Medien abgeschlossen ===');
    } catch (e, stackTrace) {
      print('Fehler beim Importieren der vorab geladenen Medien: $e');
      print('Stack Trace: $stackTrace');
    }
  }

  // Vorab geladene Medien manuell neu importieren (auch wenn bereits vorhanden)
  Future<void> reimportPreloadedMedia() async {
    try {
      print('=== Starte Neuimport der vorab geladenen Medien ===');

      // Liste der Standard-Dateien (explizit definiert)
      final standardPDFs = [
        'assets/pdf/Die Magie des Pilgerns.pdf',
        'assets/pdf/Mache dich auf den Weg.pdf',
        'assets/pdf/Packliste Wandern.pdf',
      ];

      final standardMP3s = [
        'assets/audio/3 Minuten Atemraum.mp3',
        'assets/audio/Atem Ruhe Freundlichkeit.mp3',
      ];

      // Versuche zuerst über AssetManifest
      try {
        final manifestContent =
            await rootBundle.loadString('AssetManifest.json');
        final Map<String, dynamic> manifestMap = json.decode(manifestContent);
        print(
            'AssetManifest geladen, ${manifestMap.keys.length} Assets gefunden');

        // PDFs importieren
        final pdfAssets = manifestMap.keys
            .where((String key) =>
                key.startsWith('assets/pdf/') && key.endsWith('.pdf'))
            .toList();

        print('Gefundene PDF-Assets im Manifest: ${pdfAssets.length}');
        for (String assetPath in pdfAssets) {
          print('  - $assetPath');
          await _importAsset(assetPath, MedienTyp.pdf, forceReimport: true);
        }

        // MP3s importieren
        final mp3Assets = manifestMap.keys
            .where((String key) =>
                key.startsWith('assets/audio/') && key.endsWith('.mp3'))
            .toList();

        print('Gefundene MP3-Assets im Manifest: ${mp3Assets.length}');
        for (String assetPath in mp3Assets) {
          print('  - $assetPath');
          await _importAsset(assetPath, MedienTyp.mp3, forceReimport: true);
        }
      } catch (e) {
        print('Fehler beim Laden über AssetManifest: $e');
        print('Versuche direkten Import der Standard-Dateien...');
      }

      // Fallback: Direkter Import der Standard-Dateien
      print('Importiere Standard-PDFs direkt (forceReimport):');
      for (String assetPath in standardPDFs) {
        try {
          await _importAsset(assetPath, MedienTyp.pdf, forceReimport: true);
        } catch (e) {
          print('Fehler beim Importieren von $assetPath: $e');
        }
      }

      print('Importiere Standard-MP3s direkt (forceReimport):');
      for (String assetPath in standardMP3s) {
        try {
          await _importAsset(assetPath, MedienTyp.mp3, forceReimport: true);
        } catch (e) {
          print('Fehler beim Importieren von $assetPath: $e');
        }
      }

      print('=== Neuimport der vorab geladenen Medien abgeschlossen ===');
    } catch (e, stackTrace) {
      print('Fehler beim Neuimportieren der vorab geladenen Medien: $e');
      print('Stack Trace: $stackTrace');
      rethrow;
    }
  }

  // Einzelne Asset-Datei importieren
  Future<void> _importAsset(String assetPath, MedienTyp typ,
      {bool forceReimport = false}) async {
    try {
      print(
          'Importiere Asset: $assetPath (Typ: ${typ == MedienTyp.pdf ? 'PDF' : 'MP3'})');

      // Datei aus Assets laden
      final ByteData data = await rootBundle.load(assetPath);
      final List<int> bytes = data.buffer.asUint8List();
      print('Asset geladen: ${bytes.length} bytes');

      // Dateiname aus Pfad extrahieren
      final fileName = assetPath.split('/').last;
      final extension = typ == MedienTyp.pdf ? '.pdf' : '.mp3';

      // ID generieren: Extension entfernen und Leerzeichen durch Unterstriche ersetzen
      String baseName = fileName;
      if (baseName.toLowerCase().endsWith(extension.toLowerCase())) {
        baseName = baseName.substring(0, baseName.length - extension.length);
      }
      final id = 'preloaded_${baseName.replaceAll(' ', '_')}';
      print('Generierte ID: $id für Dateiname: $fileName');

      // Prüfen ob bereits vorhanden
      final existingMedia = await getMedienDateien();
      MedienDatei? existingMediaItem;
      try {
        existingMediaItem = existingMedia.firstWhere((media) => media.id == id);
      } catch (e) {
        // Nicht gefunden, das ist ok
        existingMediaItem = null;
      }
      print('Bereits vorhandene Medien: ${existingMedia.length}');

      // Debug: Zeige alle vorhandenen IDs für PDFs
      if (typ == MedienTyp.pdf) {
        final existingPDFs =
            existingMedia.where((m) => m.typ == MedienTyp.pdf).toList();
        print('Vorhandene PDF-IDs in DB:');
        for (var pdf in existingPDFs) {
          print('  - ID: ${pdf.id}, Dateiname: ${pdf.dateiname}');
        }
      }

      // Wenn bereits vorhanden, prüfe ob Datei noch existiert
      if (existingMediaItem != null) {
        final file = File(existingMediaItem.dateipfad);
        if (file.existsSync()) {
          if (forceReimport) {
            // Bei forceReimport: Datei aktualisieren
            print('Standard-Datei existiert, aktualisiere: $fileName');
            await file.writeAsBytes(bytes);
            print('Standard-Datei aktualisiert: $fileName');
          } else {
            // Normal: Datei existiert, überspringe Import
            print(
                'Vorab geladenes Medium bereits vorhanden (ID: $id): $fileName');
          }
          return;
        } else {
          // Datei fehlt, lösche DB-Eintrag und importiere neu
          print(
              'Standard-Datei existiert in DB, aber Datei fehlt. Importiere neu: $fileName');
          final db = await database;
          await db.delete(
            'medien_dateien',
            where: 'id = ?',
            whereArgs: [existingMediaItem.id],
          );
          // Setze existingMediaItem auf null, damit die Datei neu importiert wird
          existingMediaItem = null;
        }
      }

      // App-Verzeichnis für Dateien verwenden (nicht temporäres Verzeichnis)
      final appDir = await getAppDirectory();
      final targetPath = '${appDir.path}/$fileName';
      print('Zielpfad: $targetPath');

      // Datei in App-Verzeichnis schreiben
      final file = File(targetPath);
      await file.writeAsBytes(bytes);

      // Prüfen ob Datei erfolgreich geschrieben wurde
      if (!file.existsSync()) {
        print('FEHLER: Datei konnte nicht geschrieben werden: $targetPath');
        return;
      }

      final fileSize = file.lengthSync();
      print(
          '${typ == MedienTyp.pdf ? 'PDF' : 'MP3'} erfolgreich kopiert nach: $targetPath');
      print('Dateigröße: $fileSize bytes');

      // MedienDatei-Objekt erstellen
      final medienDatei = MedienDatei(
        id: id,
        typ: typ,
        dateiname: fileName,
        dateipfad: targetPath,
        groesse: bytes.length,
        importDatum: DateTime.now(),
        metadaten: {
          'isPreloaded': true,
          'originalAssetPath': assetPath,
        },
      );

      // In Datenbank speichern
      await insertMedienDatei(medienDatei);
      print(
          '✓ Vorab geladenes ${typ == MedienTyp.pdf ? 'PDF' : 'MP3'} erfolgreich importiert: $fileName (ID: $id)');
    } catch (e, stackTrace) {
      print('FEHLER beim Importieren von $assetPath: $e');
      print('Stack Trace: $stackTrace');
    }
  }

  // Manuell eine PDF-Datei zu den vorab geladenen PDFs hinzufügen
  Future<void> addPreloadedPDF(File pdfFile) async {
    try {
      final fileName = pdfFile.path.split('/').last;
      final id =
          'preloaded_${fileName.replaceAll('.pdf', '').replaceAll(' ', '_')}';

      // Prüfen ob bereits vorhanden
      final existingPDFs = await getMedienDateien();
      if (existingPDFs.any((pdf) => pdf.id == id)) {
        print('PDF bereits vorhanden: $fileName');
        return;
      }

      // Datei in temporäres Verzeichnis kopieren
      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/$fileName';
      final tempFile = await pdfFile.copy(tempPath);

      // MedienDatei-Objekt erstellen
      final medienDatei = MedienDatei(
        id: id,
        typ: MedienTyp.pdf,
        dateiname: fileName,
        dateipfad: tempPath,
        groesse: await tempFile.length(),
        importDatum: DateTime.now(),
        metadaten: {
          'isPreloaded': true,
          'addedManually': true,
        },
      );

      // In Datenbank speichern
      await insertMedienDatei(medienDatei);
      print('PDF manuell hinzugefügt: $fileName');
    } catch (e) {
      print('Fehler beim Hinzufügen der PDF: $e');
    }
  }

  // App-Verzeichnis für Dateien abrufen
  Future<Directory> getAppDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final medienDir = Directory('${appDir.path}/medien');

    if (!await medienDir.exists()) {
      await medienDir.create(recursive: true);
    }

    return medienDir;
  }

  // Notizen Operationen
  Future<void> insertNotiz(Notiz notiz) async {
    final db = await database;
    await db.insert('notizen', notiz.toMap());
  }

  Future<List<Notiz>> getAllNotizen() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('notizen');
    return List.generate(maps.length, (i) => Notiz.fromMap(maps[i]));
  }

  Future<void> updateNotiz(Notiz notiz) async {
    final db = await database;
    await db.update(
      'notizen',
      notiz.toMap(),
      where: 'id = ?',
      whereArgs: [notiz.id],
    );
  }

  Future<void> deleteNotiz(String id) async {
    final db = await database;
    await db.delete(
      'notizen',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Notiz>> getNotizenByEtappe(String etappenId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'notizen',
      where: 'etappen_id = ?',
      whereArgs: [etappenId],
      orderBy: 'erstellt_am DESC',
    );
    return List.generate(maps.length, (i) => Notiz.fromMap(maps[i]));
  }

  // Beispiel-Etappe erstellen (nur beim ersten App-Start)
  Future<void> createExampleStageIfNeeded(
      {bool isBeispielEtappeGeloescht = false}) async {
    try {
      // Prüfen ob der User die Beispiel-Etappe bereits gelöscht hat
      if (isBeispielEtappeGeloescht) {
        print(
            'Beispiel-Etappe wurde vom User gelöscht, überspringe Erstellung');
        return;
      }

      // Prüfen ob bereits die Beispiel-Etappe vorhanden ist
      final db = await database;
      final existingExample = await db.query(
        'etappen',
        where: 'id = ?',
        whereArgs: ['beispiel_etappe_2025'],
      );

      if (existingExample.isNotEmpty) {
        print('Beispiel-Etappe bereits vorhanden, überspringe Erstellung');
        return;
      }

      // Bereinige fehlerhafte Etappen (falls vorhanden)
      await _cleanupCorruptedStages();

      // Beispiel-Bild kopieren und Bild-Eintrag erstellen
      final bildId = await _createExampleImage();

      // Beispielwetter erstellen
      final beispielWetter = WetterDaten(
        temperatur: 18.5,
        beschreibung: 'Leicht bewölkt',
        hauptKategorie: 'Clouds',
        icon: '02d',
        luftfeuchtigkeit: 65.0,
        windgeschwindigkeit: 12.3,
        windrichtung: 225.0, // SW
        luftdruck: 1013.2,
        gefuehlteTemperatur: 19.2,
        zeitstempel: DateTime(2025, 8, 1, 6, 0),
        ort: 'Beispielort',
      );

      // Beispiel-Etappe erstellen
      final beispielEtappe = Etappe(
        id: 'beispiel_etappe_2025',
        name: 'Beispiel-Etappe',
        startzeit: DateTime(2025, 8, 1, 6, 0),
        endzeit: DateTime(2025, 8, 1, 10, 30), // 4,5 Stunden Dauer
        status: EtappenStatus.abgeschlossen,
        gesamtDistanz: 30000.0, // 30 km in Metern
        schrittAnzahl: 42000, // Realistische Schrittanzahl für 30km
        gpsPunkte: _createExampleGPSPoints(),
        notizen:
            'Tipp: Nutze die App weniger für Zahlen und Fakten. Konzentriere dich auf deine persönlichen Eindrücke und Erfahrungen.',
        erstellungsDatum: DateTime(2025, 8, 1, 6, 0),
        bildIds: bildId != null ? [bildId] : [],
        startWetter: beispielWetter,
        wetterVerlauf: [beispielWetter],
      );

      // In Datenbank speichern
      await insertEtappe(beispielEtappe);
      print('Beispiel-Etappe erfolgreich erstellt');
    } catch (e) {
      print('Fehler beim Erstellen der Beispiel-Etappe: $e');
    }
  }

  // Beispiel-Bild kopieren und Bild-Eintrag erstellen
  Future<String?> _createExampleImage() async {
    try {
      // Versuche das Bild aus Assets zu laden
      ByteData? imageData;
      try {
        imageData = await rootBundle.load('assets/images/beispiel.jpg');
      } catch (e) {
        print(
            'beispiel.jpg nicht in Assets gefunden, versuche aus Projektroot');

        // Fallback: Versuche aus Projektroot zu laden
        final projectRoot = Directory.current;
        final beispielFile = File('${projectRoot.path}/beispiel.jpg');

        if (beispielFile.existsSync()) {
          final bytes = await beispielFile.readAsBytes();
          imageData = ByteData.view(Uint8List.fromList(bytes).buffer);
        } else {
          print(
              'beispiel.jpg nicht gefunden - Beispiel-Etappe wird ohne Bild erstellt');
          return null;
        }
      }

      // App-Verzeichnis für Bilder erstellen
      final appDir = await getApplicationDocumentsDirectory();
      final bilderDir = Directory('${appDir.path}/bilder');
      if (!await bilderDir.exists()) {
        await bilderDir.create(recursive: true);
      }

      // Bild speichern
      final zielPfad = '${bilderDir.path}/beispiel_etappe.jpg';
      final file = File(zielPfad);
      await file.writeAsBytes(imageData.buffer.asUint8List());

      // Bild-Eintrag erstellen
      final bildId = 'beispiel_bild_2025';
      final beispielBild = Bild(
        id: bildId,
        dateiname: 'beispiel_etappe.jpg',
        dateipfad: zielPfad,
        latitude: 47.3769, // Beispiel-Koordinaten (Zürich)
        longitude: 8.5417,
        aufnahmeZeit: DateTime(2025, 8, 1, 8, 30),
        etappenId: 'beispiel_etappe_2025',
        metadaten: {
          'isExample': true,
          'beschreibung': 'Beispielbild für die Beispiel-Etappe',
        },
      );

      await insertBild(beispielBild);
      print('Beispiel-Bild erfolgreich erstellt: $zielPfad');
      return bildId;
    } catch (e) {
      print('Fehler beim Erstellen des Beispiel-Bildes: $e');
      return null;
    }
  }

  // Beispiel-GPS-Punkte erstellen (simulierte Route)
  List<GPSPunkt> _createExampleGPSPoints() {
    final startLat = 47.3769;
    final startLon = 8.5417;
    final punkte = <GPSPunkt>[];

    // Simuliere eine Route mit 30 GPS-Punkten über 4,5 Stunden
    for (int i = 0; i < 30; i++) {
      final zeitOffset = Duration(minutes: i * 9); // Alle 9 Minuten ein Punkt
      final latOffset = (i * 0.002) - 0.03; // Leichte Bewegung nach Süden
      final lonOffset = (i * 0.001) - 0.015; // Leichte Bewegung nach Westen

      punkte.add(GPSPunkt(
        latitude: startLat + latOffset,
        longitude: startLon + lonOffset,
        altitude: 400.0 + (i * 2.5), // Leichter Anstieg
        timestamp: DateTime(2025, 8, 1, 6, 0).add(zeitOffset),
        accuracy: 3.0 + (i % 3), // Wechselnde Genauigkeit
      ));
    }

    return punkte;
  }

  // Bereinige fehlerhafte Etappen (die nicht korrekt geladen werden können)
  Future<void> _cleanupCorruptedStages() async {
    try {
      final db = await database;
      final allEtappenMaps = await db.query('etappen');

      for (final etappenMap in allEtappenMaps) {
        try {
          // Versuche die Etappe zu laden
          Etappe.fromMap(etappenMap);
        } catch (e) {
          // Wenn das Laden fehlschlägt, lösche die fehlerhafte Etappe
          print('Lösche fehlerhafte Etappe mit ID: ${etappenMap['id']}');
          await db.delete(
            'etappen',
            where: 'id = ?',
            whereArgs: [etappenMap['id']],
          );
        }
      }
    } catch (e) {
      print('Fehler beim Bereinigen fehlerhafter Etappen: $e');
    }
  }
}

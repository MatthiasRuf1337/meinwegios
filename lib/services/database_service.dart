import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import '../models/etappe.dart';
import '../models/bild.dart';
import '../models/medien_datei.dart';

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
      version: 1,
      onCreate: _createDB,
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
        bildIds TEXT
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
    final db = await database;
    await db.delete(
      'medien_dateien',
      where: 'id = ?',
      whereArgs: [medienDateiId],
    );
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }

  // Vorab geladene Medien (PDFs und MP3s) importieren
  Future<void> importPreloadedMedia() async {
    try {
      // Datenbank zurücksetzen für Medien-Import
      final db = await database;
      await db.delete('medien_dateien');
      print('Datenbank für Medien-Import zurückgesetzt');

      // Prüfen ob bereits Medien in der Datenbank sind
      final existingMedia = await getMedienDateien();
      if (existingMedia.isNotEmpty) {
        print('Medien bereits in der Datenbank vorhanden, überspringe Import');
        return;
      }

      // Assets-Verzeichnis durchsuchen
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);

      // PDFs importieren
      final pdfAssets = manifestMap.keys
          .where((String key) =>
              key.startsWith('assets/pdf/') && key.endsWith('.pdf'))
          .toList();

      for (String assetPath in pdfAssets) {
        await _importAsset(assetPath, MedienTyp.pdf);
      }

      // MP3s importieren
      final mp3Assets = manifestMap.keys
          .where((String key) =>
              key.startsWith('assets/audio/') && key.endsWith('.mp3'))
          .toList();

      for (String assetPath in mp3Assets) {
        await _importAsset(assetPath, MedienTyp.mp3);
      }

      print('Vorab geladene Medien erfolgreich importiert');
    } catch (e) {
      print('Fehler beim Importieren der vorab geladenen Medien: $e');
    }
  }

  // Einzelne Asset-Datei importieren
  Future<void> _importAsset(String assetPath, MedienTyp typ) async {
    try {
      // Datei aus Assets laden
      final ByteData data = await rootBundle.load(assetPath);
      final List<int> bytes = data.buffer.asUint8List();

      // Dateiname aus Pfad extrahieren
      final fileName = assetPath.split('/').last;
      final extension = typ == MedienTyp.pdf ? '.pdf' : '.mp3';
      final id =
          'preloaded_${fileName.replaceAll(extension, '').replaceAll(' ', '_')}';

      // Temporären Pfad für die Datei erstellen
      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/$fileName';

      // Datei in temporäres Verzeichnis schreiben
      final file = File(tempPath);
      await file.writeAsBytes(bytes);

      // Prüfen ob Datei erfolgreich geschrieben wurde
      if (!file.existsSync()) {
        print('Fehler: Datei konnte nicht geschrieben werden: $tempPath');
        return;
      }

      print(
          '${typ == MedienTyp.pdf ? 'PDF' : 'MP3'} erfolgreich kopiert nach: $tempPath');
      print('Dateigröße: ${file.lengthSync()} bytes');

      // MedienDatei-Objekt erstellen
      final medienDatei = MedienDatei(
        id: id,
        typ: typ,
        dateiname: fileName,
        dateipfad: tempPath,
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
          'Vorab geladenes ${typ == MedienTyp.pdf ? 'PDF' : 'MP3'} importiert: $fileName');
    } catch (e) {
      print('Fehler beim Importieren von $assetPath: $e');
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
}

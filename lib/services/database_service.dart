import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
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
} 
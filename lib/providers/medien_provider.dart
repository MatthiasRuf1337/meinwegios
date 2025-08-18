import 'package:flutter/foundation.dart';
import 'dart:io';
import '../models/medien_datei.dart';
import '../services/database_service.dart';

class MedienProvider with ChangeNotifier {
  List<MedienDatei> _medienDateien = [];
  bool _isLoading = false;

  List<MedienDatei> get medienDateien => _medienDateien;
  bool get isLoading => _isLoading;

  List<MedienDatei> get pdfDateien =>
      _medienDateien.where((m) => m.istPDF).toList();
  List<MedienDatei> get mp3Dateien =>
      _medienDateien.where((m) => m.istMP3).toList();

  MedienProvider() {
    _loadMedienDateien();
  }

  Future<void> _loadMedienDateien() async {
    _isLoading = true;
    notifyListeners();

    try {
      _medienDateien = await DatabaseService.instance.getMedienDateien();
      _medienDateien.sort((a, b) {
        // Erst nach Buchsortierung, dann nach Importdatum
        final buchSortA = a.buchSortierPrioritaet;
        final buchSortB = b.buchSortierPrioritaet;

        if (buchSortA != buchSortB) {
          return buchSortA.compareTo(buchSortB);
        }

        // Bei gleicher Buchpriorität nach Importdatum (neueste zuerst)
        return b.importDatum.compareTo(a.importDatum);
      });
    } catch (e) {
      print('Fehler beim Laden der Medien-Dateien: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadMedienDateien() async {
    await _loadMedienDateien();
  }

  Future<void> addMedienDatei(MedienDatei medienDatei) async {
    try {
      await DatabaseService.instance.insertMedienDatei(medienDatei);
      _medienDateien.add(medienDatei);
      _medienDateien.sort((a, b) {
        // Erst nach Buchsortierung, dann nach Importdatum
        final buchSortA = a.buchSortierPrioritaet;
        final buchSortB = b.buchSortierPrioritaet;

        if (buchSortA != buchSortB) {
          return buchSortA.compareTo(buchSortB);
        }

        // Bei gleicher Buchpriorität nach Importdatum (neueste zuerst)
        return b.importDatum.compareTo(a.importDatum);
      });
      notifyListeners();
    } catch (e) {
      print('Fehler beim Hinzufügen der Medien-Datei: $e');
    }
  }

  Future<void> deleteMedienDatei(String medienDateiId) async {
    try {
      await DatabaseService.instance.deleteMedienDatei(medienDateiId);
      _medienDateien.removeWhere((m) => m.id == medienDateiId);
      notifyListeners();
    } catch (e) {
      print('Fehler beim Löschen der Medien-Datei: $e');
    }
  }

  List<MedienDatei> getMedienDateienByTyp(MedienTyp typ) {
    return _medienDateien.where((m) => m.typ == typ).toList();
  }

  List<MedienDatei> searchMedienDateien(String query) {
    if (query.isEmpty) return _medienDateien;

    return _medienDateien
        .where((medienDatei) =>
            medienDatei.dateiname.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  List<MedienDatei> getMedienDateienByDateRange(DateTime start, DateTime end) {
    return _medienDateien
        .where((medienDatei) =>
            medienDatei.importDatum.isAfter(start) &&
            medienDatei.importDatum.isBefore(end))
        .toList();
  }

  int getMedienDateienCount() {
    return _medienDateien.length;
  }

  int getMedienDateienCountByTyp(MedienTyp typ) {
    return _medienDateien.where((m) => m.typ == typ).length;
  }

  double getGesamtGroesse() {
    return _medienDateien.fold(
        0.0, (sum, medienDatei) => sum + medienDatei.groesse);
  }

  String getFormatierteGesamtGroesse() {
    final groesse = getGesamtGroesse();
    if (groesse < 1024) {
      return '${groesse.toStringAsFixed(0)} B';
    } else if (groesse < 1024 * 1024) {
      return '${(groesse / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(groesse / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  Future<bool> importFile(File file) async {
    try {
      if (!file.existsSync()) {
        print('Datei existiert nicht: ${file.path}');
        return false;
      }

      final fileName = file.path.split('/').last;
      final fileExtension = fileName.split('.').last.toLowerCase();

      // Bestimme den Medientyp basierend auf der Dateiendung
      MedienTyp? medienTyp;
      switch (fileExtension) {
        case 'pdf':
          medienTyp = MedienTyp.pdf;
          break;
        case 'mp3':
        case 'wav':
        case 'm4a':
        case 'aac':
        case 'flac':
        case 'ogg':
          medienTyp = MedienTyp.mp3;
          break;
        case 'jpg':
        case 'jpeg':
        case 'png':
        case 'gif':
        case 'bmp':
        case 'webp':
        case 'tiff':
          medienTyp = MedienTyp.bild;
          break;
        case 'txt':
        case 'doc':
        case 'docx':
        case 'xls':
        case 'xlsx':
        case 'ppt':
        case 'pptx':
        case 'zip':
        case 'rar':
        case '7z':
        case 'tar':
        case 'gz':
          medienTyp = MedienTyp.andere;
          break;
        default:
          medienTyp = MedienTyp.andere;
          break;
      }

      // Kopiere die Datei in das App-Verzeichnis
      final appDir = await DatabaseService.instance.getAppDirectory();
      final targetPath = '${appDir.path}/$fileName';
      final targetFile = File(targetPath);

      // Wenn die Datei bereits existiert, füge einen Zeitstempel hinzu
      if (targetFile.existsSync()) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final nameWithoutExtension =
            fileName.substring(0, fileName.lastIndexOf('.'));
        final newFileName = '${nameWithoutExtension}_$timestamp.$fileExtension';
        final newTargetPath = '${appDir.path}/$newFileName';
        await file.copy(newTargetPath);

        // Erstelle MedienDatei mit dem neuen Namen
        final medienDatei = MedienDatei(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          dateiname: newFileName,
          dateipfad: newTargetPath,
          typ: medienTyp,
          groesse: await file.length(),
          importDatum: DateTime.now(),
        );

        await addMedienDatei(medienDatei);
      } else {
        await file.copy(targetPath);

        // Erstelle MedienDatei
        final medienDatei = MedienDatei(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          dateiname: fileName,
          dateipfad: targetPath,
          typ: medienTyp,
          groesse: await file.length(),
          importDatum: DateTime.now(),
        );

        await addMedienDatei(medienDatei);
      }

      return true;
    } catch (e) {
      print('Fehler beim Importieren der Datei: $e');
      return false;
    }
  }
}

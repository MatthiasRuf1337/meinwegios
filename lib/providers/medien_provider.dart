import 'package:flutter/foundation.dart';
import '../models/medien_datei.dart';
import '../services/database_service.dart';

class MedienProvider with ChangeNotifier {
  List<MedienDatei> _medienDateien = [];
  bool _isLoading = false;

  List<MedienDatei> get medienDateien => _medienDateien;
  bool get isLoading => _isLoading;

  List<MedienDatei> get pdfDateien => _medienDateien.where((m) => m.istPDF).toList();
  List<MedienDatei> get mp3Dateien => _medienDateien.where((m) => m.istMP3).toList();

  MedienProvider() {
    _loadMedienDateien();
  }

  Future<void> _loadMedienDateien() async {
    _isLoading = true;
    notifyListeners();

    try {
      _medienDateien = await DatabaseService.instance.getMedienDateien();
      _medienDateien.sort((a, b) => b.importDatum.compareTo(a.importDatum));
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
      _medienDateien.sort((a, b) => b.importDatum.compareTo(a.importDatum));
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
    
    return _medienDateien.where((medienDatei) =>
        medienDatei.dateiname.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }

  List<MedienDatei> getMedienDateienByDateRange(DateTime start, DateTime end) {
    return _medienDateien.where((medienDatei) =>
        medienDatei.importDatum.isAfter(start) &&
        medienDatei.importDatum.isBefore(end)
    ).toList();
  }

  int getMedienDateienCount() {
    return _medienDateien.length;
  }

  int getMedienDateienCountByTyp(MedienTyp typ) {
    return _medienDateien.where((m) => m.typ == typ).length;
  }

  double getGesamtGroesse() {
    return _medienDateien.fold(0.0, (sum, medienDatei) => sum + medienDatei.groesse);
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
} 
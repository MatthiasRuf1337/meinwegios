import 'package:flutter/foundation.dart';
import '../models/bild.dart';
import '../services/database_service.dart';

class BilderProvider with ChangeNotifier {
  List<Bild> _bilder = [];
  bool _isLoading = false;

  List<Bild> get bilder => _bilder;
  bool get isLoading => _isLoading;

  BilderProvider() {
    _loadBilder();
  }

  Future<void> _loadBilder() async {
    _isLoading = true;
    notifyListeners();

    try {
      _bilder = await DatabaseService.instance.getBilder();
      _bilder.sort((a, b) => b.aufnahmeZeit.compareTo(a.aufnahmeZeit));
    } catch (e) {
      print('Fehler beim Laden der Bilder: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadBilder() async {
    await _loadBilder();
  }

  Future<void> addBild(Bild bild) async {
    try {
      await DatabaseService.instance.insertBild(bild);
      _bilder.add(bild);
      _bilder.sort((a, b) => b.aufnahmeZeit.compareTo(a.aufnahmeZeit));
      notifyListeners();
    } catch (e) {
      print('Fehler beim Hinzufügen des Bildes: $e');
    }
  }

  Future<void> deleteBild(String bildId) async {
    try {
      await DatabaseService.instance.deleteBild(bildId);
      _bilder.removeWhere((b) => b.id == bildId);
      notifyListeners();
    } catch (e) {
      print('Fehler beim Löschen des Bildes: $e');
    }
  }

  List<Bild> getBilderByEtappe(String etappenId) {
    return _bilder.where((bild) => bild.etappenId == etappenId).toList();
  }

  List<Bild> getBilderWithGPS() {
    return _bilder.where((bild) => bild.hatGPS).toList();
  }

  List<Bild> searchBilder(String query) {
    if (query.isEmpty) return _bilder;
    
    return _bilder.where((bild) =>
        bild.dateiname.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }

  List<Bild> getBilderByDateRange(DateTime start, DateTime end) {
    return _bilder.where((bild) =>
        bild.aufnahmeZeit.isAfter(start) &&
        bild.aufnahmeZeit.isBefore(end)
    ).toList();
  }

  int getBilderCount() {
    return _bilder.length;
  }

  int getBilderCountByEtappe(String etappenId) {
    return _bilder.where((bild) => bild.etappenId == etappenId).length;
  }
} 
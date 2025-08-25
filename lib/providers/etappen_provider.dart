import 'package:flutter/foundation.dart';
import '../models/etappe.dart';
import '../services/database_service.dart';
import 'settings_provider.dart';

class EtappenProvider with ChangeNotifier {
  List<Etappe> _etappen = [];
  Etappe? _aktuelleEtappe;
  bool _isLoading = false;
  SettingsProvider? _settingsProvider;

  List<Etappe> get etappen => _etappen;
  Etappe? get aktuelleEtappe => _aktuelleEtappe;
  bool get isLoading => _isLoading;
  bool get hatAktuelleEtappe => _aktuelleEtappe != null;

  EtappenProvider() {
    _loadEtappen();
  }

  // Setter für SettingsProvider
  void setSettingsProvider(SettingsProvider settingsProvider) {
    _settingsProvider = settingsProvider;
  }

  Future<void> _loadEtappen() async {
    _isLoading = true;
    notifyListeners();

    try {
      _etappen = await DatabaseService.instance.getEtappen();
      _etappen.sort((a, b) => b.erstellungsDatum.compareTo(a.erstellungsDatum));
    } catch (e) {
      print('Fehler beim Laden der Etappen: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Öffentliche Methode um Etappen neu zu laden
  Future<void> reloadEtappen() async {
    print('EtappenProvider: Lade Etappen neu...');
    await _loadEtappen();
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

      // Prüfen ob es sich um die Beispiel-Etappe handelt
      if (etappenId == 'beispiel_etappe_2025' && _settingsProvider != null) {
        await _settingsProvider!.setBeispielEtappeGeloescht(true);
        print('Beispiel-Etappe gelöscht - Flag gesetzt');
      }

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
}

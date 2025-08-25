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

      // Nach App-Neustart: Aktive Etappen wiederherstellen oder bereinigen
      await _recoverActiveEtappen();
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

  // Recovery-Mechanismus für aktive Etappen nach App-Neustart
  Future<void> _recoverActiveEtappen() async {
    try {
      // Suche nach Etappen mit Status "aktiv"
      final activeEtappen = _etappen
          .where((etappe) => etappe.status == EtappenStatus.aktiv)
          .toList();

      if (activeEtappen.isEmpty) {
        print('EtappenProvider: Keine aktiven Etappen gefunden');
        return;
      }

      print(
          'EtappenProvider: ${activeEtappen.length} aktive Etappe(n) nach App-Neustart gefunden');

      for (final etappe in activeEtappen) {
        await _handleActiveEtappeRecovery(etappe);
      }
    } catch (e) {
      print('EtappenProvider: Fehler beim Recovery aktiver Etappen: $e');
    }
  }

  // Behandlung einer einzelnen aktiven Etappe
  Future<void> _handleActiveEtappeRecovery(Etappe etappe) async {
    try {
      final now = DateTime.now();
      final timeSinceStart = now.difference(etappe.startzeit);

      print(
          'EtappenProvider: Aktive Etappe "${etappe.name}" gefunden (seit ${timeSinceStart.inMinutes} Minuten)');

      // Wenn die Etappe sehr lange läuft (mehr als 24 Stunden), automatisch abschließen
      if (timeSinceStart.inHours > 24) {
        print(
            'EtappenProvider: Etappe läuft zu lange (${timeSinceStart.inHours}h) - automatisch abschließen');
        await _autoCompleteEtappe(etappe,
            'Automatisch abgeschlossen nach App-Neustart (${timeSinceStart.inHours}h aktiv)');
        return;
      }

      // Wenn die Etappe weniger als 6 Stunden läuft, als aktuelle Etappe wiederherstellen
      if (timeSinceStart.inHours < 6) {
        print(
            'EtappenProvider: Stelle aktive Etappe "${etappe.name}" wieder her');
        _aktuelleEtappe = etappe;
        return;
      }

      // Für Etappen zwischen 6-24 Stunden: Benutzer entscheiden lassen
      // (Dies wird später in der UI behandelt)
      print(
          'EtappenProvider: Etappe "${etappe.name}" benötigt Benutzer-Entscheidung (${timeSinceStart.inHours}h aktiv)');
    } catch (e) {
      print(
          'EtappenProvider: Fehler beim Behandeln der aktiven Etappe ${etappe.id}: $e');
    }
  }

  // Automatisches Abschließen einer Etappe
  Future<void> _autoCompleteEtappe(Etappe etappe, String reason) async {
    try {
      final completedEtappe = etappe.copyWith(
        status: EtappenStatus.abgeschlossen,
        endzeit: DateTime.now(),
        notizen:
            etappe.notizen != null ? '${etappe.notizen}\n\n$reason' : reason,
      );

      await updateEtappe(completedEtappe);
      print(
          'EtappenProvider: Etappe "${etappe.name}" automatisch abgeschlossen');
    } catch (e) {
      print(
          'EtappenProvider: Fehler beim automatischen Abschließen der Etappe: $e');
    }
  }

  // Öffentliche Methode um verwaiste aktive Etappen zu finden
  List<Etappe> getOrphanedActiveEtappen() {
    final now = DateTime.now();
    return _etappen.where((etappe) {
      if (etappe.status != EtappenStatus.aktiv) return false;
      if (etappe == _aktuelleEtappe) return false; // Nicht die aktuell aktive

      final timeSinceStart = now.difference(etappe.startzeit);
      return timeSinceStart.inHours >= 6 && timeSinceStart.inHours <= 24;
    }).toList();
  }

  // Manuelle Wiederherstellung einer Etappe
  Future<void> restoreEtappe(Etappe etappe) async {
    try {
      // Aktuelle Etappe stoppen falls vorhanden
      if (_aktuelleEtappe != null) {
        await _autoCompleteEtappe(_aktuelleEtappe!,
            'Automatisch beendet für Wiederherstellung einer anderen Etappe');
      }

      // Etappe als aktuelle setzen
      _aktuelleEtappe = etappe;
      notifyListeners();

      print(
          'EtappenProvider: Etappe "${etappe.name}" manuell wiederhergestellt');
    } catch (e) {
      print('EtappenProvider: Fehler beim Wiederherstellen der Etappe: $e');
    }
  }

  // Manuelle Beendigung einer verwaisten Etappe
  Future<void> completeOrphanedEtappe(Etappe etappe) async {
    await _autoCompleteEtappe(
        etappe, 'Manuell abgeschlossen nach App-Neustart');
  }
}

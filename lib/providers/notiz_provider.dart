import 'package:flutter/foundation.dart';
import '../models/notiz.dart';
import '../services/database_service.dart';

class NotizProvider with ChangeNotifier {
  List<Notiz> _notizen = [];
  bool _isLoading = false;

  List<Notiz> get notizen => _notizen;
  bool get isLoading => _isLoading;

  List<Notiz> getNotizenByEtappe(String etappenId) {
    return _notizen
        .where((notiz) => notiz.etappenId == etappenId)
        .toList()
        ..sort((a, b) => b.erstelltAm.compareTo(a.erstelltAm)); // Neueste zuerst
  }

  Future<void> loadNotizen() async {
    _isLoading = true;
    notifyListeners();

    try {
      _notizen = await DatabaseService.instance.getAllNotizen();
    } catch (e) {
      print('Fehler beim Laden der Notizen: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addNotiz(Notiz notiz) async {
    try {
      await DatabaseService.instance.insertNotiz(notiz);
      _notizen.add(notiz);
      notifyListeners();
    } catch (e) {
      print('Fehler beim Hinzufügen der Notiz: $e');
      rethrow;
    }
  }

  Future<void> updateNotiz(Notiz notiz) async {
    try {
      await DatabaseService.instance.updateNotiz(notiz);
      final index = _notizen.indexWhere((n) => n.id == notiz.id);
      if (index != -1) {
        _notizen[index] = notiz;
        notifyListeners();
      }
    } catch (e) {
      print('Fehler beim Aktualisieren der Notiz: $e');
      rethrow;
    }
  }

  Future<void> deleteNotiz(String id) async {
    try {
      await DatabaseService.instance.deleteNotiz(id);
      _notizen.removeWhere((notiz) => notiz.id == id);
      notifyListeners();
    } catch (e) {
      print('Fehler beim Löschen der Notiz: $e');
      rethrow;
    }
  }
}

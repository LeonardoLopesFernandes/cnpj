import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/empresa.dart';

class StorageService {
  static const String _historyKey = 'lista_empresas';
  static const String _favoritesKey = 'lista_favoritos';
  static const int _maxHistory = 10;

  Future<List<Empresa>> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_historyKey);
    if (data == null || data.isEmpty) return [];
    try {
      final list = jsonDecode(data) as List;
      return list.map((e) => Empresa.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveHistory(List<Empresa> empresas) async {
    final prefs = await SharedPreferences.getInstance();
    final limited =
        empresas.length > _maxHistory ? empresas.sublist(0, _maxHistory) : empresas;
    await prefs.setString(
        _historyKey, jsonEncode(limited.map((e) => e.toJson()).toList()));
  }

  Future<void> addToHistory(Empresa empresa) async {
    final list = await loadHistory();
    list.removeWhere((e) => e.cnpj == empresa.cnpj);
    list.insert(0, empresa);
    await saveHistory(list);
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }

  Future<List<Empresa>> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_favoritesKey);
    if (data == null || data.isEmpty) return [];
    try {
      final list = jsonDecode(data) as List;
      return list.map((e) => Empresa.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveFavorites(List<Empresa> empresas) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _favoritesKey, jsonEncode(empresas.map((e) => e.toJson()).toList()));
  }

  Future<bool> isFavorite(String cnpj) async {
    final list = await loadFavorites();
    return list.any((e) => e.cnpj == cnpj);
  }

  Future<void> toggleFavorite(Empresa empresa) async {
    final list = await loadFavorites();
    final idx = list.indexWhere((e) => e.cnpj == empresa.cnpj);
    if (idx >= 0) {
      list.removeAt(idx);
    } else {
      list.insert(0, empresa);
    }
    await saveFavorites(list);
  }

  Future<void> clearFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_favoritesKey);
  }
}

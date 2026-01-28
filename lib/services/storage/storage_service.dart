import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class StorageService {
  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // String operations
  Future<void> setString(String key, String value) async {
    await _prefs.setString(key, value);
  }

  String? getString(String key) => _prefs.getString(key);

  // Boolean operations
  Future<void> setBool(String key, bool value) async {
    await _prefs.setBool(key, value);
  }

  bool? getBool(String key) => _prefs.getBool(key);

  // Integer operations
  Future<void> setInt(String key, int value) async {
    await _prefs.setInt(key, value);
  }

  int? getInt(String key) => _prefs.getInt(key);

  // List operations
  Future<void> setStringList(String key, List<String> value) async {
    await _prefs.setStringList(key, value);
  }

  List<String>? getStringList(String key) => _prefs.getStringList(key);

  // JSON operations
  Future<void> setJson(String key, Map<String, dynamic> json) async {
    await _prefs.setString(key, jsonEncode(json));
  }

  Map<String, dynamic>? getJson(String key) {
    final value = _prefs.getString(key);
    if (value == null) return null;
    return jsonDecode(value) as Map<String, dynamic>;
  }

  Future<void> setJsonList(String key, List<Map<String, dynamic>> list) async {
    await _prefs.setString(key, jsonEncode(list));
  }

  List<Map<String, dynamic>>? getJsonList(String key) {
    final value = _prefs.getString(key);
    if (value == null) return null;
    final decoded = jsonDecode(value) as List<dynamic>;
    return decoded.map((e) => e as Map<String, dynamic>).toList();
  }

  // Clear operations
  Future<void> remove(String key) async {
    await _prefs.remove(key);
  }

  Future<void> clear() async {
    await _prefs.clear();
  }

  bool hasKey(String key) => _prefs.containsKey(key);
}

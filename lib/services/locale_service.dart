import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LocaleService extends ChangeNotifier {
  String _currentLang = 'en';
  Map<String, String> _strings = {};
  final Map<String, Map<String, String>> _cache = {};
  List<Map<String, String>> _languages = [];

  String get currentLang => _currentLang;
  List<Map<String, String>> get languages => _languages;

  Future<void> init() async {
    await _loadManifest();
    await loadLanguage(_currentLang);
  }

  Future<void> _loadManifest() async {
    try {
      final raw = await rootBundle.loadString('assets/locales/locales.json');
      final Map<String, dynamic> decoded = json.decode(raw);
      final List<dynamic> list = decoded['languages'];
      _languages = list
          .map((e) => Map<String, String>.from(e))
          .toList();
      if (_languages.isNotEmpty) {
        final hasDefault = _languages.any((l) => l['code'] == _currentLang);
        if (!hasDefault) {
          _currentLang = _languages.first['code'] ?? 'en';
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Manifest load error: $e');
      _languages = [];
    }
  }

  Future<void> loadLanguage(String langCode) async {
    if (_cache.containsKey(langCode)) {
      _strings = _cache[langCode]!;
      _currentLang = langCode;
      notifyListeners();
      return;
    }

    try {
      final jsonString =
      await rootBundle.loadString('assets/locales/$langCode.json');
      final Map<String, dynamic> decoded = json.decode(jsonString);
      final Map<String, String> loaded = decoded.map(
            (key, value) => MapEntry(key, value.toString()),
      );
      _cache[langCode] = loaded;
      _strings = loaded;
      _currentLang = langCode;
      notifyListeners();
    } catch (e) {
      debugPrint('Locale load error for $langCode: $e');
    }
  }

  String t(String key) {
    return _strings[key] ?? key;
  }
}
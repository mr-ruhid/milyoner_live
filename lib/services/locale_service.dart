import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LocaleService extends ChangeNotifier {
  String _currentLang = 'en';
  Map<String, String> _strings = {};
  final Map<String, Map<String, String>> _cache = {};

  String get currentLang => _currentLang;

  static const List<Map<String, String>> supportedLanguages = [
    {'code': 'az', 'flag': '🇦🇿', 'name': 'Azərbaycan'},
    {'code': 'en', 'flag': '🇬🇧', 'name': 'English'},
    {'code': 'tr', 'flag': '🇹🇷', 'name': 'Türkçe'},
    {'code': 'ru', 'flag': '🇷🇺', 'name': 'Русский'},
  ];

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
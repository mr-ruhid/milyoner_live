import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/question.dart';

class QuestionService extends ChangeNotifier {
  static const String _storageKey = 'user_questions';
  List<Question> _questions = [];
  bool _isLoaded = false;
  String _currentLang = 'en';
  bool _usedFallback = false;

  List<Question> get questions => _questions;
  bool get isLoaded => _isLoaded;
  String get currentLang => _currentLang;
  bool get usedFallback => _usedFallback;

  Future<void> loadQuestions(String langCode) async {
    _currentLang = langCode;
    _usedFallback = false;
    final prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString('${_storageKey}_$langCode');

    if (raw != null && raw.isNotEmpty) {
      try {
        final List<dynamic> decoded = json.decode(raw);
        _questions = decoded
            .map((e) => Question.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        _isLoaded = true;
        notifyListeners();
        return;
      } catch (e) {
        debugPrint('Question load error: $e');
      }
    }

    await _loadFromAssets(langCode);
  }

  Future<void> _loadFromAssets(String langCode) async {
    try {
      final jsonString = await rootBundle
          .loadString('assets/questions/questions_$langCode.json');
      final Map<String, dynamic> decoded = json.decode(jsonString);
      final List<dynamic> list = decoded['questions'];
      _questions = list
          .map((e) => Question.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      await _save();
    } catch (e) {
      debugPrint('Asset load error for $langCode: $e');
      if (langCode != 'en') {
        await _loadFallbackEnglish();
      } else {
        _questions = [];
      }
    }
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> _loadFallbackEnglish() async {
    try {
      final jsonString =
      await rootBundle.loadString('assets/questions/questions_en.json');
      final Map<String, dynamic> decoded = json.decode(jsonString);
      final List<dynamic> list = decoded['questions'];
      _questions = list
          .map((e) => Question.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      _usedFallback = true;
    } catch (e) {
      debugPrint('English fallback load error: $e');
      _questions = [];
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final String raw =
    json.encode(_questions.map((q) => q.toJson()).toList());
    await prefs.setString('${_storageKey}_$_currentLang', raw);
  }

  Future<void> addQuestion(Question question) async {
    _questions.add(question);
    await _save();
    notifyListeners();
  }

  Future<void> updateQuestion(String id, Question updated) async {
    final index = _questions.indexWhere((q) => q.id == id);
    if (index != -1) {
      _questions[index] = updated;
      await _save();
      notifyListeners();
    }
  }

  Future<void> deleteQuestion(String id) async {
    _questions.removeWhere((q) => q.id == id);
    await _save();
    notifyListeners();
  }

  Future<void> saveQuestionForLanguages(
      String id,
      Map<String, Question> perLang,
      ) async {
    final prefs = await SharedPreferences.getInstance();
    for (final entry in perLang.entries) {
      final lang = entry.key;
      final newQ = entry.value;
      final key = '${_storageKey}_$lang';
      final raw = prefs.getString(key);
      List<Question> list = [];
      if (raw != null && raw.isNotEmpty) {
        try {
          final decoded = json.decode(raw) as List;
          list = decoded
              .map((e) => Question.fromJson(Map<String, dynamic>.from(e)))
              .toList();
        } catch (_) {}
      }
      final idx = list.indexWhere((q) => q.id == id);
      if (idx != -1) {
        list[idx] = newQ;
      } else {
        list.add(newQ);
      }
      await prefs.setString(
        key,
        json.encode(list.map((q) => q.toJson()).toList()),
      );
    }
    await loadQuestions(_currentLang);
  }

  Future<Map<String, Question>> loadQuestionTranslations(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, Question> result = {};
    final keys = prefs.getKeys();
    for (final key in keys) {
      if (!key.startsWith('${_storageKey}_')) continue;
      final lang = key.substring('${_storageKey}_'.length);
      final raw = prefs.getString(key);
      if (raw == null || raw.isEmpty) continue;
      try {
        final decoded = json.decode(raw) as List;
        final list = decoded
            .map((e) => Question.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        final idx = list.indexWhere((q) => q.id == id);
        if (idx != -1) {
          result[lang] = list[idx];
        }
      } catch (_) {}
    }
    return result;
  }

  Future<void> deleteQuestionFromAllLanguages(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs
        .getKeys()
        .where((k) => k.startsWith('${_storageKey}_'))
        .toList();
    for (final key in keys) {
      final raw = prefs.getString(key);
      if (raw == null || raw.isEmpty) continue;
      try {
        final decoded = json.decode(raw) as List;
        final list = decoded
            .map((e) => Question.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        list.removeWhere((q) => q.id == id);
        await prefs.setString(
          key,
          json.encode(list.map((q) => q.toJson()).toList()),
        );
      } catch (_) {}
    }
    await loadQuestions(_currentLang);
  }

  Future<void> resetToDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('${_storageKey}_$_currentLang');
    await _loadFromAssets(_currentLang);
  }

  String generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/question.dart';

class QuestionService extends ChangeNotifier {
  static const String _storageKey = 'user_questions';
  List<Question> _questions = [];
  bool _isLoaded = false;

  List<Question> get questions => _questions;
  bool get isLoaded => _isLoaded;

  Future<void> loadQuestions() async {
    final prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_storageKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final List<dynamic> decoded = json.decode(raw);
        _questions = decoded
            .map((e) => Question.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      } catch (e) {
        debugPrint('Question load error: $e');
        _questions = [];
      }
    }
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final String raw = json.encode(
      _questions.map((q) => q.toJson()).toList(),
    );
    await prefs.setString(_storageKey, raw);
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

  Future<void> clearAll() async {
    _questions.clear();
    await _save();
    notifyListeners();
  }

  List<Question> getQuestionsForLanguage(String lang) {
    return _questions.where((q) => q.hasLanguage(lang)).toList();
  }

  String generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}
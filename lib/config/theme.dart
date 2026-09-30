
import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFF0A0E27);
  static const Color panelDark = Color(0xFF151A3A);
  static const Color panelBlue = Color(0xFF1E2A5A);
  static const Color gold = Color(0xFFFFD700);
  static const Color goldDark = Color(0xFFB8860B);
  static const Color correct = Color(0xFF2ECC71);
  static const Color wrong = Color(0xFFE74C3C);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B8D4);
  static const Color optionA = Color(0xFFE74C3C);
  static const Color optionB = Color(0xFF3498DB);
  static const Color optionC = Color(0xFFF39C12);
  static const Color optionD = Color(0xFF2ECC71);
}

class AppStrings {
  static const Map<String, Map<String, String>> values = {
    'az': {
      'app_title': 'MİLYONER',
      'app_subtitle': 'CANLI',
      'select_language': 'DİL SEÇ',
      'start_game': 'OYUNA BAŞLA',
      'question': 'SUAL',
      'time_left': 'QALAN VAXT',
      'correct': 'DÜZGÜN!',
      'wrong': 'SƏHV!',
      'next': 'NÖVBƏTİ',
      'skip': 'KEÇ',
      'fifty_fifty': '50/50',
      'reveal': 'CAVABI GÖSTƏR',
      'manage_questions': 'SUALLARI İDARƏ ET',
      'add_question': 'SUAL ƏLAVƏ ET',
      'edit_question': 'SUALI REDAKTƏ ET',
      'delete_question': 'SUALI SİL',
      'save': 'YADDA SAXLA',
      'cancel': 'LƏĞV ET',
      'question_text': 'Sual mətni',
      'option_a': 'A variantı',
      'option_b': 'B variantı',
      'option_c': 'C variantı',
      'option_d': 'D variantı',
      'correct_answer': 'Düzgün cavab',
      'reward': 'Mükafat',
      'settings': 'AYARLAR',
      'sound': 'SƏS',
      'music': 'MUSİQİ',
    },
    'en': {
      'app_title': 'MILLIONAIRE',
      'app_subtitle': 'LIVE',
      'select_language': 'SELECT LANGUAGE',
      'start_game': 'START GAME',
      'question': 'QUESTION',
      'time_left': 'TIME LEFT',
      'correct': 'CORRECT!',
      'wrong': 'WRONG!',
      'next': 'NEXT',
      'skip': 'SKIP',
      'fifty_fifty': '50/50',
      'reveal': 'REVEAL ANSWER',
      'manage_questions': 'MANAGE QUESTIONS',
      'add_question': 'ADD QUESTION',
      'edit_question': 'EDIT QUESTION',
      'delete_question': 'DELETE QUESTION',
      'save': 'SAVE',
      'cancel': 'CANCEL',
      'question_text': 'Question text',
      'option_a': 'Option A',
      'option_b': 'Option B',
      'option_c': 'Option C',
      'option_d': 'Option D',
      'correct_answer': 'Correct answer',
      'reward': 'Reward',
      'settings': 'SETTINGS',
      'sound': 'SOUND',
      'music': 'MUSIC',
    },
    'tr': {
      'app_title': 'MİLYONER',
      'app_subtitle': 'CANLI',
      'select_language': 'DİL SEÇ',
      'start_game': 'OYUNA BAŞLA',
      'question': 'SORU',
      'time_left': 'KALAN SÜRE',
      'correct': 'DOĞRU!',
      'wrong': 'YANLIŞ!',
      'next': 'SONRAKİ',
      'skip': 'GEÇ',
      'fifty_fifty': '50/50',
      'reveal': 'CEVABI GÖSTER',
      'manage_questions': 'SORULARI YÖNET',
      'add_question': 'SORU EKLE',
      'edit_question': 'SORUYU DÜZENLE',
      'delete_question': 'SORUYU SİL',
      'save': 'KAYDET',
      'cancel': 'İPTAL',
      'question_text': 'Soru metni',
      'option_a': 'A seçeneği',
      'option_b': 'B seçeneği',
      'option_c': 'C seçeneği',
      'option_d': 'D seçeneği',
      'correct_answer': 'Doğru cevap',
      'reward': 'Ödül',
      'settings': 'AYARLAR',
      'sound': 'SES',
      'music': 'MÜZİK',
    },
    'ru': {
      'app_title': 'МИЛЛИОНЕР',
      'app_subtitle': 'В ЭФИРЕ',
      'select_language': 'ВЫБЕРИТЕ ЯЗЫК',
      'start_game': 'НАЧАТЬ ИГРУ',
      'question': 'ВОПРОС',
      'time_left': 'ОСТАЛОСЬ',
      'correct': 'ПРАВИЛЬНО!',
      'wrong': 'НЕПРАВИЛЬНО!',
      'next': 'ДАЛЕЕ',
      'skip': 'ПРОПУСТИТЬ',
      'fifty_fifty': '50/50',
      'reveal': 'ПОКАЗАТЬ ОТВЕТ',
      'manage_questions': 'УПРАВЛЕНИЕ ВОПРОСАМИ',
      'add_question': 'ДОБАВИТЬ ВОПРОС',
      'edit_question': 'РЕДАКТИРОВАТЬ',
      'delete_question': 'УДАЛИТЬ',
      'save': 'СОХРАНИТЬ',
      'cancel': 'ОТМЕНА',
      'question_text': 'Текст вопроса',
      'option_a': 'Вариант A',
      'option_b': 'Вариант B',
      'option_c': 'Вариант C',
      'option_d': 'Вариант D',
      'correct_answer': 'Правильный ответ',
      'reward': 'Награда',
      'settings': 'НАСТРОЙКИ',
      'sound': 'ЗВУК',
      'music': 'МУЗЫКА',
    },
  };

  static String get(String lang, String key) {
    return values[lang]?[key] ?? values['en']?[key] ?? key;
  }
}
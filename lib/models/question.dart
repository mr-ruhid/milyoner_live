class Question {
  final String id;
  final Map<String, Map<String, dynamic>> translations;
  final int correct;
  final int reward;

  Question({
    required this.id,
    required this.translations,
    required this.correct,
    required this.reward,
  });

  String getQuestion(String lang) {
    return translations[lang]?['question'] ??
        translations['en']?['question'] ??
        '';
  }

  List<String> getOptions(String lang) {
    final opts = translations[lang]?['options'] ??
        translations['en']?['options'] ??
        [];
    return List<String>.from(opts);
  }

  bool hasLanguage(String lang) {
    return translations.containsKey(lang);
  }

  Question copyWith({
    String? id,
    Map<String, Map<String, dynamic>>? translations,
    int? correct,
    int? reward,
  }) {
    return Question(
      id: id ?? this.id,
      translations: translations ?? this.translations,
      correct: correct ?? this.correct,
      reward: reward ?? this.reward,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'translations': translations,
      'correct': correct,
      'reward': reward,
    };
  }

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'].toString(),
      translations: Map<String, Map<String, dynamic>>.from(
        (json['translations'] as Map).map(
              (k, v) => MapEntry(k.toString(), Map<String, dynamic>.from(v)),
        ),
      ),
      correct: json['correct'] as int,
      reward: json['reward'] as int? ?? 100,
    );
  }
}
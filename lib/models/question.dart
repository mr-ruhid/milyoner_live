class Question {
  final String id;
  final String question;
  final List<String> options;
  final int correct;
  final int reward;

  Question({
    required this.id,
    required this.question,
    required this.options,
    required this.correct,
    required this.reward,
  });

  Question copyWith({
    String? id,
    String? question,
    List<String>? options,
    int? correct,
    int? reward,
  }) {
    return Question(
      id: id ?? this.id,
      question: question ?? this.question,
      options: options ?? this.options,
      correct: correct ?? this.correct,
      reward: reward ?? this.reward,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'options': options,
      'correct': correct,
      'reward': reward,
    };
  }

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'].toString(),
      question: json['question'] as String,
      options: List<String>.from(json['options']),
      correct: json['correct'] as int,
      reward: json['reward'] as int? ?? 100,
    );
  }
}
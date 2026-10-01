class PlayerStats {
  final String username;
  final String? avatarUrl;
  final int correctCount;
  final int totalAnswered;
  final int bonusPoints;
  final bool sentUniverse;
  final int totalCoins;

  PlayerStats({
    required this.username,
    this.avatarUrl,
    required this.correctCount,
    required this.totalAnswered,
    this.bonusPoints = 0,
    this.sentUniverse = false,
    this.totalCoins = 0,
  });

  int get score => correctCount + bonusPoints;

  PlayerStats copyWith({
    String? username,
    String? avatarUrl,
    int? correctCount,
    int? totalAnswered,
    int? bonusPoints,
    bool? sentUniverse,
    int? totalCoins,
  }) {
    return PlayerStats(
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      correctCount: correctCount ?? this.correctCount,
      totalAnswered: totalAnswered ?? this.totalAnswered,
      bonusPoints: bonusPoints ?? this.bonusPoints,
      sentUniverse: sentUniverse ?? this.sentUniverse,
      totalCoins: totalCoins ?? this.totalCoins,
    );
  }

  Map<String, dynamic> toJson() => {
    'username': username,
    'avatarUrl': avatarUrl,
    'correctCount': correctCount,
    'totalAnswered': totalAnswered,
    'bonusPoints': bonusPoints,
    'sentUniverse': sentUniverse,
    'totalCoins': totalCoins,
  };

  factory PlayerStats.fromJson(Map<String, dynamic> json) {
    return PlayerStats(
      username: json['username'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      correctCount: json['correctCount'] as int? ?? 0,
      totalAnswered: json['totalAnswered'] as int? ?? 0,
      bonusPoints: json['bonusPoints'] as int? ?? 0,
      sentUniverse: json['sentUniverse'] as bool? ?? false,
      totalCoins: json['totalCoins'] as int? ?? 0,
    );
  }
}
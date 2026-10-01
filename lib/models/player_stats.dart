class PlayerStats {
  final String username;
  final String? avatarUrl;
  final int correctCount;
  final int totalAnswered;
  final bool sentUniverse;
  final int totalCoins;

  PlayerStats({
    required this.username,
    this.avatarUrl,
    required this.correctCount,
    required this.totalAnswered,
    this.sentUniverse = false,
    this.totalCoins = 0,
  });

  PlayerStats copyWith({
    String? username,
    String? avatarUrl,
    int? correctCount,
    int? totalAnswered,
    bool? sentUniverse,
    int? totalCoins,
  }) {
    return PlayerStats(
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      correctCount: correctCount ?? this.correctCount,
      totalAnswered: totalAnswered ?? this.totalAnswered,
      sentUniverse: sentUniverse ?? this.sentUniverse,
      totalCoins: totalCoins ?? this.totalCoins,
    );
  }

  Map<String, dynamic> toJson() => {
    'username': username,
    'avatarUrl': avatarUrl,
    'correctCount': correctCount,
    'totalAnswered': totalAnswered,
    'sentUniverse': sentUniverse,
    'totalCoins': totalCoins,
  };

  factory PlayerStats.fromJson(Map<String, dynamic> json) {
    return PlayerStats(
      username: json['username'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      correctCount: json['correctCount'] as int? ?? 0,
      totalAnswered: json['totalAnswered'] as int? ?? 0,
      sentUniverse: json['sentUniverse'] as bool? ?? false,
      totalCoins: json['totalCoins'] as int? ?? 0,
    );
  }
}
enum GiftAction {
  answerA,
  answerB,
  answerC,
  answerD,
  powerFifty,
  powerReveal,
  powerNext,
  superUniverse,
}

class Gift {
  final String name;
  final String emoji;
  final int coins;
  final GiftAction action;

  const Gift({
    required this.name,
    required this.emoji,
    required this.coins,
    required this.action,
  });

  bool get isAnswer =>
      action == GiftAction.answerA ||
          action == GiftAction.answerB ||
          action == GiftAction.answerC ||
          action == GiftAction.answerD;

  bool get isPower =>
      action == GiftAction.powerFifty ||
          action == GiftAction.powerReveal ||
          action == GiftAction.powerNext;

  bool get isSuper => action == GiftAction.superUniverse;

  int? get answerIndex {
    switch (action) {
      case GiftAction.answerA:
        return 0;
      case GiftAction.answerB:
        return 1;
      case GiftAction.answerC:
        return 2;
      case GiftAction.answerD:
        return 3;
      default:
        return null;
    }
  }
}

class GiftRegistry {
  static const List<Gift> all = [
    Gift(name: 'Rose', emoji: '🌹', coins: 1, action: GiftAction.answerA),
    Gift(name: 'Finger Heart', emoji: '🫰', coins: 5, action: GiftAction.answerB),
    Gift(name: 'Hand Hearts', emoji: '🫶', coins: 10, action: GiftAction.answerC),
    Gift(name: 'Diamond', emoji: '💎', coins: 100, action: GiftAction.answerD),

    Gift(name: 'Ice Cream', emoji: '🍦', coins: 1, action: GiftAction.powerFifty),
    Gift(name: 'GG', emoji: '🎮', coins: 1, action: GiftAction.powerReveal),
    Gift(name: 'Donut', emoji: '🍩', coins: 30, action: GiftAction.powerNext),

    Gift(name: 'Universe', emoji: '🌌', coins: 34999, action: GiftAction.superUniverse),
  ];

  static Gift? byName(String name) {
    for (final gift in all) {
      if (gift.name.toLowerCase() == name.toLowerCase()) return gift;
    }
    return null;
  }

  static Gift? byAction(GiftAction action) {
    for (final gift in all) {
      if (gift.action == action) return gift;
    }
    return null;
  }

  static List<Gift> get answerGifts =>
      all.where((g) => g.isAnswer).toList();

  static List<Gift> get powerGifts =>
      all.where((g) => g.isPower).toList();

  static List<Gift> get superGifts =>
      all.where((g) => g.isSuper).toList();
}
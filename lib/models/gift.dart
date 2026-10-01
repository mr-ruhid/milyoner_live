enum GiftAction {
  answerA,
  answerB,
  answerC,
  answerD,
  powerFifty,
  powerNext,
  powerNextPlusPoint,
  superUniverse,
}

class Gift {
  final String name;
  final String assetPath;
  final int coins;
  final GiftAction action;

  const Gift({
    required this.name,
    required this.assetPath,
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
          action == GiftAction.powerNext ||
          action == GiftAction.powerNextPlusPoint;

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
    Gift(
      name: 'Rose',
      assetPath: 'assets/gifts/rose.png',
      coins: 1,
      action: GiftAction.answerA,
    ),
    Gift(
      name: 'TikTok',
      assetPath: 'assets/gifts/tiktok.png',
      coins: 1,
      action: GiftAction.answerB,
    ),
    Gift(
      name: 'GG',
      assetPath: 'assets/gifts/gg.webp',
      coins: 1,
      action: GiftAction.answerC,
    ),
    Gift(
      name: 'Love',
      assetPath: 'assets/gifts/love.webp',
      coins: 1,
      action: GiftAction.answerD,
    ),
    Gift(
      name: 'Rosa',
      assetPath: 'assets/gifts/rosa.webp',
      coins: 10,
      action: GiftAction.powerFifty,
    ),
    Gift(
      name: 'Star',
      assetPath: 'assets/gifts/star.webp',
      coins: 1,
      action: GiftAction.powerNext,
    ),
    Gift(
      name: 'Airdrop',
      assetPath: 'assets/gifts/airdrop.webp',
      coins: 10,
      action: GiftAction.powerNextPlusPoint,
    ),
    Gift(
      name: 'Universe',
      assetPath: 'assets/gifts/universe.png',
      coins: 34999,
      action: GiftAction.superUniverse,
    ),
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
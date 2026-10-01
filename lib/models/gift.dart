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
  final List<int> ids;

  const Gift({
    required this.name,
    required this.assetPath,
    required this.coins,
    required this.action,
    required this.ids,
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
      ids: [5655, 10602, 13035],
    ),
    Gift(
      name: 'TikTok',
      assetPath: 'assets/gifts/tiktok.png',
      coins: 1,
      action: GiftAction.answerB,
      ids: [5269, 8286, 6064],
    ),
    Gift(
      name: 'GG',
      assetPath: 'assets/gifts/gg.webp',
      coins: 1,
      action: GiftAction.answerC,
      ids: [15231, 13506, 7932, 6890],
    ),
    Gift(
      name: 'Love',
      assetPath: 'assets/gifts/love.webp',
      coins: 1,
      action: GiftAction.answerD,
      ids: [8913, 7997, 8912, 8914],
    ),
    Gift(
      name: 'Rosa',
      assetPath: 'assets/gifts/rosa.webp',
      coins: 999,
      action: GiftAction.powerFifty,
      ids: [14453, 6245, 10382, 5753, 9717],
    ),
    Gift(
      name: 'Star',
      assetPath: 'assets/gifts/star.webp',
      coins: 1,
      action: GiftAction.powerNext,
      ids: [6432],
    ),
    Gift(
      name: 'Airdrop',
      assetPath: 'assets/gifts/airdrop.webp',
      coins: 10,
      action: GiftAction.powerNextPlusPoint,
      ids: [],
    ),
    Gift(
      name: 'Universe',
      assetPath: 'assets/gifts/universe.png',
      coins: 34999,
      action: GiftAction.superUniverse,
      ids: [9072, 9101, 7531, 7603, 6038, 6039, 6041, 7312, 7310],
    ),
  ];

  static Gift? byId(int id) {
    for (final gift in all) {
      if (gift.ids.contains(id)) return gift;
    }
    return null;
  }

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

  static List<Gift> get answerGifts => all.where((g) => g.isAnswer).toList();
  static List<Gift> get powerGifts => all.where((g) => g.isPower).toList();
  static List<Gift> get superGifts => all.where((g) => g.isSuper).toList();
}
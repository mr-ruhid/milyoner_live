import 'dart:async';
import 'package:flutter/material.dart';
import 'package:piratetok_live/piratetok_live.dart';
import '../models/gift.dart';

enum LiveStatus { disconnected, connecting, connected, error }

class GiftEvent {
  final String username;
  final String? nickname;
  final String? avatarUrl;
  final Gift gift;
  final int repeatCount;
  final int totalCoins;

  GiftEvent({
    required this.username,
    this.nickname,
    this.avatarUrl,
    required this.gift,
    this.repeatCount = 1,
    required this.totalCoins,
  });

  String get displayName =>
      (nickname != null && nickname!.isNotEmpty) ? nickname! : username;
}

class LiveService extends ChangeNotifier {
  TikTokLiveClient? _client;

  LiveStatus _status = LiveStatus.disconnected;
  String? _roomId;
  String? _lastError;
  bool _manualDisconnect = false;

  Function(GiftEvent event)? onGift;
  Function(String langCode)? onLanguageCommand;
  Function(LiveStatus status)? onStatusChanged;

  LiveStatus get status => _status;
  String? get roomId => _roomId;
  String? get lastError => _lastError;
  bool get isConnected => _status == LiveStatus.connected;

  Future<void> connect(String tiktokUsername) async {
    if (_status == LiveStatus.connecting || _status == LiveStatus.connected) {
      return;
    }

    _manualDisconnect = false;
    _roomId = tiktokUsername;
    _lastError = null;
    _setStatus(LiveStatus.connecting);

    try {
      _client = TikTokLiveClient(tiktokUsername)
          .maxRetries(10)
          .timeout(const Duration(seconds: 20))
          .staleTimeout(const Duration(seconds: 90));

      _client!.on(EventType.gift, _handleGift);
      _client!.on(EventType.chat, _handleChat);

      await _client!.connect();

      if (_manualDisconnect) {
        _client?.disconnect();
        return;
      }

      _setStatus(LiveStatus.connected);
    } catch (e) {
      _lastError = e.toString();
      _setStatus(LiveStatus.error);
      debugPrint('LiveService connect error: $e');
    }
  }

  void _handleGift(dynamic evt) {
    try {
      final data = evt.data as Map<String, dynamic>?;
      if (data == null) return;

      final giftMap = data['gift'] as Map<String, dynamic>?;
      if (giftMap == null) return;

      final giftName = giftMap['name'] as String?;
      if (giftName == null) return;

      final gift = GiftRegistry.byName(giftName);
      if (gift == null) return;

      final user = data['user'] as Map<String, dynamic>?;
      final repeat = (data['repeatCount'] as num?)?.toInt() ?? 1;

      final event = GiftEvent(
        username: user?['uniqueId'] as String? ?? 'unknown',
        nickname: user?['nickname'] as String?,
        avatarUrl: user?['avatarUrl'] as String?,
        gift: gift,
        repeatCount: repeat,
        totalCoins: gift.coins * repeat,
      );

      onGift?.call(event);
    } catch (e) {
      debugPrint('LiveService gift parse error: $e');
    }
  }

  void _handleChat(dynamic evt) {
    try {
      final data = evt.data as Map<String, dynamic>?;
      if (data == null) return;

      final content = data['content'] as String?;
      if (content == null || content.isEmpty) return;

      final cmd = content.trim().toLowerCase();
      if (!cmd.startsWith('/')) return;

      const langs = ['az', 'en', 'ru', 'tr'];
      final langCode = cmd.substring(1);
      if (langs.contains(langCode)) {
        onLanguageCommand?.call(langCode);
      }
    } catch (e) {
      debugPrint('LiveService chat parse error: $e');
    }
  }

  void _setStatus(LiveStatus s) {
    _status = s;
    onStatusChanged?.call(s);
    notifyListeners();
  }

  Future<void> disconnect() async {
    _manualDisconnect = true;
    _client?.disconnect();
    _client = null;
    _roomId = null;
    _setStatus(LiveStatus.disconnected);
  }

  @override
  void dispose() {
    _manualDisconnect = true;
    _client?.disconnect();
    _client = null;
    super.dispose();
  }
}
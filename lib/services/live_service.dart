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
  final int giftId;
  final int repeatCount;
  final int totalCoins;

  GiftEvent({
    required this.username,
    this.nickname,
    this.avatarUrl,
    required this.gift,
    required this.giftId,
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

    final cleanUsername = tiktokUsername
        .trim()
        .replaceFirst(RegExp(r'^@'), '')
        .replaceAll(RegExp(r'\s+'), '');

    if (cleanUsername.isEmpty) {
      _lastError = 'Username is empty';
      _setStatus(LiveStatus.error);
      return;
    }

    _manualDisconnect = false;
    _roomId = cleanUsername;
    _lastError = null;
    _setStatus(LiveStatus.connecting);

    try {
      final onlineResult = await checkOnline(
        cleanUsername,
        timeout: const Duration(seconds: 15),
      );

      final roomId = onlineResult.roomId;
      debugPrint('LiveService roomId: $roomId');

      if (roomId == null || roomId.isEmpty) {
        throw Exception('User is not live right now');
      }

      if (_manualDisconnect) {
        _setStatus(LiveStatus.disconnected);
        return;
      }

      _client = TikTokLiveClient(cleanUsername)
          .maxRetries(10)
          .timeout(const Duration(seconds: 20))
          .staleTimeout(const Duration(seconds: 90));

      _client!.on(EventType.gift, _handleGift);
      _client!.on(EventType.chat, _handleChat);

      await _client!.connect();

      if (_manualDisconnect) {
        _client?.disconnect();
        _setStatus(LiveStatus.disconnected);
        return;
      }

      _setStatus(LiveStatus.connected);
    } catch (e) {
      _lastError = _friendlyError(e);
      _setStatus(LiveStatus.error);
      debugPrint('LiveService connect error: $e');
    }
  }

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('HostNotOnline') ||
        msg.contains('not live') ||
        msg.contains('offline')) {
      return 'User is not live on TikTok right now';
    }
    if (msg.contains('DeviceBlocked') || msg.contains('DEVICE_BLOCKED')) {
      return 'Access blocked by TikTok. Try again later';
    }
    if (msg.contains('NotFound') || msg.contains('404')) {
      return 'TikTok user not found';
    }
    if (msg.contains('timeout') || msg.contains('Timeout')) {
      return 'Connection timed out. Check your network';
    }
    return msg;
  }

  void _handleGift(dynamic evt) {
    try {
      final data = evt.data as Map<String, dynamic>?;
      if (data == null) return;

      final giftMap = data['gift'] as Map<String, dynamic>?;
      if (giftMap == null) return;

      final rawId = giftMap['id'];
      final giftId = (rawId is int) ? rawId : int.tryParse('$rawId');
      if (giftId == null) return;

      final gift = GiftRegistry.byId(giftId);
      if (gift == null) {
        debugPrint('Unknown gift id: $giftId (${giftMap['name']})');
        return;
      }

      final user = data['user'] as Map<String, dynamic>?;
      final repeat = (data['repeatCount'] as num?)?.toInt() ?? 1;

      final event = GiftEvent(
        username: user?['uniqueId'] as String? ?? 'unknown',
        nickname: user?['nickname'] as String?,
        avatarUrl: user?['avatarUrl'] as String?,
        gift: gift,
        giftId: giftId,
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
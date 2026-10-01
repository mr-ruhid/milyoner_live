import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
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
  WebSocketChannel? _channel;
  StreamSubscription? _sub;
  Timer? _reconnectTimer;

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

  Future<void> connect(String tiktokUsername, {String baseUrl = 'ws://localhost:8080'}) async {
    if (_status == LiveStatus.connecting || _status == LiveStatus.connected) return;

    _manualDisconnect = false;
    _roomId = tiktokUsername;
    _lastError = null;
    _setStatus(LiveStatus.connecting);

    try {
      final uri = Uri.parse('$baseUrl/ws?user=$tiktokUsername');
      _channel = WebSocketChannel.connect(uri);
      await _channel!.ready;

      _sub = _channel!.stream.listen(
        _handleRaw,
        onDone: _handleDone,
        onError: _handleError,
        cancelOnError: true,
      );

      _setStatus(LiveStatus.connected);
    } catch (e) {
      _lastError = e.toString();
      _setStatus(LiveStatus.error);
      _scheduleReconnect(baseUrl);
    }
  }

  void _handleRaw(dynamic raw) {
    try {
      final data = json.decode(raw as String) as Map<String, dynamic>;
      final type = data['type'] as String?;

      if (type == 'gift') {
        _handleGift(data);
      } else if (type == 'command') {
        _handleCommand(data);
      }
    } catch (e) {
      debugPrint('LiveService parse error: $e');
    }
  }

  void _handleGift(Map<String, dynamic> data) {
    final giftName = data['giftName'] as String?;
    if (giftName == null) return;

    final gift = GiftRegistry.byName(giftName);
    if (gift == null) return;

    final repeat = (data['repeatCount'] as num?)?.toInt() ?? 1;
    final coins = gift.coins * repeat;

    final event = GiftEvent(
      username: data['username'] as String? ?? 'unknown',
      nickname: data['nickname'] as String?,
      avatarUrl: data['avatarUrl'] as String?,
      gift: gift,
      repeatCount: repeat,
      totalCoins: coins,
    );

    onGift?.call(event);
  }

  void _handleCommand(Map<String, dynamic> data) {
    final cmd = (data['cmd'] as String?)?.toLowerCase();
    if (cmd == null) return;

    const langs = ['az', 'en', 'ru', 'tr'];
    if (langs.contains(cmd)) {
      onLanguageCommand?.call(cmd);
    }
  }

  void _handleDone() {
    _setStatus(LiveStatus.disconnected);
    if (!_manualDisconnect) _scheduleReconnect('ws://localhost:8080');
  }

  void _handleError(dynamic error) {
    _lastError = error.toString();
    _setStatus(LiveStatus.error);
  }

  void _scheduleReconnect(String baseUrl) {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      if (_manualDisconnect || _roomId == null) return;
      connect(_roomId!, baseUrl: baseUrl);
    });
  }

  void _setStatus(LiveStatus s) {
    _status = s;
    onStatusChanged?.call(s);
    notifyListeners();
  }

  Future<void> disconnect() async {
    _manualDisconnect = true;
    _reconnectTimer?.cancel();
    await _sub?.cancel();
    await _channel?.sink.close();
    _channel = null;
    _sub = null;
    _roomId = null;
    _setStatus(LiveStatus.disconnected);
  }

  @override
  void dispose() {
    _manualDisconnect = true;
    _reconnectTimer?.cancel();
    _sub?.cancel();
    _channel?.sink.close();
    super.dispose();
  }
}
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class SoundService extends ChangeNotifier {
  final AudioPlayer _bgPlayer = AudioPlayer();
  final AudioPlayer _fxPlayer = AudioPlayer();

  bool _enabled = true;
  bool _mainPlaying = false;

  bool get enabled => _enabled;

  static const String _main = 'sound/main.mp3';
  static const String _questions = 'sound/questions.mp3';
  static const String _result = 'sound/result.mp3';
  static const String _winner = 'sound/winner.mp3';

  SoundService() {
    _bgPlayer.setReleaseMode(ReleaseMode.loop);
    _fxPlayer.setReleaseMode(ReleaseMode.release);
  }

  void setEnabled(bool value) {
    _enabled = value;
    if (!value) {
      _bgPlayer.pause();
      _fxPlayer.stop();
    } else {
      _playMain();
    }
    notifyListeners();
  }

  Future<void> _playMain() async {
    if (!_enabled) return;
    try {
      await _bgPlayer.stop();
      await _bgPlayer.setVolume(0.5);
      await _bgPlayer.play(AssetSource(_main));
      _mainPlaying = true;
    } catch (e) {
      debugPrint('SoundService main error: $e');
    }
  }

  Future<void> startHomeMusic() async {
    if (!_enabled || _mainPlaying) return;
    await _playMain();
  }

  Future<void> startQuestion() async {
    if (!_enabled) return;
    try {
      await _fxPlayer.stop();
      await _fxPlayer.setVolume(0.8);
      await _fxPlayer.play(AssetSource(_questions));

      await _bgPlayer.setVolume(0.15);
    } catch (e) {
      debugPrint('SoundService question error: $e');
    }
  }

  Future<void> stopQuestion() async {
    try {
      await _fxPlayer.stop();
      await _bgPlayer.setVolume(0.5);
    } catch (e) {
      debugPrint('SoundService stopQuestion error: $e');
    }
  }

  Future<void> playResult() async {
    if (!_enabled) return;
    try {
      await _fxPlayer.stop();
      await _fxPlayer.setVolume(0.8);
      await _fxPlayer.play(AssetSource(_result));
      await _bgPlayer.setVolume(0.5);
    } catch (e) {
      debugPrint('SoundService result error: $e');
    }
  }

  Future<void> startWinners() async {
    if (!_enabled) return;
    try {
      await _fxPlayer.stop();
      await _bgPlayer.stop();
      _mainPlaying = false;

      await _bgPlayer.setVolume(0.7);
      await _bgPlayer.play(AssetSource(_winner));
      _mainPlaying = true;
    } catch (e) {
      debugPrint('SoundService winners error: $e');
    }
  }

  Future<void> stopWinners() async {
    if (!_enabled) return;
    await _playMain();
  }

  Future<void> pauseAll() async {
    await _bgPlayer.pause();
    await _fxPlayer.stop();
  }

  Future<void> resumeAll() async {
    if (!_enabled) return;
    await _bgPlayer.resume();
  }

  @override
  void dispose() {
    _bgPlayer.dispose();
    _fxPlayer.dispose();
    super.dispose();
  }
}
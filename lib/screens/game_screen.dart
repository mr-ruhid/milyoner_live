import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/question.dart';
import '../models/voter_info.dart';
import '../models/player_stats.dart';
import '../models/gift.dart';
import '../services/question_service.dart';
import '../services/locale_service.dart';
import '../services/live_service.dart';
import '../services/sound_service.dart';
import 'question_form_screen.dart';
import 'result_screen.dart';
import 'winners_screen.dart';

const Color _kBorder = Color(0xFFD9D4C3);
const LinearGradient _kFill = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [Color(0xFF0B45A8), Color(0xFF041A52)],
);
const LinearGradient _kBackground = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [Color(0xFF061340), Color(0xFF0A1A5C), Color(0xFF1A0F5E)],
);

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  List<Question> _questions = [];
  int _currentIndex = 0;
  int _timeLeft = 30;
  Timer? _timer;
  Timer? _autoNextTimer;
  Timer? _tickerTimer;
  Timer? _highlightTimer;

  bool _isVotingActive = false;
  bool _showResult = false;
  bool _gameEnding = false;
  bool _pendingGameEnd = false;

  Map<String, int> _votes = {'A': 0, 'B': 0, 'C': 0, 'D': 0};
  Map<String, List<VoterInfo>> _voters = {'A': [], 'B': [], 'C': [], 'D': []};
  Map<String, int> _voterAnswers = {};

  List<int> _hiddenOptions = [];
  bool _fiftyFiftyUsed = false;

  int _topVotedIndex = -1;
  bool _topVotedWasCorrect = false;

  final Map<String, PlayerStats> _stats = {};
  LiveService? _live;
  SoundService? _sound;

  GiftEvent? _lastGift;
  GiftAction? _highlightedAction;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _attachLive();
      _loadQuestions();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _autoNextTimer?.cancel();
    _tickerTimer?.cancel();
    _highlightTimer?.cancel();
    _live?.onGift = null;
    _live?.onLanguageCommand = null;
    _sound?.stopQuestion();
    super.dispose();
  }

  void _attachLive() {
    _live = context.read<LiveService>();
    _sound = context.read<SoundService>();
    _live!.onGift = _handleGift;
    _live!.onLanguageCommand = _handleLanguage;
  }

  void _handleLanguage(String code) {
    if (!mounted) return;
    context.read<LocaleService>().loadLanguage(code);
  }

  void _handleGift(GiftEvent event) {
    if (!mounted) return;

    _ensurePlayer(event);
    _showTicker(event);
    _highlightGift(event.gift.action);

    if (event.gift.isSuper) {
      _markUniverse(event.username);
      if (_showResult) {
        _pendingGameEnd = true;
      } else {
        _endGame();
      }
      return;
    }

    if (!_isVotingActive) return;

    if (event.gift.isAnswer) {
      _onAnswerGift(event);
    } else if (event.gift.action == GiftAction.powerFifty) {
      _useFiftyFifty();
    } else if (event.gift.action == GiftAction.powerNext) {
      _nextQuestion();
    } else if (event.gift.action == GiftAction.powerNextPlusPoint) {
      _addBonus(event.username);
      _nextQuestion();
    }
  }

  void _showTicker(GiftEvent event) {
    _tickerTimer?.cancel();
    setState(() => _lastGift = event);
    _tickerTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted) return;
      setState(() => _lastGift = null);
    });
  }

  void _highlightGift(GiftAction action) {
    _highlightTimer?.cancel();
    setState(() => _highlightedAction = action);
    _highlightTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() => _highlightedAction = null);
    });
  }

  void _onAnswerGift(GiftEvent event) {
    final idx = event.gift.answerIndex;
    if (idx == null) return;
    if (_hiddenOptions.contains(idx)) return;

    final letter = 'ABCD'[idx];
    final username = event.username;
    final isFirstVote = !_voterAnswers.containsKey(username);

    setState(() {
      _votes[letter] = (_votes[letter] ?? 0) + event.totalCoins;
      if (isFirstVote) {
        _voterAnswers[username] = idx;
        _voters[letter]!.add(VoterInfo(
          username: event.displayName,
          avatarUrl: event.avatarUrl,
        ));
      }
    });
  }

  void _ensurePlayer(GiftEvent event) {
    final key = event.username;
    final existing = _stats[key];
    if (existing == null) {
      _stats[key] = PlayerStats(
        username: event.displayName,
        avatarUrl: event.avatarUrl,
        correctCount: 0,
        totalAnswered: 0,
        totalCoins: event.totalCoins,
      );
    } else {
      _stats[key] = existing.copyWith(
        avatarUrl: event.avatarUrl ?? existing.avatarUrl,
        totalCoins: existing.totalCoins + event.totalCoins,
      );
    }
  }

  void _addBonus(String username) {
    final s = _stats[username];
    if (s == null) return;
    _stats[username] = s.copyWith(bonusPoints: s.bonusPoints + 1);
  }

  void _markUniverse(String username) {
    final s = _stats[username];
    if (s == null) return;
    _stats[username] = s.copyWith(sentUniverse: true);
  }

  void _loadQuestions() {
    final service = context.read<QuestionService>();
    _questions = List.from(service.questions);
    if (!mounted) return;
    setState(() {});
    if (_questions.isNotEmpty) _startRound();
  }

  Question? get _currentQuestion =>
      _currentIndex < _questions.length ? _questions[_currentIndex] : null;

  void _startRound() {
    _timer?.cancel();
    _autoNextTimer?.cancel();
    setState(() {
      _timeLeft = 30;
      _isVotingActive = true;
      _showResult = false;
      _votes = {'A': 0, 'B': 0, 'C': 0, 'D': 0};
      _voters = {'A': [], 'B': [], 'C': [], 'D': []};
      _voterAnswers = {};
      _hiddenOptions = [];
      _fiftyFiftyUsed = false;
      _topVotedIndex = -1;
      _topVotedWasCorrect = false;
    });

    _sound?.startQuestion();

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _timeLeft--);
      if (_timeLeft <= 0) {
        t.cancel();
        _revealResult();
      }
    });
  }

  Future<void> _revealResult() async {
    _timer?.cancel();
    _sound?.stopQuestion();
    _sound?.playResult();

    final question = _currentQuestion;
    if (question == null) return;

    final letters = ['A', 'B', 'C', 'D'];
    int topIdx = -1;
    int topCoins = -1;
    for (int i = 0; i < 4; i++) {
      final c = _votes[letters[i]] ?? 0;
      if (c > topCoins) {
        topCoins = c;
        topIdx = i;
      }
    }

    final totalCoins = _votes.values.fold<int>(0, (a, b) => a + b);
    final correctIdx = question.correct;

    for (final entry in _voterAnswers.entries) {
      final s = _stats[entry.key];
      if (s == null) continue;
      final isCorrect = entry.value == correctIdx;
      _stats[entry.key] = s.copyWith(
        correctCount: s.correctCount + (isCorrect ? 1 : 0),
        totalAnswered: s.totalAnswered + 1,
      );
    }

    setState(() {
      _isVotingActive = false;
      _showResult = true;
      _topVotedIndex = topCoins > 0 ? topIdx : -1;
      _topVotedWasCorrect = _topVotedIndex == correctIdx && topCoins > 0;
    });

    if (totalCoins == 0) {
      _autoNextTimer = Timer(const Duration(seconds: 3), () {
        if (!mounted) return;
        if (_pendingGameEnd) {
          _pendingGameEnd = false;
          _endGame();
        } else {
          _advance();
        }
      });
      return;
    }

    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    if (_pendingGameEnd) {
      _pendingGameEnd = false;
      _endGame();
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResultScreen(
          question: question,
          votes: Map.from(_votes),
          voters: Map.from(_voters),
          topVotedWasCorrect: _topVotedWasCorrect,
          topVotedIndex: _topVotedIndex,
        ),
      ),
    );

    if (!mounted) return;

    if (_pendingGameEnd) {
      _pendingGameEnd = false;
      _endGame();
    } else if (!_gameEnding) {
      _advance();
    }
  }

  void _advance() {
    _autoNextTimer?.cancel();
    if (_currentIndex + 1 >= _questions.length) {
      _endGame();
    } else {
      _currentIndex++;
      _startRound();
    }
  }

  void _nextQuestion() {
    if (_gameEnding) return;
    _timer?.cancel();
    _autoNextTimer?.cancel();
    _advance();
  }

  Future<void> _endGame() async {
    if (_gameEnding) return;
    _gameEnding = true;
    _timer?.cancel();
    _autoNextTimer?.cancel();
    _sound?.stopQuestion();

    final players = _stats.values.toList();

    _sound?.startWinners();

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WinnersScreen(players: players),
      ),
    );

    if (!mounted) return;
    _sound?.stopWinners();

    _stats.clear();
    _currentIndex = 0;
    _gameEnding = false;
    _startRound();
  }

  void _useFiftyFifty() {
    if (_fiftyFiftyUsed || _currentQuestion == null || !_isVotingActive) return;
    final correct = _currentQuestion!.correct;
    final wrong = [0, 1, 2, 3].where((i) => i != correct).toList()..shuffle();
    setState(() {
      _fiftyFiftyUsed = true;
      _hiddenOptions = wrong.take(2).toList();
    });
  }

  void _openAddQuestion() async {
    final service = context.read<QuestionService>();
    final locale = context.read<LocaleService>();
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const QuestionFormScreen()),
    );
    await service.loadQuestions(locale.currentLang);
    if (!mounted) return;
    _loadQuestions();
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleService>();
    final service = context.watch<QuestionService>();

    if (_questions.isEmpty) return _buildEmptyState(locale, service);

    final options = _currentQuestion?.options ?? [];
    final letters = ['A', 'B', 'C', 'D'];
    final totalCoins = _votes.values.fold<int>(0, (a, b) => a + b);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: _kBackground),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              children: [
                _buildTopBar(locale),
                const SizedBox(height: 10),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 7,
                        child: _buildGameArea(
                          locale,
                          options,
                          letters,
                          totalCoins,
                        ),
                      ),
                      const SizedBox(width: 14),
                      SizedBox(
                        width: 260,
                        child: _buildGiftPanel(locale),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGameArea(
      LocaleService locale,
      List<String> options,
      List<String> letters,
      int totalCoins,
      ) {
    return Column(
      children: [
        SizedBox(
          height: 120,
          child: SvgPicture.asset('assets/logo/logo.svg'),
        ),
        const SizedBox(height: 6),
        _buildLanguageHint(locale),
        const SizedBox(height: 12),
        _buildQuestionPanel(),
        const SizedBox(height: 12),
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: _buildAnswer(
                        letter: letters[0],
                        text: options.isNotEmpty ? options[0] : '',
                        index: 0,
                        totalCoins: totalCoins,
                        leftExtend: 24,
                        rightExtend: 8,
                      ),
                    ),
                    Expanded(
                      child: _buildAnswer(
                        letter: letters[1],
                        text: options.length > 1 ? options[1] : '',
                        index: 1,
                        totalCoins: totalCoins,
                        leftExtend: 8,
                        rightExtend: 24,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: _buildAnswer(
                        letter: letters[2],
                        text: options.length > 2 ? options[2] : '',
                        index: 2,
                        totalCoins: totalCoins,
                        leftExtend: 24,
                        rightExtend: 8,
                      ),
                    ),
                    Expanded(
                      child: _buildAnswer(
                        letter: letters[3],
                        text: options.length > 3 ? options[3] : '',
                        index: 3,
                        totalCoins: totalCoins,
                        leftExtend: 8,
                        rightExtend: 24,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildEndGameButton(locale),
      ],
    );
  }

  Widget _buildTopBar(LocaleService locale) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: _kFill,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _kBorder, width: 1.5),
          ),
          child: Text(
            '${_currentIndex + 1}/${_questions.length}',
            style: GoogleFonts.orbitron(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.gold,
            ),
          ),
        ),
        const SizedBox(width: 10),
        _buildLiveBadge(),
        const SizedBox(width: 10),
        Expanded(child: _buildTicker(locale)),
        const SizedBox(width: 10),
        if (_showResult)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: (_topVotedWasCorrect
                  ? AppColors.correct
                  : AppColors.wrong)
                  .withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _topVotedWasCorrect
                    ? AppColors.correct
                    : AppColors.wrong,
              ),
            ),
            child: Text(
              _topVotedWasCorrect ? locale.t('correct') : locale.t('wrong'),
              style: GoogleFonts.orbitron(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: _topVotedWasCorrect
                    ? AppColors.correct
                    : AppColors.wrong,
              ),
            ),
          ),
        const SizedBox(width: 10),
        _buildTimer(),
      ],
    );
  }

  Widget _buildLiveBadge() {
    final live = context.watch<LiveService>();
    final connected = live.isConnected;
    final color = connected ? AppColors.correct : AppColors.wrong;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(color: color, blurRadius: 6, spreadRadius: 1),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            connected ? 'LIVE' : 'OFF',
            style: GoogleFonts.orbitron(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicker(LocaleService locale) {
    final gift = _lastGift;
    final show = gift != null;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: show ? 1.0 : 0.5,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          gradient: show
              ? const LinearGradient(
            colors: [Color(0xFF1F7A4A), Color(0xFF0E3A24)],
          )
              : _kFill,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: show ? AppColors.correct : _kBorder.withOpacity(0.5),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            if (show) ...[
              SizedBox(
                width: 22,
                height: 22,
                child: Image.asset(
                  gift.gift.assetPath,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.card_giftcard,
                    color: AppColors.gold,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  '${gift.displayName} ${locale.t('just_sent')} ${gift.gift.name}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ] else
              Text(
                locale.t('waiting_gifts'),
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.white54,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimer() {
    final isLow = _timeLeft <= 10;
    final color = isLow ? AppColors.wrong : _kBorder;
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: _kFill,
        border: Border.all(color: color, width: 2),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.4), blurRadius: 12),
        ],
      ),
      child: Center(
        child: Text(
          '$_timeLeft',
          style: GoogleFonts.orbitron(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionPanel() {
    return _hexPanel(
      height: 70,
      leftExtend: 24,
      rightExtend: 24,
      borderColor: _kBorder,
      gradient: _kFill,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Text(
            _currentQuestion?.question ?? '',
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.white,
              height: 1.3,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnswer({
    required String letter,
    required String text,
    required int index,
    required int totalCoins,
    required double leftExtend,
    required double rightExtend,
  }) {
    final hidden = _hiddenOptions.contains(index);
    final isCorrect = _showResult && _currentQuestion?.correct == index;
    final isTopWrong =
        _showResult && !_topVotedWasCorrect && _topVotedIndex == index;

    final coins = _votes[letter] ?? 0;
    final double percent =
    totalCoins == 0 ? 0.0 : (coins / totalCoins * 100);
    final showPercent = totalCoins > 0;

    Color borderColor = _kBorder;
    Gradient fill = _kFill;

    if (_showResult && isCorrect) {
      borderColor = AppColors.correct;
      fill = AppColors.hexPanelCorrect;
    } else if (_showResult && isTopWrong) {
      borderColor = AppColors.wrong;
      fill = AppColors.hexPanelWrong;
    }

    final dimOthers = _showResult && !isCorrect && !isTopWrong;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 400),
      opacity: hidden ? 0.15 : (dimOthers ? 0.35 : 1.0),
      child: _hexPanel(
        borderColor: borderColor,
        gradient: fill,
        leftExtend: leftExtend,
        rightExtend: rightExtend,
        child: Stack(
          children: [
            if (showPercent)
              Positioned.fill(
                child: ClipPath(
                  clipper: _HexClipper(),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: AnimatedFractionallySizedBox(
                      duration: const Duration(milliseconds: 500),
                      widthFactor: (percent / 100).clamp(0.0, 1.0),
                      heightFactor: 1.0,
                      alignment: Alignment.centerLeft,
                      child: Container(
                        color: borderColor.withOpacity(0.22),
                      ),
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Center(
                    child: Text(
                      text,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _showResult && (isCorrect || isTopWrong)
                            ? borderColor
                            : Colors.transparent,
                        border: Border.all(color: borderColor, width: 1.5),
                      ),
                      child: Center(
                        child: Text(
                          letter,
                          style: GoogleFonts.orbitron(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: _showResult && (isCorrect || isTopWrong)
                                ? AppColors.background
                                : AppColors.gold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (showPercent)
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${percent.toStringAsFixed(0)}%',
                        style: GoogleFonts.orbitron(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: borderColor,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGiftPanel(LocaleService locale) {
    return Container(
      decoration: BoxDecoration(
        gradient: _kFill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: _kBorder, width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.card_giftcard,
                  color: AppColors.gold,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  locale.t('send_to_vote'),
                  style: GoogleFonts.orbitron(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: AppColors.gold,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                ...GiftRegistry.all.map(
                      (g) => _buildGiftRow(g),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGiftRow(Gift gift) {
    final isHighlighted = _highlightedAction == gift.action;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isHighlighted
            ? AppColors.correct.withOpacity(0.25)
            : Colors.black.withOpacity(0.25),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isHighlighted ? AppColors.correct : _kBorder.withOpacity(0.3),
          width: isHighlighted ? 2 : 1,
        ),
        boxShadow: isHighlighted
            ? [
          BoxShadow(
            color: AppColors.correct.withOpacity(0.5),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ]
            : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 26,
            height: 26,
            child: Image.asset(
              gift.assetPath,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.card_giftcard,
                color: AppColors.gold,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              gift.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 6),
          _buildGiftActionLabel(gift),
        ],
      ),
    );
  }

  Widget _buildGiftActionLabel(Gift gift) {
    String text;
    Color color;

    switch (gift.action) {
      case GiftAction.answerA:
        text = 'A';
        color = AppColors.optionA;
        break;
      case GiftAction.answerB:
        text = 'B';
        color = AppColors.optionB;
        break;
      case GiftAction.answerC:
        text = 'C';
        color = AppColors.optionC;
        break;
      case GiftAction.answerD:
        text = 'D';
        color = AppColors.optionD;
        break;
      case GiftAction.powerFifty:
        text = '50/50';
        color = AppColors.gold;
        break;
      case GiftAction.powerNext:
        text = 'NEXT';
        color = AppColors.optionB;
        break;
      case GiftAction.powerNextPlusPoint:
        text = '+1';
        color = AppColors.gold;
        break;
      case GiftAction.superUniverse:
        text = 'WIN';
        color = AppColors.wrong;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        text,
        style: GoogleFonts.orbitron(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildEndGameButton(LocaleService locale) {
    return GestureDetector(
      onTap: _gameEnding ? null : _endGame,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: _gameEnding ? 0.35 : 1.0,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: _kFill,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: AppColors.wrong, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.wrong.withOpacity(0.3),
                blurRadius: 12,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.stop_circle_outlined,
                color: AppColors.wrong,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                locale.t('end_game'),
                style: GoogleFonts.orbitron(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hexPanel({
    required Widget child,
    required Gradient gradient,
    required Color borderColor,
    required double leftExtend,
    required double rightExtend,
    double? height,
    double borderWidth = 2.0,
  }) {
    final hex = Stack(
      children: [
        Positioned.fill(
          child: ClipPath(
            clipper: _HexClipper(),
            child: Container(color: borderColor),
          ),
        ),
        Positioned.fill(
          child: Padding(
            padding: EdgeInsets.all(borderWidth),
            child: ClipPath(
              clipper: _HexClipper(),
              child: Container(
                decoration: BoxDecoration(gradient: gradient),
                child: child,
              ),
            ),
          ),
        ),
      ],
    );

    final content = Stack(
      children: [
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          bottom: 0,
          child: Center(
            child: Container(height: borderWidth, color: borderColor),
          ),
        ),
        Positioned.fill(
          child: Padding(
            padding: EdgeInsets.only(left: leftExtend, right: rightExtend),
            child: hex,
          ),
        ),
      ],
    );

    if (height != null) {
      return SizedBox(height: height, child: content);
    }
    return content;
  }

  Widget _buildLanguageHint(LocaleService locale) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      decoration: BoxDecoration(
        gradient: _kFill,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kBorder.withOpacity(0.6), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.chat_bubble_outline,
            color: AppColors.gold,
            size: 12,
          ),
          const SizedBox(width: 6),
          Text(
            locale.t('chat_language_hint'),
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(LocaleService locale, QuestionService service) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: _kBackground),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      _buildCircleButton(
                        icon: Icons.arrow_back,
                        onTap: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    gradient: _kFill,
                    shape: BoxShape.circle,
                    border: Border.all(color: _kBorder, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.quiz_outlined,
                    size: 64,
                    color: AppColors.gold,
                  ),
                ),
                const SizedBox(height: 28),
                if (service.usedFallback)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.gold.withOpacity(0.6),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: AppColors.gold,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Showing English questions - no ${locale.currentLang.toUpperCase()} file yet',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: AppColors.gold,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Text(
                  locale.t('no_questions'),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.orbitron(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Add questions for ${locale.currentLang.toUpperCase()} to start playing',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.white60,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                GestureDetector(
                  onTap: _openAddQuestion,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.gold, AppColors.goldDark],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: _kBorder, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.gold.withOpacity(0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.add_circle_outline,
                          color: Color(0xFF041A52),
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          locale.t('add_question'),
                          style: GoogleFonts.orbitron(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF041A52),
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          gradient: _kFill,
          shape: BoxShape.circle,
          border: Border.all(color: _kBorder, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(icon, color: AppColors.gold, size: 20),
      ),
    );
  }
}

class _HexClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final p = size.height * 0.45;
    return Path()
      ..moveTo(p, 0)
      ..lineTo(size.width - p, 0)
      ..lineTo(size.width, size.height / 2)
      ..lineTo(size.width - p, size.height)
      ..lineTo(p, size.height)
      ..lineTo(0, size.height / 2)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
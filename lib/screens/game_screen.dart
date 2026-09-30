import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/question.dart';
import '../services/question_service.dart';
import '../services/locale_service.dart';

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
  bool _isVotingActive = false;
  bool _showResult = false;
  Map<String, int> _votes = {'A': 0, 'B': 0, 'C': 0, 'D': 0};
  List<int> _hiddenOptions = [];
  bool _fiftyFiftyUsed = false;
  bool _revealUsed = false;
  int _topVotedIndex = -1;
  bool _topVotedWasCorrect = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadQuestions());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _autoNextTimer?.cancel();
    super.dispose();
  }

  void _loadQuestions() {
    final service = context.read<QuestionService>();
    _questions = List.from(service.questions);
    if (mounted) {
      setState(() {});
      if (_questions.isNotEmpty) {
        _startRound();
      }
    }
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
      _hiddenOptions = [];
      _fiftyFiftyUsed = false;
      _revealUsed = false;
      _topVotedIndex = -1;
      _topVotedWasCorrect = false;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _timeLeft--);
      if (_timeLeft <= 0) {
        t.cancel();
        _revealResult();
      }
    });
  }

  void _revealResult() {
    _timer?.cancel();

    final letters = ['A', 'B', 'C', 'D'];
    int topIdx = -1;
    int topCount = -1;
    for (int i = 0; i < 4; i++) {
      final c = _votes[letters[i]] ?? 0;
      if (c > topCount) {
        topCount = c;
        topIdx = i;
      }
    }

    setState(() {
      _isVotingActive = false;
      _showResult = true;
      _topVotedIndex = topCount > 0 ? topIdx : -1;
      _topVotedWasCorrect =
          _topVotedIndex == _currentQuestion?.correct && topCount > 0;
    });

    _autoNextTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) _nextQuestion();
    });
  }

  void _nextQuestion() {
    _autoNextTimer?.cancel();
    if (_currentIndex + 1 >= _questions.length) {
      _currentIndex = 0;
    } else {
      _currentIndex++;
    }
    _startRound();
  }

  void _addVote(String letter) {
    if (!_isVotingActive) return;
    final index = 'ABCD'.indexOf(letter);
    if (_hiddenOptions.contains(index)) return;
    setState(() {
      _votes[letter] = (_votes[letter] ?? 0) + 1;
    });
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

  void _useReveal() {
    if (_revealUsed || _currentQuestion == null || !_isVotingActive) return;
    setState(() => _revealUsed = true);
    _revealResult();
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleService>();

    if (_questions.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Text(
            locale.t('add_question'),
            style: GoogleFonts.poppins(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.3),
            radius: 1.4,
            colors: [
              Color(0xFF0F1B4C),
              Color(0xFF060920),
              Color(0xFF000000),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildHeader(locale),
                const SizedBox(height: 12),
                _buildQuestionPanel(),
                const SizedBox(height: 12),
                Expanded(child: _buildAnswers(locale)),
                const SizedBox(height: 10),
                _buildBottomBar(locale),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(LocaleService locale) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.panelBlue.withOpacity(0.6),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.gold.withOpacity(0.5)),
          ),
          child: Text(
            '${_currentIndex + 1}/${_questions.length}',
            style: GoogleFonts.orbitron(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.gold,
            ),
          ),
        ),
        const Spacer(),
        if (_showResult)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: _topVotedWasCorrect
                  ? AppColors.correct.withOpacity(0.2)
                  : AppColors.wrong.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _topVotedWasCorrect
                    ? AppColors.correct
                    : AppColors.wrong,
              ),
            ),
            child: Text(
              _topVotedWasCorrect
                  ? locale.t('correct')
                  : locale.t('wrong'),
              style: GoogleFonts.orbitron(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: _topVotedWasCorrect
                    ? AppColors.correct
                    : AppColors.wrong,
              ),
            ),
          ),
        const SizedBox(width: 12),
        _buildTimer(),
      ],
    );
  }

  Widget _buildTimer() {
    final isLow = _timeLeft <= 10;
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: isLow
              ? [AppColors.wrong, AppColors.wrong.withOpacity(0.6)]
              : [AppColors.panelBlue, AppColors.panelDark],
        ),
        border: Border.all(
          color: isLow ? AppColors.wrong : AppColors.gold,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: (isLow ? AppColors.wrong : AppColors.gold)
                .withOpacity(0.4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Center(
        child: Text(
          '$_timeLeft',
          style: GoogleFonts.orbitron(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF152A6B), Color(0xFF0A1A4A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(
          color: AppColors.gold.withOpacity(0.8),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Text(
        _currentQuestion?.question ?? '',
        textAlign: TextAlign.center,
        style: GoogleFonts.poppins(
          fontSize: 19,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildAnswers(LocaleService locale) {
    final options = _currentQuestion?.options ?? [];
    final letters = ['A', 'B', 'C', 'D'];
    final totalVotes = _votes.values.fold<int>(0, (a, b) => a + b);

    return Column(
      children: List.generate(4, (i) {
        final letter = letters[i];
        final hidden = _hiddenOptions.contains(i);
        final isCorrect =
            _showResult && _currentQuestion?.correct == i;
        final isTopWrong = _showResult &&
            !_topVotedWasCorrect &&
            _topVotedIndex == i;

        final voteCount = _votes[letter] ?? 0;
        final percent =
        totalVotes == 0 ? 0 : (voteCount / totalVotes * 100);

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: GestureDetector(
              onTap: hidden ? null : () => _addVote(letter),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 400),
                opacity: hidden
                    ? 0.15
                    : (_showResult && !isCorrect && !isTopWrong)
                    ? 0.35
                    : 1.0,
                child: _buildAnswerButton(
                  letter: letter,
                  text: i < options.length ? options[i] : '',
                  isCorrect: isCorrect,
                  isTopWrong: isTopWrong,
                  percent: percent,
                  showPercent: totalVotes > 0,
                  showResult: _showResult,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildAnswerButton({
    required String letter,
    required String text,
    required bool isCorrect,
    required bool isTopWrong,
    required double percent,
    required bool showPercent,
    required bool showResult,
  }) {
    Color borderColor = AppColors.gold.withOpacity(0.6);
    Color fillTop = const Color(0xFF1E2A5A);
    Color fillBottom = const Color(0xFF0F1B3D);

    if (showResult && isCorrect) {
      borderColor = AppColors.correct;
      fillTop = AppColors.correct.withOpacity(0.35);
      fillBottom = AppColors.correct.withOpacity(0.15);
    } else if (showResult && isTopWrong) {
      borderColor = AppColors.wrong;
      fillTop = AppColors.wrong.withOpacity(0.35);
      fillBottom = AppColors.wrong.withOpacity(0.15);
    }

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [fillTop, fillBottom],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: borderColor, width: 2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(40),
            child: Stack(
              children: [
                if (showPercent)
                  Positioned.fill(
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: (percent / 100).clamp(0.0, 1.0),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              borderColor.withOpacity(0.25),
                              borderColor.withOpacity(0.05),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: showResult && (isCorrect || isTopWrong)
                              ? borderColor
                              : AppColors.background.withOpacity(0.6),
                          border: Border.all(
                            color: borderColor,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            letter,
                            style: GoogleFonts.orbitron(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: showResult && (isCorrect || isTopWrong)
                                  ? AppColors.background
                                  : AppColors.gold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          text,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (showPercent)
                        Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Text(
                            '${percent.toStringAsFixed(0)}%',
                            style: GoogleFonts.orbitron(
                              fontSize: 14,
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
        ),
      ],
    );
  }

  Widget _buildBottomBar(LocaleService locale) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            icon: Icons.content_cut,
            label: locale.t('fifty_fifty'),
            enabled: _isVotingActive && !_fiftyFiftyUsed,
            onTap: _useFiftyFifty,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildActionButton(
            icon: Icons.visibility,
            label: locale.t('reveal'),
            enabled: _isVotingActive && !_revealUsed,
            onTap: _useReveal,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildActionButton(
            icon: Icons.skip_next,
            label: locale.t('next'),
            enabled: true,
            onTap: _nextQuestion,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: enabled ? 1.0 : 0.35,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.panelDark.withOpacity(0.7),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: enabled
                  ? AppColors.gold.withOpacity(0.8)
                  : AppColors.panelBlue,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: enabled ? AppColors.gold : AppColors.textSecondary,
                size: 16,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: enabled
                        ? AppColors.gold
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
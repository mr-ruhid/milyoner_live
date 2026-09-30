import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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

    final options = _currentQuestion?.options ?? [];
    final letters = ['A', 'B', 'C', 'D'];
    final totalVotes = _votes.values.fold<int>(0, (a, b) => a + b);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.2),
            radius: 1.4,
            colors: [
              Color(0xFF1E3A8A),
              Color(0xFF0A1440),
              Color(0xFF000000),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              children: [
                _buildTopBar(locale),
                const SizedBox(height: 12),
                _buildLogo(),
                const SizedBox(height: 20),
                _buildQuestionPanel(),
                const SizedBox(height: 20),
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
                                totalVotes: totalVotes,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: _buildAnswer(
                                letter: letters[1],
                                text: options.length > 1 ? options[1] : '',
                                index: 1,
                                totalVotes: totalVotes,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildAnswer(
                                letter: letters[2],
                                text: options.length > 2 ? options[2] : '',
                                index: 2,
                                totalVotes: totalVotes,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: _buildAnswer(
                                letter: letters[3],
                                text: options.length > 3 ? options[3] : '',
                                index: 3,
                                totalVotes: totalVotes,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _buildBottomBar(locale),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(LocaleService locale) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.gold.withOpacity(0.6)),
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
        const Spacer(),
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

  Widget _buildTimer() {
    final isLow = _timeLeft <= 10;
    final color = isLow ? AppColors.wrong : AppColors.gold;
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withOpacity(0.5),
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
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return SizedBox(
      height: 90,
      child: SvgPicture.asset('assets/logo/logo.svg'),
    );
  }

  Widget _buildQuestionPanel() {
    return _hexPanel(
      height: 78,
      borderColor: Colors.white.withOpacity(0.9),
      fillColors: const [Color(0xFF1E40AF), Color(0xFF0F2166)],
      child: Center(
        child: Text(
          _currentQuestion?.question ?? '',
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
            height: 1.3,
          ),
        ),
      ),
    );
  }

  Widget _buildAnswer({
    required String letter,
    required String text,
    required int index,
    required int totalVotes,
  }) {
    final hidden = _hiddenOptions.contains(index);
    final isCorrect = _showResult && _currentQuestion?.correct == index;
    final isTopWrong = _showResult &&
        !_topVotedWasCorrect &&
        _topVotedIndex == index;

    final voteCount = _votes[letter] ?? 0;
    final double percent =
    totalVotes == 0 ? 0.0 : (voteCount / totalVotes * 100);
    final showPercent = totalVotes > 0;

    Color borderColor = Colors.white.withOpacity(0.85);
    List<Color> fill = const [Color(0xFF1E40AF), Color(0xFF0F2166)];

    if (_showResult && isCorrect) {
      borderColor = AppColors.correct;
      fill = [
        AppColors.correct.withOpacity(0.55),
        AppColors.correct.withOpacity(0.25),
      ];
    } else if (_showResult && isTopWrong) {
      borderColor = AppColors.wrong;
      fill = [
        AppColors.wrong.withOpacity(0.55),
        AppColors.wrong.withOpacity(0.25),
      ];
    }

    final dimOthers = _showResult && !isCorrect && !isTopWrong;

    return GestureDetector(
      onTap: hidden ? null : () => _addVote(letter),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 400),
        opacity: hidden ? 0.15 : (dimOthers ? 0.35 : 1.0),
        child: _hexPanel(
          borderColor: borderColor,
          fillColors: fill,
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
                          color: borderColor.withOpacity(0.18),
                        ),
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
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
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color:
                            _showResult && (isCorrect || isTopWrong)
                                ? AppColors.background
                                : AppColors.gold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (showPercent)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
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
      ),
    );
  }

  Widget _hexPanel({
    required Widget child,
    required List<Color> fillColors,
    required Color borderColor,
    double? height,
    double borderWidth = 2.0,
  }) {
    final content = Stack(
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
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: fillColors,
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: child,
              ),
            ),
          ),
        ),
      ],
    );

    if (height != null) {
      return SizedBox(height: height, child: content);
    }
    return content;
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
            color: Colors.black.withOpacity(0.4),
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
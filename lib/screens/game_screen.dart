import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/question.dart';
import '../services/question_service.dart';
import '../services/locale_service.dart';
import 'question_form_screen.dart';

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

  void _openAddQuestion() async {
    final service = context.read<QuestionService>();
    final locale = context.read<LocaleService>();
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const QuestionFormScreen()),
    );
    await service.loadQuestions(locale.currentLang);
    if (!mounted) return;
    setState(() {});
    _loadQuestions();
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleService>();
    final service = context.watch<QuestionService>();

    if (_questions.isEmpty) {
      return _buildEmptyState(locale, service);
    }

    final options = _currentQuestion?.options ?? [];
    final letters = ['A', 'B', 'C', 'D'];
    final totalVotes = _votes.values.fold<int>(0, (a, b) => a + b);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: _kBackground),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _buildTopBar(locale),
                ),
                const SizedBox(height: 8),
                _buildLogo(),
                const SizedBox(height: 8),
                _buildLanguageHint(locale),
                const SizedBox(height: 16),
                _buildQuestionPanel(),
                const SizedBox(height: 14),
                SizedBox(
                  height: 160,
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
                                leftExtend: 24,
                                rightExtend: 8,
                              ),
                            ),
                            Expanded(
                              child: _buildAnswer(
                                letter: letters[1],
                                text: options.length > 1 ? options[1] : '',
                                index: 1,
                                totalVotes: totalVotes,
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
                                totalVotes: totalVotes,
                                leftExtend: 24,
                                rightExtend: 8,
                              ),
                            ),
                            Expanded(
                              child: _buildAnswer(
                                letter: letters[3],
                                text: options.length > 3 ? options[3] : '',
                                index: 3,
                                totalVotes: totalVotes,
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
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _buildBottomBar(locale),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
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
                  'No questions yet',
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
                      gradient: LinearGradient(
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

  Widget _buildLogo() {
    return SizedBox(
      height: 180,
      child: SvgPicture.asset('assets/logo/logo.svg'),
    );
  }

  Widget _buildQuestionPanel() {
    return _hexPanel(
      height: 74,
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
    required int totalVotes,
    required double leftExtend,
    required double rightExtend,
  }) {
    final hidden = _hiddenOptions.contains(index);
    final isCorrect = _showResult && _currentQuestion?.correct == index;
    final isTopWrong =
        _showResult && !_topVotedWasCorrect && _topVotedIndex == index;

    final voteCount = _votes[letter] ?? 0;
    final double percent =
    totalVotes == 0 ? 0.0 : (voteCount / totalVotes * 100);
    final showPercent = totalVotes > 0;

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

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: hidden ? null : () => _addVote(letter),
      child: AnimatedOpacity(
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
        const SizedBox(width: 10),
        Expanded(
          child: _buildActionButton(
            icon: Icons.visibility,
            label: locale.t('reveal'),
            enabled: _isVotingActive && !_revealUsed,
            onTap: _useReveal,
          ),
        ),
        const SizedBox(width: 10),
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
            gradient: _kFill,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: _kBorder, width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: enabled ? AppColors.gold : Colors.white54,
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
                    color: enabled ? Colors.white : Colors.white54,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageHint(LocaleService locale) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        gradient: _kFill,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kBorder.withOpacity(0.6), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            color: AppColors.gold,
            size: 13,
          ),
          const SizedBox(width: 8),
          Text(
            locale.t('chat_language_hint'),
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),
        ],
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
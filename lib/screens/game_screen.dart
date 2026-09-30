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
  bool _isVotingActive = false;
  bool _showResult = false;
  Map<String, int> _votes = {'A': 0, 'B': 0, 'C': 0, 'D': 0};
  List<int> _hiddenOptions = [];
  bool _fiftyFiftyUsed = false;
  bool _revealUsed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadQuestions());
  }

  @override
  void dispose() {
    _timer?.cancel();
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
    setState(() {
      _timeLeft = 30;
      _isVotingActive = true;
      _showResult = false;
      _votes = {'A': 0, 'B': 0, 'C': 0, 'D': 0};
      _hiddenOptions = [];
      _fiftyFiftyUsed = false;
      _revealUsed = false;
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
    setState(() {
      _isVotingActive = false;
      _showResult = true;
    });
  }

  void _nextQuestion() {
    if (_currentIndex + 1 >= _questions.length) {
      _currentIndex = 0;
    } else {
      _currentIndex++;
    }
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                locale.t('add_question'),
                style: GoogleFonts.poppins(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                ),
                child: Text(
                  locale.t('cancel'),
                  style: GoogleFonts.poppins(color: AppColors.background),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildHeader(locale),
              const SizedBox(height: 16),
              _buildQuestionPanel(locale),
              const SizedBox(height: 16),
              Expanded(child: _buildAnswers()),
              const SizedBox(height: 12),
              _buildBottomBar(locale),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(LocaleService locale) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          locale.t('app_title'),
          style: GoogleFonts.orbitron(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.gold,
            letterSpacing: 3,
          ),
        ),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: AppColors.panelBlue,
                borderRadius: BorderRadius.circular(10),
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
            const SizedBox(width: 10),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: _timeLeft <= 10
                    ? AppColors.wrong
                    : AppColors.panelBlue,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.gold, width: 2),
              ),
              child: Center(
                child: Text(
                  '$_timeLeft',
                  style: GoogleFonts.orbitron(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuestionPanel(LocaleService locale) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.panelBlue, AppColors.panelDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.gold, width: 2),
      ),
      child: Column(
        children: [
          Text(
            '${locale.t('reward')}: ${_currentQuestion?.reward ?? 0}',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.gold,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _currentQuestion?.question ?? '',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswers() {
    final options = _currentQuestion?.options ?? [];
    final letters = ['A', 'B', 'C', 'D'];
    final colors = [
      AppColors.optionA,
      AppColors.optionB,
      AppColors.optionC,
      AppColors.optionD,
    ];
    final totalVotes = _votes.values.fold<int>(0, (a, b) => a + b);

    return Column(
      children: List.generate(4, (i) {
        final hidden = _hiddenOptions.contains(i);
        final isCorrect =
            _showResult && _currentQuestion?.correct == i;

        Color baseColor = colors[i];
        if (_showResult && isCorrect) baseColor = AppColors.correct;

        final voteCount = _votes[letters[i]] ?? 0;
        final percent =
        totalVotes == 0 ? 0 : (voteCount / totalVotes * 100);

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: hidden ? 0.15 : 1.0,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      baseColor.withOpacity(0.9),
                      baseColor.withOpacity(0.6),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.gold.withOpacity(0.5),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.background.withOpacity(0.4),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.gold,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          letters[i],
                          style: GoogleFonts.orbitron(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.gold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        i < options.length ? options[i] : '',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (totalVotes > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.background.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${percent.toStringAsFixed(0)}%',
                          style: GoogleFonts.orbitron(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
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
        opacity: enabled ? 1.0 : 0.4,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.panelDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: enabled ? AppColors.gold : AppColors.panelBlue,
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: enabled
                    ? AppColors.gold
                    : AppColors.textSecondary,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: enabled
                      ? AppColors.gold
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
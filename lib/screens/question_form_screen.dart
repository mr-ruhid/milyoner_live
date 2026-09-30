import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/question.dart';
import '../services/question_service.dart';
import '../services/locale_service.dart';

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

class QuestionFormScreen extends StatefulWidget {
  final Question? question;

  const QuestionFormScreen({super.key, this.question});

  @override
  State<QuestionFormScreen> createState() => _QuestionFormScreenState();
}

class _QuestionFormScreenState extends State<QuestionFormScreen> {
  final Map<String, TextEditingController> _questionControllers = {};
  final Map<String, List<TextEditingController>> _optionControllers = {};
  final List<String> _langs = [];
  String _activeTab = 'en';
  int _correct = 0;
  int _reward = 100;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    final locale = context.read<LocaleService>();
    final langs = locale.languages.map((l) => l['code']!).toList();
    _langs.clear();
    _langs.addAll(langs.isEmpty ? ['en'] : langs);

    for (final code in _langs) {
      _questionControllers[code] = TextEditingController();
      _optionControllers[code] =
          List.generate(4, (_) => TextEditingController());
    }

    if (widget.question != null) {
      final service = context.read<QuestionService>();
      final translations =
      await service.loadQuestionTranslations(widget.question!.id);

      if (translations.isNotEmpty) {
        for (final entry in translations.entries) {
          final code = entry.key;
          final q = entry.value;
          if (!_questionControllers.containsKey(code)) continue;
          _questionControllers[code]!.text = q.question;
          for (int i = 0; i < 4 && i < q.options.length; i++) {
            _optionControllers[code]![i].text = q.options[i];
          }
          _correct = q.correct;
          _reward = q.reward;
        }
      } else {
        final q = widget.question!;
        _questionControllers[locale.currentLang]!.text = q.question;
        for (int i = 0; i < 4 && i < q.options.length; i++) {
          _optionControllers[locale.currentLang]![i].text = q.options[i];
        }
        _correct = q.correct;
        _reward = q.reward;
      }
      _activeTab = _langs.first;
    } else {
      _activeTab = locale.currentLang;
    }

    setState(() => _loading = false);
  }

  @override
  void dispose() {
    for (final c in _questionControllers.values) {
      c.dispose();
    }
    for (final list in _optionControllers.values) {
      for (final c in list) {
        c.dispose();
      }
    }
    super.dispose();
  }

  bool _isLangFilled(String code) {
    final qCtrl = _questionControllers[code];
    final oCtrl = _optionControllers[code];
    if (qCtrl == null || oCtrl == null) return false;
    if (qCtrl.text.trim().isEmpty) return false;
    for (final c in oCtrl) {
      if (c.text.trim().isEmpty) return false;
    }
    return true;
  }

  int get _filledCount =>
      _langs.where(_isLangFilled).length;

  @override
  Widget build(BuildContext context) {
    final locale = context.read<LocaleService>();
    final isEdit = widget.question != null;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: _kBackground),
        child: SafeArea(
          child: _loading
              ? const Center(
            child: CircularProgressIndicator(color: AppColors.gold),
          )
              : Column(
            children: [
              _buildAppBar(context, locale, isEdit),
              _buildProgressBar(),
              _buildLangTabs(locale),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
                  child: _buildForm(locale, _activeTab),
                ),
              ),
              _buildBottomBar(locale),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(
      BuildContext context,
      LocaleService locale,
      bool isEdit,
      ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          _buildCircleButton(
            icon: Icons.arrow_back,
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              isEdit ? locale.t('edit_question') : locale.t('add_question'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.orbitron(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
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

  Widget _buildProgressBar() {
    final total = _langs.length;
    final filled = _filledCount;
    final isComplete = filled == total && total > 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                isComplete ? Icons.check_circle : Icons.info_outline,
                color: isComplete ? AppColors.correct : AppColors.gold,
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                '$filled / $total languages filled',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isComplete ? AppColors.correct : Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : filled / total,
              minHeight: 4,
              backgroundColor: Colors.black.withOpacity(0.4),
              valueColor: AlwaysStoppedAnimation(
                isComplete ? AppColors.correct : AppColors.gold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLangTabs(LocaleService locale) {
    final langs = locale.languages;
    if (langs.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemCount: langs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final lang = langs[i];
          final code = lang['code']!;
          final flag = lang['flag'] ?? '🌐';
          final isActive = _activeTab == code;
          final isFilled = _isLangFilled(code);

          return GestureDetector(
            onTap: () => setState(() => _activeTab = code),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: isActive ? _kFill : null,
                color: isActive ? null : Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive
                      ? AppColors.gold
                      : (isFilled
                      ? AppColors.correct.withOpacity(0.6)
                      : AppColors.wrong.withOpacity(0.6)),
                  width: isActive ? 1.8 : 1.2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(flag, style: const TextStyle(fontSize: 15)),
                  const SizedBox(width: 6),
                  Text(
                    code.toUpperCase(),
                    style: GoogleFonts.orbitron(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: isActive ? AppColors.gold : Colors.white70,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    isFilled ? Icons.check_circle : Icons.error_outline,
                    color: isFilled ? AppColors.correct : AppColors.wrong,
                    size: 13,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildForm(LocaleService locale, String code) {
    final qCtrl = _questionControllers[code];
    final oCtrl = _optionControllers[code];
    if (qCtrl == null || oCtrl == null) return const SizedBox.shrink();

    final langInfo = locale.languages.firstWhere(
          (l) => l['code'] == code,
      orElse: () => {'flag': '🌐', 'name': code},
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _kBorder.withOpacity(0.4)),
          ),
          child: Row(
            children: [
              Text(
                langInfo['flag'] ?? '🌐',
                style: const TextStyle(fontSize: 22),
              ),
              const SizedBox(width: 10),
              Text(
                (langInfo['name'] ?? code).toString().toUpperCase(),
                style: GoogleFonts.orbitron(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: AppColors.gold,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildLabel(locale.t('question_text')),
        const SizedBox(height: 8),
        TextField(
          controller: qCtrl,
          onChanged: (_) => setState(() {}),
          style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
          maxLines: 3,
          decoration: _inputDecoration('...'),
        ),
        const SizedBox(height: 20),
        _buildLabel('Options'),
        const SizedBox(height: 8),
        ...List.generate(4, (i) => _buildOptionField(oCtrl[i], i)),
        const SizedBox(height: 20),
        _buildLabel(locale.t('correct_answer')),
        const SizedBox(height: 8),
        _buildCorrectSelector(),
        const SizedBox(height: 20),
        _buildLabel(locale.t('reward')),
        const SizedBox(height: 8),
        _buildRewardSelector(),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: AppColors.gold,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text.toUpperCase(),
          style: GoogleFonts.orbitron(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(color: Colors.white30, fontSize: 12),
      filled: true,
      fillColor: Colors.black.withOpacity(0.35),
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: _kBorder.withOpacity(0.4),
          width: 1.2,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
      ),
    );
  }

  Widget _buildOptionField(TextEditingController ctrl, int index) {
    final letter = String.fromCharCode(65 + index);
    final isCorrect = _correct == index;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCorrect
                  ? AppColors.correct.withOpacity(0.2)
                  : Colors.transparent,
              border: Border.all(
                color: isCorrect ? AppColors.correct : _kBorder,
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                letter,
                style: GoogleFonts.orbitron(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: isCorrect ? AppColors.correct : AppColors.gold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: ctrl,
              onChanged: (_) => setState(() {}),
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
              decoration: _inputDecoration('$letter option'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorrectSelector() {
    return Row(
      children: List.generate(4, (i) {
        final selected = _correct == i;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _correct = i),
            child: Container(
              margin: EdgeInsets.only(right: i == 3 ? 0 : 8),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: selected
                    ? LinearGradient(
                  colors: [
                    AppColors.correct,
                    AppColors.correct.withOpacity(0.6),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                )
                    : _kFill,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: selected ? AppColors.correct : _kBorder,
                  width: 1.5,
                ),
                boxShadow: selected
                    ? [
                  BoxShadow(
                    color: AppColors.correct.withOpacity(0.4),
                    blurRadius: 12,
                  ),
                ]
                    : null,
              ),
              child: Center(
                child: Text(
                  String.fromCharCode(65 + i),
                  style: GoogleFonts.orbitron(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color:
                    selected ? AppColors.background : AppColors.gold,
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildRewardSelector() {
    return Row(
      children: [100, 200, 500, 1000].asMap().entries.map((entry) {
        final i = entry.key;
        final r = entry.value;
        final selected = _reward == r;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _reward = r),
            child: Container(
              margin: EdgeInsets.only(right: i == 3 ? 0 : 8),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: selected
                    ? LinearGradient(
                  colors: [AppColors.gold, AppColors.goldDark],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                )
                    : _kFill,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: selected ? AppColors.gold : _kBorder,
                  width: 1.5,
                ),
                boxShadow: selected
                    ? [
                  BoxShadow(
                    color: AppColors.gold.withOpacity(0.4),
                    blurRadius: 12,
                  ),
                ]
                    : null,
              ),
              child: Center(
                child: Text(
                  '$r',
                  style: GoogleFonts.orbitron(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: selected ? AppColors.background : Colors.white,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBottomBar(LocaleService locale) {
    final isComplete = _filledCount == _langs.length && _langs.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: GestureDetector(
        onTap: isComplete ? _save : null,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: isComplete ? 1.0 : 0.4,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isComplete
                    ? [AppColors.gold, AppColors.goldDark]
                    : [Colors.grey.shade700, Colors.grey.shade900],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: _kBorder, width: 1.5),
              boxShadow: isComplete
                  ? [
                BoxShadow(
                  color: AppColors.gold.withOpacity(0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isComplete
                      ? Icons.check_circle_outline
                      : Icons.lock_outline,
                  color: isComplete
                      ? const Color(0xFF041A52)
                      : Colors.white54,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Text(
                  locale.t('save'),
                  style: GoogleFonts.orbitron(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: isComplete
                        ? const Color(0xFF041A52)
                        : Colors.white54,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_filledCount != _langs.length) {
      _showError('Fill all languages first');
      return;
    }

    final service = context.read<QuestionService>();
    final id = widget.question?.id ?? service.generateId();

    final Map<String, Question> perLang = {};
    for (final code in _langs) {
      final qCtrl = _questionControllers[code]!;
      final oCtrl = _optionControllers[code]!;
      perLang[code] = Question(
        id: id,
        question: qCtrl.text.trim(),
        options: oCtrl.map((c) => c.text.trim()).toList(),
        correct: _correct,
        reward: _reward,
      );
    }

    await service.saveQuestionForLanguages(id, perLang);

    if (!mounted) return;
    Navigator.pop(context);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.poppins()),
        backgroundColor: AppColors.wrong,
      ),
    );
  }
}
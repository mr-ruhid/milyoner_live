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
  final TextEditingController _questionController = TextEditingController();
  final List<TextEditingController> _optionControllers =
  List.generate(4, (_) => TextEditingController());
  int _correct = 0;
  int _reward = 100;

  @override
  void initState() {
    super.initState();
    if (widget.question != null) {
      final q = widget.question!;
      _questionController.text = q.question;
      for (int i = 0; i < 4 && i < q.options.length; i++) {
        _optionControllers[i].text = q.options[i];
      }
      _correct = q.correct;
      _reward = q.reward;
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    for (final c in _optionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.read<LocaleService>();
    final isEdit = widget.question != null;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: _kBackground),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context, locale, isEdit),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel(locale.t('question_text')),
                      const SizedBox(height: 8),
                      _buildQuestionField(),
                      const SizedBox(height: 20),
                      _buildLabel('Options'),
                      const SizedBox(height: 8),
                      ...List.generate(4, (i) => _buildOptionField(i)),
                      const SizedBox(height: 20),
                      _buildLabel(locale.t('correct_answer')),
                      const SizedBox(height: 8),
                      _buildCorrectSelector(),
                      const SizedBox(height: 20),
                      _buildLabel(locale.t('reward')),
                      const SizedBox(height: 8),
                      _buildRewardSelector(),
                      const SizedBox(height: 30),
                      _buildSaveButton(locale),
                    ],
                  ),
                ),
              ),
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
      hintStyle: GoogleFonts.poppins(
        color: Colors.white30,
        fontSize: 12,
      ),
      filled: true,
      fillColor: Colors.black.withOpacity(0.35),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
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

  Widget _buildQuestionField() {
    return TextField(
      controller: _questionController,
      style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
      maxLines: 3,
      decoration: _inputDecoration('...'),
    );
  }

  Widget _buildOptionField(int index) {
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
              controller: _optionControllers[index],
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
                    color: selected ? AppColors.background : AppColors.gold,
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
                  colors: [
                    AppColors.gold,
                    AppColors.goldDark,
                  ],
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
                    color: selected
                        ? AppColors.background
                        : Colors.white,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSaveButton(LocaleService locale) {
    return GestureDetector(
      onTap: _save,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: Color(0xFF041A52),
              size: 22,
            ),
            const SizedBox(width: 10),
            Text(
              locale.t('save'),
              style: GoogleFonts.orbitron(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF041A52),
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    final service = context.read<QuestionService>();

    final questionText = _questionController.text.trim();
    final options = _optionControllers.map((c) => c.text.trim()).toList();

    if (questionText.isEmpty || options.any((o) => o.isEmpty)) {
      _showError('Fill all fields');
      return;
    }

    if (widget.question == null) {
      final q = Question(
        id: service.generateId(),
        question: questionText,
        options: options,
        correct: _correct,
        reward: _reward,
      );
      service.addQuestion(q);
    } else {
      final q = widget.question!.copyWith(
        question: questionText,
        options: options,
        correct: _correct,
        reward: _reward,
      );
      service.updateQuestion(widget.question!.id, q);
    }

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
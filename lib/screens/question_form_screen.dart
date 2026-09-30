import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/question.dart';
import '../services/question_service.dart';
import '../services/locale_service.dart';

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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.panelDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.gold),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEdit ? locale.t('edit_question') : locale.t('add_question'),
          style: GoogleFonts.orbitron(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.gold,
            letterSpacing: 1.5,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel(locale.t('question_text')),
            const SizedBox(height: 8),
            TextField(
              controller: _questionController,
              style: GoogleFonts.poppins(color: AppColors.textPrimary),
              maxLines: 3,
              decoration: _inputDecoration('...'),
            ),
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
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(
        color: AppColors.textSecondary.withOpacity(0.5),
        fontSize: 12,
      ),
      filled: true,
      fillColor: AppColors.panelDark,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _buildOptionField(int index) {
    final letter = String.fromCharCode(65 + index);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.panelBlue,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                letter,
                style: GoogleFonts.orbitron(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.gold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _optionControllers[index],
              style: GoogleFonts.poppins(color: AppColors.textPrimary),
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
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: selected ? AppColors.correct : AppColors.panelDark,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: selected ? AppColors.correct : AppColors.panelBlue,
                ),
              ),
              child: Center(
                child: Text(
                  String.fromCharCode(65 + i),
                  style: GoogleFonts.orbitron(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: selected
                        ? AppColors.background
                        : AppColors.textPrimary,
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
      children: [100, 200, 500, 1000].map((r) {
        final selected = _reward == r;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _reward = r),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.gold.withOpacity(0.2)
                    : AppColors.panelDark,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: selected ? AppColors.gold : AppColors.panelBlue,
                ),
              ),
              child: Center(
                child: Text(
                  '$r',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: selected
                        ? AppColors.gold
                        : AppColors.textPrimary,
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
          gradient: const LinearGradient(
            colors: [AppColors.gold, AppColors.goldDark],
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: Text(
            locale.t('save'),
            style: GoogleFonts.orbitron(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.background,
              letterSpacing: 2,
            ),
          ),
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
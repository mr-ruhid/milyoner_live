import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/question.dart';
import '../services/question_service.dart';
import '../services/locale_service.dart';
import '../config/theme.dart';

class QuestionFormScreen extends StatefulWidget {
  final Question? question;

  const QuestionFormScreen({super.key, this.question});

  @override
  State<QuestionFormScreen> createState() => _QuestionFormScreenState();
}

class _QuestionFormScreenState extends State<QuestionFormScreen> {
  final Map<String, TextEditingController> _questionControllers = {};
  final Map<String, List<TextEditingController>> _optionControllers = {};
  final Set<String> _activeLangs = {};
  String _primaryLang = 'en';
  int _correct = 0;
  int _reward = 100;

  @override
  void initState() {
    super.initState();

    for (final lang in LocaleService.supportedLanguages) {
      final code = lang['code']!;
      _questionControllers[code] = TextEditingController();
      _optionControllers[code] = List.generate(
        4,
            (_) => TextEditingController(),
      );
    }

    if (widget.question != null) {
      final q = widget.question!;
      _correct = q.correct;
      _reward = q.reward;
      for (final entry in q.translations.entries) {
        final code = entry.key;
        if (!_questionControllers.containsKey(code)) continue;
        _activeLangs.add(code);
        _questionControllers[code]!.text =
            entry.value['question']?.toString() ?? '';
        final opts = List<String>.from(entry.value['options'] ?? []);
        for (int i = 0; i < 4 && i < opts.length; i++) {
          _optionControllers[code]![i].text = opts[i];
        }
      }
    } else {
      _activeLangs.add('en');
    }
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
            _buildLangSelector(),
            const SizedBox(height: 20),
            _buildLangFields(),
            const SizedBox(height: 20),
            _buildCorrectAnswer(),
            const SizedBox(height: 20),
            _buildReward(),
            const SizedBox(height: 30),
            _buildSaveButton(locale),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildLangSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Languages',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: LocaleService.supportedLanguages.map((lang) {
            final code = lang['code']!;
            final active = _activeLangs.contains(code);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (active) {
                    if (_activeLangs.length > 1) {
                      _activeLangs.remove(code);
                      if (_primaryLang == code) {
                        _primaryLang = _activeLangs.first;
                      }
                    }
                  } else {
                    _activeLangs.add(code);
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: active
                      ? AppColors.gold.withOpacity(0.15)
                      : AppColors.panelDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: active ? AppColors.gold : AppColors.panelBlue,
                    width: active ? 2 : 1,
                  ),
                ),
                child: Text(
                  '${lang['flag']} ${lang['name']}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: active ? FontWeight.bold : FontWeight.normal,
                    color: active ? AppColors.gold : AppColors.textSecondary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildLangFields() {
    return Column(
      children: _activeLangs.map((code) {
        final langInfo = LocaleService.supportedLanguages
            .firstWhere((l) => l['code'] == code);
        final isPrimary = _primaryLang == code;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.panelDark,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isPrimary ? AppColors.gold : AppColors.panelBlue,
              width: isPrimary ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '${langInfo['flag']} ${langInfo['name']}',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.gold,
                    ),
                  ),
                  const Spacer(),
                  if (!isPrimary)
                    GestureDetector(
                      onTap: () => setState(() => _primaryLang = code),
                      child: Text(
                        'Set primary',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.gold,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'PRIMARY',
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: AppColors.background,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _questionControllers[code],
                style: GoogleFonts.poppins(color: AppColors.textPrimary),
                maxLines: 2,
                decoration: _inputDecoration('Question'),
              ),
              const SizedBox(height: 10),
              ...List.generate(4, (i) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TextField(
                    controller: _optionControllers[code]![i],
                    style: GoogleFonts.poppins(color: AppColors.textPrimary),
                    decoration: _inputDecoration(
                      '${String.fromCharCode(65 + i)} option',
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      }).toList(),
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
      fillColor: AppColors.background.withOpacity(0.5),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _buildCorrectAnswer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Correct answer',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: List.generate(4, (i) {
            final selected = _correct == i;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _correct = i),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.correct
                        : AppColors.panelDark,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected
                          ? AppColors.correct
                          : AppColors.panelBlue,
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
        ),
      ],
    );
  }

  Widget _buildReward() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reward',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        Row(
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
        ),
      ],
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
    final locale = context.read<LocaleService>();

    final translations = <String, Map<String, dynamic>>{};
    for (final code in _activeLangs) {
      final questionText = _questionControllers[code]!.text.trim();
      final options = _optionControllers[code]!
          .map((c) => c.text.trim())
          .toList();

      if (questionText.isEmpty || options.any((o) => o.isEmpty)) {
        _showError('Fill all fields for ${code.toUpperCase()}');
        return;
      }
      translations[code] = {
        'question': questionText,
        'options': options,
      };
    }

    if (translations.isEmpty) {
      _showError('Select at least one language');
      return;
    }

    if (widget.question == null) {
      final q = Question(
        id: service.generateId(),
        translations: translations,
        correct: _correct,
        reward: _reward,
      );
      service.addQuestion(q);
    } else {
      final q = widget.question!.copyWith(
        translations: translations,
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
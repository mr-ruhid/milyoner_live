import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../services/question_service.dart';
import '../services/locale_service.dart';
import 'question_form_screen.dart';

class ManageQuestionsScreen extends StatefulWidget {
  const ManageQuestionsScreen({super.key});

  @override
  State<ManageQuestionsScreen> createState() => _ManageQuestionsScreenState();
}

class _ManageQuestionsScreenState extends State<ManageQuestionsScreen> {
  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleService>();
    final service = context.watch<QuestionService>();
    final list = service.questions;

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
          locale.t('manage_questions'),
          style: GoogleFonts.orbitron(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.gold,
            letterSpacing: 1.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.restore, color: AppColors.gold),
            tooltip: 'Reset to defaults',
            onPressed: () => _confirmReset(service),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.gold,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const QuestionFormScreen()),
          );
        },
        icon: const Icon(Icons.add, color: AppColors.background),
        label: Text(
          locale.t('add_question'),
          style: GoogleFonts.poppins(
            color: AppColors.background,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: list.isEmpty
          ? _buildEmpty(locale)
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final q = list[index];
          return _buildQuestionCard(q, index, service);
        },
      ),
    );
  }

  Widget _buildEmpty(LocaleService locale) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.quiz_outlined,
            size: 80,
            color: AppColors.textSecondary.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          Text(
            locale.t('add_question'),
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(dynamic q, int index, QuestionService service) {
    final letters = ['A', 'B', 'C', 'D'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.panelDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.panelBlue),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: AppColors.gold,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: GoogleFonts.orbitron(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.background,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  q.question,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: List.generate(4, (i) {
              final isCorrect = i == q.correct;
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isCorrect
                      ? AppColors.correct.withOpacity(0.2)
                      : AppColors.panelBlue.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isCorrect ? AppColors.correct : AppColors.panelBlue,
                  ),
                ),
                child: Text(
                  '${letters[i]}: ${q.options[i]}',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: isCorrect ? FontWeight.bold : FontWeight.normal,
                    color: isCorrect
                        ? AppColors.correct
                        : AppColors.textSecondary,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.panelBlue,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${q.reward}',
                  style: GoogleFonts.orbitron(
                    fontSize: 11,
                    color: AppColors.gold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(
                  Icons.edit,
                  color: AppColors.optionB,
                  size: 20,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => QuestionFormScreen(question: q),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete,
                  color: AppColors.wrong,
                  size: 20,
                ),
                onPressed: () => _confirmDelete(q, service),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDelete(dynamic q, QuestionService service) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.panelDark,
        title: Text(
          'Delete?',
          style: GoogleFonts.poppins(color: AppColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'No',
              style: GoogleFonts.poppins(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              service.deleteQuestion(q.id);
              Navigator.pop(context);
            },
            child: Text(
              'Yes',
              style: GoogleFonts.poppins(color: AppColors.wrong),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmReset(QuestionService service) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.panelDark,
        title: Text(
          'Reset to defaults?',
          style: GoogleFonts.poppins(color: AppColors.textPrimary),
        ),
        content: Text(
          'Your custom questions will be deleted.',
          style: GoogleFonts.poppins(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'No',
              style: GoogleFonts.poppins(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              service.resetToDefaults();
              Navigator.pop(context);
            },
            child: Text(
              'Yes',
              style: GoogleFonts.poppins(color: AppColors.wrong),
            ),
          ),
        ],
      ),
    );
  }
}
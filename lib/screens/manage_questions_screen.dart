import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/question_service.dart';
import '../services/locale_service.dart';
import '../config/theme.dart';
import 'question_form_screen.dart';

class ManageQuestionsScreen extends StatefulWidget {
  const ManageQuestionsScreen({super.key});

  @override
  State<ManageQuestionsScreen> createState() => _ManageQuestionsScreenState();
}

class _ManageQuestionsScreenState extends State<ManageQuestionsScreen> {
  String _filterLang = 'all';

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleService>();
    final service = context.watch<QuestionService>();

    final list = _filterLang == 'all'
        ? service.questions
        : service.questions.where((q) => q.hasLanguage(_filterLang)).toList();

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
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.gold,
            letterSpacing: 2,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.gold,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const QuestionFormScreen(),
            ),
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
      body: Column(
        children: [
          _buildFilterRow(locale),
          Expanded(
            child: list.isEmpty
                ? _buildEmpty(locale)
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              itemBuilder: (context, index) {
                final q = list[index];
                return _buildQuestionCard(q, index, locale, service);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow(LocaleService locale) {
    final langs = [
      {'code': 'all', 'label': 'ALL'},
      ...LocaleService.supportedLanguages
          .map((l) => {'code': l['code']!, 'label': l['code']!.toUpperCase()}),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      color: AppColors.panelDark,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: langs.map((l) {
            final selected = _filterLang == l['code'];
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _filterLang = l['code']!),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.gold
                        : AppColors.panelBlue.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected ? AppColors.gold : AppColors.panelBlue,
                    ),
                  ),
                  child: Text(
                    l['label']!,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: selected
                          ? AppColors.background
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
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

  Widget _buildQuestionCard(
      dynamic q,
      int index,
      LocaleService locale,
      QuestionService service,
      ) {
    final previewLang = _filterLang == 'all' ? 'en' : _filterLang;
    final questionText = q.getQuestion(previewLang);
    final langs = (q.translations as Map).keys.join(', ').toUpperCase();

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
                  questionText,
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.panelBlue,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  langs,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: AppColors.gold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.edit, color: AppColors.optionB, size: 20),
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
                icon: const Icon(Icons.delete, color: AppColors.wrong, size: 20),
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
}
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
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
      body: Container(
        decoration: const BoxDecoration(gradient: _kBackground),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context, locale, service),
              Expanded(
                child: list.isEmpty
                    ? _buildEmpty(locale)
                    : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final q = list[index];
                    return _buildQuestionCard(q, index, service);
                  },
                ),
              ),
            ],
          ),
        ),
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
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(
      BuildContext context,
      LocaleService locale,
      QuestionService service,
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
              locale.t('manage_questions'),
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
          const SizedBox(width: 10),
          _buildCircleButton(
            icon: Icons.restore,
            onTap: () => _confirmReset(service),
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

  Widget _buildEmpty(LocaleService locale) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: _kFill,
              shape: BoxShape.circle,
              border: Border.all(color: _kBorder, width: 2),
            ),
            child: const Icon(
              Icons.quiz_outlined,
              size: 56,
              color: AppColors.gold,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            locale.t('add_question'),
            style: GoogleFonts.orbitron(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.white70,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(dynamic q, int index, QuestionService service) {
    final letters = ['A', 'B', 'C', 'D'];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        gradient: _kFill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.transparent,
                    border: Border.all(color: _kBorder, width: 1.5),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: GoogleFonts.orbitron(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: AppColors.gold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      q.question,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        height: 1.3,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...List.generate(4, (i) {
              final isCorrect = i == q.correct;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isCorrect
                        ? AppColors.correct.withOpacity(0.2)
                        : Colors.black.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isCorrect
                          ? AppColors.correct
                          : _kBorder.withOpacity(0.4),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCorrect
                              ? AppColors.correct
                              : Colors.transparent,
                          border: Border.all(
                            color: isCorrect
                                ? AppColors.correct
                                : _kBorder,
                            width: 1.2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            letters[i],
                            style: GoogleFonts.orbitron(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: isCorrect
                                  ? AppColors.background
                                  : AppColors.gold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          q.options[i],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: isCorrect
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isCorrect
                                ? AppColors.correct
                                : Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 6),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _kBorder.withOpacity(0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.monetization_on_outlined,
                        color: AppColors.gold,
                        size: 13,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${q.reward}',
                        style: GoogleFonts.orbitron(
                          fontSize: 11,
                          color: AppColors.gold,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                _buildSmallAction(
                  icon: Icons.edit,
                  color: AppColors.optionB,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => QuestionFormScreen(question: q),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                _buildSmallAction(
                  icon: Icons.delete,
                  color: AppColors.wrong,
                  onTap: () => _confirmDelete(q, service),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallAction({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withOpacity(0.3),
          border: Border.all(color: color.withOpacity(0.7), width: 1.2),
        ),
        child: Icon(icon, color: color, size: 16),
      ),
    );
  }

  void _confirmDelete(dynamic q, QuestionService service) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF071A52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: _kBorder, width: 1.5),
        ),
        title: Text(
          'Delete?',
          style: GoogleFonts.orbitron(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'No',
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              service.deleteQuestion(q.id);
              Navigator.pop(context);
            },
            child: Text(
              'Yes',
              style: GoogleFonts.poppins(
                color: AppColors.wrong,
                fontWeight: FontWeight.w700,
              ),
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
        backgroundColor: const Color(0xFF071A52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: _kBorder, width: 1.5),
        ),
        title: Text(
          'Reset to defaults?',
          style: GoogleFonts.orbitron(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        content: Text(
          'Your custom questions will be deleted.',
          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'No',
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              service.resetToDefaults();
              Navigator.pop(context);
            },
            child: Text(
              'Yes',
              style: GoogleFonts.poppins(
                color: AppColors.wrong,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
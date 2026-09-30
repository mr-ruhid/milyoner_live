import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../services/locale_service.dart';
import '../services/question_service.dart';
import 'game_screen.dart';
import 'manage_questions_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleService>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [
              Color(0xFF1E2A5A),
              Color(0xFF0A0E27),
              Color(0xFF000000),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const Spacer(flex: 2),
                _buildLogo(locale),
                const Spacer(flex: 2),
                _buildStartButton(context, locale),
                const SizedBox(height: 14),
                _buildManageButton(context, locale),
                const Spacer(flex: 1),
                _buildLanguageBar(context, locale),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(LocaleService locale) {
    return Column(
      children: [
        Container(
          width: 130,
          height: 130,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [AppColors.gold, AppColors.goldDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.gold.withOpacity(0.5),
                blurRadius: 40,
                spreadRadius: 6,
              ),
            ],
          ),
          child: Center(
            child: Text(
              '?',
              style: GoogleFonts.orbitron(
                fontSize: 72,
                fontWeight: FontWeight.bold,
                color: AppColors.background,
              ),
            ),
          ),
        ),
        const SizedBox(height: 28),
        Text(
          locale.t('app_title'),
          style: GoogleFonts.orbitron(
            fontSize: 46,
            fontWeight: FontWeight.bold,
            color: AppColors.gold,
            letterSpacing: 6,
            shadows: [
              Shadow(
                color: AppColors.gold.withOpacity(0.6),
                blurRadius: 20,
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          locale.t('app_subtitle'),
          style: GoogleFonts.orbitron(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondary,
            letterSpacing: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildStartButton(BuildContext context, LocaleService locale) {
    return GestureDetector(
      onTap: () async {
        final service = context.read<QuestionService>();
        await service.loadQuestions(locale.currentLang);
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const GameScreen()),
          );
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.gold, AppColors.goldDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.gold.withOpacity(0.5),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.play_arrow_rounded,
              color: AppColors.background,
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(
              locale.t('start_game'),
              style: GoogleFonts.orbitron(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.background,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManageButton(BuildContext context, LocaleService locale) {
    return GestureDetector(
      onTap: () async {
        final service = context.read<QuestionService>();
        await service.loadQuestions(locale.currentLang);
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ManageQuestionsScreen(),
            ),
          );
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.panelDark.withOpacity(0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.gold.withOpacity(0.6),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.library_add_outlined,
              color: AppColors.gold,
              size: 22,
            ),
            const SizedBox(width: 10),
            Text(
              locale.t('add_question'),
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.gold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageBar(BuildContext context, LocaleService locale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            locale.t('select_language'),
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 2,
            ),
          ),
        ),
        Row(
          children: LocaleService.supportedLanguages.map((lang) {
            final code = lang['code']!;
            final isSelected = locale.currentLang == code;
            return Expanded(
              child: GestureDetector(
                onTap: () => locale.loadLanguage(code),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.gold.withOpacity(0.15)
                        : AppColors.panelDark.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.gold
                          : AppColors.panelBlue,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                      BoxShadow(
                        color: AppColors.gold.withOpacity(0.3),
                        blurRadius: 10,
                      ),
                    ]
                        : [],
                  ),
                  child: Column(
                    children: [
                      Text(
                        lang['flag']!,
                        style: const TextStyle(fontSize: 22),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        code.toUpperCase(),
                        style: GoogleFonts.orbitron(
                          fontSize: 11,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: isSelected
                              ? AppColors.gold
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
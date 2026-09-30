import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../services/locale_service.dart';
import '../services/question_service.dart';
import 'game_screen.dart';
import 'manage_questions_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _showLangPicker = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleService>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF060920),
              Color(0xFF0A0E27),
              Color(0xFF000000),
            ],
          ),
        ),
        child: Stack(
          children: [
            _buildAmbientGlow(),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Column(
                  children: [
                    _buildTopBar(locale),
                    const Spacer(flex: 2),
                    _buildLogo(),
                    const Spacer(flex: 3),
                    _buildPrimaryButton(context, locale),
                    const SizedBox(height: 12),
                    _buildSecondaryRow(context, locale),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmbientGlow() {
    return Positioned(
      top: -120,
      left: -120,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (_, __) {
          return Container(
            width: 340,
            height: 340,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.gold.withOpacity(0.08 * _pulseAnimation.value),
                  Colors.transparent,
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopBar(LocaleService locale) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          _buildLiveBadge(locale),
          const Spacer(),
          _buildLangButton(locale),
        ],
      ),
    );
  }

  Widget _buildLiveBadge(LocaleService locale) {
    return Row(
      children: [
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (_, __) {
            return Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.wrong.withOpacity(_pulseAnimation.value),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.wrong.withOpacity(0.6),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(width: 8),
        Text(
          'LIVE',
          style: GoogleFonts.orbitron(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
            letterSpacing: 3,
          ),
        ),
      ],
    );
  }

  Widget _buildLangButton(LocaleService locale) {
    final current = locale.languages.firstWhere(
          (l) => l['code'] == locale.currentLang,
      orElse: () => {'code': 'en', 'flag': '🇬🇧', 'name': 'English'},
    );

    return GestureDetector(
      onTap: () => setState(() => _showLangPicker = !_showLangPicker),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.panelDark.withOpacity(0.7),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: AppColors.panelBlue,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              current['flag'] ?? '🌐',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(width: 6),
            Text(
              (current['code'] ?? 'en').toUpperCase(),
              style: GoogleFonts.orbitron(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              _showLangPicker
                  ? Icons.keyboard_arrow_up
                  : Icons.keyboard_arrow_down,
              color: AppColors.gold,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (_, __) {
            return Container(
              width: 340,
              height: 340,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.gold.withOpacity(
                      0.3 * _pulseAnimation.value,
                    ),
                    Colors.transparent,
                  ],
                ),
              ),
            );
          },
        ),
        SvgPicture.asset(
          'assets/logo/logo.svg',
          width: 280,
          height: 280,
        ),
      ],
    );
  }

  Widget _buildPrimaryButton(BuildContext context, LocaleService locale) {
    return GestureDetector(
      onTap: () => _startGame(context, locale),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.gold, AppColors.goldDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.gold.withOpacity(0.35),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.play_circle_fill_rounded,
              color: AppColors.background,
              size: 26,
            ),
            const SizedBox(width: 10),
            Text(
              locale.t('start_game'),
              style: GoogleFonts.orbitron(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppColors.background,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecondaryRow(BuildContext context, LocaleService locale) {
    return Row(
      children: [
        Expanded(
          child: _buildOutlineButton(
            icon: Icons.edit_note_rounded,
            label: locale.t('manage_questions'),
            onTap: () => _openManage(context, locale),
          ),
        ),
        const SizedBox(width: 10),
        _buildIconOnlyButton(
          icon: Icons.refresh_rounded,
          onTap: () => _confirmReset(context),
        ),
      ],
    );
  }

  Widget _buildOutlineButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.panelDark.withOpacity(0.5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.panelBlue,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.gold, size: 18),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconOnlyButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.panelDark.withOpacity(0.5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.panelBlue,
            width: 1.2,
          ),
        ),
        child: Icon(icon, color: AppColors.gold, size: 18),
      ),
    );
  }

  void _startGame(BuildContext context, LocaleService locale) async {
    final service = context.read<QuestionService>();
    await service.loadQuestions(locale.currentLang);
    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const GameScreen()),
    );
  }

  void _openManage(BuildContext context, LocaleService locale) async {
    final service = context.read<QuestionService>();
    await service.loadQuestions(locale.currentLang);
    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ManageQuestionsScreen()),
    );
  }

  void _confirmReset(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.panelDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.panelBlue,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 20),
              Icon(
                Icons.restart_alt_rounded,
                color: AppColors.wrong,
                size: 40,
              ),
              const SizedBox(height: 12),
              Text(
                'Reset all questions?',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Your custom questions will be deleted.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(
                            color: AppColors.panelBlue,
                          ),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        context.read<QuestionService>().resetToDefaults();
                        Navigator.pop(context);
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: AppColors.wrong,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Reset',
                        style: GoogleFonts.poppins(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
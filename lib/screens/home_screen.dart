import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../services/locale_service.dart';
import '../services/question_service.dart';
import 'game_screen.dart';
import 'manage_questions_screen.dart';

// Millionaire-style palette
const Color _kBorder = Color(0xFFD9D4C3);
const Color _kBlueTop = Color(0xFF0B45A8);
const Color _kBlueBottom = Color(0xFF041A52);

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
              Color(0xFF061340),
              Color(0xFF0A1A5C),
              Color(0xFF1A0F5E),
            ],
          ),
        ),
        child: Stack(
          children: [
            _buildAmbientGlow(),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    child: _buildTopBar(locale),
                  ),
                  const Spacer(flex: 2),
                  _buildLogo(),
                  const Spacer(flex: 2),
                  _buildPrimaryButton(context, locale),
                  const SizedBox(height: 14),
                  _buildSecondaryRow(context, locale),
                  const SizedBox(height: 40),
                ],
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
                  const Color(0xFF1E5BD6)
                      .withOpacity(0.25 * _pulseAnimation.value),
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
            color: Colors.white70,
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
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_kBlueTop, _kBlueBottom],
          ),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: _kBorder, width: 1.5),
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
                color: Colors.white,
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
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.gold.withOpacity(0.25 * _pulseAnimation.value),
                    Colors.transparent,
                  ],
                ),
              ),
            );
          },
        ),
        SvgPicture.asset(
          'assets/logo/logo.svg',
          width: 260,
          height: 260,
        ),
      ],
    );
  }

  // Wide "question bar" style button, lines run to the screen edges
  Widget _buildPrimaryButton(BuildContext context, LocaleService locale) {
    return _HexButton(
      height: 70,
      leftExtend: 22,
      rightExtend: 22,
      onTap: () => _startGame(context, locale),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.play_circle_fill_rounded,
            color: AppColors.gold,
            size: 28,
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              locale.t('start_game'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.orbitron(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Two "answer" style buttons side by side, joined by a short line
  Widget _buildSecondaryRow(BuildContext context, LocaleService locale) {
    return Row(
      children: [
        Expanded(
          child: _HexButton(
            height: 58,
            leftExtend: 22,
            rightExtend: 8,
            onTap: () => _openManage(context, locale),
            child: _buildButtonContent(
              icon: Icons.edit_note_rounded,
              label: locale.t('manage_questions'),
            ),
          ),
        ),
        Expanded(
          child: _HexButton(
            height: 58,
            leftExtend: 8,
            rightExtend: 22,
            onTap: () => _confirmReset(context),
            child: _buildButtonContent(
              icon: Icons.refresh_rounded,
              label: 'Reset',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildButtonContent({required IconData icon, required String label}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: AppColors.gold, size: 18),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
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
      backgroundColor: const Color(0xFF071A52),
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
                  color: _kBorder,
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
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Your custom questions will be deleted.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.white70,
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
                          side: const BorderSide(color: _kBorder),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
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
                          color: Colors.white,
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

/// Pointed-end (hexagon-like) button with horizontal connector lines,
/// like the answer bars in "Who Wants to Be a Millionaire".
class _HexButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  final double height;
  final double leftExtend;
  final double rightExtend;

  const _HexButton({
    required this.child,
    required this.onTap,
    required this.height,
    required this.leftExtend,
    required this.rightExtend,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        height: height,
        child: CustomPaint(
          painter: _HexPainter(leftExtend, rightExtend),
          child: Padding(
            padding: EdgeInsets.only(
              left: leftExtend + 24,
              right: rightExtend + 24,
            ),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}

class _HexPainter extends CustomPainter {
  final double leftExtend;
  final double rightExtend;

  _HexPainter(this.leftExtend, this.rightExtend);

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    final midY = h / 2;
    final slant = h * 0.42;
    const stroke = 2.0;

    final l = leftExtend;
    final r = size.width - rightExtend;

    final path = Path()
      ..moveTo(l, midY)
      ..lineTo(l + slant, stroke / 2)
      ..lineTo(r - slant, stroke / 2)
      ..lineTo(r, midY)
      ..lineTo(r - slant, h - stroke / 2)
      ..lineTo(l + slant, h - stroke / 2)
      ..close();

    // Soft shadow
    canvas.drawPath(
      path.shift(const Offset(0, 3)),
      Paint()
        ..color = Colors.black.withOpacity(0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Blue gradient fill
    final fill = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [_kBlueTop, _kBlueBottom],
      ).createShader(Rect.fromLTWH(0, 0, size.width, h));
    canvas.drawPath(path, fill);

    // Cream border
    final border = Paint()
      ..color = _kBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, border);

    // Connector lines
    final line = Paint()
      ..color = _kBorder
      ..strokeWidth = stroke;
    if (l > 0) canvas.drawLine(Offset(0, midY), Offset(l, midY), line);
    if (rightExtend > 0) {
      canvas.drawLine(Offset(r, midY), Offset(size.width, midY), line);
    }
  }

  @override
  bool shouldRepaint(covariant _HexPainter old) =>
      old.leftExtend != leftExtend || old.rightExtend != rightExtend;
}
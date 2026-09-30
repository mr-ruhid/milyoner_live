
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedLanguage = 'az';
  bool _isMusicOn = true;
  bool _isSoundOn = true;

  final List<Map<String, String>> _languages = [
    {'code': 'az', 'flag': '🇦🇿', 'name': 'Azərbaycan'},
    {'code': 'en', 'flag': '🇬🇧', 'name': 'English'},
    {'code': 'tr', 'flag': '🇹🇷', 'name': 'Türkçe'},
    {'code': 'ru', 'flag': '🇷🇺', 'name': 'Русский'},
  ];

  @override
  Widget build(BuildContext context) {
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
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              children: [
                const Spacer(flex: 2),

                // Logo və başlıq
                _buildLogo(),

                const Spacer(flex: 1),

                // Dil seçimi
                _buildLanguageSection(),

                const SizedBox(height: 32),

                // Başla düyməsi
                _buildStartButton(),

                const SizedBox(height: 24),

                // Alt hissə - səs/musiqi idarəsi
                _buildBottomControls(),

                const Spacer(flex: 1),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🏆 Logo və başlıq
  Widget _buildLogo() {
    return Column(
      children: [
        // Ulduz effekti ilə loqo dairəsi
        Container(
          width: 140,
          height: 140,
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
                spreadRadius: 8,
              ),
            ],
          ),
          child: Center(
            child: Text(
              '?',
              style: GoogleFonts.orbitron(
                fontSize: 80,
                fontWeight: FontWeight.bold,
                color: AppColors.background,
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),

        // Başlıq
        Text(
          'MILYONER',
          style: GoogleFonts.orbitron(
            fontSize: 52,
            fontWeight: FontWeight.bold,
            color: AppColors.gold,
            letterSpacing: 8,
            shadows: [
              Shadow(
                color: AppColors.gold.withOpacity(0.6),
                blurRadius: 20,
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Alt başlıq
        Text(
          'LIVE',
          style: GoogleFonts.orbitron(
            fontSize: 20,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondary,
            letterSpacing: 12,
          ),
        ),
      ],
    );
  }

  // 🌍 Dil seçimi
  Widget _buildLanguageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'DİL SEÇ / SELECT LANGUAGE',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 2,
            ),
          ),
        ),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: _languages.map((lang) {
            final isSelected = _selectedLanguage == lang['code'];
            return _buildLanguageChip(lang, isSelected);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildLanguageChip(Map<String, String> lang, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedLanguage = lang['code']!;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.gold.withOpacity(0.15)
              : AppColors.panelDark.withOpacity(0.6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.gold : AppColors.panelBlue,
            width: isSelected ? 2 : 1.5,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: AppColors.gold.withOpacity(0.3),
              blurRadius: 12,
            ),
          ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(lang['flag']!, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(
              lang['name']!,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.gold : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ▶️ Başla düyməsi
  Widget _buildStartButton() {
    return GestureDetector(
      onTap: () {
        // Sonra burada GameScreen-ə keçəcəyik
        // Navigator.push(context, MaterialPageRoute(
        //   builder: (_) => const GameScreen(),
        // ));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Oyun başlayır... Dil: $_selectedLanguage',
              style: GoogleFonts.poppins(color: AppColors.textPrimary),
            ),
            backgroundColor: AppColors.panelBlue,
            duration: const Duration(seconds: 2),
          ),
        );
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
              'OYUNA BAŞLA',
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

  // 🎵 Alt idarə düymələri
  Widget _buildBottomControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildIconToggle(
          icon: _isMusicOn ? Icons.music_note : Icons.music_off,
          isOn: _isMusicOn,
          onTap: () => setState(() => _isMusicOn = !_isMusicOn),
        ),
        const SizedBox(width: 24),
        _buildIconToggle(
          icon: _isSoundOn ? Icons.volume_up : Icons.volume_off,
          isOn: _isSoundOn,
          onTap: () => setState(() => _isSoundOn = !_isSoundOn),
        ),
        const SizedBox(width: 24),
        _buildIconToggle(
          icon: Icons.info_outline,
          isOn: false,
          onTap: () {
            // Sonra info dialoqu əlavə edəcəyik
          },
        ),
      ],
    );
  }

  Widget _buildIconToggle({
    required IconData icon,
    required bool isOn,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.panelDark.withOpacity(0.6),
          border: Border.all(
            color: isOn ? AppColors.gold : AppColors.panelBlue,
            width: 1.5,
          ),
        ),
        child: Icon(
          icon,
          color: isOn ? AppColors.gold : AppColors.textSecondary,
          size: 22,
        ),
      ),
    );
  }
}
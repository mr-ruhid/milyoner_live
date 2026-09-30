import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFF0A0E27);
  static const Color panelDark = Color(0xFF151A3A);
  static const Color panelBlue = Color(0xFF1E2A5A);
  static const Color gold = Color(0xFFFFD700);
  static const Color goldDark = Color(0xFFB8860B);
  static const Color correct = Color(0xFF2ECC71);
  static const Color wrong = Color(0xFFE74C3C);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B8D4);
  static const Color optionA = Color(0xFFE74C3C);
  static const Color optionB = Color(0xFF3498DB);
  static const Color optionC = Color(0xFFF39C12);
  static const Color optionD = Color(0xFF2ECC71);

  static const Color gameBgCenter = Color(0xFF2A4CB8);
  static const Color gameBgMid = Color(0xFF0F2166);
  static const Color gameBgEdge = Color(0xFF000000);

  static const Color panelFill = Color(0xFF1A1A3E);
  static const Color panelFillDark = Color(0xFF0D0D28);

  static const Color hexBorder = Color(0xFFFFFFFF);
  static const Color hexBorderDim = Color(0xFFB0B8D4);

  static const Color overlay = Color(0x66000000);
  static const Color overlayStrong = Color(0x99000000);

  static const RadialGradient gameBackground = RadialGradient(
    center: Alignment.center,
    radius: 0.95,
    colors: [
      gameBgCenter,
      gameBgMid,
      gameBgEdge,
    ],
    stops: [0.0, 0.55, 1.0],
  );

  static const LinearGradient hexPanelFill = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF232350),
      Color(0xFF0D0D28),
    ],
  );

  static const LinearGradient hexPanelCorrect = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF1F7A4A),
      Color(0xFF0E3A24),
    ],
  );

  static const LinearGradient hexPanelWrong = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF8B2A2A),
      Color(0xFF3D0F0F),
    ],
  );

  static const LinearGradient goldButton = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [gold, goldDark],
  );
}
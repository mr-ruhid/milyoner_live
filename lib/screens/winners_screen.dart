import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/player_stats.dart';
import '../services/locale_service.dart';
import '../services/sound_service.dart';

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

class WinnersScreen extends StatefulWidget {
  final List<PlayerStats> players;
  final int autoCloseSeconds;

  const WinnersScreen({
    super.key,
    required this.players,
    this.autoCloseSeconds = 20,
  });

  @override
  State<WinnersScreen> createState() => _WinnersScreenState();
}

class _WinnersScreenState extends State<WinnersScreen> {
  int _timeLeft = 20;
  Timer? _timer;
  late List<PlayerStats> _sorted;

  @override
  void initState() {
    super.initState();
    _timeLeft = widget.autoCloseSeconds;
    _sorted = _sortPlayers(widget.players);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<SoundService>().startWinners();
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _timeLeft--);
      if (_timeLeft <= 0) {
        t.cancel();
        if (mounted) Navigator.pop(context);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  List<PlayerStats> _sortPlayers(List<PlayerStats> list) {
    final sorted = List<PlayerStats>.from(list);
    sorted.sort((a, b) {
      if (a.sentUniverse != b.sentUniverse) {
        return a.sentUniverse ? -1 : 1;
      }
      if (a.score != b.score) {
        return b.score.compareTo(a.score);
      }
      return b.totalCoins.compareTo(a.totalCoins);
    });
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleService>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: _kBackground),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              children: [
                _buildTopBar(locale),
                const SizedBox(height: 14),
                _buildTitle(locale),
                const SizedBox(height: 18),
                Expanded(
                  child: _sorted.isEmpty
                      ? _buildEmpty(locale)
                      : _buildLeaderboard(locale),
                ),
                const SizedBox(height: 12),
                _buildBottomBar(locale),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(LocaleService locale) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            gradient: _kFill,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _kBorder, width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.emoji_events,
                color: AppColors.gold,
                size: 15,
              ),
              const SizedBox(width: 7),
              Text(
                locale.t('final_results'),
                style: GoogleFonts.orbitron(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: AppColors.gold,
                  letterSpacing: 1.4,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: _kFill,
            border: Border.all(color: _kBorder, width: 1.5),
          ),
          child: Center(
            child: Text(
              '$_timeLeft',
              style: GoogleFonts.orbitron(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTitle(LocaleService locale) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.gold, AppColors.goldDark],
            ),
            border: Border.all(color: _kBorder, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.gold.withOpacity(0.5),
                blurRadius: 22,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(
            Icons.workspace_premium,
            size: 38,
            color: Color(0xFF041A52),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          locale.t('winners'),
          style: GoogleFonts.orbitron(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 5,
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty(LocaleService locale) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.sentiment_dissatisfied,
            size: 56,
            color: Colors.white24,
          ),
          const SizedBox(height: 14),
          Text(
            locale.t('no_players'),
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white54,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboard(LocaleService locale) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: _sorted.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) => _buildPlayerRow(locale, _sorted[i], i),
    );
  }

  Widget _buildPlayerRow(
      LocaleService locale,
      PlayerStats player,
      int index,
      ) {
    final isFirst = index == 0;
    final isUniverse = player.sentUniverse;
    final rank = index + 1;

    final Color borderColor = isFirst
        ? AppColors.gold
        : (isUniverse ? AppColors.optionC : _kBorder);
    final Gradient fill = isFirst
        ? const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF5C4416), Color(0xFF2A1E08)],
    )
        : _kFill;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: fill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: isFirst ? 2 : 1.5),
        boxShadow: isFirst
            ? [
          BoxShadow(
            color: AppColors.gold.withOpacity(0.4),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ]
            : null,
      ),
      child: Row(
        children: [
          _buildRankBadge(rank, isFirst),
          const SizedBox(width: 12),
          _buildAvatar(player, 42),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        player.username,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (isUniverse) ...[
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.auto_awesome,
                        size: 15,
                        color: AppColors.optionC,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${player.score} / ${player.totalAnswered} ${locale.t('correct_short')}',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (isFirst)
            const Icon(
              Icons.workspace_premium,
              color: AppColors.gold,
              size: 26,
            ),
        ],
      ),
    );
  }

  Widget _buildRankBadge(int rank, bool isFirst) {
    if (isFirst) {
      return Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.gold, AppColors.goldDark],
          ),
          border: Border.all(color: _kBorder, width: 1.5),
        ),
        child: Center(
          child: Text(
            '$rank',
            style: GoogleFonts.orbitron(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF041A52),
            ),
          ),
        ),
      );
    }
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withOpacity(0.35),
        border: Border.all(color: _kBorder.withOpacity(0.7), width: 1.3),
      ),
      child: Center(
        child: Text(
          '$rank',
          style: GoogleFonts.orbitron(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: AppColors.gold,
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(PlayerStats player, double size) {
    if (player.avatarUrl != null && player.avatarUrl!.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          player.avatarUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _initialAvatar(player, size),
        ),
      );
    }
    return _initialAvatar(player, size);
  }

  Widget _initialAvatar(PlayerStats player, double size) {
    final initial = player.username.isNotEmpty
        ? player.username[0].toUpperCase()
        : '?';
    final color = _colorFor(player.username);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(color: _kBorder, width: 1.3),
      ),
      child: Center(
        child: Text(
          initial,
          style: GoogleFonts.orbitron(
            fontSize: size * 0.42,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Color _colorFor(String name) {
    const palette = [
      Color(0xFFE74C3C),
      Color(0xFF3498DB),
      Color(0xFFF39C12),
      Color(0xFF2ECC71),
      Color(0xFF9B59B6),
      Color(0xFF1ABC9C),
      Color(0xFFE91E63),
      Color(0xFF00BCD4),
    ];
    return palette[name.hashCode.abs() % palette.length];
  }

  Widget _buildBottomBar(LocaleService locale) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.gold, AppColors.goldDark],
          ),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: _kBorder, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.gold.withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.replay,
              color: Color(0xFF041A52),
              size: 22,
            ),
            const SizedBox(width: 10),
            Text(
              locale.t('new_game'),
              style: GoogleFonts.orbitron(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF041A52),
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
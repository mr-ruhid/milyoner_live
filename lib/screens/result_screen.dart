import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';
import '../models/question.dart';
import '../models/voter_info.dart';

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

class ResultScreen extends StatefulWidget {
  final Question question;
  final Map<String, int> votes;
  final Map<String, List<VoterInfo>> voters;
  final bool topVotedWasCorrect;
  final int topVotedIndex;
  final int autoAdvanceSeconds;

  const ResultScreen({
    super.key,
    required this.question,
    required this.votes,
    required this.voters,
    required this.topVotedWasCorrect,
    required this.topVotedIndex,
    this.autoAdvanceSeconds = 8,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  int _timeLeft = 8;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timeLeft = widget.autoAdvanceSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _timeLeft--);
      if (_timeLeft <= 0) {
        t.cancel();
        _close();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _close() {
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final letters = ['A', 'B', 'C', 'D'];
    final correctIdx = widget.question.correct;
    final correctLetter = letters[correctIdx];
    final correctText = widget.question.options[correctIdx];
    final correctVoters = widget.voters[correctLetter] ?? [];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: _kBackground),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 16),
                _buildQuestionPanel(),
                const SizedBox(height: 16),
                _buildCorrectAnswer(correctLetter, correctText),
                const SizedBox(height: 22),
                _buildVotersHeader(correctVoters.length),
                const SizedBox(height: 10),
                Expanded(child: _buildVotersList(correctVoters)),
                const SizedBox(height: 12),
                _buildNextButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            gradient: _kFill,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _kBorder, width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.topVotedWasCorrect
                    ? Icons.emoji_events
                    : Icons.cancel_outlined,
                color: widget.topVotedWasCorrect
                    ? AppColors.correct
                    : AppColors.wrong,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                widget.topVotedWasCorrect ? 'CORRECT' : 'WRONG',
                style: GoogleFonts.orbitron(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: widget.topVotedWasCorrect
                      ? AppColors.correct
                      : AppColors.wrong,
                  letterSpacing: 1.5,
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

  Widget _buildQuestionPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        gradient: _kFill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder, width: 1.5),
      ),
      child: Text(
        widget.question.question,
        textAlign: TextAlign.center,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.white,
          height: 1.3,
        ),
      ),
    );
  }

  Widget _buildCorrectAnswer(String letter, String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.correct.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.correct, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.correct.withOpacity(0.3),
            blurRadius: 16,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.correct,
            ),
            child: Center(
              child: Text(
                letter,
                style: GoogleFonts.orbitron(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: AppColors.background,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVotersHeader(int count) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 14,
          decoration: BoxDecoration(
            color: AppColors.gold,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'VOTED FOR THE CORRECT ANSWER',
          style: GoogleFonts.orbitron(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.gold.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.gold.withOpacity(0.6)),
          ),
          child: Text(
            '$count',
            style: GoogleFonts.orbitron(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: AppColors.gold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVotersList(List<VoterInfo> voters) {
    if (voters.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_off_outlined,
              size: 48,
              color: Colors.white24,
            ),
            const SizedBox(height: 12),
            Text(
              'No one voted correctly',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.white54,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: voters.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) => _buildVoterRow(voters[i], i + 1),
    );
  }

  Widget _buildVoterRow(VoterInfo voter, int rank) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: _kFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.correct.withOpacity(0.5),
          width: 1.3,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withOpacity(0.4),
              border: Border.all(
                color: AppColors.gold.withOpacity(0.7),
                width: 1.2,
              ),
            ),
            child: Center(
              child: Text(
                '$rank',
                style: GoogleFonts.orbitron(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: AppColors.gold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          _buildAvatar(voter, 34),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              voter.username,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const Icon(
            Icons.check_circle,
            color: AppColors.correct,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(VoterInfo voter, double size) {
    if (voter.avatarUrl != null && voter.avatarUrl!.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          voter.avatarUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildInitialAvatar(voter, size),
        ),
      );
    }
    return _buildInitialAvatar(voter, size);
  }

  Widget _buildInitialAvatar(VoterInfo voter, double size) {
    final initial =
    voter.username.isNotEmpty ? voter.username[0].toUpperCase() : '?';
    final color = _colorForName(voter.username);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(color: _kBorder, width: 1.2),
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

  Color _colorForName(String name) {
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

  Widget _buildNextButton() {
    return GestureDetector(
      onTap: _close,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.gold, AppColors.goldDark],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
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
              Icons.skip_next,
              color: Color(0xFF041A52),
              size: 22,
            ),
            const SizedBox(width: 10),
            Text(
              'NEXT QUESTION',
              style: GoogleFonts.orbitron(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF041A52),
                letterSpacing: 1.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
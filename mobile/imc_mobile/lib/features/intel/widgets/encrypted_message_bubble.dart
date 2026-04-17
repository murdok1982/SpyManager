import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/colors.dart';

class EncryptedMessageBubble extends StatefulWidget {
  const EncryptedMessageBubble({
    super.key,
    required this.content,
    required this.hash,
    required this.timestamp,
  });

  final String content;
  final String hash;
  final DateTime timestamp;

  @override
  State<EncryptedMessageBubble> createState() => _EncryptedMessageBubbleState();
}

class _EncryptedMessageBubbleState extends State<EncryptedMessageBubble> {
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.accentCyan.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lock_outline, size: 14, color: AppColors.accentCyan),
              const SizedBox(width: 6),
              Text(
                'ENCRYPTED MESSAGE',
                style: GoogleFonts.robotoMono(
                  fontSize: 10,
                  color: AppColors.accentCyan,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => _revealed = !_revealed),
                child: Text(
                  _revealed ? 'HIDE' : 'REVEAL',
                  style: GoogleFonts.robotoMono(
                    fontSize: 10,
                    color: AppColors.warning,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_revealed)
            Text(
              widget.content,
              style: GoogleFonts.roboto(
                fontSize: 14,
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ).animate().fadeIn(duration: 300.ms)
          else
            Text(
              _obfuscate(widget.content),
              style: GoogleFonts.robotoMono(
                fontSize: 14,
                color: AppColors.textMuted,
                letterSpacing: 1,
              ),
            ),
          const SizedBox(height: 10),
          const Divider(color: AppColors.borderSubtle, height: 1),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'HASH: ${widget.hash}',
                style: GoogleFonts.robotoMono(
                  fontSize: 9,
                  color: AppColors.textMuted,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _obfuscate(String text) {
    const chars = 'ABCDEF0123456789';
    final result = StringBuffer();
    for (final ch in text.characters) {
      if (ch == ' ') {
        result.write('  ');
      } else {
        result.write(chars[(ch.codeUnitAt(0) * 7 + 3) % chars.length]);
      }
    }
    return result.toString();
  }
}

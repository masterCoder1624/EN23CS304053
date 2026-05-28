/// SentimentBadge - Colored pill badge for sentiment display
/// Shows sentiment with icon and label

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class SentimentBadge extends StatelessWidget {
  final String sentiment; // 'positive', 'negative', 'neutral'
  final String label;
  final bool showIcon;

  const SentimentBadge({
    super.key,
    required this.sentiment,
    this.label = '',
    this.showIcon = true,
  });

  Color _getSentimentColor() {
    switch (sentiment.toLowerCase()) {
      case 'positive':
        return AppColors.positive;
      case 'negative':
        return AppColors.negative;
      case 'neutral':
      default:
        return AppColors.neutral;
    }
  }

  IconData _getSentimentIcon() {
    switch (sentiment.toLowerCase()) {
      case 'positive':
        return Icons.thumb_up_rounded;
      case 'negative':
        return Icons.thumb_down_rounded;
      case 'neutral':
      default:
        return Icons.remove_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getSentimentColor();
    final icon = _getSentimentIcon();
    final displayLabel = label.isEmpty ? sentiment : label;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
          ],
          Text(
            displayLabel,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

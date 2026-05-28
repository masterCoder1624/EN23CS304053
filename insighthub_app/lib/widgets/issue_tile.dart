import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'modern_card.dart';

/// IssueTile - List tile for detected product issues
/// Shows topic name, mention count, and severity badge with dark theme styling
class IssueTile extends StatelessWidget {
  final String topic;
  final int mentions;
  final String severity;
  final VoidCallback? onTap;

  const IssueTile({
    super.key,
    required this.topic,
    required this.mentions,
    required this.severity,
    this.onTap,
  });

  Color get _severityColor {
    switch (severity.toLowerCase()) {
      case 'high':
        return AppColors.error;
      case 'medium':
        return AppColors.warning;
      case 'low':
        return AppColors.secondary;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData get _severityIcon {
    switch (severity.toLowerCase()) {
      case 'high':
        return Icons.error_rounded;
      case 'medium':
        return Icons.warning_amber_rounded;
      case 'low':
        return Icons.info_rounded;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Row(
        children: [
          // Severity icon badge
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: _severityColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(_severityIcon, color: _severityColor, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),

          // Topic name + mentions
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  topic[0].toUpperCase() + topic.substring(1),
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$mentions mentions',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Severity badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: _severityColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: _severityColor.withOpacity(0.3)),
            ),
            child: Text(
              severity.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _severityColor,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

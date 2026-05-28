/// TopicChip - Chip-style badge for displaying topics/keywords
/// Used in insights and explorer screens

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class TopicChip extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool selected;
  final Color? backgroundColor;
  final Color? textColor;

  const TopicChip({
    super.key,
    required this.label,
    this.onTap,
    this.selected = false,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? AppColors.surfaceLight;
    final txtColor = textColor ?? AppColors.textPrimary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withOpacity(0.2) : bgColor,
          border: Border.all(
            color: selected ? AppColors.primary : bgColor,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.primary : txtColor,
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import 'modern_card.dart';

/// SentimentCard - Displays a donut chart of sentiment distribution
/// Shows positive, negative, and neutral sentiment breakdown with dark theme
class SentimentCard extends StatelessWidget {
  final int positive;
  final int negative;
  final int neutral;

  const SentimentCard({
    super.key,
    required this.positive,
    required this.negative,
    required this.neutral,
  });

  int get _total => positive + negative + neutral;

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sentiment Breakdown',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Chart + Legend side by side
          SizedBox(
            height: 160,
            child: Row(
              children: [
                // Donut chart
                Expanded(
                  flex: 3,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 3,
                      centerSpaceRadius: 36,
                      sections: _sections(),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                // Legend
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _legendRow('Positive', positive, AppColors.positive),
                      const SizedBox(height: AppSpacing.md),
                      _legendRow('Negative', negative, AppColors.error),
                      const SizedBox(height: AppSpacing.md),
                      _legendRow('Neutral', neutral, AppColors.neutral),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _sections() {
    final total = _total == 0 ? 1 : _total; // avoid division by zero
    return [
      PieChartSectionData(
        value: positive.toDouble(),
        color: AppColors.positive,
        radius: 28,
        title: '${(positive / total * 100).round()}%',
        titleStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        value: negative.toDouble(),
        color: AppColors.error,
        radius: 28,
        title: '${(negative / total * 100).round()}%',
        titleStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        value: neutral.toDouble(),
        color: AppColors.neutral,
        radius: 28,
        title: '${(neutral / total * 100).round()}%',
        titleStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    ];
  }

  Widget _legendRow(String label, int count, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Text(
          '$count',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

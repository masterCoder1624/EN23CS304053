import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../widgets/loading_widget.dart';
import '../widgets/modern_card.dart';
import '../widgets/topic_chip.dart';

/// InsightsScreen - AI-generated insights display
/// Shows what users love, main complaints, trending keywords with modern dark theme
class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchInsights();
  }

  Future<void> _fetchInsights() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await ApiService.getInsights();
      setState(() {
        // Extract the data field from the wrapped API response
        _data = response['data'] as Map<String, dynamic>? ?? response;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const LoadingWidget(message: 'Analysing insights…'),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_rounded,
                  size: 48, color: AppColors.error),
              const SizedBox(height: AppSpacing.md),
              Text('Failed to load insights',
                  style: GoogleFonts.inter(
                      fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: _fetchInsights,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final aiInsights = _data!['ai_insights'] ?? {};
    final whatUsersLove =
        List<String>.from(aiInsights['what_users_love'] ?? []);
    final mainComplaints =
        List<String>.from(aiInsights['main_complaints'] ?? []);
    final summary = aiInsights['summary'] ?? '';
    final topKeywords = List<String>.from(_data!['top_keywords'] ?? []);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _fetchInsights,
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.xxl,
          ),
          children: [
            // Header
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Insights',
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Powered by NLP & machine learning',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── What Users Love ──
            _buildSection(
              emoji: '❤️',
              title: 'What Users Love',
              items: whatUsersLove,
              color: AppColors.positive,
              icon: Icons.favorite_rounded,
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── Main Complaints ──
            _buildSection(
              emoji: '⚠️',
              title: 'Main Complaints',
              items: mainComplaints,
              color: AppColors.error,
              icon: Icons.warning_rounded,
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── Top Keywords (TF-IDF) ──
            if (topKeywords.isNotEmpty) ...[
              _buildKeywordsCard(topKeywords),
              const SizedBox(height: AppSpacing.lg),
            ],

            // ── AI Summary ──
            if (summary.isNotEmpty)
              ModernCard(
                padding: const EdgeInsets.all(AppSpacing.lg),
                backgroundColor: AppColors.primary.withOpacity(0.1),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.2),
                  width: 1,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: Icon(
                            Icons.auto_awesome_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Text(
                          'AI Summary',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      summary,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.65,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Builds a section card for loved/complained topics with dark theme styling
  Widget _buildSection({
    required String emoji,
    required String title,
    required List<String> items,
    required Color color,
    required IconData icon,
  }) {
    return ModernCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: AppSpacing.sm),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (items.isEmpty)
            Text(
              'No data yet — upload reviews to get started.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            )
          else
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: items
                  .map((item) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: color.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, size: 14, color: color),
                        const SizedBox(width: 6),
                        Text(
                          item[0].toUpperCase() + item.substring(1),
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ))
                  .toList(),
            ),
        ],
      ),
    );
  }

  /// Renders a card with TF-IDF extracted keywords as chips
  Widget _buildKeywordsCard(List<String> keywords) {
    return ModernCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🔑', style: TextStyle(fontSize: 20)),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Trending Keywords',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: keywords
                .map((kw) => TopicChip(
                  label: kw,
                  backgroundColor: AppColors.surfaceLight,
                  textColor: AppColors.textPrimary,
                ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

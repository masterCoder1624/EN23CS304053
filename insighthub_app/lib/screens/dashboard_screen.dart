import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../widgets/stat_card.dart';
import '../widgets/issue_tile.dart';
import '../widgets/sentiment_card.dart';
import '../widgets/loading_widget.dart';
import '../widgets/modern_card.dart';

/// Main dashboard showing key metrics, sentiment chart, AI summary, and issues.
/// Modern dark-themed interface with premium card design
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _loading
          ? const LoadingWidget(message: 'Fetching analytics…')
          : _error != null
              ? _buildError()
              : _buildDashboard(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.15),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Icon(
                Icons.cloud_off_rounded,
                size: 48,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Unable to connect',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Make sure the backend server is running\nand try again.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: _fetchData,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(
                'Retry',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard() {
    final total = _data!['total_reviews'] ?? 0;
    final sentiment = _data!['sentiment'] ?? {};
    final positive = sentiment['positive'] ?? 0;
    final negative = sentiment['negative'] ?? 0;
    final neutral = sentiment['neutral'] ?? 0;
    final issues = (_data!['issues'] as List?) ?? [];
    final aiInsights = _data!['ai_insights'] ?? {};
    final summary = aiInsights['summary'] ?? 'No summary available.';
    final negPct =
        total > 0 ? '${(negative / total * 100).toStringAsFixed(1)}%' : '0%';
    final posPct =
        total > 0 ? '${(positive / total * 100).toStringAsFixed(1)}%' : '0%';

    return RefreshIndicator(
      onRefresh: _fetchData,
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
          // ── Header ──
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dashboard',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Your feedback analytics at a glance',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── Key Metrics Grid ──
          Row(
            children: [
              Expanded(
                child: StatCard(
                  icon: Icons.reviews_rounded,
                  title: 'Total Reviews',
                  value: '$total',
                  accentColor: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: StatCard(
                  icon: Icons.sentiment_satisfied_rounded,
                  title: 'Positive',
                  value: posPct,
                  accentColor: AppColors.positive,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  icon: Icons.trending_down_rounded,
                  title: 'Negative',
                  value: negPct,
                  accentColor: AppColors.error,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: StatCard(
                  icon: Icons.remove_rounded,
                  title: 'Neutral',
                  value: '${(neutral / total * 100).toStringAsFixed(1)}%',
                  accentColor: AppColors.neutral,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── Sentiment Distribution ──
          if (sentiment.isNotEmpty)
            SentimentCard(
              positive: positive,
              negative: negative,
              neutral: neutral,
            ),
          const SizedBox(height: AppSpacing.lg),

          // ── AI Summary Card ──
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
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── Issues Section ──
          if (issues.isNotEmpty) ...[
            Text(
              'Detected Issues',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ...issues.take(5).map((issue) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: IssueTile(
                    topic: issue['topic'] ?? '',
                    mentions: issue['frequency'] ?? 0,
                    severity: issue['severity'] ?? 'low',
                  ),
                )),
            if (issues.length > 5)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Text(
                  'and ${issues.length - 5} more issues',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

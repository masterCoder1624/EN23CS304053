import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../widgets/loading_widget.dart';
import '../widgets/modern_card.dart';
import '../widgets/sentiment_badge.dart';
import '../widgets/topic_chip.dart';

/// ExplorerScreen - Review explorer with sentiment filter and scrollable list
/// Modern dark-themed interface for browsing and filtering customer reviews
class ExplorerScreen extends StatefulWidget {
  const ExplorerScreen({super.key});

  @override
  State<ExplorerScreen> createState() => _ExplorerScreenState();
}

class _ExplorerScreenState extends State<ExplorerScreen> {
  List<dynamic> _allReviews = [];
  bool _loading = true;
  String? _error;
  String _filter = 'all'; // all | positive | negative | neutral

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
      // Extract the data field from the wrapped API response
      final data = response['data'] as Map<String, dynamic>? ?? response;
      setState(() {
        _allReviews = _extractReviews(data);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  /// Extract review-level data from the insights payload.
  /// Falls back to a synthetic list if there's no review-level data.
  List<Map<String, dynamic>> _extractReviews(Map<String, dynamic> data) {
    // If the backend exposes a 'reviews' key in its response we use it.
    if (data.containsKey('reviews') && data['reviews'] is List) {
      return List<Map<String, dynamic>>.from(data['reviews']);
    }

    // Otherwise build a synthetic list from the aggregated data so the
    // explorer screen still shows something useful.
    final List<Map<String, dynamic>> synthetic = [];
    final sentiment = data['sentiment'] ?? {};
    final issues = List<Map<String, dynamic>>.from(data['issues'] ?? []);
    final ai = data['ai_insights'] ?? {};
    final loved = List<String>.from(ai['what_users_love'] ?? []);
    final complaints = List<String>.from(ai['main_complaints'] ?? []);

    // Generate sample entries from positive topics
    for (final topic in loved) {
      synthetic.add({
        'text': 'Users love the $topic experience.',
        'sentiment': 'positive',
        'topics': [topic],
      });
    }
    // Generate entries from complaint topics
    for (final topic in complaints) {
      synthetic.add({
        'text': 'Users report issues with $topic.',
        'sentiment': 'negative',
        'topics': [topic],
      });
    }
    // Generate entries from issues
    for (final issue in issues) {
      if (!complaints.contains(issue['topic'])) {
        synthetic.add({
          'text': 'Issue detected: ${issue['topic']} (${issue['severity']} severity).',
          'sentiment': 'negative',
          'topics': [issue['topic']],
        });
      }
    }
    // Add some neutral placeholders based on total
    final total = data['total_reviews'] ?? 0;
    final neutralCount = (sentiment['neutral'] ?? 0) as int;
    if (neutralCount > 0 && synthetic.length < total) {
      synthetic.add({
        'text': '$neutralCount reviews had neutral sentiment.',
        'sentiment': 'neutral',
        'topics': [],
      });
    }

    return synthetic;
  }

  List<dynamic> get _filtered {
    if (_filter == 'all') return _allReviews;
    return _allReviews
        .where((r) => r['sentiment'] == _filter)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const LoadingWidget(message: 'Loading reviews…'),
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
              Text('Failed to load reviews',
                  style: GoogleFonts.inter(
                      fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: _fetchData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final filtered = _filtered;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header + filter
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Explorer',
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Browse and filter customer reviews',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                // Filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _filterChip('All', 'all'),
                      const SizedBox(width: AppSpacing.sm),
                      _filterChip('Positive', 'positive'),
                      const SizedBox(width: AppSpacing.sm),
                      _filterChip('Negative', 'negative'),
                      const SizedBox(width: AppSpacing.sm),
                      _filterChip('Neutral', 'neutral'),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),

          // Review list
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inbox_rounded,
                            size: 56, color: AppColors.textSecondary.withOpacity(0.3)),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'No reviews found',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _fetchData,
                    color: AppColors.primary,
                    backgroundColor: AppColors.surface,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        0,
                        AppSpacing.lg,
                        AppSpacing.xxl,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final review = filtered[index];
                        return _reviewCard(review);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final selected = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : AppColors.surfaceLight,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _reviewCard(dynamic review) {
    final text = review['text'] ?? '';
    final sentiment = review['sentiment'] ?? 'neutral';
    final topics = List<String>.from(review['topics'] ?? []);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: ModernCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Review text
            Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Sentiment badge + topic chips
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                // Sentiment badge
                SentimentBadge(sentiment: sentiment),
                
                // Topic chips
                ...topics.map((t) => TopicChip(
                  label: t,
                  backgroundColor: AppColors.surfaceLight,
                  textColor: AppColors.textSecondary,
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

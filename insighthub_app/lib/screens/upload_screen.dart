import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../widgets/modern_card.dart';

/// UploadScreen - CSV file upload interface with drag-and-drop styling
/// Modern dark-themed interface with premium upload experience
class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen>
    with SingleTickerProviderStateMixin {
  bool _uploading = false;
  String? _message;
  bool _success = false;
  int _reviewsProcessed = 0;
  String? _fileName;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUpload() async {
    // Pick CSV file
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result == null || result.files.single.path == null) return;

    final file = File(result.files.single.path!);
    setState(() {
      _fileName = result.files.single.name;
      _uploading = true;
      _message = null;
      _success = false;
    });

    try {
      final response = await ApiService.uploadFile(file);
      setState(() {
        _uploading = false;
        _success = response['success'] == true;
        // Extract data from the nested response structure
        final data = response['data'] as Map<String, dynamic>? ?? {};
        _reviewsProcessed = data['reviews_processed'] as int? ?? 0;
        _message = response['message'] ?? 'Upload complete.';
      });
    } catch (e) {
      setState(() {
        _uploading = false;
        _success = false;
        _message = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header ──
              Text(
                'Upload Reviews',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Add your customer feedback CSV file',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // ── Upload area ──
              GestureDetector(
                onTap: _uploading ? null : _pickAndUpload,
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    final scale =
                        _uploading ? 1.0 : 1.0 + _pulseController.value * 0.02;
                    return Transform.scale(scale: scale, child: child);
                  },
                  child: ModernCard(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xxl,
                      horizontal: AppSpacing.lg,
                    ),
                    backgroundColor: AppColors.surface,
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.3),
                      width: 2,
                      strokeAlign: BorderSide.strokeAlignInside,
                    ),
                    child: Column(
                      children: [
                        // Icon badge
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                          ),
                          child: Icon(
                            Icons.cloud_upload_rounded,
                            size: 48,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        
                        // Title
                        Text(
                          'Upload CSV File',
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        
                        // Description
                        Text(
                          'Select a CSV with a "review" column\nto start analysing customer feedback',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        
                        // Button
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.md,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.folder_open_rounded,
                                  color: Colors.white, size: 18),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                'Browse Files',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // ── Uploading indicator ──
              if (_uploading)
                ModernCard(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Uploading & Analysing…',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            if (_fileName != null)
                              Text(
                                _fileName!,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              // ── Result message ──
              if (_message != null && !_uploading)
                ModernCard(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  backgroundColor: _success
                      ? AppColors.positive.withOpacity(0.15)
                      : AppColors.error.withOpacity(0.15),
                  border: Border.all(
                    color: _success
                        ? AppColors.positive.withOpacity(0.3)
                        : AppColors.error.withOpacity(0.3),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _success
                            ? Icons.check_circle_rounded
                            : Icons.error_rounded,
                        color: _success
                            ? AppColors.positive
                            : AppColors.error,
                        size: 28,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _success ? 'Upload Successful' : 'Upload Failed',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: _success
                                    ? AppColors.positive
                                    : AppColors.error,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _success
                                  ? '$_reviewsProcessed reviews processed'
                                  : _message!,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: _success
                                    ? AppColors.positive.withOpacity(0.8)
                                    : AppColors.error.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

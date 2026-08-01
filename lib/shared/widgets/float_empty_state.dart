import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'float_logo.dart';

/// Reusable empty state with on-brand FloatLogo + fun copy.
/// 
/// Use for screens with no data yet (Portfolio, Alerts, etc.).
class FloatEmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? ctaText;
  final VoidCallback? onCta;

  const FloatEmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    this.ctaText,
    this.onCta,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FloatLogo(
              size: 120,
              animated: false,
              showRipples: false,
              showBubbles: true,
              showExtraDecorations: true,
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.moonlightText : AppColors.darkText,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 15,
                color: isDark ? AppColors.moonlightSilver : Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            if (ctaText != null && onCta != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.moonlightSurface : AppColors.sand)
                      .withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: GestureDetector(
                  onTap: onCta,
                  child: Text(
                    ctaText!,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.moonlightAccent : AppColors.primaryTeal,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'float_logo.dart';

/// Reusable header with the FloatLogo for consistent branding.
/// 
/// Use for screens that want a small brand mark + title.
/// Example:
///   FloatHeader(title: 'Portfolio')
class FloatHeader extends StatelessWidget {
  final String title;
  final double logoSize;
  final bool showLogo;

  const FloatHeader({
    super.key,
    required this.title,
    this.logoSize = 32,
    this.showLogo = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        if (showLogo) ...[
          FloatLogo(
            size: logoSize,
            animated: false,
            showRipples: false,
            showBubbles: false,
            showExtraDecorations: false,
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.moonlightText : AppColors.deepNavy,
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class ColdkeyBadge extends StatelessWidget {
  final String coldkey;
  final bool isLive;
  final String? lastUpdated;

  const ColdkeyBadge({
    super.key,
    required this.coldkey,
    this.isLive = false,
    this.lastUpdated,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final short = coldkey.length > 12 ? '${coldkey.substring(0, 8)}...${coldkey.substring(coldkey.length - 4)}' : coldkey;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: (isDark ? AppColors.moonlightGlow : AppColors.primaryTeal).withOpacity(isDark ? 0.12 : 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (isDark ? AppColors.moonlightGlow : AppColors.primaryTeal).withOpacity(0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isLive ? Icons.cloud_done : Icons.link,
            size: 14,
            color: isDark ? AppColors.moonlightGlow : AppColors.primaryTeal,
          ),
          const SizedBox(width: 6),
          Text(
            'Marcus Coldkey: $short',
            style: TextStyle(
              fontSize: 11,
              fontFamily: 'monospace',
              color: isDark ? AppColors.moonlightGlow : AppColors.primaryTeal,
            ),
          ),
        ],
      ),
    );
  }
}

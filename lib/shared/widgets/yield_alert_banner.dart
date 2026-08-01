import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/utils/yield_alerts.dart';

/// Banner that shows active yield alerts
class YieldAlertBanner extends StatelessWidget {
  final List<YieldAlert> alerts;
  final VoidCallback? onDismiss;
  final VoidCallback? onViewAll;

  const YieldAlertBanner({
    super.key,
    required this.alerts,
    this.onDismiss,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final highestSeverity = alerts.fold<AlertSeverity>(
      AlertSeverity.low,
      (prev, a) => a.severity.index > prev.index ? a.severity : prev,
    );

    final bgColor = _getSeverityColor(highestSeverity, isDark).withOpacity(0.15);
    final borderColor = _getSeverityColor(highestSeverity, isDark).withOpacity(0.4);
    final iconColor = _getSeverityColor(highestSeverity, isDark);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(
            _getSeverityIcon(highestSeverity),
            color: iconColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${alerts.length} Yield Alert${alerts.length > 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.moonlightText : AppColors.deepNavy,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  alerts.first.message,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : Colors.grey[700],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (onViewAll != null)
            TextButton(
              onPressed: onViewAll,
              child: const Text('View All'),
            ),
          if (onDismiss != null)
            IconButton(
              onPressed: onDismiss,
              icon: const Icon(Icons.close, size: 18),
              tooltip: 'Dismiss',
            ),
        ],
      ),
    );
  }

  Color _getSeverityColor(AlertSeverity severity, bool isDark) {
    switch (severity) {
      case AlertSeverity.low:
        return Colors.blue;
      case AlertSeverity.medium:
        return Colors.orange;
      case AlertSeverity.high:
        return Colors.red;
    }
  }

  IconData _getSeverityIcon(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.low:
        return Icons.info_outline;
      case AlertSeverity.medium:
        return Icons.warning_amber_outlined;
      case AlertSeverity.high:
        return Icons.error_outline;
    }
  }
}

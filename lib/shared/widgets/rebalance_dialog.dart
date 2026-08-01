import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/utils/rebalance_engine.dart';

/// Dialog that shows rebalance suggestions
class RebalanceDialog extends StatelessWidget {
  final List<RebalanceSuggestion> suggestions;
  final VoidCallback? onExecute;
  final VoidCallback? onDismiss;

  const RebalanceDialog({
    super.key,
    required this.suggestions,
    this.onExecute,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: isDark ? AppColors.moonlightSurface : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(Icons.balance, color: AppColors.primaryTeal),
          const SizedBox(width: 8),
          Text(
            'Rebalance Suggestions',
            style: TextStyle(
              color: isDark ? AppColors.moonlightText : AppColors.deepNavy,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: suggestions.isEmpty
            ? const Text('Portfolio is balanced. No action needed. 🛟')
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${suggestions.length} suggestion${suggestions.length > 1 ? 's' : ''} based on drift > 5%',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white60 : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...suggestions.map((s) => _buildSuggestionTile(s, isDark)).toList(),
                ],
              ),
      ),
      actions: [
        if (onDismiss != null)
          TextButton(
            onPressed: onDismiss,
            child: const Text('Later'),
          ),
        if (onExecute != null && suggestions.isNotEmpty)
          ElevatedButton(
            onPressed: onExecute,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryTeal,
              foregroundColor: Colors.white,
            ),
            child: const Text('Review Trades'),
          ),
      ],
    );
  }

  Widget _buildSuggestionTile(RebalanceSuggestion s, bool isDark) {
    final isTrim = s.action == RebalanceAction.trim;
    final color = isTrim ? Colors.orange : Colors.green;
    final icon = isTrim ? Icons.trending_down : Icons.trending_up;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.moonlightSurfaceAlt : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SN${s.subnetId}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.moonlightText : AppColors.deepNavy,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${s.currentPct.toStringAsFixed(1)}% → ${s.targetPct.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isTrim ? 'TRIM' : 'ADD',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${s.amountTao.toStringAsFixed(2)} TAO',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.moonlightText : AppColors.deepNavy,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

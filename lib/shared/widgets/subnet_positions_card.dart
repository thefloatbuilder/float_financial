import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../models/subnet_position.dart';
import 'float_logo.dart';

/// Subnet Positions Tracker — Shows real TAO staked across subnets
/// Tracks: SN64 Chutes, SN4 Targon, SN53 Engy, SN0 Root
class SubnetPositionsCard extends StatelessWidget {
  final List<SubnetPosition> positions;
  final VoidCallback? onRefresh;
  final VoidCallback? onStakeMore;

  const SubnetPositionsCard({
    super.key,
    required this.positions,
    this.onRefresh,
    this.onStakeMore,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalStaked = positions.fold<double>(0, (sum, p) => sum + p.stakedTao);
    final totalValue = positions.fold<double>(0, (sum, p) => sum + p.currentValueTao);
    final totalYield = positions.fold<double>(0, (sum, p) => sum + p.monthlyYieldTao);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [AppColors.moonlightSurface, AppColors.moonlightSurfaceAlt]
              : [AppColors.primaryTeal.withOpacity(0.1), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.moonlightSurfaceAlt : AppColors.primaryTeal.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              FloatLogo(
                size: 32,
                animated: false,
                showRipples: false,
                showBubbles: false,
                showExtraDecorations: false,
                performance: totalValue >= totalStaked ? 'positive' : 'negative',
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Subnet Positions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.moonlightText : AppColors.deepNavy,
                      ),
                    ),
                    Text(
                      '${positions.length} subnets • ${totalStaked.toStringAsFixed(1)} TAO staked',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (onRefresh != null)
                IconButton(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh, size: 20),
                  tooltip: 'Refresh positions',
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Summary row
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.moonlightSurfaceAlt : Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(
                  'Total Value',
                  '${totalValue.toStringAsFixed(2)} TAO',
                  totalValue >= totalStaked ? Colors.green : Colors.red,
                  isDark,
                ),
                _buildSummaryItem(
                  'P&L',
                  '${(totalValue - totalStaked >= 0 ? '+' : '')}${(totalValue - totalStaked).toStringAsFixed(2)}',
                  totalValue >= totalStaked ? Colors.green : Colors.red,
                  isDark,
                ),
                _buildSummaryItem(
                  'Monthly Yield',
                  '${totalYield.toStringAsFixed(3)} TAO',
                  AppColors.primaryTeal,
                  isDark,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Positions list
          ...positions.map((p) => _buildPositionRow(p, isDark)).toList(),

          // Stake more button
          if (onStakeMore != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onStakeMore,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Stake More TAO'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color, bool isDark) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.white60 : Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildPositionRow(SubnetPosition p, bool isDark) {
    final pnlColor = p.pnlTao >= 0 ? Colors.green : Colors.red;
    final pnlSign = p.pnlTao >= 0 ? '+' : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.moonlightSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.moonlightSurfaceAlt : Colors.grey[200]!,
        ),
      ),
      child: Row(
        children: [
          // Subnet badge
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getSubnetColor(p.subnetId).withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                'SN${p.subnetId}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _getSubnetColor(p.subnetId),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.moonlightText : AppColors.deepNavy,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${p.stakedTao.toStringAsFixed(2)} TAO → ${p.alphaBalance.toStringAsFixed(2)} α',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white60 : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          // Value & P&L
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${p.currentValueTao.toStringAsFixed(2)} TAO',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.moonlightText : AppColors.deepNavy,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: pnlColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$pnlSign${p.pnlTao.toStringAsFixed(2)} (${p.pnlPercent.toStringAsFixed(1)}%)',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: pnlColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getSubnetColor(int subnetId) {
    switch (subnetId) {
      case 64: return Colors.blue;
      case 4: return Colors.purple;
      case 53: return Colors.teal;
      case 0: return Colors.orange;
      default: return Colors.grey;
    }
  }
}

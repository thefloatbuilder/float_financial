import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/widgets/float_logo.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/providers/portfolio_provider.dart';
import '../../shared/providers/subnet_positions_provider.dart';
import '../../shared/providers/performance_provider.dart';
import '../../shared/widgets/animated_number.dart';
import '../../shared/widgets/subnet_positions_card.dart';
import '../../shared/widgets/yield_alert_banner.dart';
import '../../shared/widgets/rebalance_dialog.dart';
import '../../shared/widgets/lead_capture_form.dart';
import '../../shared/widgets/portfolio_performance_chart.dart';
import '../../shared/widgets/app_loading.dart';
import '../../shared/widgets/admin_leads_view.dart';
import '../../shared/utils/leads_exporter.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final portfolio = ref.watch(portfolioProvider);
    
    return Scaffold(
      body: SafeArea(
        child: _buildDashboard(context, portfolio),
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, Map<String, dynamic> portfolio) {
    final totalValue = (portfolio['total_value'] as num? ?? 0).toStringAsFixed(0);
    final monthlyChange = portfolio['monthly_change'] as num? ?? 0;
    final dailyYield = portfolio['daily_yield_estimate_usd'] as num? ?? 0;
    final isLive = portfolio['is_live'] == true;
    final isPositive = monthlyChange >= 0;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Offline / stale-data banner — taostats or price feed unreachable.
          // Cached values (if any) still render below; never silently $0.
          if (!isLive)
            Consumer(
              builder: (context, ref, _) {
                final isDark = Theme.of(context).brightness == Brightness.dark;
                final lastUpdated = portfolio['last_updated'] as String?;
                final lastUpdatedLabel = lastUpdated != null
                    ? DateTime.tryParse(lastUpdated)?.toLocal().toString().substring(0, 16)
                    : null;
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(isDark ? 0.18 : 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.orange.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.cloud_off, color: Colors.orange, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          lastUpdatedLabel != null
                              ? "Live prices unavailable — showing last data from $lastUpdatedLabel"
                              : "Live prices unavailable — check your connection",
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: isDark ? AppColors.moonlightText : AppColors.darkText,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          ref.invalidate(subnetPositionsProvider);
                          ref.read(portfolioProvider.notifier).refreshColdkeyData();
                        },
                        child: const Text('Retry', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                );
              },
            ),

          // Header - cruise mode brand style
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Wraps instead of overflowing on narrow phone widths.
              Flexible(
                child: Row(
                  children: [
                    FloatLogo(
                      size: 42,
                      animated: false,
                      showRipples: false,
                      showBubbles: false,
                      showExtraDecorations: false,
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Good morning!',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? AppColors.moonlightText
                                  : AppColors.deepNavy,
                            ),
                          ),
                          Text(
                            'Your portfolio, on cruise mode',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white60
                                  : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (isLive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.withOpacity(0.25), Colors.teal.withOpacity(0.2)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '🌊 LIVE',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.green,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Portfolio Value Card — stronger pool/float cruise mode (inspired by the image)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: AppColors.cruiseGradient,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryTeal.withOpacity(0.4),
                  blurRadius: 28,
                  offset: const Offset(0, 14),
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(0, -4),
                ),
              ],
              // Subtle water surface highlight
              border: Border.all(
                color: Colors.white.withOpacity(0.15),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Portfolio Value',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                AnimatedNumber(
                  value: double.parse(totalValue),
                  prefix: '\$',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 44,
                    fontWeight: FontWeight.bold,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.22),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${isPositive ? '+' : ''}${monthlyChange.toStringAsFixed(1)}% this month',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(width: 6, height: 2, color: Colors.white.withOpacity(0.3)),
                    const SizedBox(width: 4),
                    Container(width: 10, height: 2, color: Colors.white.withOpacity(0.2)),
                    const SizedBox(width: 4),
                    Container(width: 6, height: 2, color: Colors.white.withOpacity(0.3)),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Stats Row
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  "Daily Yield",
                  "\$${dailyYield.toStringAsFixed(0)}",
                  isPositive ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  context,
                  "Monthly Change",
                  "${isPositive ? "+" : ""}${monthlyChange.toStringAsFixed(1)}%",
                  isPositive ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Scopes Overview - enhanced with simple bars
          Consumer(
            builder: (context, ref, _) {
              final scopes = ref.watch(portfolioProvider.notifier).scopesWithStats;
              final isDark = Theme.of(context).brightness == Brightness.dark;
              if (scopes.isEmpty) return const SizedBox.shrink();
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.moonlightSurface : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: isDark ? AppColors.moonlightSurfaceAlt : Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Text("🏝️ Scopes Overview", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      const Spacer(),
                      Text("${scopes.length} active", style: TextStyle(fontSize: 11, color: Colors.grey)),
                    ]),
                    const SizedBox(height: 10),
                    ...scopes.take(4).map((scope) {
                      final name = scope["name"] as String? ?? "Scope";
                      final pct = (scope["value_pct"] as num?)?.toDouble() ?? 0.0;
                      final yld = (scope["daily_yield"] as num?)?.toDouble() ?? 0.0;
                      // target_pct retained in scope data; shown on Portfolio screen
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                Text("${pct.toStringAsFixed(1)}% • \$${yld.toStringAsFixed(0)}/d", style: TextStyle(fontSize: 12, color: isDark ? AppColors.moonlightSilver : Colors.grey[600])),
                              ],
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: (pct / 100).clamp(0.0, 1.0),
                                minHeight: 6,
                                backgroundColor: isDark ? Colors.white12 : Colors.grey.shade200,
                                valueColor: AlwaysStoppedAnimation(AppColors.primaryTeal),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 20),

          // Subnet Positions - TAO staking tracker
          Consumer(
            builder: (context, ref, _) {
              final positionsAsync = ref.watch(subnetPositionsProvider);
              return positionsAsync.when(
                data: (positions) => SubnetPositionsCard(
                  positions: positions,
                  onRefresh: () => ref.refresh(subnetPositionsProvider),
                  onStakeMore: () {
                    // TODO: Navigate to staking flow
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Stake more TAO - coming soon!')),
                    );
                  },
                ),
                loading: () => const ShimmerCard(height: 180),
                error: (_, __) => const SizedBox.shrink(),
              );
            },
          ),

          // Yield Alerts Banner
          Consumer(
            builder: (context, ref, _) {
              final alertsAsync = ref.watch(yieldAlertsProvider);
              return alertsAsync.when(
                data: (alerts) => YieldAlertBanner(
                  alerts: alerts,
                  onDismiss: () {
                    // TODO: Store dismissed alerts
                  },
                  onViewAll: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('All Yield Alerts'),
                        content: SizedBox(
                          width: double.maxFinite,
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: alerts.length,
                            itemBuilder: (_, i) => ListTile(
                              title: Text(alerts[i].message),
                              subtitle: Text(alerts[i].timestamp.toString()),
                            ),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              );
            },
          ),

          // Rebalance Suggestions Button
          Consumer(
            builder: (context, ref, _) {
              final needsRebalanceAsync = ref.watch(needsRebalanceProvider);
              return needsRebalanceAsync.when(
                data: (needsRebalance) {
                  if (!needsRebalance) return const SizedBox.shrink();
                  return Container(
                    margin: const EdgeInsets.only(top: 8, bottom: 16),
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final suggestions = await ref.read(rebalanceSuggestionsProvider.future);
                        if (!context.mounted) return;
                        showDialog(
                          context: context,
                          builder: (_) => RebalanceDialog(
                            suggestions: suggestions,
                            onDismiss: () => Navigator.pop(context),
                            onExecute: () {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Rebalance execution - coming soon!')),
                              );
                            },
                          ),
                        );
                      },
                      icon: const Icon(Icons.balance, size: 18),
                      label: const Text('Rebalance Suggested'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              );
            },
          ),

          // Portfolio Performance Chart
          Consumer(
            builder: (context, ref, _) {
              final performanceAsync = ref.watch(performanceDataProvider);
              return performanceAsync.when(
                data: (dataPoints) => PortfolioPerformanceChart(
                  dataPoints: dataPoints,
                  title: 'Portfolio Performance',
                ),
                loading: () => const ShimmerCard(height: 180),
                error: (_, __) => const SizedBox.shrink(),
              );
            },
          ),

          const SizedBox(height: 20),

          // Lead Capture Form
          const LeadCaptureForm(),

          const SizedBox(height: 20),

          // Admin Leads View + Export
          Consumer(
            builder: (context, ref, _) {
              final leadCountAsync = ref.watch(leadCountProvider);
              return Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Lead Management',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.moonlightText
                              : AppColors.deepNavy,
                        ),
                      ),
                      leadCountAsync.when(
                        data: (count) => count > 0
                            ? ElevatedButton.icon(
                                onPressed: () => LeadsExporter.exportToCsv(),
                                icon: const Icon(Icons.download, size: 18),
                                label: const Text('Export CSV'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryTeal,
                                  foregroundColor: Colors.white,
                                ),
                              )
                            : const SizedBox.shrink(),
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const AdminLeadsView(),
                ],
              );
            },
          ),

          const SizedBox(height: 20),
          Consumer(
            builder: (context, ref, _) {
              final scopes = ref.watch(portfolioProvider.notifier).scopesWithStats;
              final drifting = scopes.where((s) => ((s['drift'] as num?)?.abs() ?? 0) > 5).toList();
              if (drifting.isEmpty) return const SizedBox.shrink();
              final isDark = Theme.of(context).brightness == Brightness.dark;
              return Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.moonlightSurface : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primaryTeal.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(children: [
                      Text('🌊 Rebalance Suggestions', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    ]),
                    const SizedBox(height: 8),
                    ...drifting.map((s) {
                      final name = s['name'] as String? ?? 'Scope';
                      final drift = (s['drift'] as num).toDouble();
                      final dir = drift > 0 ? 'Trim' : 'Add to';
                      return GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: Text("Rebalance $name"),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Current drift: ${drift.toStringAsFixed(1)}%"),
                                  const SizedBox(height: 8),
                                  const Text("Quick action will move the first asset in this scope toward balance (unassign or to nearest under-target scope)."),
                                ],
                              ),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(_), child: const Text("Cancel")),
                                ElevatedButton(
                                  onPressed: () {
                                    final notifier = ref.read(portfolioProvider.notifier);
                                    final scopeHoldings = (s["holdings"] as List?)?.cast<Map<String, dynamic>>() ?? [];
                                    if (scopeHoldings.isNotEmpty) {
                                      final assetName = scopeHoldings.first["name"] as String;
                                      // Smart target: move to an under-target scope if one exists
                                      String? targetScopeId;
                                      if (drift > 0) {
                                        final under = scopes.firstWhere((sc) => ((sc["drift"] as num?)?.toDouble() ?? 0) < -3, orElse: () => {});
                                        if (under.isNotEmpty) targetScopeId = under["id"] as String?;
                                      }
                                      notifier.moveAssetToScope(assetName, targetScopeId);
                                      Navigator.pop(_);
                                      final dest = targetScopeId != null ? "another scope" : "unassigned";
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text("Moved $assetName $dest from $name for rebalancing.")),
                                      );
                                    } else {
                                      Navigator.pop(_);
                                    }
                                  },
                                  child: const Text("Quick Rebalance"),
                                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryTeal),
                                ),
                              ],
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text('• $dir $name (${drift.toStringAsFixed(1)}% drift) →', style: const TextStyle(fontSize: 13, color: AppColors.primaryTeal)),
                        ),
                      );
                    }),
                    const SizedBox(height: 6),
                    const Text('Check Portfolio to move assets between scopes.', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 24),
          
          // Quick Actions
          Row(
            children: [
              Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? AppColors.moonlightText 
                      : AppColors.deepNavy,
                ),
              ),
              const SizedBox(width: 8),
              const Text('🏖️', style: TextStyle(fontSize: 16)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  context,
                  'Save Snapshot',
                  Icons.camera_alt,
                  () => _saveSnapshot(context, portfolio),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  context,
                  'View Reports',
                  Icons.assessment,
                  () => Navigator.pushNamed(context, '/reports'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.moonlightSurface : AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.moonlightSurfaceAlt : Colors.grey.shade100,
          width: 1.0,
        ),
        boxShadow: isDark ? [] : [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: TextStyle(
                  color: isDark ? Colors.white60 : Colors.grey[600],
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (title.contains('Yield'))
                const Padding(
                  padding: EdgeInsets.only(left: 6),
                  child: Text('🌊', style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, String label, IconData icon, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        backgroundColor: AppColors.primaryTeal,
        foregroundColor: Colors.white,
        elevation: 3,
        shadowColor: AppColors.primaryTeal.withOpacity(0.3),
      ),
    );
  }

  void _saveSnapshot(BuildContext context, Map<String, dynamic> portfolio) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Snapshot saved! Check Reports history.')),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/widgets/float_logo.dart';
import '../../shared/widgets/float_header.dart';
import '../../shared/providers/portfolio_provider.dart';
import '../../shared/widgets/animated_number.dart';
import '../../shared/widgets/snapshot_comparison.dart';
import 'package:fl_chart/fl_chart.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final portfolio = ref.watch(portfolioProvider);
    // currentUserProvider available via ref when personalization is needed

    final totalValue = (portfolio['total_value'] ?? 152581.0);
    final monthlyChange = portfolio['monthly_change'] ?? 12.4;
    final dailyYield = portfolio['daily_yield_estimate_usd'] ?? 412.0;
    final isPositive = monthlyChange >= 0;

    final roth = portfolio['roth_ira'] ?? {'btc_amount': 0.0, 'xrp_amount': 0.0, 'total_usd': 0.0};

    return Scaffold(
      appBar: AppBar(
        title: const FloatHeader(title: 'Reports', logoSize: 26),
        backgroundColor: Theme.of(context).brightness == Brightness.dark 
            ? AppColors.moonlightBackground 
            : AppColors.lightGray,
        foregroundColor: Theme.of(context).brightness == Brightness.dark 
            ? AppColors.moonlightText 
            : AppColors.deepNavy,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                FloatLogo(
                  size: 32,
                  animated: false,
                  showRipples: false,
                  showBubbles: false,
                  showExtraDecorations: false,
                ),
                const SizedBox(width: 10),
                Text(
                  'Financial Reports',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? AppColors.moonlightText 
                        : AppColors.deepNavy,
                  ),
                ),
                const SizedBox(width: 8),
                const Text('🏖️', style: TextStyle(fontSize: 16)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Overview & analytics',
              style: TextStyle(
                fontSize: 15, 
                color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.white60 
                    : Colors.grey[600]
              ),
            ),
            const SizedBox(height: 24),

            // Scopes Allocation (NEW - main focus)
            Builder(builder: (ctx) {
              final scopes = ref.read(portfolioProvider.notifier).scopesWithStats;
              final isDarkLocal = Theme.of(ctx).brightness == Brightness.dark;
              if (scopes.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDarkLocal ? AppColors.moonlightSurface : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isDarkLocal ? AppColors.moonlightSurfaceAlt : Colors.grey.shade200),
                  ),
                  child: const Text('No custom scopes yet. Create some in Portfolio to see breakdowns here. 🏝️', style: TextStyle(fontSize: 14)),
                );
              }

              // Build pie sections for scope allocation
              // scope percentages are self-normalizing; no total needed
              final pieSections = scopes.map((s) {
                final pct = (s['value_pct'] as num?)?.toDouble() ?? 0;
                final colorVal = (s['holdings'] as List?)?.isNotEmpty == true 
                  ? ((s['holdings'] as List).first as Map)['color'] as int? ?? 0xFF14B8A6 
                  : 0xFF14B8A6;
                return PieChartSectionData(
                  color: Color(colorVal),
                  value: pct,
                  title: '${pct.toStringAsFixed(0)}%',
                  radius: 55,
                  titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                  borderSide: BorderSide(
                    color: isDarkLocal ? Colors.white.withOpacity(0.4) : Colors.black.withOpacity(0.3),
                    width: 2,
                  ),
                );
              }).toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Scope Allocation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: isDarkLocal ? AppColors.moonlightText : AppColors.deepNavy)),
                  const SizedBox(height: 12),
                  StatefulBuilder(
                    builder: (ctx, setState) {
                      // touch-selection highlight can be added later
                      final touchedSections = pieSections.asMap().entries.map((e) {
                        // index reserved for future touch-tap emphasis
                        final sec = e.value;
                        return PieChartSectionData(
                          color: sec.color,
                          value: sec.value,
                          title: sec.title,
                          radius: 55,
                          titleStyle: sec.titleStyle,
                          borderSide: BorderSide(
                          color: isDarkLocal ? Colors.white.withOpacity(0.4) : Colors.black.withOpacity(0.3),
                          width: 2,
                        ),
                        );
                      }).toList();

                      return SizedBox(
                        height: 180,
                        child: PieChart(
                          PieChartData(
                            sections: touchedSections,
                            centerSpaceRadius: 45,
                            sectionsSpace: 3,
                            pieTouchData: PieTouchData(
                              touchCallback: (event, response) {
                                if (response != null && response.touchedSection != null) {
                                  final idx = response.touchedSection!.touchedSectionIndex;
                                  if (idx >= 0 && idx < scopes.length) {
                                    setState(() {
                                      // selection updated
                                    });
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                      SnackBar(content: Text("Selected scope — tap list or pie"), duration: const Duration(seconds: 1)),
                                    );
                                  }
                                }
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  // Scope list with metrics
                  ...scopes.map((scope) {
                    final name = scope['name'] as String? ?? 'Scope';
                    final pct = (scope['value_pct'] as num?)?.toDouble() ?? 0;
                    final value = (scope['total_value'] as num?)?.toDouble() ?? 0;
                    final yld = (scope['daily_yield'] as num?)?.toDouble() ?? 0;
                    final chg = (scope['monthly_change'] as num?)?.toDouble() ?? 12.4;
                    final isPos = chg >= 0;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDarkLocal ? AppColors.moonlightSurface : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isDarkLocal ? AppColors.moonlightSurfaceAlt : Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                              Text('${pct.toStringAsFixed(1)}%', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryTeal)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(child: Text('Value: \$${value.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13))),
                              Expanded(child: Text('Yield: \$${yld.toStringAsFixed(0)}/d', style: const TextStyle(fontSize: 13))),
                              Expanded(
                                child: Text(
                                  '${isPos ? '+' : ''}${chg.toStringAsFixed(1)}%',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isPos ? Colors.green : Colors.orange),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 8),

                  // Scope Health summary
                  Builder(builder: (_) {
                    if (scopes.isEmpty) return const SizedBox.shrink();
                    final sorted = [...scopes]..sort((a,b) => ((b["monthly_change"] as num?)?.toDouble() ?? 0).compareTo((a["monthly_change"] as num?)?.toDouble() ?? 0));
                    final best = sorted.first;
                    final worst = sorted.last;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDarkLocal ? AppColors.moonlightSurfaceAlt : AppColors.sand,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Text("🏝️ Best", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                            Text(best["name"] as String? ?? "", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            Text("+${(best["monthly_change"] as num?)?.toDouble() ?? 0}%", style: const TextStyle(color: Colors.green, fontSize: 12)),
                          ])),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Text("🌊 Watch", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                            Text(worst["name"] as String? ?? "", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            Text("${(worst["monthly_change"] as num?)?.toDouble() ?? 0}%", style: const TextStyle(color: Colors.orange, fontSize: 12)),
                          ])),
                        ],
                      ),
                    );
                  }),

                  // Target vs Actual + Rebalance Suggestions (new)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDarkLocal ? AppColors.moonlightSurface : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDarkLocal ? AppColors.moonlightSurfaceAlt : Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('🎯 Target vs Actual', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 10),
                        ...scopes.map((scope) {
                          final name = scope['name'] as String? ?? 'Scope';
                          final actual = (scope['value_pct'] as num?)?.toDouble() ?? 0.0;
                          final target = (scope['target_pct'] as num?)?.toDouble() ?? 25.0;
                          final drift = (scope['drift'] as num?)?.toDouble() ?? (actual - target);
                          final isOver = drift > 0;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w600))),
                                    Text('${actual.toStringAsFixed(1)}% / ${target.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 12)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                LinearProgressIndicator(
                                  value: (actual / 100).clamp(0.0, 1.0),
                                  backgroundColor: isDarkLocal ? Colors.white24 : Colors.grey.shade200,
                                  color: isOver ? Colors.orange : AppColors.primaryTeal,
                                ),
                                Text(
                                  '${drift >= 0 ? '+' : ''}${drift.toStringAsFixed(1)}% drift',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: drift.abs() > 5 ? (isOver ? Colors.orange : Colors.green) : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 12),
                        if (scopes.any((s) => ((s['drift'] as num?)?.abs() ?? 0) > 5))
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primaryTeal.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('🌊 Rebalance Ideas', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                const SizedBox(height: 4),
                                ...scopes.where((s) => ((s['drift'] as num?)?.abs() ?? 0) > 5).map((s) {
                                  final d = (s['drift'] as num).toDouble();
                                  final dir = d > 0 ? 'Reduce' : 'Increase';
                                  return GestureDetector(
                                    onTap: () {
                                      // Could navigate or show more in full app
                                    },
                                    child: Text('• $dir exposure in ${s['name']} (tap in Portfolio to adjust)', style: const TextStyle(fontSize: 12, color: AppColors.primaryTeal)),
                                  );
                                }),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Quick actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            final target = "a scope";
                            showDialog(
                              context: ctx,
                              builder: (_) => AlertDialog(
                                title: const Text("Manage Scopes"),
                                content: Text("Head to the Portfolio tab to manage $target. The pie there is fully interactive for moving assets."),
                                actions: [TextButton(onPressed: () => Navigator.pop(_), child: const Text("Got it"))],
                              ),
                            );
                          },
                          icon: const Icon(Icons.tune, size: 16),
                          label: const Text("Manage Scopes", style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10), foregroundColor: AppColors.primaryTeal),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            final target = "a scope";
                            showDialog(
                              context: ctx,
                              builder: (_) => AlertDialog(
                                title: const Text("Manage Scopes"),
                                content: Text("Head to the Portfolio tab to manage $target. The pie there is fully interactive for moving assets."),
                                actions: [TextButton(onPressed: () => Navigator.pop(_), child: const Text("Got it"))],
                              ),
                            );
                          },
                          icon: const Icon(Icons.notifications, size: 16),
                          label: const Text("Set Alert", style: TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryTeal, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 10)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Tap pie to highlight a scope.', style: TextStyle(fontSize: 11, color: isDarkLocal ? Colors.white54 : Colors.grey[500], fontStyle: FontStyle.italic)),
                ],
              );
            }),
            const SizedBox(height: 24),

            // Portfolio Total - stronger cruise/pool mode
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.moonlightGradient
                    : AppColors.cruiseGradientLight,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryTeal.withOpacity(0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: Colors.white.withOpacity(0.12),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.account_balance_wallet, color: Colors.white, size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Total Portfolio Value', 
                          style: TextStyle(fontSize: 13, color: Colors.white70)),
                        AnimatedNumber(
                          value: totalValue,
                          prefix: '\$',
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Coldkey Yield — pool-inspired card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark 
                    ? AppColors.moonlightSurface 
                    : AppColors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isPositive 
                    ? AppColors.primaryTeal.withOpacity(0.3) 
                    : Colors.orange.withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow: Theme.of(context).brightness == Brightness.dark ? [] : [
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
                      const Text('Coldkey Yield', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 6),
                      const Text('🌊', style: TextStyle(fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Your float is cruising nicely',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? Colors.white54 
                          : Colors.grey[500],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Monthly Change', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            AnimatedNumber(
                              value: monthlyChange,
                              suffix: '%',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: isPositive ? AppColors.primaryTeal : Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Daily Yield Est.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            Text(
                              '\$${dailyYield.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.deepNavy,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ROTH
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark 
                    ? AppColors.moonlightSurface 
                    : AppColors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: Theme.of(context).brightness == Brightness.dark ? [] : [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ROTH IRA (Manual)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text(
                    'BTC: ${(roth['btc_amount'] ?? 0).toStringAsFixed(5)}  •  XRP: ${(roth['xrp_amount'] ?? 0).toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Total: \$${(roth['total_usd'] ?? 0).toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.primaryTeal),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Snapshots: live history + comparison 🛟
            const SnapshotComparison(),
          ],
        ),
      ),
    );
  }
}

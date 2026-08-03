import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/providers/portfolio_provider.dart';
import '../../shared/widgets/float_header.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';

class PortfolioScreen extends ConsumerWidget {
  const PortfolioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final portfolio = ref.watch(portfolioProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final totalValue = (portfolio['total_value'] as num?)?.toDouble() ?? 152581.0;
    final monthlyChange = (portfolio['monthly_change'] as num?)?.toDouble() ?? 12.4;
    final dailyYield = (portfolio['daily_yield_estimate_usd'] as num?)?.toDouble() ?? 412.0;
    final apy = (portfolio['apy'] as num?)?.toDouble() ?? 8.7;
    final isPositive = monthlyChange >= 0;

    final holdings = (portfolio['holdings'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final scopesWithStats = ref.watch(portfolioProvider.notifier).scopesWithStats;

    return Scaffold(
      appBar: AppBar(
        title: const FloatHeader(title: 'Portfolio', logoSize: 28),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero - cruise branding
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: isDark ? AppColors.moonlightGradient : AppColors.cruiseGradientLight,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryTeal.withOpacity(isDark ? 0.25 : 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('Total Float Value', style: TextStyle(fontSize: 14, color: Colors.white70)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                        child: const Text('🌊 LIVE', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('\$${totalValue.toStringAsFixed(0)}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(isPositive ? Icons.arrow_upward : Icons.arrow_downward, color: Colors.white70, size: 16),
                      const SizedBox(width: 4),
                      Text('${isPositive ? '+' : ''}${monthlyChange.toStringAsFixed(1)}% this month', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Quick stats
            Row(
              children: [
                _buildStatCard(context, 'Daily Yield', '\$${dailyYield.toStringAsFixed(0)}', '🌊', isDark),
                const SizedBox(width: 12),
                _buildStatCard(context, 'Est. APY', '${apy.toStringAsFixed(1)}%', '🏖️', isDark),
              ],
            ),

            const SizedBox(height: 24),

            // ENTIRE PORTFOLIO PIE - full net worth scope
            _buildPieSection(context, 'Entire Portfolio (Full Net Worth)', holdings, isDark, interactive: true, ref: ref),

            // CUSTOM SCOPES
            Text('Custom Scopes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: isDark ? AppColors.moonlightText : AppColors.deepNavy)),
            if (scopesWithStats.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2, bottom: 8),
                child: Text(
                  "${scopesWithStats.length} scopes • ${scopesWithStats.fold<double>(0.0, (sum, s) => sum + ((s['value_pct'] as num?)?.toDouble() ?? 0)).toStringAsFixed(1)}% of portfolio",
                  style: TextStyle(fontSize: 12, color: isDark ? AppColors.moonlightSilver : Colors.grey[600]),
                ),
              ),

            if (scopesWithStats.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: isDark ? AppColors.moonlightSurfaceAlt : AppColors.sand, borderRadius: BorderRadius.circular(16)),
                child: const Text('No custom scopes yet. Create one to group specific assets (e.g. Roth, Speculative, Coldkey only).', style: TextStyle(fontSize: 13)),
              )
            else
              ...scopesWithStats.map((scope) {
                final scopeHoldings = (scope['holdings'] as List?)?.cast<Map<String, dynamic>>() ?? [];
                final valuePct = (scope['value_pct'] as num?)?.toDouble() ?? 0.0;
                final scopeYield = (scope['daily_yield'] as num?)?.toDouble() ?? 0.0;
                return Column(
                  children: [
                    _buildPieSection(context, scope['name'] as String, scopeHoldings, isDark),
                    Padding(
                      padding: const EdgeInsets.only(top: 2, bottom: 2),
                      child: Row(
                        children: [
                          Text('${valuePct.toStringAsFixed(1)}% of portfolio', style: TextStyle(fontSize: 12, color: isDark ? AppColors.moonlightSilver : Colors.grey[600])),
                          if (scope.containsKey('target_pct')) Text('Target ${(scope['target_pct'] as num).toDouble().toStringAsFixed(0)}% (drift ${( (scope['drift'] ?? 0) as num).toDouble().toStringAsFixed(1)}%)', style: TextStyle(fontSize: 11, color: AppColors.primaryTeal)),
                          const Spacer(),
                          Text('Est. daily yield \$${scopeYield.toStringAsFixed(0)}', style: TextStyle(fontSize: 12, color: isDark ? AppColors.moonlightSilver : Colors.grey[600])),
                        ],
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => ref.read(portfolioProvider.notifier).deleteCustomScope(scope['id'] as String),
                        icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                        label: const Text('Delete Scope', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ).animate().fadeIn(duration: const Duration(milliseconds: 280)).slideY(begin: 0.04);
              }),

            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _showImportDialog(context, ref),
              icon: const Icon(Icons.cloud_download),
              label: const Text("Import from Exchange / Wallet"),
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.primaryTeal, side: BorderSide(color: AppColors.primaryTeal)),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: () => _showCreateScopeDialog(context, ref, holdings),
              icon: const Icon(Icons.add),
              label: const Text("Create New Scope"),
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.primaryTeal, side: BorderSide(color: AppColors.primaryTeal)),
            ),

            const SizedBox(height: 24),

            // Legacy detail cards
            Text('Your Holdings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: isDark ? AppColors.moonlightText : AppColors.deepNavy)),
            const SizedBox(height: 12),
            _buildHoldingCard(context, 'Coldkey Stake', '${(portfolio['total_stake'] as num?)?.toDouble() ?? 142.5} TAO', '\$${(totalValue * 0.85).toStringAsFixed(0)}', '🛟', isDark),
            const SizedBox(height: 10),
            _buildHoldingCard(context, 'ROTH IRA', 'Mixed Assets', '\$${(portfolio['roth_ira']?['total_usd'] as num?)?.toStringAsFixed(0) ?? '9,424'}', '🏝️', isDark),

            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: isDark ? AppColors.moonlightSurfaceAlt : AppColors.sand, borderRadius: BorderRadius.circular(16)),
              child: const Row(children: [
                Text('🌴', style: TextStyle(fontSize: 18)),
                SizedBox(width: 10),
                Expanded(child: Text('Track your full float with the main pie. Create custom scopes for specific strategies.', style: TextStyle(fontSize: 13))),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, String emoji, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.moonlightSurface : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: isDark ? AppColors.moonlightSurfaceAlt : Colors.grey.shade200),
          boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text(emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(fontSize: 13, color: isDark ? AppColors.moonlightSilver : Colors.grey[600])),
            ]),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: isDark ? AppColors.moonlightText : AppColors.deepNavy)),
          ],
        ),
      ),
    );
  }

  Widget _buildHoldingCard(BuildContext context, String title, String subtitle, String value, String emoji, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.moonlightSurface : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? AppColors.moonlightSurfaceAlt : Colors.grey.shade200),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.primaryTeal.withOpacity(0.12), borderRadius: BorderRadius.circular(12)), child: Text(emoji, style: const TextStyle(fontSize: 20))),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? AppColors.moonlightText : AppColors.deepNavy)),
          Text(subtitle, style: TextStyle(fontSize: 13, color: isDark ? AppColors.moonlightSilver : Colors.grey[600])),
        ])),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: isDark ? AppColors.moonlightText : AppColors.deepNavy)),
      ]),
    );
  }


  Widget _buildPieSection(BuildContext context, String title, List<Map<String, dynamic>> holdings, bool isDark, {bool interactive = false, WidgetRef? ref}) {
    if (holdings.isEmpty) return const SizedBox.shrink();
    final total = holdings.fold<double>(0, (sum, h) => sum + (h['value'] as num).toDouble());

    final sections = holdings.map((h) {
      final value = (h['value'] as num).toDouble();
      final pct = total > 0 ? (value / total * 100) : 0;
      return PieChartSectionData(
        color: isDark 
            ? Color(h['color'] as int)
            : Color.fromARGB(
                255,
                (Color(h['color'] as int).red * 0.82).round().clamp(0, 255),
                (Color(h['color'] as int).green * 0.82).round().clamp(0, 255),
                (Color(h['color'] as int).blue * 0.82).round().clamp(0, 255),
              ),
        value: value,
        title: '${pct.toStringAsFixed(0)}%',
        radius: 60,
        titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
        borderSide: BorderSide(
          color: isDark ? Colors.white.withOpacity(0.5) : Colors.black.withOpacity(0.4),
          width: 2.5,
        ),
      );
    }).toList();

    PieChartData chartData = PieChartData(
      sections: sections,
      centerSpaceRadius: 40,
      sectionsSpace: 2,
    );

    if (interactive && ref != null) {
      chartData = PieChartData(
        sections: sections,
        centerSpaceRadius: 40,
        sectionsSpace: 2,
        pieTouchData: PieTouchData(
          touchCallback: (FlTouchEvent event, pieTouchResponse) {
            if (event is FlTapUpEvent && pieTouchResponse != null && pieTouchResponse.touchedSection != null) {
              final index = pieTouchResponse.touchedSection!.touchedSectionIndex;
              if (index >= 0 && index < holdings.length) {
                final asset = holdings[index];
                _showMoveAssetDialog(context, ref, asset['name'] as String);
              }
            }
          },
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: isDark ? AppColors.moonlightText : AppColors.deepNavy)),
        if (interactive)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text('Tap a segment to move asset between scopes', style: TextStyle(fontSize: 11, color: isDark ? AppColors.moonlightSilver : Colors.grey[600])),
          ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: PieChart(chartData),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 6,
          children: holdings.map((h) {
            final value = (h['value'] as num).toDouble();
            final pct = total > 0 ? (value / total * 100) : 0;
            return GestureDetector(
              onTap: interactive && ref != null ? () => _showMoveAssetDialog(context, ref, h['name'] as String) : null,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 10, height: 10, decoration: BoxDecoration(color: Color(h['color'] as int), shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text('${h['name']} \$${value.toStringAsFixed(0)} (${pct.toStringAsFixed(0)}%)' + (h.containsKey('source') && h['source'] != null ? ' [${h['source']}]' : ''), style: TextStyle(fontSize: 12, color: isDark ? AppColors.moonlightSilver : Colors.grey[700])),
              ]),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Future<void> _showMoveAssetDialog(BuildContext context, WidgetRef ref, String assetName) async {
    final scopes = ref.read(portfolioProvider.notifier).allCustomScopes;
    final options = <String, String?>{'Unassign (remove from all scopes)': null};
    for (var s in scopes) {
      options[s['name'] as String] = s['id'] as String?;
    }

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Move $assetName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.entries.map((entry) {
            return ListTile(
              title: Text(entry.key),
              onTap: () {
                ref.read(portfolioProvider.notifier).moveAssetToScope(assetName, entry.value);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$assetName moved to ${entry.key}')),
                );
              },
            );
          }).toList(),
        ),
      ),
    );
  }


  Future<void> _showImportDialog(BuildContext context, WidgetRef ref) async {
    final exchangeOptions = ["Coinbase", "Kraken", "Binance", "Coldkey Wallet"];
    String selectedExchange = "Coinbase";
    final addressController = TextEditingController(text: "0x742d35Cc6634C0532925a3b844Bc454e4438f44e");
    final keyController = TextEditingController(text: "sk_live_••••••••••••••••");

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text("Import Assets"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedExchange,
                  items: exchangeOptions.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (v) => setState(() => selectedExchange = v!),
                  decoration: const InputDecoration(labelText: "Exchange / Wallet"),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(labelText: "Wallet Address", hintText: "Paste address"),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: keyController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: "API Key (optional)", hintText: "Paste key"),
                ),
                const SizedBox(height: 12),
                const Text("This is a demo import — assets will be tagged with the source and added to a new scope.", style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () {
                ref.read(portfolioProvider.notifier).simulateImport(
                  selectedExchange,
                  addressController.text.trim(),
                  keyController.text.trim(),
                );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Imported from $selectedExchange — new scope created!")),
                );
              },
              child: const Text("Import"),
            ),
          ],
        ),
      ),
    );
  }



  // ignore: unused_element
  Future<void> _showEditScopeDialog(BuildContext context, WidgetRef ref, Map<String, dynamic> scope) async {
    final nameController = TextEditingController(text: scope["name"] as String);
    final allHoldings = (ref.read(portfolioProvider)["holdings"] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final currentAssets = Set<String>.from((scope["asset_names"] as List?) ?? []);
    final selected = Set<String>.from(currentAssets);

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text("Edit ${scope["name"]}"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: "Scope Name")),
                const SizedBox(height: 12),
                const Text("Assets in this scope:", style: TextStyle(fontWeight: FontWeight.w600)),
                ...allHoldings.map((h) {
                  final name = h["name"] as String;
                  return CheckboxListTile(
                    value: selected.contains(name),
                    title: Text(name),
                    subtitle: Text("\$${(h["value"] as num).toStringAsFixed(0)}"),
                    onChanged: (v) {
                      setState(() {
                        if (v == true) selected.add(name); else selected.remove(name);
                      });
                    },
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () {
                ref.read(portfolioProvider.notifier).editCustomScope(
                  scope["id"] as String,
                  newName: nameController.text.trim().isNotEmpty ? nameController.text.trim() : null,
                  newAssetNames: selected.toList(),
                );
                Navigator.pop(ctx);
              },
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCreateScopeDialog(BuildContext context, WidgetRef ref, List<Map<String, dynamic>> allHoldings) async {
    final selected = <String>{};
    final nameController = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Create Custom Scope'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Scope Name (e.g. Roth, Speculative)')),
                const SizedBox(height: 12),
                const Text('Target % of portfolio:', style: TextStyle(fontWeight: FontWeight.w600)),
                StatefulBuilder(builder: (ctx2, setS) { double t = 25; return Column(children: [Slider(value: t, min:0,max:100, onChanged: (v){setS((){t=v;});}), Text('${t.round()}%')]); }),
                const SizedBox(height: 16),
                const Text('Select assets to include:', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                ...allHoldings.map((h) {
                  final name = h['name'] as String;
                  final checked = selected.contains(name);
                  return CheckboxListTile(
                    value: checked,
                    title: Text(name),
                    subtitle: Text('\$${(h['value'] as num).toStringAsFixed(0)}'),
                    onChanged: (v) {
                      setState(() {
                        if (v == true) {
                          selected.add(name);
                        } else {
                          selected.remove(name);
                        }
                      });
                    },
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.trim().isNotEmpty && selected.isNotEmpty) {
                  ref.read(portfolioProvider.notifier).createCustomScope(nameController.text.trim(), selected.toList(), targetPct: 25.0);
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  // ignore: unused_element

  // ignore: unused_element
  Widget _buildQuickScopeButton(BuildContext context, WidgetRef ref, String exchange, List<String> assetNames, String emoji) {
    return OutlinedButton(
      onPressed: () {
        ref.read(portfolioProvider.notifier).createExchangeScope(exchange, assetNames);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Created $exchange Scope with ${assetNames.join(', ')}"), duration: const Duration(seconds: 2)),
        );
      },
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryTeal,
        side: BorderSide(color: AppColors.primaryTeal),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(exchange),
        ],
      ),
    );
  }

  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/providers/alerts_provider.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/services/supabase_service.dart';
import '../../shared/widgets/float_header.dart';
import '../../shared/widgets/float_empty_state.dart';

class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      data: (user) {
        if (user == null) {
          return const Scaffold(
            body: Center(child: Text('Please log in')),
          );
        }

        final alertsAsync = ref.watch(alertsProvider(user.id));

        return Scaffold(
          appBar: AppBar(title: const FloatHeader(title: 'Alerts', logoSize: 28)),
          body: alertsAsync.when(
            data: (alerts) {
              if (alerts.isEmpty) {
                return const FloatEmptyState(
                  title: 'All quiet on the water',
                  subtitle: 'No alerts set yet — tap below to create one and relax.',
                  ctaText: '🌊  Set your first alert',
                  onCta: null,
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: alerts.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final alert = alerts[index];
                  final color = _getColorForType(alert.type);
                  final isDark = Theme.of(context).brightness == Brightness.dark;

                  return Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.moonlightSurface : AppColors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: isDark ? AppColors.moonlightSurfaceAlt : Colors.grey.shade200),
                      boxShadow: isDark ? [] : [
                        BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3)),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.notifications_active, color: color),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${alert.asset} • ${alert.type}' + (alert.asset.contains("Scope") || alert.asset.contains("Portfolio") ? " 🏝️" : ""),
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  color: isDark ? AppColors.moonlightText : AppColors.darkText,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(alert.condition, style: TextStyle(color: isDark ? AppColors.moonlightSilver : Colors.grey, fontSize: 15)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('Error: $error')),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showCreateAlertSheet(context, ref, user.id),
            icon: const Icon(Icons.add),
            label: const Text('🌊 New Alert'),
            backgroundColor: AppColors.primaryTeal,
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) => Scaffold(body: Center(child: Text('Error: $error'))),
    );
  }

  Color _getColorForType(String type) {
    switch (type.toLowerCase()) {
      case 'price':
        return AppColors.sunshineYellow;
      case 'apy':
        return AppColors.coral;
      default:
        return AppColors.primaryTeal;
    }
  }

  void _showCreateAlertSheet(BuildContext context, WidgetRef ref, String userId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _CreateAlertSheet(
        onCreate: (asset, type, condition) async {
          await SupabaseService.createAlert(
            userId: userId,
            asset: asset,
            type: type,
            condition: condition,
          );
          ref.invalidate(alertsProvider(userId));
          if (context.mounted) Navigator.pop(context);
        },
      ),
    );
  }
}

class _CreateAlertSheet extends StatefulWidget {
  final Function(String asset, String type, String condition) onCreate;

  const _CreateAlertSheet({required this.onCreate});

  @override
  State<_CreateAlertSheet> createState() => _CreateAlertSheetState();
}

class _CreateAlertSheetState extends State<_CreateAlertSheet> {
  final _assetController = TextEditingController();
  String _selectedType = 'APY';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Create New Alert', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),

          const Text('Asset', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _assetController,
            decoration: InputDecoration(
              hintText: 'ETH, BTC, USDC...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 20),

          const Text('Alert Type', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _AlertTypeChip('APY', AppColors.coral, _selectedType == 'APY', () => setState(() => _selectedType = 'APY')),
              _AlertTypeChip('Price', AppColors.sunshineYellow, _selectedType == 'Price', () => setState(() => _selectedType = 'Price')),
              _AlertTypeChip('Pool', AppColors.primaryTeal, _selectedType == 'Pool', () => setState(() => _selectedType = 'Pool')),
            ],
          ),
          const SizedBox(height: 24),

          ElevatedButton(
            onPressed: () {
              if (_assetController.text.isNotEmpty) {
                widget.onCreate(_assetController.text, _selectedType, 'Below threshold');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryTeal,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Create Alert', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _AlertTypeChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _AlertTypeChip(this.label, this.color, this.isSelected, this.onTap);

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      backgroundColor: color.withOpacity(0.15),
      selectedColor: color.withOpacity(0.3),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w500),
    );
  }
}
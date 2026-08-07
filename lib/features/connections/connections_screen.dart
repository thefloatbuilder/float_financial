import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/services/connection_service.dart';
import '../../shared/widgets/float_header.dart';

/// Provider: the user's saved connections (persisted locally).
final connectionsProvider =
    AsyncNotifierProvider<ConnectionsNotifier, List<UserConnection>>(
        ConnectionsNotifier.new);

class ConnectionsNotifier extends AsyncNotifier<List<UserConnection>> {
  @override
  Future<List<UserConnection>> build() => ConnectionService.loadConnections();

  Future<void> add(UserConnection c) async {
    await ConnectionService.addConnection(c);
    ref.invalidateSelf();
  }

  Future<void> remove(UserConnection c) async {
    await ConnectionService.removeConnection(c.platformId, address: c.address);
    ref.invalidateSelf();
  }
}

/// "Connections" tab — sync Float to every platform the user invests on.
/// Three tiers: address paste (self-custody), exchange API keys, and
/// brokerages via aggregator (requires Plaid/SnapTrade keys).
class ConnectionsScreen extends ConsumerWidget {
  const ConnectionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionsAsync = ref.watch(connectionsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const FloatHeader(title: 'Connections', logoSize: 28)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Connected accounts summary
          connectionsAsync.when(
            data: (connections) => _ConnectedSection(connections: connections),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          const SizedBox(height: 24),
          _SectionHeader(
            emoji: '🔐',
            title: 'Self-Custody & Hardware Wallets',
            subtitle: 'Paste a public address — read-only, nothing leaves your device.',
            isDark: isDark,
          ),
          ...ConnectionService.addressPlatforms.map((p) => _PlatformTile(platform: p)),

          const SizedBox(height: 24),
          _SectionHeader(
            emoji: '🏦',
            title: 'Crypto Exchanges',
            subtitle: 'Generate a read-only API key on the exchange and paste it here.',
            isDark: isDark,
          ),
          ...ConnectionService.apiKeyPlatforms.map((p) => _PlatformTile(platform: p)),

          const SizedBox(height: 24),
          _SectionHeader(
            emoji: '📈',
            title: 'Brokerages & Retirement',
            subtitle: 'Stocks, ETFs, IRAs, 401(k)s — synced via a secure aggregator.',
            isDark: isDark,
          ),
          ...ConnectionService.brokeragePlatforms.map((p) => _PlatformTile(platform: p)),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final bool isDark;

  const _SectionHeader({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$emoji  $title',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.moonlightText : AppColors.deepNavy,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12.5,
              color: isDark ? AppColors.moonlightSilver : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConnectedSection extends ConsumerWidget {
  final List<UserConnection> connections;
  const _ConnectedSection({required this.connections});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (connections.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.moonlightSurface : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: isDark ? AppColors.moonlightSurfaceAlt : Colors.grey.shade200),
        ),
        child: Column(
          children: [
            const Text('🌊', style: TextStyle(fontSize: 32)),
            const SizedBox(height: 8),
            Text(
              'Nothing connected yet',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: isDark ? AppColors.moonlightText : AppColors.darkText,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Link a wallet, exchange, or brokerage below and Float pulls it all into one net worth.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.moonlightSilver : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Connected (${connections.length})',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.moonlightText : AppColors.deepNavy,
          ),
        ),
        const SizedBox(height: 10),
        ...connections.map((c) {
          final platform = ConnectionService.byId(c.platformId);
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.moonlightSurface : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primaryTeal.withOpacity(0.35)),
            ),
            child: Row(
              children: [
                Text(platform?.icon ?? '🔗', style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        platform?.name ?? c.platformId,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: isDark ? AppColors.moonlightText : AppColors.darkText,
                        ),
                      ),
                      Text(
                        c.address != null
                            ? '${c.chain?.toUpperCase() ?? ''} • ${_shorten(c.address!)}'
                            : c.label,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.moonlightSilver : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Linked', style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.w700)),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  color: Colors.grey,
                  tooltip: 'Disconnect',
                  onPressed: () => ref.read(connectionsProvider.notifier).remove(c),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  static String _shorten(String addr) =>
      addr.length > 16 ? '${addr.substring(0, 8)}…${addr.substring(addr.length - 6)}' : addr;
}

class _PlatformTile extends ConsumerWidget {
  final PlatformConnector platform;
  const _PlatformTile({required this.platform});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.moonlightSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.moonlightSurfaceAlt : Colors.grey.shade200),
      ),
      child: ListTile(
        leading: Text(platform.icon, style: const TextStyle(fontSize: 26)),
        title: Text(
          platform.name,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.moonlightText : AppColors.darkText,
          ),
        ),
        subtitle: Text(
          platform.blurb,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? AppColors.moonlightSilver : Colors.grey.shade600,
          ),
        ),
        trailing: const Icon(Icons.add_circle_outline, color: AppColors.primaryTeal),
        onTap: () {
          switch (platform.tier) {
            case ConnectionTier.address:
              _showAddressSheet(context, ref, platform);
            case ConnectionTier.apiKey:
              _showApiKeySheet(context, ref, platform);
            case ConnectionTier.brokerage:
              _showBrokerageSheet(context, platform);
          }
        },
      ),
    );
  }

  void _showAddressSheet(BuildContext context, WidgetRef ref, PlatformConnector p) {
    final addressController = TextEditingController();
    String chain = p.addressHints.first;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Connect ${p.name}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              const Text(
                'Read-only — Float only watches the public address. Private keys never leave your wallet.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              if (p.addressHints.length > 1) ...[
                const Text('Network', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: p.addressHints.map((c) {
                    final label = switch (c) { 'btc' => 'Bitcoin', 'evm' => 'EVM (ETH/Base/etc)', 'sol' => 'Solana', _ => c };
                    return ChoiceChip(
                      label: Text(label),
                      selected: chain == c,
                      onSelected: (_) => setSheetState(() => chain = c),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],
              TextField(
                controller: addressController,
                decoration: InputDecoration(
                  hintText: 'Paste your public address',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final addr = addressController.text.trim();
                  if (addr.isEmpty) return;
                  await ref.read(connectionsProvider.notifier).add(UserConnection(
                        platformId: p.id,
                        label: p.name,
                        tier: p.tier,
                        addedAt: DateTime.now(),
                        address: addr,
                        chain: chain,
                      ));
                  if (sheetContext.mounted) Navigator.pop(sheetContext);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Connect', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showApiKeySheet(BuildContext context, WidgetRef ref, PlatformConnector p) {
    final keyController = TextEditingController();
    final secretController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 24,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Connect ${p.name}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(p.blurb, style: const TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 6),
            const Text(
              '⚠️ Read-only keys only — never enable trading or withdrawals. Keys are stored on this device only.',
              style: TextStyle(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: keyController,
              decoration: InputDecoration(
                hintText: 'API Key',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: secretController,
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'API Secret',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final key = keyController.text.trim();
                final secret = secretController.text.trim();
                if (key.isEmpty || secret.isEmpty) return;
                await ref.read(connectionsProvider.notifier).add(UserConnection(
                      platformId: p.id,
                      label: p.name,
                      tier: p.tier,
                      addedAt: DateTime.now(),
                      apiKey: key,
                      apiSecret: secret,
                    ));
                if (sheetContext.mounted) Navigator.pop(sheetContext);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryTeal,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Connect', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  void _showBrokerageSheet(BuildContext context, PlatformConnector p) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Connect ${p.name}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Text(
              '${p.name} syncs through a secure brokerage aggregator (Plaid / SnapTrade). '
              'Float\'s aggregator account isn\'t live yet — once it is, you\'ll tap here, '
              'log in on ${p.name}\'s own page, and holdings flow in automatically.',
              style: const TextStyle(fontSize: 13.5, color: Colors.grey, height: 1.4),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primaryTeal.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '🚧 Coming soon — notify me when brokerage sync is live.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primaryTeal),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

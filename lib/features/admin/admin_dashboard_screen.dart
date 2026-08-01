import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/providers/admin_clients_provider.dart';
import '../../shared/widgets/float_header.dart';
import 'client_detail_screen.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientsAsync = ref.watch(adminClientsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const FloatHeader(title: 'Admin', logoSize: 28),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            color: AppColors.deepNavy,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total AUM', style: TextStyle(color: Colors.white70, fontSize: 14)),
                SizedBox(height: 4),
                Text('\$300,470+', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('Clients loaded from Supabase', style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          Expanded(
            child: clientsAsync.when(
              data: (clients) {
                if (clients.isEmpty) {
                  return const Center(child: Text('No clients found'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: clients.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final client = clients[index];
                    final tier = client['tier'] ?? 'Drifter Deck';
                    final name = client['name'] ?? 'Unknown';
                    final email = client['email'] ?? '';

                    final isDark = Theme.of(context).brightness == Brightness.dark;
                    return GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ClientDetailScreen(client: client),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.moonlightSurface : AppColors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isDark ? AppColors.moonlightSurfaceAlt : Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppColors.primaryTeal.withOpacity(0.15),
                              child: Text(name[0], style: const TextStyle(color: AppColors.primaryTeal, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                      color: isDark ? AppColors.moonlightText : AppColors.darkText,
                                    ),
                                  ),
                                  Text(tier, style: const TextStyle(color: AppColors.primaryTeal, fontSize: 13)),
                                  if (email.isNotEmpty) Text(email, style: TextStyle(color: isDark ? AppColors.moonlightSilver : Colors.grey, fontSize: 12)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
    );
  }
}
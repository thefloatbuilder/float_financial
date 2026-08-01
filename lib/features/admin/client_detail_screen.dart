import 'package:flutter/material.dart';
import '../../shared/widgets/float_logo.dart';
import '../../shared/widgets/float_header.dart';
import '../../core/constants/app_colors.dart';

class ClientDetailScreen extends StatelessWidget {
  final Map<String, dynamic> client;

  const ClientDetailScreen({super.key, required this.client});

  @override
  Widget build(BuildContext context) {
    final name = client['name'] ?? 'Client';
    final email = client['email'] ?? '';
    final tier = client['tier'] ?? 'Drifter Deck';
    final portfolioValue = (client['portfolio_value'] as num?)?.toDouble() ?? 0.0;

    return Scaffold(
      appBar: AppBar(title: FloatHeader(title: name, logoSize: 26)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.primaryTeal.withOpacity(0.2),
              child: Text(name[0], style: const TextStyle(fontSize: 32, color: AppColors.primaryTeal)),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                FloatLogo(
                  size: 28,
                  animated: false,
                  showRipples: false,
                  showBubbles: false,
                  showExtraDecorations: false,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Theme.of(context).brightness == Brightness.dark ? AppColors.moonlightText : AppColors.darkText)),
                      Text(email, style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? AppColors.moonlightSilver : Colors.grey, fontSize: 16)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Chip(
              label: Text(tier),
              backgroundColor: AppColors.primaryTeal.withOpacity(0.15),
              labelStyle: const TextStyle(color: AppColors.primaryTeal),
            ),
            const SizedBox(height: 32),

            Text('Portfolio Value', style: TextStyle(fontSize: 16, color: Theme.of(context).brightness == Brightness.dark ? AppColors.moonlightSilver : Colors.grey)),
            Text(
              '\$${portfolioValue.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Theme.of(context).brightness == Brightness.dark ? AppColors.moonlightText : AppColors.darkText),
            ),

            const SizedBox(height: 40),
            Text('Recent Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Theme.of(context).brightness == Brightness.dark ? AppColors.moonlightText : AppColors.darkText)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark ? AppColors.moonlightSurface : AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? AppColors.moonlightSurfaceAlt : Colors.grey.shade200),
              ),
              child: Text('No recent activity yet', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? AppColors.moonlightSilver : Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }
}
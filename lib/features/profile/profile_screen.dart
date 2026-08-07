import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_config.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/providers/theme_provider.dart';
import '../../shared/services/supabase_service.dart';
import '../../shared/widgets/float_logo.dart';
import '../../shared/widgets/float_header.dart';
import '../../shared/widgets/app_loading.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const FloatHeader(title: 'Profile', logoSize: 28),
        elevation: 0,
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Please log in'));
          }

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 32),
                // Brand FloatLogo as profile accent (with subtle extra decor for fun)
                Stack(
                  alignment: Alignment.center,
                  children: [
                    FloatLogo(
                      size: 118,
                      animated: false,
                      showRipples: false,
                      showBubbles: true,
                      showExtraDecorations: true,
                    ),
                    CircleAvatar(
                      radius: 42,
                      backgroundColor: AppColors.primaryTeal.withOpacity(0.9),
                      child: Text(
                        user.name[0],
                        style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(user.name, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).brightness == Brightness.dark ? AppColors.moonlightText : AppColors.darkText)),
                Text(user.email, style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? AppColors.moonlightSilver : Colors.grey, fontSize: 16)),
                const SizedBox(height: 4),
                const Text(
                  '🌊 On cruise mode',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryTeal.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    user.tier,
                    style: const TextStyle(color: AppColors.primaryTeal, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 40),

                // Theme Toggle
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark ? AppColors.moonlightSurface : AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? AppColors.moonlightSurfaceAlt : Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('🏖️', style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 8),
                          Text(
                            'Appearance',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Theme.of(context).brightness == Brightness.dark ? AppColors.moonlightText : AppColors.darkText,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SegmentedButton<ThemeMode>(
                        segments: const [
                          ButtonSegment(value: ThemeMode.light, label: Text('Light'), icon: Icon(Icons.light_mode)),
                          ButtonSegment(value: ThemeMode.dark, label: Text('Dark'), icon: Icon(Icons.dark_mode)),
                          ButtonSegment(value: ThemeMode.system, label: Text('System'), icon: Icon(Icons.brightness_auto)),
                        ],
                        selected: {themeMode},
                        onSelectionChanged: (selection) {
                          ref.read(themeModeProvider.notifier).state = selection.first;
                        },
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await SupabaseService.signOut();
                      if (context.mounted) {
                        context.go('/');
                      }
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Log Out'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade50,
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    AppConfig.isDemoMode ? 'v1.0.0 — demo build' : 'v1.0.0',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.moonlightSilver
                          : Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
        loading: () => const Center(child: AppLoading()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }
}
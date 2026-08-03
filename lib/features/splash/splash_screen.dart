import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/widgets/float_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    // Give the animated logo time to play (matches video feel)
    await Future.delayed(const Duration(milliseconds: 1850));

    if (!mounted) return;

    // Check auth — safe when Supabase isn't initialized (demo mode)
    bool hasUser = false;
    try {
      final user = Supabase.instance.client.auth.currentUser;
      hasUser = user != null;
    } catch (_) {
      // Supabase not initialized — demo mode, go to login
      hasUser = false;
    }

    if (mounted) {
      if (hasUser) {
        context.go('/home');
      } else {
        context.go('/');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final backgroundGradient = isDark
        ? AppColors.moonlightGradient
        : const LinearGradient(
            colors: [
              Color(0xFFFFB347), // warm peach/orange
              Color(0xFFFF9A8B),
              Color(0xFF00C4CC), // crystal turquoise
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: backgroundGradient),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Reusable animated FloatLogo (video-inspired rainbow float + ripples + bubbles)
              const FloatLogo(
                size: 140,
                animated: true,
                showRipples: true,
                showBubbles: true,
              ),

              const SizedBox(height: 28),

              // Logo text
              Text(
                'Float Financial',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.moonlightText : Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Your Portfolio, On Cruise Mode',
                style: TextStyle(
                  color: isDark ? AppColors.moonlightSilver : Colors.white70,
                  fontSize: 16,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

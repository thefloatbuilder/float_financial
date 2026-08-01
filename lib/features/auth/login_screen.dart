import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_config.dart';
import '../../shared/widgets/float_logo.dart';
import '../../shared/services/supabase_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _signIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await SupabaseService.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      if (mounted) context.go('/home');
    } catch (e) {
      setState(() {
        _errorMessage = 'Login failed. Please check your credentials.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signUp() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Force name to "Marcus" for this flow
      final name = 'Marcus';
      await SupabaseService.signUpWithEmail(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        name,
      );
      if (mounted) {
        // In demo mode we bypass the "check email" step and go straight in
        context.go('/home');
      }
    } catch (e) {
      debugPrint('SIGNUP ERROR (demo): $e');
      // For demo mode, force through even if there's an error
      if (mounted) {
        context.go('/home');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark ? AppColors.moonlightGradient : AppColors.sunlightGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                FloatLogo(
                  size: 118,
                  animated: false,
                  showRipples: false,
                  showBubbles: true,
                  showExtraDecorations: true,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Float Financial',
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Your Portfolio, On Cruise Mode',
                  style: TextStyle(fontSize: 15, color: Colors.white70, fontWeight: FontWeight.w500),
                ),
                if (AppConfig.isDemoMode) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white30),
                    ),
                    child: const Text(
                      'DEMO MODE — mock data, no real backend',
                      style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                    ),
                  ),
                ],
                const SizedBox(height: 48),

                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    hintText: 'Email',
                    filled: true,
                    fillColor: isDark ? AppColors.moonlightSurface : Colors.white,
                    hintStyle: TextStyle(color: isDark ? AppColors.moonlightSilver : null),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: TextStyle(color: isDark ? AppColors.moonlightText : null),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'Password',
                    filled: true,
                    fillColor: isDark ? AppColors.moonlightSurface : Colors.white,
                    hintStyle: TextStyle(color: isDark ? AppColors.moonlightSilver : null),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: TextStyle(color: isDark ? AppColors.moonlightText : null),
                ),
                const SizedBox(height: 20),

                if (_errorMessage != null)
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                const SizedBox(height: 12),

                ElevatedButton(
                  onPressed: _isLoading ? null : _signIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? AppColors.moonlightAccent : Colors.white,
                    foregroundColor: isDark ? AppColors.moonlightBackground : AppColors.deepNavy,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: AppColors.primaryTeal)
                      : const Text('Sign In', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _isLoading ? null : _signUp,
                  child: Text(
                    'Create Account',
                    style: TextStyle(color: isDark ? AppColors.moonlightText : Colors.white, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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
  final _nameController = TextEditingController();
  bool _isLoading = false;
  bool _isSignUpMode = false;
  String? _errorMessage;
  String? _infoMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _infoMessage = null;
    });

    try {
      await SupabaseService.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      if (mounted) context.go('/home');
    } catch (e) {
      debugPrint('SIGNIN ERROR: $e');
      if (!mounted) return;
      final msg = e.toString().toLowerCase();
      setState(() {
        if (msg.contains('invalid login credentials') || msg.contains('invalid_credentials')) {
          _errorMessage = 'Wrong email or password.';
        } else if (msg.contains('email not confirmed')) {
          _errorMessage = 'Check your inbox — confirm your email first.';
        } else {
          _errorMessage = 'Sign-in failed. Check your connection and try again.';
        }
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
      _infoMessage = null;
    });

    try {
      final name = _nameController.text.trim().isEmpty
          ? _emailController.text.split('@').first
          : _nameController.text.trim();
      final response = await SupabaseService.signUpWithEmail(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        name,
      );
      if (!mounted) return;
      if (AppConfig.isDemoMode || response.session != null) {
        // Demo mode, or email confirmation disabled — session issued.
        context.go('/home');
      } else {
        // Email confirmation enabled on the project — tell the user to verify.
        setState(() {
          _isSignUpMode = false;
          _infoMessage = 'Account created! Confirm your email, then sign in.';
        });
      }
    } catch (e) {
      debugPrint('SIGNUP ERROR: $e');
      if (!mounted) return;
      final msg = e.toString().toLowerCase();
      setState(() {
        if (msg.contains('already registered') || msg.contains('user_already_exists')) {
          _errorMessage = 'That email is already registered — try signing in.';
        } else if (msg.contains('password')) {
          _errorMessage = 'Password too weak — use at least 6 characters.';
        } else if (msg.contains('email')) {
          _errorMessage = 'That doesn\'t look like a valid email address.';
        } else {
          _errorMessage = 'Sign-up failed. Check your connection and try again.';
        }
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            decoration: BoxDecoration(
              gradient: isDark ? AppColors.moonlightGradient : AppColors.sunlightGradient,
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight - MediaQuery.of(context).padding.vertical),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
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

                if (_isSignUpMode) ...[
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: 'Name',
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
                ],
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

                if (_infoMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      _infoMessage!,
                      style: const TextStyle(color: Colors.lightGreenAccent, fontWeight: FontWeight.w600),
                    ),
                  ),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ),
                const SizedBox(height: 4),

                ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : (_isSignUpMode ? _signUp : _signIn),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? AppColors.moonlightAccent : Colors.white,
                    foregroundColor: isDark ? AppColors.moonlightBackground : AppColors.deepNavy,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: AppColors.primaryTeal)
                      : Text(_isSignUpMode ? 'Create Account' : 'Sign In',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () => setState(() {
                            _isSignUpMode = !_isSignUpMode;
                            _errorMessage = null;
                            _infoMessage = null;
                          }),
                  child: Text(
                    _isSignUpMode ? 'Already have an account? Sign in' : 'Create Account',
                    style: TextStyle(color: isDark ? AppColors.moonlightText : Colors.white, fontSize: 16),
                  ),
                ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

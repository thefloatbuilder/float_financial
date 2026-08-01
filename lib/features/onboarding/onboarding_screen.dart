import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../shared/widgets/float_logo.dart';
import '../../core/constants/app_colors.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Welcome to Float',
      description: 'Your portfolio, floating easy. Smart tracking and consulting for the modern investor — on cruise mode.',
      color: AppColors.primaryTeal,
      useFloatLogo: true,
    ),
    OnboardingPage(
      icon: Icons.show_chart,
      title: 'Track Your Portfolio',
      description: 'See your total value, yield, and asset allocation in real time. 📈',
      color: AppColors.oceanBlue,
    ),
    OnboardingPage(
      icon: Icons.notifications_active,
      title: 'Smart Alerts',
      description: 'Get notified when prices, APYs, or pools hit your targets — so you can stay relaxed. 🛟',
      color: AppColors.coral,
    ),
    OnboardingPage(
      icon: Icons.star,
      title: 'Choose Your Tier',
      description: 'Drifter Deck, Buoy Brigade, or Captain\'s Current — unlock more as you grow.',
      color: AppColors.vibrantPurple,
      useFloatLogo: true,
    ),
  ];

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      context.go('/home');
    }
  }

  void _skip() {
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_currentPage];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark ? AppColors.moonlightGradient : AppColors.sunlightGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: TextButton(
                    onPressed: _skip,
                    child: Text(
                      'Skip',
                      style: TextStyle(color: isDark ? AppColors.moonlightText : Colors.white70),
                    ),
                  ),
                ),
                const Spacer(),
                if (page.useFloatLogo)
                  FloatLogo(
                    size: 140,
                    animated: false,
                    showRipples: false,
                    showBubbles: true,
                    showExtraDecorations: true,
                  )
                else
                  Icon(page.icon, size: 100, color: page.color),
                const SizedBox(height: 40),
                Text(
                  page.title,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.moonlightText : Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  page.description,
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? AppColors.moonlightSilver : Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: index == _currentPage
                            ? (isDark ? AppColors.moonlightAccent : Colors.white)
                            : (isDark ? AppColors.moonlightSurface : Colors.white.withOpacity(0.4)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? AppColors.moonlightAccent : Colors.white,
                    foregroundColor: isDark ? AppColors.moonlightBackground : AppColors.deepNavy,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    _currentPage == _pages.length - 1 ? 'Get Started' : 'Next',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
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

class OnboardingPage {
  final String title;
  final String description;
  final Color color;
  final bool useFloatLogo;
  final IconData? icon;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.color,
    this.useFloatLogo = false,
    this.icon,
  });
}

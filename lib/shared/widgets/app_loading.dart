import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Branded full-section loading indicator (teal spinner).
class AppLoading extends StatelessWidget {
  const AppLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryTeal),
      ),
    );
  }
}

/// A single shimmer "bone" — rounded rectangle that pulses while content loads.
class ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius = 8,
  });

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark
        ? AppColors.moonlightSurfaceAlt.withOpacity(0.6)
        : Colors.grey.shade300;
    final highlight = isDark
        ? AppColors.moonlightSurfaceAlt.withOpacity(0.25)
        : Colors.grey.shade100;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [base, highlight, base],
              stops: [
                0.0,
                _controller.value,
                1.0,
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Card-shaped shimmer placeholder matching the app's rounded-card style.
class ShimmerCard extends StatelessWidget {
  final double height;
  final EdgeInsetsGeometry padding;

  const ShimmerCard({
    super.key,
    this.height = 120,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: isDark ? AppColors.moonlightSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.moonlightSurfaceAlt : Colors.grey.shade200,
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ShimmerBox(width: 120, height: 14),
          ShimmerBox(width: 200, height: 24),
          ShimmerBox(width: 160, height: 14),
        ],
      ),
    );
  }
}

/// List-of-cards shimmer placeholder (for alerts-style list screens).
class ShimmerList extends StatelessWidget {
  final int itemCount;
  final double itemHeight;

  const ShimmerList({
    super.key,
    this.itemCount = 3,
    this.itemHeight = 84,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => ShimmerCard(height: itemHeight),
    );
  }
}

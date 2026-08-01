import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Reusable "Float" logo graphic based on the brand visuals.
/// 
/// - Rainbow inflatable float + yellow duck in water (from the provided images/video).
/// - Optional expanding ripples and rising bubbles/droplets (video-inspired).
/// - Optional extra on-brand decorations (starfish, sandcastle, shell, palm tree, beach ball) for empty states and fun moments.
/// - Automatically adapts to light (Sunlight) / dark (Moonlight) theme.
/// 
/// Usage:
///   FloatLogo(size: 140, animated: true)                          // splash / hero
///   FloatLogo(size: 80, animated: false, showExtraDecorations: true)  // empty states
///   FloatLogo(size: 48, animated: false)                          // header / small
///   FloatLogo(performance: 'positive') // calm green ripples
class FloatLogo extends StatefulWidget {
  final double size;
  final bool animated;
  final bool showRipples;
  final bool showBubbles;
  final bool showExtraDecorations;
  final String performance; // 'positive' (calm teal/green), 'negative' (choppier coral/red), 'neutral'

  const FloatLogo({
    super.key,
    this.size = 128,
    this.animated = true,
    this.showRipples = true,
    this.showBubbles = true,
    this.showExtraDecorations = false,
    this.performance = 'neutral',
  });

  @override
  State<FloatLogo> createState() => _FloatLogoState();
}

class _FloatLogoState extends State<FloatLogo> with TickerProviderStateMixin {
  late AnimationController? _rippleController;
  late AnimationController? _bubblesController;
  late AnimationController? _logoController;

  final List<_Bubble> _bubbles = [];

  @override
  void initState() {
    super.initState();

    if (widget.animated) {
      _rippleController = AnimationController(
        duration: const Duration(milliseconds: 1600),
        vsync: this,
      );

      _bubblesController = AnimationController(
        duration: const Duration(milliseconds: 2200),
        vsync: this,
      );

      _logoController = AnimationController(
        duration: const Duration(milliseconds: 900),
        vsync: this,
      );

      _createBubbles();

      _rippleController!.repeat();
      _bubblesController!.repeat();
      _logoController!.forward();
    }
  }

  void _createBubbles() {
    if (!widget.showBubbles) return;

    final positions = [
      const Offset(0.25, 0.75),
      const Offset(0.65, 0.82),
      const Offset(0.15, 0.88),
      const Offset(0.82, 0.70),
      const Offset(0.40, 0.92),
    ];

    for (int i = 0; i < positions.length; i++) {
      _bubbles.add(
        _Bubble(
          position: positions[i],
          delay: i * 280,
          size: 4.0 + (i % 3) * 1.5,
          controller: _bubblesController!,
        ),
      );
    }
  }

  @override
  void dispose() {
    _rippleController?.dispose();
    _bubblesController?.dispose();
    _logoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget graphic = SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Water surface glow
          Container(
            width: widget.size * 0.92,
            height: widget.size * 0.92,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(isDark ? 0.06 : 0.12),
            ),
          ),

          // Expanding ripples (video-style)
          if (widget.showRipples && widget.animated && _rippleController != null)
            AnimatedBuilder(
              animation: _rippleController!,
              builder: (context, child) {
                final rippleValue = _rippleController!.value;
                final intensity = widget.performance == 'negative' ? 1.25 : (widget.performance == 'positive' ? 0.9 : 1.0);
                final speed = widget.performance == 'negative' ? 1.15 : 1.0;

                return Stack(
                  alignment: Alignment.center,
                  children: List.generate(3, (index) {
                    final delay = index * 0.28;
                    final progress = ((rippleValue * speed) + delay) % 1.0;
                    final scale = 0.65 + (progress * 0.55 * intensity);
                    final opacity = (1.0 - progress * (widget.performance == 'negative' ? 0.9 : 1.0)).clamp(0.0, widget.performance == 'negative' ? 0.7 : 0.55);

                    Color rippleColor;
                    if (widget.performance == 'positive') {
                      rippleColor = isDark ? AppColors.moonlightAccent : AppColors.floatGreen;
                    } else if (widget.performance == 'negative') {
                      rippleColor = isDark ? AppColors.moonlightCoral : AppColors.coral;
                    } else {
                      rippleColor = isDark ? AppColors.moonlightAccent : Colors.white;
                    }

                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        width: widget.size * 0.92,
                        height: widget.size * 0.92,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: rippleColor.withOpacity(opacity),
                            width: widget.performance == 'negative' ? 2.9 : 2.1,
                          ),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),

          // Main circular pool graphic (rainbow float + duck)
          Container(
            width: widget.size * 0.92,
            height: widget.size * 0.92,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(isDark ? 0.08 : 0.18),
              boxShadow: [
                BoxShadow(
                  color: (isDark
                          ? AppColors.moonlightGlow
                          : Colors.white)
                      .withOpacity(isDark ? 0.32 : 0.35),
                  blurRadius: widget.size * (isDark ? 0.26 : 0.22),
                  spreadRadius: widget.size * (isDark ? 0.03 : 0.025),
                ),
              ],
            ),
            padding: EdgeInsets.all(widget.size * 0.06),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: isDark ? [
                  BoxShadow(
                    color: AppColors.moonlightGlow.withOpacity(0.18),
                    blurRadius: widget.size * 0.18,
                    spreadRadius: -2,
                  ),
                ] : null,
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/brand/float_raft_icon_source.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          // Animated bubbles / droplets
          if (widget.showBubbles && widget.animated)
            ..._bubbles.map((bubble) => _buildBubble(bubble, isDark)),

          // Extra on-brand decorations (starfish, sandcastle, shell)
          if (widget.showExtraDecorations)
            ..._buildExtraDecorations(isDark),
        ],
      ),
    );

    // Gentle logo settle animation (capture inner graphic to avoid closure cycle)
    if (widget.animated && _logoController != null) {
      final innerGraphic = graphic;
      graphic = AnimatedBuilder(
        animation: _logoController!,
        builder: (context, child) {
          final scale = 0.92 + (_logoController!.value * 0.08);
          return Transform.scale(scale: scale, child: innerGraphic);
        },
      );
    }

    return graphic;
  }

  List<Widget> _buildExtraDecorations(bool isDark) {
    final decorColor = isDark ? AppColors.moonlightSilver : AppColors.sunGold;
    final accentColor = isDark ? AppColors.moonlightAccent : AppColors.coral;

    return [
      // Palm tree (top-left)
      Positioned(
        top: widget.size * -0.12,
        left: widget.size * -0.10,
        child: Transform.rotate(
          angle: -0.35,
          child: Text(
            "🌴",
            style: TextStyle(
              fontSize: widget.size * 0.22,
              color: decorColor.withOpacity(0.8),
            ),
          ),
        ),
      ),

      // Starfish (top-right)
      Positioned(
        top: widget.size * -0.08,
        right: widget.size * -0.05,
        child: Transform.rotate(
          angle: 0.4,
          child: Text(
            "⭐",
            style: TextStyle(
              fontSize: widget.size * 0.18,
              color: decorColor.withOpacity(0.85),
            ),
          ),
        ),
      ),

      // Small sandcastle (bottom-left)
      Positioned(
        bottom: widget.size * -0.06,
        left: widget.size * -0.02,
        child: Transform.rotate(
          angle: -0.2,
          child: Text(
            "🏰",
            style: TextStyle(
              fontSize: widget.size * 0.16,
              color: accentColor.withOpacity(0.8),
            ),
          ),
        ),
      ),

      // Shell (bottom-right)
      Positioned(
        bottom: widget.size * -0.04,
        right: widget.size * 0.08,
        child: Text(
            "🐚",
            style: TextStyle(
              fontSize: widget.size * 0.14,
              color: decorColor.withOpacity(0.7),
            ),
        ),
      ),

      // Beach ball (far right)
      Positioned(
        top: widget.size * 0.12,
        right: widget.size * -0.14,
        child: Transform.rotate(
          angle: 0.2,
          child: Text(
            "🏐",
            style: TextStyle(
              fontSize: widget.size * 0.13,
              color: accentColor.withOpacity(0.85),
            ),
          ),
        ),
      ),
    ];
  }

  Widget _buildBubble(_Bubble bubble, bool isDark) {
    return AnimatedBuilder(
      animation: bubble.controller,
      builder: (context, child) {
        final t = ((bubble.controller.value * 1000 + bubble.delay) % 1000) / 1000.0;

        final dy = bubble.position.dy - (t * 0.45);
        final dx = bubble.position.dx + (0.08 * (t - 0.5));
        final opacity = (1.0 - t * 1.1).clamp(0.0, 0.85);
        final size = bubble.size * (0.7 + 0.6 * (1.0 - t));

        return Positioned(
          left: dx * widget.size,
          top: dy * widget.size,
          child: Opacity(
            opacity: opacity,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(isDark ? 0.65 : 0.75),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? AppColors.moonlightGlow.withOpacity(0.45) : Colors.white.withOpacity(0.3),
                  width: isDark ? 0.8 : 0.5,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Bubble {
  final Offset position;
  final int delay;
  final double size;
  final AnimationController controller;

  _Bubble({
    required this.position,
    required this.delay,
    required this.size,
    required this.controller,
  });
}

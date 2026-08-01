import 'package:flutter/material.dart';

class AnimatedNumber extends StatelessWidget {
  final num value;
  final String? prefix;
  final String? suffix;
  final TextStyle? style;
  final Duration duration;
  final Curve curve;

  const AnimatedNumber({
    super.key,
    required this.value,
    this.prefix,
    this.suffix,
    this.style,
    this.duration = const Duration(milliseconds: 620),
    this.curve = Curves.easeOutExpo,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: value.toDouble() * 0.65, end: value.toDouble()),
      duration: duration,
      curve: curve,
      builder: (context, animatedValue, child) {
        return Text(
          '${prefix ?? ''}${animatedValue.toStringAsFixed(0)}${suffix ?? ''}',
          style: style,
        );
      },
    );
  }
}

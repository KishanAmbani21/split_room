import 'package:flutter/material.dart';

import '../../../shared/theme/app_colors.dart';

class AnimatedCounter extends StatelessWidget {
  const AnimatedCounter({
    required this.value,
    required this.style,
    super.key,
    this.prefix = AppColors.currencySymbol,
    this.duration = const Duration(milliseconds: 900),
  });

  final double value;
  final TextStyle? style;
  final String prefix;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, child) {
        final display = animatedValue == animatedValue.truncateToDouble()
            ? animatedValue.toInt().toString()
            : animatedValue.toStringAsFixed(2);
        return Text('$prefix$display', style: style);
      },
    );
  }
}

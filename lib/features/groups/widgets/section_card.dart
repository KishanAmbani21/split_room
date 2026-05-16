import 'package:flutter/material.dart';

import '../../../shared/widgets/glass_card.dart';

class SectionCard extends StatelessWidget {
  const SectionCard({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(20),
    this.tint,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: padding,
      borderRadius: 22,
      tint: tint,
      child: child,
    );
  }
}

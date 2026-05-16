import 'package:flutter/material.dart';

enum SplitType {
  equal('Equal Split', Icons.pie_chart_outline_rounded, 'Split bills equally'),
  custom('Custom Split', Icons.tune_rounded, 'Set custom amounts per person'),
  percentage(
    'Percentage Split',
    Icons.percent_rounded,
    'Split by percentage shares',
  );

  const SplitType(this.label, this.icon, this.subtitle);

  final String label;
  final IconData icon;
  final String subtitle;
}

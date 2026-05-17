import 'package:flutter/material.dart';

enum SplitType {
  equal(
    'Split equally',
    Icons.groups_rounded,
    'Same amount for each selected member',
  ),
  shares(
    'By shares',
    Icons.pie_chart_rounded,
    'Use portions — e.g. 2 shares eats more than 1',
  ),
  percentage(
    'By percentage',
    Icons.percent_rounded,
    'Each member\'s share must add up to 100%',
  ),
  custom(
    'Exact amounts',
    Icons.edit_note_rounded,
    'Enter the exact amount each person owes',
  );

  const SplitType(this.label, this.icon, this.subtitle);

  final String label;
  final IconData icon;
  final String subtitle;

  /// Short hint shown under the split type cards.
  String get exampleHint {
    switch (this) {
      case SplitType.equal:
        return 'Example: ₹600 ÷ 3 people = ₹200 each';
      case SplitType.shares:
        return 'Example: 2:1:1 shares on ₹400 → ₹200, ₹100, ₹100';
      case SplitType.percentage:
        return 'Example: 50% + 30% + 20% = 100% of the bill';
      case SplitType.custom:
        return 'Example: You enter ₹250, ₹150, ₹200 manually';
    }
  }
}

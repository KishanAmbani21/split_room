import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';

class SplitwiseTabBar extends StatelessWidget {
  const SplitwiseTabBar({required this.controller, super.key});

  final TabController controller;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final muted = brightness == Brightness.dark
        ? AppColors.darkTextMuted
        : AppColors.lightTextMuted;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: brightness == Brightness.dark
              ? AppColors.darkMuted
              : AppColors.lightMuted,
          borderRadius: BorderRadius.circular(12),
        ),
        child: TabBar(
          controller: controller,
          dividerHeight: 0,
          indicatorSize: TabBarIndicatorSize.tab,
          indicator: BoxDecoration(
            color: AppColors.glassFill(brightness),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: AppColors.cardShadow(brightness),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          labelColor: AppColors.primaryColor(brightness),
          unselectedLabelColor: muted,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          tabs: const [
            Tab(text: 'Overall'),
            Tab(text: 'Paid by Me'),
            Tab(text: 'Others Paid'),
          ],
        ),
      ),
    );
  }
}

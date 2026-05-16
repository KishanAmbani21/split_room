import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/theme/app_colors.dart';
import '../providers/add_expense_provider.dart';

class ReceiptImagePicker extends ConsumerWidget {
  const ReceiptImagePicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(addExpenseProvider);
    final notifier = ref.read(addExpenseProvider.notifier);
    final hasImage = state.receiptImagePath != null;

    return Column(
      children: [
        GestureDetector(
          onTap: state.isSubmitting ? null : notifier.pickReceiptImage,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
            width: double.infinity,
            height: hasImage ? 160 : 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  AppColors.cyan.withValues(alpha: 0.12),
                  AppColors.blue.withValues(alpha: 0.08),
                ],
              ),
              border: Border.all(
                color: AppColors.cyan.withValues(alpha: 0.35),
                width: 1.5,
              ),
              image: hasImage
                  ? DecorationImage(
                      image: FileImage(File(state.receiptImagePath!)),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: hasImage
                ? Stack(
                    children: [
                      Positioned(
                        top: 8,
                        right: 8,
                        child: IconButton(
                          onPressed: state.isSubmitting
                              ? null
                              : notifier.clearReceiptImage,
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black54,
                          ),
                          icon: const Icon(Icons.close_rounded, color: Colors.white),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.cyan, AppColors.blue],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.receipt_long_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Tap to attach bill photo',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.cyan.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

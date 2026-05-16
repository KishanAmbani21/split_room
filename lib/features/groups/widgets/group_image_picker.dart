import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/theme/app_colors.dart';
import '../providers/create_group_provider.dart';

class GroupImagePicker extends ConsumerWidget {
  const GroupImagePicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(createGroupProvider);
    final notifier = ref.read(createGroupProvider.notifier);

    return Column(
      children: [
        GestureDetector(
          onTap: state.isSubmitting ? null : notifier.pickGroupImage,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
                width: 116,
                height: 116,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [
                      Color(0x334F8CFF),
                      Color(0x338B5CF6),
                      Color(0x3322D3EE),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: AppColors.blue.withValues(alpha: 0.35),
                    width: 2,
                  ),
                  image: state.groupImagePath != null
                      ? DecorationImage(
                          image: FileImage(File(state.groupImagePath!)),
                          fit: BoxFit.cover,
                        )
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.purple.withValues(alpha: 0.2),
                      blurRadius: 28,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: state.groupImagePath == null
                    ? const Icon(
                        Icons.groups_rounded,
                        size: 46,
                        color: AppColors.blue,
                      )
                    : null,
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: AppColors.primaryGradientLight,
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.blue.withValues(alpha: 0.35),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Tap to add group photo',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.blue.withValues(alpha: 0.75),
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

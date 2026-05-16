import 'package:flutter/material.dart';

import '../../../shared/theme/app_colors.dart';

class GradientCreateButton extends StatefulWidget {
  const GradientCreateButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  State<GradientCreateButton> createState() => _GradientCreateButtonState();
}

class _GradientCreateButtonState extends State<GradientCreateButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scale = Tween<double>(begin: 1, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onTap() async {
    if (widget.isLoading || widget.onPressed == null) return;
    await _controller.forward();
    await _controller.reverse();
    widget.onPressed!();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final enabled = !widget.isLoading && widget.onPressed != null;
    final primary = AppColors.primaryColor(brightness);

    return ScaleTransition(
      scale: _scale,
      child: Material(
        color: enabled ? primary : AppColors.lightBorder,
        borderRadius: BorderRadius.circular(12),
        elevation: enabled ? 2 : 0,
        shadowColor: primary.withValues(alpha: 0.35),
        child: InkWell(
          onTap: enabled ? _onTap : null,
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: Center(
              child: widget.isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      widget.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

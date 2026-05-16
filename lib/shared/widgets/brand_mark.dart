import 'package:flutter/material.dart';

import '../branding/app_branding.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({this.size = 64, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: scheme.inverseSurface,
        borderRadius: BorderRadius.circular(size * 0.24),
      ),
      padding: EdgeInsets.all(size * 0.16),
      child: Image.asset(
        AppBranding.logoAsset,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => Icon(
          Icons.account_balance_wallet_outlined,
          color: scheme.onInverseSurface,
          size: size * 0.52,
        ),
      ),
    );
  }
}

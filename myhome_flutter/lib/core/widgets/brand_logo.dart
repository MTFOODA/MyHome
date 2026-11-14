import 'package:flutter/material.dart';
import '../config/locale_config.dart';

/// Selected Arabic architectural logo, shared by navigation and account screens.
class BrandIcon extends StatelessWidget {
  final double size;
  const BrandIcon({super.key, this.size = 36});

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(size * .22),
    child: Image.asset(
      'assets/branding/app-icon.png',
      width: size,
      height: size,
      excludeFromSemantics: true,
      filterQuality: FilterQuality.medium,
    ),
  );
}

class BrandWordmark extends StatelessWidget {
  final double width;
  const BrandWordmark({super.key, this.width = 180});

  @override
  Widget build(BuildContext context) => Center(
    child: ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.asset(
        'assets/branding/wordmark.png',
        width: width,
        height: width * 2 / 3,
        fit: BoxFit.contain,
        semanticLabel: context.l10n.appName,
        filterQuality: FilterQuality.medium,
      ),
    ),
  );
}

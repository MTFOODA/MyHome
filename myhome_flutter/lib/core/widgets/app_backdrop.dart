import 'package:flutter/material.dart';

/// The UI/ui .jpeg reference: a soft upper glow fading into the app canvas.
class AppBackdrop extends StatelessWidget {
  final Widget child;
  const AppBackdrop({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF111C20) : const Color(0xFFF7F9F9),
        gradient: RadialGradient(
          center: const Alignment(0, -.65),
          radius: .95,
          colors: dark
              ? [const Color(0xFF254F55), const Color(0xFF111C20)]
              : [const Color(0xFFB2DCDE), const Color(0xFFF7F9F9)],
          stops: const [0, 1],
        ),
      ),
      child: child,
    );
  }
}

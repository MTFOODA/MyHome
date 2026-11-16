import 'package:flutter/material.dart';

enum ArchitecturalScene {
  corner('architecture-corner-v1'),
  balconies('architecture-balconies-v1'),
  courtyard('architecture-courtyard-v1');

  final String filename;
  const ArchitecturalScene(this.filename);
  String get asset => 'assets/backgrounds/$filename.webp';
}

/// Decorative only: no network requests, focus targets or blocked gestures.
/// The photo fades into the existing theme instead of competing with controls.
class ArchitecturalBackdrop extends StatelessWidget {
  final ArchitecturalScene scene;
  const ArchitecturalBackdrop({super.key, required this.scene});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final tint = dark ? const Color(0xFF10272D) : const Color(0xFFEAF5F4);
    return IgnorePointer(
      child: ExcludeSemantics(
        child: ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (rect) => const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Colors.white, Colors.transparent],
            stops: [0, .55, 1],
          ).createShader(rect),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                scene.asset,
                fit: BoxFit.cover,
                alignment: const Alignment(0, .25),
                filterQuality: FilterQuality.medium,
                errorBuilder: (_, _, _) => ColoredBox(color: tint),
              ),
              ColoredBox(color: tint.withValues(alpha: dark ? .70 : .76)),
            ],
          ),
        ),
      ),
    );
  }
}

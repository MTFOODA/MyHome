import 'package:flutter/material.dart';

/// Transparent, individually distinct miniatures; never used for tool icons.
class ChoiceArtwork extends StatelessWidget {
  static const asset = 'assets/illustrations/choice-atlas-v2.png';
  final String name;
  final double size;
  const ChoiceArtwork(this.name, {super.key, this.size = 64});

  static int? cellFor(String name) => switch (name) {
    'apartment' => 0,
    'studio' => 1,
    'duplex' => 2,
    'villa' => 3,
    'room' => 4,
    'sale_cash' => 5,
    'sale_installments' => 6,
    'private_rental' => 7,
    'shared_rental' => 8,
    'furnished' => 9,
    'unfurnished' => 10,
    'water' => 11,
    'electricity' => 12,
    'gas' => 13,
    'plastered' => 14,
    'consent' => 15,
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    final cell = cellFor(name);
    if (cell == null) return const SizedBox.shrink();
    return ExcludeSemantics(
      child: SizedBox(
        width: size,
        height: size,
        child: ClipRect(
          clipper: const _ArtworkCellClipper(),
          child: OverflowBox(
            alignment: Alignment(
              -1 + (cell % 4) * 2 / 3,
              -1 + (cell ~/ 4) * 2 / 3,
            ),
            minWidth: size * 4,
            maxWidth: size * 4,
            minHeight: size * 4,
            maxHeight: size * 4,
            child: Image.asset(
              asset,
              width: size * 4,
              height: size * 4,
              fit: BoxFit.fill,
              filterQuality: FilterQuality.medium,
            ),
          ),
        ),
      ),
    );
  }
}

// Keep neighboring-row edge pixels outside each independently displayed cell.
class _ArtworkCellClipper extends CustomClipper<Rect> {
  const _ArtworkCellClipper();
  @override
  Rect getClip(Size size) =>
      Rect.fromLTRB(0, size.height * .08, size.width, size.height);
  @override
  bool shouldReclip(covariant _ArtworkCellClipper oldClipper) => false;
}

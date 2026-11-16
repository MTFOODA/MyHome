import 'package:flutter/material.dart';

/// Transparent, individually distinct miniatures; never used for tool icons.
class ChoiceArtwork extends StatelessWidget {
  static const factsAsset = 'assets/illustrations/property-facts-v3.png';
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
    'area_m2' => 16,
    'bathrooms' => 17,
    'elevator' => 18,
    'red_brick' => 19,
    'lux' => 20,
    'super_lux' => 21,
    'ultra_super_lux' => 21,
    'one_year' => 22,
    'three_years' => 23,
    'five_years' => 24,
    'old_rent' => 25,
    'custom' => 26,
    'net' => 27,
    'gross' => 28,
    'capacity' => 29,
    'allHomes' => 30,
    'location' => 31,
    'buyer_cash' => 32,
    'buyer_installments' => 33,
    'tenant_private' => 34,
    'tenant_shared' => 35,
    'bedrooms' => 4,
    'total_beds' || 'available_beds' => 8,
    'custom_months' || 'installment_count' => 26,
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    if (name == 'ultra_super_lux') {
      return ExcludeSemantics(
        child: Image.asset(
          'assets/illustrations/ultra-finish-v1.png',
          width: size,
          height: size,
        ),
      );
    }
    final code = cellFor(name);
    if (code == null) return const SizedBox.shrink();
    final cell = code < 16 ? code : code - 16;
    final columns = code < 16 ? 4 : 5;
    return ExcludeSemantics(
      child: SizedBox(
        width: size,
        height: size,
        child: ClipRect(
          clipper: const _ArtworkCellClipper(),
          child: OverflowBox(
            alignment: Alignment(
              -1 + (cell % columns) * 2 / (columns - 1),
              -1 + (cell ~/ columns) * 2 / 3,
            ),
            minWidth: size * columns,
            maxWidth: size * columns,
            minHeight: size * 4,
            maxHeight: size * 4,
            child: Image.asset(
              code < 16 ? asset : factsAsset,
              width: size * columns,
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

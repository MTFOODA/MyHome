import 'package:flutter/material.dart';

/// Locally bundled artwork; each cell is clipped from one illustrated atlas.
class PropertyIllustration extends StatelessWidget {
  final String name;
  final double size;
  const PropertyIllustration(this.name, {super.key, this.size = 48});

  static int cell(String name) => switch (name) {
    'pricing' => 1,
    'utilities' => 7,
    'furnished' => 13,
    'net' || 'gross' || 'area_measurement' => 6,
    'total_beds' || 'available_beds' => 4,
    'custom_months' || 'installment_count' => 2,
    'governorate_id' ||
    'area_id' ||
    'approximate_location' ||
    'location_url' => 5,
    'title' || 'description' => 15,
    'sale_cash' || 'buyer_cash' || 'price' || 'negotiable' => 1,
    'sale_installments' || 'buyer_installments' || 'rental_period' => 2,
    'private_rental' || 'tenant_private' || 'room' => 3,
    'shared_rental' || 'tenant_shared' || 'beds' || 'capacity' => 4,
    'location' || 'governorate' || 'area' => 5,
    'dimensions' || 'area_m2' || 'bedrooms' || 'bathrooms' => 6,
    'water' => 7,
    'electricity' => 8,
    'gas' => 9,
    'elevator' => 10,
    'red_brick' => 11,
    'plastered' => 12,
    'lux' || 'finishing' => 13,
    'super_lux' => 14,
    'photos' || 'verification' || 'review' || 'documents' => 15,
    _ => 0,
  };

  @override
  Widget build(BuildContext context) {
    final navigation =
        name.startsWith('nav-') ||
        ['bedrooms', 'bathrooms', 'capacity'].contains(name);
    final index = navigation
        ? switch (name) {
            'bedrooms' => 0,
            'bathrooms' => 1,
            'capacity' => 2,
            _ => int.parse(name.substring(4)),
          }
        : cell(name.replaceFirst('owner_', ''));
    return ExcludeSemantics(
      child: Align(
        widthFactor: 1,
        heightFactor: 1,
        child: SizedBox.square(
          dimension: size,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(size * .24),
            child: OverflowBox(
              alignment: Alignment(
                -1 + (index % 4) * 2 / 3,
                -1 + (index ~/ 4) * 2 / 3,
              ),
              maxWidth: size * 4,
              maxHeight: size * 4,
              child: Image.asset(
                navigation
                    ? 'assets/illustrations/navigation-atlas.png'
                    : 'assets/illustrations/property-atlas.png',
                width: size * 4,
                height: size * 4,
                fit: BoxFit.fill,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Small controls keep familiar symbols with a visible color accent.
class ColorSymbol extends StatelessWidget {
  final IconData icon;
  final double size;
  const ColorSymbol(this.icon, {super.key, this.size = 22});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(7),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(12),
    ),
    child: AppImageIcon(icon, size: size),
  );
}

class AppImageIcon extends StatelessWidget {
  final IconData? icon;
  final double? size;
  final Color? color;
  final String? semanticLabel;
  final TextDirection? textDirection;
  const AppImageIcon(
    this.icon, {
    super.key,
    this.size,
    this.color,
    this.semanticLabel,
    this.textDirection,
  });
  static String artwork(IconData? icon) {
    if ({
      Icons.bed,
      Icons.bed_outlined,
      Icons.bedroom_parent_outlined,
    }.contains(icon)) {
      return 'nav-0';
    }
    if ({
      Icons.bathtub,
      Icons.bathtub_outlined,
      Icons.bathroom_outlined,
    }.contains(icon)) {
      return 'nav-1';
    }
    if ({
      Icons.person,
      Icons.person_outline,
      Icons.people,
      Icons.people_outline,
      Icons.groups_outlined,
      Icons.manage_accounts_outlined,
    }.contains(icon)) {
      return 'nav-2';
    }
    if ({
      Icons.favorite,
      Icons.favorite_border,
      Icons.star_outline,
      Icons.star_border,
    }.contains(icon)) {
      return 'nav-3';
    }
    if ({
      Icons.chat,
      Icons.chat_outlined,
      Icons.message_outlined,
      Icons.forum_outlined,
    }.contains(icon)) {
      return 'nav-4';
    }
    if ({Icons.call, Icons.phone, Icons.phone_outlined}.contains(icon)) {
      return 'nav-5';
    }
    if ({Icons.search, Icons.travel_explore_outlined}.contains(icon)) {
      return 'nav-6';
    }
    if ({Icons.tune, Icons.filter_alt_outlined}.contains(icon)) return 'nav-7';
    if ({
      Icons.history,
      Icons.schedule,
      Icons.access_time,
      Icons.calendar_month,
    }.contains(icon)) {
      return 'nav-8';
    }
    if ({
      Icons.arrow_back,
      Icons.arrow_back_rounded,
      Icons.arrow_upward,
      Icons.expand_less,
    }.contains(icon)) {
      return 'nav-9';
    }
    if ({
      Icons.arrow_forward,
      Icons.arrow_forward_rounded,
      Icons.chevron_right,
      Icons.expand_more,
      Icons.keyboard_arrow_down_rounded,
    }.contains(icon)) {
      return 'nav-10';
    }
    if ({
      Icons.add,
      Icons.add_circle_outline,
      Icons.add_photo_alternate_outlined,
    }.contains(icon)) {
      return 'nav-11';
    }
    if ({Icons.remove, Icons.remove_circle_outline}.contains(icon)) {
      return 'nav-12';
    }
    if ({
      Icons.check,
      Icons.check_circle_rounded,
      Icons.check_circle_outline,
      Icons.verified_outlined,
      Icons.verified_user_outlined,
      Icons.price_check,
      Icons.touch_app_outlined,
    }.contains(icon)) {
      return 'nav-13';
    }
    if ({
      Icons.close,
      Icons.cancel_outlined,
      Icons.visibility_off_outlined,
    }.contains(icon)) {
      return 'nav-14';
    }
    if ({Icons.settings, Icons.settings_outlined}.contains(icon)) {
      return 'nav-15';
    }
    if ({
      Icons.home,
      Icons.home_outlined,
      Icons.home_work_outlined,
      Icons.add_home_work_outlined,
    }.contains(icon)) {
      return 'home';
    }
    if ({Icons.square_foot, Icons.straighten}.contains(icon)) {
      return 'dimensions';
    }
    if ({
      Icons.location_on_outlined,
      Icons.map_outlined,
      Icons.edit_location_alt_outlined,
      Icons.translate,
    }.contains(icon)) {
      return 'location';
    }
    if ({
      Icons.payments_outlined,
      Icons.handshake_outlined,
      Icons.savings_outlined,
    }.contains(icon)) {
      return 'sale_cash';
    }
    return 'documents';
  }

  @override
  Widget build(BuildContext context) {
    Widget image = PropertyIllustration(
      artwork(icon),
      size: size ?? IconTheme.of(context).size ?? 24,
    );
    if ({Icons.arrow_upward, Icons.expand_less}.contains(icon)) {
      image = RotatedBox(quarterTurns: 1, child: image);
    } else if ({
      Icons.expand_more,
      Icons.keyboard_arrow_down_rounded,
    }.contains(icon)) {
      image = RotatedBox(quarterTurns: 1, child: image);
    }
    final opacity =
        (IconTheme.of(context).opacity ?? 1) *
        (color?.a ?? IconTheme.of(context).color?.a ?? 1) *
        (icon == Icons.favorite_border ? .5 : 1);
    if (opacity < 1) {
      image = Opacity(opacity: opacity.clamp(0, 1), child: image);
    }
    if ((icon?.matchTextDirection ?? false) &&
        (textDirection ?? Directionality.of(context)) == TextDirection.rtl) {
      image = Transform.flip(flipX: true, child: image);
    }
    return semanticLabel == null
        ? image
        : Semantics(label: semanticLabel, image: true, child: image);
  }
}

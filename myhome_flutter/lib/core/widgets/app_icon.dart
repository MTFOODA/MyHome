import 'package:flutter/material.dart';

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
    child: AppIcon(icon, size: size),
  );
}

/// Native symbols preserve direction, disabled state, contrast and semantics.
class AppIcon extends StatelessWidget {
  final IconData? icon;
  final double? size;
  final Color? color;
  final String? semanticLabel;
  final TextDirection? textDirection;
  const AppIcon(
    this.icon, {
    super.key,
    this.size,
    this.color,
    this.semanticLabel,
    this.textDirection,
  });
  @override
  Widget build(BuildContext context) => Icon(
    icon,
    size: size,
    color: color,
    semanticLabel: semanticLabel,
    textDirection: textDirection,
  );
}

/// Only meaningful, distinct symbols are shown for structured property answers.
class FeatureSymbol extends StatelessWidget {
  final String name;
  final double size;
  const FeatureSymbol(this.name, {super.key, this.size = 32});
  static IconData? iconFor(String name) => switch (name.replaceFirst(
    'owner_',
    '',
  )) {
    'apartment' => Icons.apartment_rounded,
    'studio' => Icons.weekend_outlined,
    'duplex' => Icons.stairs_outlined,
    'villa' => Icons.villa_outlined,
    'room' => Icons.bed_outlined,
    'home' || 'information' || 'category' => Icons.home_work_outlined,
    'sale_cash' ||
    'buyer_cash' ||
    'price' ||
    'pricing' => Icons.payments_outlined,
    'sale_installments' ||
    'buyer_installments' => Icons.calendar_month_outlined,
    'private_rental' || 'tenant_private' => Icons.key_outlined,
    'shared_rental' || 'tenant_shared' || 'capacity' => Icons.groups_outlined,
    'location' ||
    'governorate' ||
    'area' ||
    'area_id' ||
    'governorate_id' => Icons.location_on_outlined,
    'dimensions' ||
    'area_m2' ||
    'area_measurement' ||
    'net' ||
    'gross' => Icons.square_foot,
    'water' => Icons.water_drop_outlined,
    'electricity' => Icons.bolt_outlined,
    'gas' => Icons.local_fire_department_outlined,
    'utilities' => Icons.home_repair_service_outlined,
    'elevator' => Icons.elevator_outlined,
    'red_brick' => Icons.grid_view_outlined,
    'plastered' => Icons.format_paint_outlined,
    'lux' || 'finishing' => Icons.chair_outlined,
    'super_lux' => Icons.auto_awesome_outlined,
    'furnished' => Icons.weekend_outlined,
    'bedrooms' ||
    'beds' ||
    'total_beds' ||
    'available_beds' => Icons.bed_outlined,
    'bathrooms' => Icons.bathtub_outlined,
    'photos' => Icons.photo_library_outlined,
    'verification' || 'documents' => Icons.verified_user_outlined,
    'review' => Icons.fact_check_outlined,
    'title' => Icons.title,
    'description' => Icons.notes_outlined,
    'rental_period' ||
    'custom_months' ||
    'installment_count' => Icons.date_range_outlined,
    'negotiable' => Icons.handshake_outlined,
    'deposit' ||
    'down_payment' ||
    'installment_amount' => Icons.account_balance_wallet_outlined,
    _ => null,
  };
  @override
  Widget build(BuildContext context) {
    final icon = iconFor(name);
    if (icon == null) return const SizedBox.shrink();
    return Icon(icon, size: size, color: Theme.of(context).colorScheme.primary);
  }
}

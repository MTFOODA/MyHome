import 'package:flutter/widgets.dart';
import '../../../core/config/marketplace_strings.dart';
import '../domain/property_repository.dart';
import 'listing_cubit.dart';
import '../domain/structured_address.dart';

/// Creates factual copy from answers only; never invents amenities or an address.
void updateGeneratedDetails(
  BuildContext context,
  ListingCubit cubit,
  LocationCatalog? catalog,
) {
  final ar = Localizations.localeOf(context).languageCode == 'ar';
  String label(String key) => words(context, key);
  final area = catalog?.areas
      .where((a) => a.id == cubit.values['area_id'])
      .firstOrNull;
  final governorate = catalog?.governorates
      .where((g) => g.id == cubit.values['governorate_id'])
      .firstOrNull;
  final place = [
    if (area != null) ar ? area.nameAr : area.nameEn,
    if (governorate != null) ar ? governorate.nameAr : governorate.nameEn,
  ].join(' · ');
  cubit.values['approximate_location'] = structuredAddress(
    cubit.values,
    place,
    arabic: ar,
  );
  if (cubit.propertyKind == null) return;
  final kind = label(cubit.propertyKind!);
  final category = label(cubit.values['category']?.toString() ?? 'addProperty');
  final title = [kind, category, if (place.isNotEmpty) place].join(' · ');
  cubit.values['title'] = title.length > 150 ? title.substring(0, 150) : title;
  final details = <String>[
    '${label('propertyKind')}: $kind. $category.',
    if (place.isNotEmpty) '${label('location')}: $place.',
    for (final field in [
      'area_m2',
      'bedrooms',
      'bathrooms',
      if (cubit.values['category'] == 'shared_rental') 'capacity',
      'area_measurement',
      'finishing',
      'total_beds',
      'available_beds',
    ])
      if (cubit.values[field] != null)
        '${label(field)}: ${marketplaceWords.containsKey('${cubit.values[field]}') ? label('${cubit.values[field]}') : cubit.values[field]}.',
    for (final field in [
      'water',
      'electricity',
      'gas',
      'elevator',
      'furnished',
    ])
      if (cubit.values[field] is bool)
        '${label(field)}: ${label(cubit.values[field] == true ? 'yes' : 'no')}.',
  ];
  cubit.values['description'] = details.join('\n');
}

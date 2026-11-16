import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/choice_artwork.dart';
import 'package:flutter/material.dart';
import '../../../core/config/marketplace_strings.dart';
import '../domain/property_repository.dart';
import '../../sales/presentation/sales_strings.dart';
import 'property_photo.dart';

class PropertyCard extends StatelessWidget {
  final PropertySummary property;
  final PropertyRepository repository;
  final VoidCallback onDetails, onSave;
  final VoidCallback? onInterested;
  final bool saved, showSave;
  const PropertyCard({
    super.key,
    required this.property,
    required this.repository,
    required this.onDetails,
    required this.onSave,
    this.saved = false,
    this.showSave = true,
    this.onInterested,
  });
  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onDetails,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!property.unavailable)
              LayoutBuilder(
                builder: (context, constraints) => SizedBox(
                  height: (constraints.maxWidth * .56).clamp(180, 340),
                  child: PropertyPhoto(
                    category: property.category,
                    id: property.coverId,
                    repository: repository,
                    private: property.coverPrivate,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    words(context, property.category),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    property.title,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (property.unavailable) ...[
                    const SizedBox(height: 12),
                    Chip(
                      avatar: AppIcon(
                        property.availability == 'paused'
                            ? Icons.visibility_off_outlined
                            : Icons.info_outline,
                        size: 18,
                      ),
                      label: Text(
                        words(
                          context,
                          property.availability == 'unavailable'
                              ? 'listingUnavailable'
                              : property.availability,
                        ),
                      ),
                    ),
                  ],
                  if (!property.unavailable) ...[
                    const SizedBox(height: 8),
                    Text(ar ? property.locationAr : property.locationEn),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        for (final metric in [
                          ('area_m2', '${property.areaM2} m²'),
                          ('bedrooms', '${property.bedrooms}'),
                          ('bathrooms', '${property.bathrooms}'),
                        ])
                          Expanded(
                            child: Column(
                              children: [
                                ChoiceArtwork(metric.$1, size: 42),
                                const SizedBox(height: 6),
                                Text(metric.$2, textAlign: TextAlign.center),
                              ],
                            ),
                          ),
                      ],
                    ),
                    if (property.areaMeasurement != null)
                      Text(words(context, property.areaMeasurement!)),
                  ],
                  const SizedBox(height: 12),
                  if (property.unavailable) Text(words(context, 'savedPrice')),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          property.allIn
                              ? '${property.price} ${ar ? 'ج.م' : 'EGP'}'
                              : salesText(context, 'eligibilityPending'),
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (showSave)
                        IconButton(
                          onPressed: onSave,
                          tooltip: saved
                              ? words(context, 'remove')
                              : '${words(context, 'save')}\n${words(context, 'saveDisclosure')}',
                          icon: AppIcon(
                            saved ? Icons.favorite : Icons.favorite_border,
                          ),
                        ),
                    ],
                  ),
                  if (property.negotiable) Text(words(context, 'negotiable')),
                  if ([
                    'private_rental',
                    'shared_rental',
                  ].contains(property.category))
                    Text(
                      property.priceBasis == 'first_payment'
                          ? salesText(context, 'firstPayment')
                          : words(
                              context,
                              property.category == 'shared_rental'
                                  ? 'perBedMonth'
                                  : 'perMonth',
                            ),
                    ),
                  if (onInterested != null) ...[
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Tooltip(
                          message: words(context, 'visitorCount'),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const ExcludeSemantics(
                                child: AppIcon(
                                  Icons.visibility_outlined,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${property.visitorCount}',
                                semanticsLabel:
                                    '${words(context, 'visitorCount')}: ${property.visitorCount}',
                              ),
                            ],
                          ),
                        ),
                        Tooltip(
                          message: words(context, 'interestedPeople'),
                          child: TextButton.icon(
                            key: ValueKey('interested-${property.id}'),
                            onPressed: onInterested,
                            style: TextButton.styleFrom(
                              minimumSize: const Size(64, 48),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                            ),
                            icon: const ExcludeSemantics(
                              child: AppIcon(Icons.bookmark_border, size: 22),
                            ),
                            label: Text(
                              '${property.savedCount}',
                              semanticsLabel:
                                  '${words(context, 'savedCount')}: ${property.savedCount}',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

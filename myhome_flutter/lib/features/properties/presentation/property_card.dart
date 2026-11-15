import 'package:flutter/material.dart';
import '../../../core/config/marketplace_strings.dart';
import '../domain/property_repository.dart';
import '../../sales/presentation/sales_strings.dart';

class PropertyCard extends StatelessWidget {
  final PropertySummary property;
  final PropertyRepository repository;
  final VoidCallback onDetails, onSave;
  final bool saved, showSave;
  const PropertyCard({
    super.key,
    required this.property,
    required this.repository,
    required this.onDetails,
    required this.onSave,
    this.saved = false,
    this.showSave = true,
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
              SizedBox(
                height: 190,
                child: property.coverId == null
                    ? const Center(
                        child: Icon(Icons.home_work_outlined, size: 60),
                      )
                    : Image.network(
                        repository.photoUrl(property.coverId!),
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const Center(
                          child: Icon(Icons.broken_image_outlined),
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
                      avatar: Icon(
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
                    Wrap(
                      spacing: 12,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Icon(Icons.square_foot, size: 18),
                        Text('${property.areaM2} m²'),
                        const Icon(Icons.bed_outlined, size: 18),
                        Text('${property.bedrooms}'),
                        const Icon(Icons.bathtub_outlined, size: 18),
                        Text('${property.bathrooms}'),
                      ],
                    ),
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
                          tooltip: words(context, saved ? 'remove' : 'save'),
                          icon: Icon(
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

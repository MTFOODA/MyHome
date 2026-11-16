import 'package:flutter/material.dart';
import '../../../core/config/marketplace_strings.dart';
import '../../../core/config/price_text.dart';
import '../domain/property_repository.dart';
import 'property_photo.dart';
import '../../sales/presentation/sales_strings.dart';

class SimilarProperties extends StatefulWidget {
  final String propertyId;
  final PropertyRepository repository;
  final ValueChanged<String> onDetails;
  const SimilarProperties({
    super.key,
    required this.propertyId,
    required this.repository,
    required this.onDetails,
  });
  @override
  State<SimilarProperties> createState() => _SimilarPropertiesState();
}

class _SimilarPropertiesState extends State<SimilarProperties> {
  late Future<List<PropertySummary>> _items = widget.repository.similar(
    widget.propertyId,
  );
  @override
  Widget build(BuildContext context) => FutureBuilder<List<PropertySummary>>(
    future: _items,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        );
      }
      if (snapshot.hasError) {
        return Center(
          child: TextButton.icon(
            onPressed: () => setState(
              () => _items = widget.repository.similar(widget.propertyId),
            ),
            icon: const Icon(Icons.refresh),
            label: Text(words(context, 'retry')),
          ),
        );
      }
      final items = snapshot.data!;
      if (items.isEmpty) return const SizedBox.shrink();
      final ar = Localizations.localeOf(context).languageCode == 'ar';
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            words(context, 'keepExploring'),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            words(context, 'similarHomes'),
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, box) {
              final width = box.maxWidth >= 900
                  ? (box.maxWidth - 32) / 3
                  : box.maxWidth >= 540
                  ? (box.maxWidth - 16) / 2
                  : box.maxWidth;
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final item in items)
                      Padding(
                        padding: const EdgeInsetsDirectional.only(end: 16),
                        child: SizedBox(
                          width: width,
                          child: Card(
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: () => widget.onDetails(item.id),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  SizedBox(
                                    height: 205,
                                    child: PropertyPhoto(
                                      id: item.coverId,
                                      category: item.category,
                                      repository: widget.repository,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${ar ? item.locationAr : item.locationEn} · ${item.areaM2} m²',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall,
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          item.title,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleMedium,
                                        ),
                                        const SizedBox(height: 18),
                                        Text(
                                          item.allIn
                                              ? '${priceText(item.price)} ${ar ? 'ج.م' : 'EGP'}'
                                              : salesText(
                                                  context,
                                                  'eligibilityPending',
                                                ),
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleLarge,
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.bed_outlined,
                                              size: 18,
                                            ),
                                            const SizedBox(width: 6),
                                            Text('${item.bedrooms}'),
                                            const SizedBox(width: 18),
                                            const Icon(
                                              Icons.bathtub_outlined,
                                              size: 18,
                                            ),
                                            const SizedBox(width: 6),
                                            Text('${item.bathrooms}'),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      );
    },
  );
}

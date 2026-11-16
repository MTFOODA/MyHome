import 'package:flutter/material.dart';
import '../../../core/config/marketplace_strings.dart';

class PropertyFeaturesGrid extends StatelessWidget {
  final Map<String, dynamic> data;
  const PropertyFeaturesGrid({super.key, required this.data});
  static const icons = <String, IconData>{
    'electricity': Icons.bolt_outlined,
    'water': Icons.water_drop_outlined,
    'gas': Icons.local_fire_department_outlined,
    'internet': Icons.wifi,
    'elevator': Icons.elevator_outlined,
    'compound': Icons.holiday_village_outlined,
    'security': Icons.shield_outlined,
    'garage': Icons.local_parking,
  };
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        words(context, 'featuresUtilities'),
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: 6),
      Text(
        words(context, 'ownerDeclared'),
        style: Theme.of(context).textTheme.bodySmall,
      ),
      const SizedBox(height: 22),
      LayoutBuilder(
        builder: (context, box) {
          final columns = box.maxWidth >= 900
              ? 4
              : box.maxWidth >= 540
              ? 3
              : 2;
          final width = (box.maxWidth - 12 * (columns - 1)) / columns;
          final colors = Theme.of(context).colorScheme;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final entry in icons.entries)
                SizedBox(
                  width: width,
                  child: Container(
                    key: ValueKey('feature-${entry.key}'),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      border: Border.all(color: colors.outlineVariant),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: colors.primaryContainer.withValues(
                                  alpha: .55,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                entry.value,
                                color: colors.primary,
                                size: 24,
                              ),
                            ),
                            Icon(
                              data[entry.key] == true
                                  ? Icons.check_circle_outline
                                  : data[entry.key] == false
                                  ? Icons.cancel_outlined
                                  : Icons.help_outline,
                              size: 18,
                              color: data[entry.key] == true
                                  ? colors.primary
                                  : colors.onSurfaceVariant,
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Text(
                          words(
                            context,
                            marketplaceWords.containsKey('${entry.key}Label')
                                ? '${entry.key}Label'
                                : entry.key,
                          ),
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          words(
                            context,
                            data[entry.key] == true
                                ? 'yes'
                                : data[entry.key] == false
                                ? 'no'
                                : 'unspecified',
                          ),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    ],
  );
}

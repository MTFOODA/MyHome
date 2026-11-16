import 'package:flutter/material.dart';
import '../../../core/config/marketplace_strings.dart';

/// Nullable owner answers: skipping never implies that a feature is absent.
class ListingOptionalFeatures extends StatelessWidget {
  final Map<String, dynamic> values;
  final void Function(String, dynamic) onChanged;
  const ListingOptionalFeatures({
    super.key,
    required this.values,
    required this.onChanged,
  });

  static const icons = <String, IconData>{
    'compound': Icons.holiday_village_outlined,
    'security': Icons.shield_outlined,
    'internet': Icons.wifi,
    'garage': Icons.local_parking,
    'orientation': Icons.explore_outlined,
    'kitchen_type': Icons.kitchen_outlined,
  };

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Divider(height: 40),
      Text(
        words(context, 'optionalFeatures'),
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 8),
      Text(words(context, 'optionalFeaturesHint')),
      const SizedBox(height: 20),
      for (final entry in icons.entries) ...[
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  entry.value,
                  color: Theme.of(context).colorScheme.primary,
                  size: 30,
                ),
                const SizedBox(height: 10),
                Text(
                  words(context, entry.key),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 14),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final choice in <dynamic>[
                      null,
                      if (entry.key == 'orientation') ...[
                        'north',
                        'south',
                        'east',
                        'west',
                        'north_south',
                      ] else if (entry.key == 'kitchen_type') ...[
                        'closed_kitchen',
                        'american_kitchen',
                      ] else ...[
                        true,
                        false,
                      ],
                    ])
                      ChoiceChip(
                        key: ValueKey(
                          'optional-${entry.key}-${choice ?? 'unspecified'}',
                        ),
                        showCheckmark: false,
                        label: Text(
                          words(
                            context,
                            choice == null
                                ? 'unspecified'
                                : choice is bool
                                ? (choice ? 'yes' : 'no')
                                : choice as String,
                          ),
                        ),
                        selected: values[entry.key] == choice,
                        onSelected: (_) => onChanged(entry.key, choice),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    ],
  );
}

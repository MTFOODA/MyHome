import 'package:flutter/material.dart';
import '../../../core/widgets/choice_artwork.dart';

class PropertyFact {
  final String artwork, label, value;
  final bool muted;
  const PropertyFact(
    this.artwork,
    this.label,
    this.value, {
    this.muted = false,
  });
}

class PropertyFactsGrid extends StatelessWidget {
  final List<PropertyFact> facts;
  const PropertyFactsGrid({super.key, required this.facts});
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth >= 1000
          ? 5
          : constraints.maxWidth >= 720
          ? 4
          : constraints.maxWidth >= 450
          ? 3
          : 2;
      final width = (constraints.maxWidth - (columns - 1) * 16) / columns;
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          for (final fact in facts)
            SizedBox(
              width: width,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Opacity(
                        opacity: fact.muted ? .4 : 1,
                        child: ChoiceArtwork(fact.artwork, size: 76),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        fact.label,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        fact.value,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );
}

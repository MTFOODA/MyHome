import 'package:flutter/material.dart';
import 'app_layout.dart';
import 'app_icon.dart';
import 'choice_artwork.dart';

/// Whole-card selection with explicit semantics and no checkbox/radio ornament.
class SelectionTile extends StatelessWidget {
  final String label;
  final String? subtitle;
  final String artwork;
  final bool illustrated;
  final bool selected;
  final ValueChanged<bool>? onChanged;
  const SelectionTile({
    super.key,
    required this.label,
    this.subtitle,
    required this.artwork,
    this.illustrated = true,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      enabled: onChanged != null,
      child: AnimatedContainer(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: selected
              ? colors.primaryContainer
              : colors.surfaceContainerLow,
          border: Border.all(
            color: selected ? colors.primary : colors.outlineVariant,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onChanged == null ? null : () => onChanged!(!selected),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: AppLayout.wide(context) ? 112 : 84,
              ),
              child: Padding(
                padding: EdgeInsets.all(AppLayout.wide(context) ? 20 : 16),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final picture =
                        illustrated && ChoiceArtwork.cellFor(artwork) != null;
                    final symbol =
                        picture || FeatureSymbol.iconFor(artwork) != null;
                    final visual = picture
                        ? ChoiceArtwork(
                            artwork,
                            size: AppLayout.wide(context) ? 76 : 60,
                          )
                        : FeatureSymbol(artwork, size: 32);
                    final text = Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          label,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 6),
                          Text(subtitle!),
                        ],
                      ],
                    );
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (symbol) ...[visual, const SizedBox(height: 12)],
                        text,
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

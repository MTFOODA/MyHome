import 'package:flutter/material.dart';
import '../../../core/config/marketplace_strings.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/app_layout.dart';

class ListingChoice extends StatelessWidget {
  final String label, illustration;
  final bool selected;
  final VoidCallback? onTap;
  const ListingChoice({
    super.key,
    required this.label,
    required this.illustration,
    required this.selected,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      child: AnimatedContainer(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: selected
              ? colors.primaryContainer
              : colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? colors.primary : colors.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: AppLayout.wide(context) ? 112 : 84,
              ),
              child: Padding(
                padding: EdgeInsets.all(AppLayout.wide(context) ? 22 : 16),
                child: Row(
                  children: [
                    if (FeatureSymbol.iconFor(illustration) != null) ...[
                      FeatureSymbol(
                        illustration,
                        size: AppLayout.wide(context) ? 40 : 30,
                      ),
                      const SizedBox(width: 16),
                    ],
                    Expanded(
                      child: Text(
                        label,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (selected)
                      const AppIcon(Icons.check_circle_rounded)
                    else
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: colors.outline),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ListingChoiceGrid extends StatelessWidget {
  final List<Widget> children;
  final bool compact;
  const ListingChoiceGrid({
    super.key,
    required this.children,
    this.compact = false,
  });
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = compact && constraints.maxWidth >= 260
          ? 2
          : children.length >= 5 && constraints.maxWidth >= 1000
          ? 3
          : constraints.maxWidth >= 560
          ? 2
          : 1;
      final width = (constraints.maxWidth - (columns - 1) * 16) / columns;
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          for (final child in children) SizedBox(width: width, child: child),
        ],
      );
    },
  );
}

/// Counts can be selected precisely without opening a keyboard.
class ListingQuantity extends StatelessWidget {
  final String field;
  final int? value;
  final int minimum, maximum;
  final List<int> presets;
  final ValueChanged<int> onChanged;
  const ListingQuantity({
    super.key,
    required this.field,
    required this.value,
    required this.onChanged,
    this.minimum = 1,
    this.maximum = 100,
    this.presets = const [1, 2, 3, 4],
  });

  Future<void> _choose(BuildContext context) async {
    var selected = (value ?? minimum).clamp(minimum, maximum);
    final controller = FixedExtentScrollController(
      initialItem: selected - minimum,
    );
    final result = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: SizedBox(
          height: 330,
          child: Column(
            children: [
              Text(
                words(context, field),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Expanded(
                child: ListWheelScrollView.useDelegate(
                  controller: controller,
                  itemExtent: 48,
                  physics: const FixedExtentScrollPhysics(),
                  onSelectedItemChanged: (index) => selected = index + minimum,
                  childDelegate: ListWheelChildBuilderDelegate(
                    childCount: maximum - minimum + 1,
                    builder: (_, index) => Center(
                      child: Text(
                        '${index + minimum}',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton.icon(
                  onPressed: () => Navigator.pop(sheetContext, selected),
                  icon: const AppIcon(Icons.check_circle_outline),
                  label: Text(words(context, 'chooseValue')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    controller.dispose();
    if (result != null) onChanged(result);
  }

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 16),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              FeatureSymbol(field),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  words(context, field),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              IconButton(
                tooltip: words(context, 'decrease'),
                key: ValueKey('decrease-$field'),
                onPressed: value == null || value! <= minimum
                    ? null
                    : () => onChanged(value! - 1),
                icon: const ColorSymbol(Icons.remove),
              ),
              Expanded(
                child: TextButton(
                  key: ValueKey('choose-$field'),
                  onPressed: () => _choose(context),
                  child: Text(
                    value?.toString() ?? words(context, 'chooseValue'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
              IconButton(
                tooltip: words(context, 'increase'),
                key: ValueKey('increase-$field'),
                onPressed: value != null && value! >= maximum
                    ? null
                    : () => onChanged(value == null ? minimum : value! + 1),
                icon: const ColorSymbol(Icons.add),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              for (final number in presets.where(
                (n) => n >= minimum && n <= maximum,
              ))
                ChoiceChip(
                  key: ValueKey('$field-$number'),
                  label: Text('$number'),
                  selected: value == number,
                  onSelected: (_) => onChanged(number),
                ),
            ],
          ),
        ],
      ),
    ),
  );
}

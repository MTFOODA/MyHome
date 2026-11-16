import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/input/number_input.dart' as number_input;
import '../../../core/config/marketplace_strings.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/choice_artwork.dart';
import '../../../core/widgets/selection_tile.dart';

class ListingChoice extends StatelessWidget {
  final String label, illustration;
  final bool selected;
  final bool illustrated;
  final VoidCallback? onTap;
  const ListingChoice({
    super.key,
    required this.label,
    required this.illustration,
    required this.selected,
    this.illustrated = true,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => SelectionTile(
    label: label,
    artwork: illustration,
    illustrated: illustrated,
    selected: selected,
    onChanged: onTap == null ? null : (_) => onTap!(),
  );
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

/// Unsigned numeric input with optional common-value shortcuts.
class ListingQuantity extends StatefulWidget {
  final String field;
  final int? value;
  final int minimum, maximum;
  final List<int> presets;
  final ValueChanged<int?> onChanged;
  const ListingQuantity({
    super.key,
    required this.field,
    required this.value,
    required this.onChanged,
    this.minimum = 1,
    this.maximum = 100,
    this.presets = const [1, 2, 3, 4],
  });

  @override
  State<ListingQuantity> createState() => _ListingQuantityState();
}

class _ListingQuantityState extends State<ListingQuantity> {
  late final TextEditingController _input = TextEditingController(
    text: widget.value?.toString() ?? '',
  );
  @override
  void didUpdateWidget(covariant ListingQuantity oldWidget) {
    super.didUpdateWidget(oldWidget);
    final entered = int.tryParse(number_input.latinDigits(_input.text));
    if (widget.value != oldWidget.value && widget.value != entered) {
      _input.text = widget.value?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  String get field => widget.field;
  int? get value => widget.value;
  int get minimum => widget.minimum;
  int get maximum => widget.maximum;
  List<int> get presets => widget.presets;
  ValueChanged<int?> get onChanged => widget.onChanged;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 16),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              if (ChoiceArtwork.cellFor(field) != null)
                ChoiceArtwork(field, size: 68),
              const SizedBox(height: 10),
              Text(
                words(context, field),
                style: Theme.of(context).textTheme.titleMedium,
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
                child: TextFormField(
                  key: ValueKey('choose-$field'),
                  controller: _input,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩۰-۹]')),
                    LengthLimitingTextInputFormatter(4),
                  ],
                  decoration: InputDecoration(
                    hintText: words(context, 'enterNumber'),
                    helperText: '$minimum – $maximum',
                    errorText:
                        value != null && (value! < minimum || value! > maximum)
                        ? words(context, 'invalidField:$field')
                        : null,
                  ),
                  onChanged: (text) {
                    final number = int.tryParse(number_input.latinDigits(text));
                    onChanged(number);
                  },
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

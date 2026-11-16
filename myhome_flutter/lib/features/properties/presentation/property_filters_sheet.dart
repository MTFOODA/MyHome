import '../../../core/widgets/app_icon.dart';
import 'listing_choices.dart';
import 'package:flutter/material.dart';
import '../../../core/config/marketplace_strings.dart';
import '../../../core/input/number_input.dart';
import '../domain/property_repository.dart';

class PropertyFiltersSheet extends StatefulWidget {
  final Map<String, dynamic> applied;
  final LocationCatalog? catalog;
  final Future<LocationCatalog> Function() loadLocations;
  const PropertyFiltersSheet({
    super.key,
    required this.applied,
    required this.catalog,
    required this.loadLocations,
  });
  @override
  State<PropertyFiltersSheet> createState() => _PropertyFiltersSheetState();
}

class _PropertyFiltersSheetState extends State<PropertyFiltersSheet> {
  late final Map<String, dynamic> _draft;
  late final TextEditingController _min, _max, _area;
  LocationCatalog? _catalog;
  bool _loading = false, _failed = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _draft = Map.of(widget.applied);
    if (![
      'lux',
      'super_lux',
      'ultra_super_lux',
    ].contains(_draft['finishing'])) {
      _draft.remove('furnished');
    }
    _catalog = widget.catalog;
    _min = TextEditingController(text: _draft['min_price']?.toString() ?? '');
    _max = TextEditingController(text: _draft['max_price']?.toString() ?? '');
    _area = TextEditingController(text: _draft['min_area']?.toString() ?? '');
    if (_catalog == null) _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final catalog = await widget.loadLocations();
      if (mounted) setState(() => _catalog = catalog);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _min.dispose();
    _max.dispose();
    _area.dispose();
    super.dispose();
  }

  void _set(String key, String? value) {
    setState(() {
      if (value == null || value.isEmpty) {
        _draft.remove(key);
      } else {
        _draft[key] =
            [
              'water',
              'electricity',
              'gas',
              'elevator',
              'negotiable',
              'furnished',
            ].contains(key)
            ? value == 'true'
            : value;
      }
      if (key == 'governorate_id') _draft.remove('area_id');
      if (key == 'finishing' &&
          !['lux', 'super_lux', 'ultra_super_lux'].contains(value)) {
        _draft.remove('furnished');
      }
    });
  }

  void _apply() {
    final numeric = {
      'min_price': _min.text,
      'max_price': _max.text,
      'min_area': _area.text,
    };
    for (final entry in numeric.entries) {
      final text = latinDigits(entry.value.trim());
      final value = num.tryParse(text);
      if (text.isNotEmpty && (value == null || !value.isFinite || value < 0)) {
        setState(() => _error = 'invalid');
        return;
      }
      if (text.isEmpty) {
        _draft.remove(entry.key);
      } else {
        _draft[entry.key] = text;
      }
    }
    if (_draft['min_price'] != null &&
        _draft['max_price'] != null &&
        num.parse(_draft['min_price'].toString()) >
            num.parse(_draft['max_price'].toString())) {
      setState(() => _error = 'invalid');
      return;
    }
    Navigator.pop(context, Map<String, dynamic>.of(_draft));
  }

  Widget _select(String key, String label, List<(String, String)> options) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: DropdownButtonFormField<String>(
          key: ValueKey('filter-$key:${_draft[key]}'),
          initialValue: _draft[key]?.toString() ?? '',
          isExpanded: true,
          decoration: InputDecoration(labelText: words(context, label)),
          items: [
            DropdownMenuItem(value: '', child: Text(words(context, 'all'))),
            ...options.map(
              (option) =>
                  DropdownMenuItem(value: option.$1, child: Text(option.$2)),
            ),
          ],
          onChanged: (value) => _set(key, value),
        ),
      );
  Widget _section(String key, IconData icon, List<Widget> children) =>
      ExpansionTile(
        key: ValueKey('filter-section-$key'),
        tilePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        childrenPadding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
        shape: const Border(),
        collapsedShape: const Border(),
        leading: AppIcon(icon),
        title: Text(
          words(context, key),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        children: children,
      );
  Widget _number(String key, TextEditingController controller) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextField(
      key: ValueKey('filter-$key'),
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: words(context, key)),
    ),
  );
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 12, 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  words(context, 'filters'),
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                key: const Key('closeFilters'),
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                onPressed: () => Navigator.pop(context),
                icon: const AppIcon(Icons.close),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
                  child: DropdownButtonFormField<String>(
                    key: ValueKey('sort:${_draft['sort']}'),
                    initialValue: _draft['sort'] as String? ?? 'newest',
                    decoration: InputDecoration(
                      labelText: words(context, 'sort'),
                    ),
                    isExpanded: true,
                    items: ['newest', 'price_asc', 'price_desc']
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(words(context, value)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => _set('sort', value),
                  ),
                ),
                const Divider(height: 28),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        words(context, 'category'),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 16),
                      ListingChoiceGrid(
                        children: [
                          for (final category in [
                            'sale_cash',
                            'sale_installments',
                            'private_rental',
                            'shared_rental',
                          ])
                            ListingChoice(
                              key: ValueKey('filter-type-$category'),
                              label: words(context, category),
                              illustration: category,
                              selected: _draft['category'] == category,
                              onTap: () => _set(
                                'category',
                                _draft['category'] == category
                                    ? null
                                    : category,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                _section('location', Icons.location_on_outlined, [
                  if (_loading) const LinearProgressIndicator(),
                  if (_failed)
                    TextButton(
                      onPressed: _load,
                      child: Text(words(context, 'retry')),
                    ),
                  _select(
                    'governorate_id',
                    'governorate',
                    (_catalog?.governorates ?? [])
                        .map((g) => (g.id, ar ? g.nameAr : g.nameEn))
                        .toList(),
                  ),
                  _select(
                    'area_id',
                    'area',
                    (_catalog?.areas ?? [])
                        .where(
                          (a) => a.governorateId == _draft['governorate_id'],
                        )
                        .map((a) => (a.id, ar ? a.nameAr : a.nameEn))
                        .toList(),
                  ),
                ]),
                const Divider(height: 1, indent: 24, endIndent: 24),
                _section('priceAndSpace', Icons.payments_outlined, [
                  _number('minPrice', _min),
                  _number('maxPrice', _max),
                  _number('minimumArea', _area),
                  _select('negotiable', 'negotiable', [
                    ('true', words(context, 'yes')),
                    ('false', words(context, 'no')),
                  ]),
                ]),
                const Divider(height: 1, indent: 24, endIndent: 24),
                _section('roomsAndCapacity', Icons.bed_outlined, [
                  _select(
                    'bedrooms',
                    'bedrooms',
                    List.generate(7, (i) => ('$i', '$i')),
                  ),
                ]),
                const Divider(height: 1, indent: 24, endIndent: 24),
                _section('utilities', Icons.tune, [
                  for (final key in ['water', 'electricity', 'gas', 'elevator'])
                    _select(key, key, [
                      ('true', words(context, 'yes')),
                      ('false', words(context, 'no')),
                    ]),
                ]),
                const Divider(height: 1, indent: 24, endIndent: 24),
                _section('finishingAndTerms', Icons.format_paint_outlined, [
                  _select(
                    'finishing',
                    'finishing',
                    [
                      'red_brick',
                      'plastered',
                      'lux',
                      'super_lux',
                      'ultra_super_lux',
                    ].map((key) => (key, words(context, key))).toList(),
                  ),
                  if ([
                    'lux',
                    'super_lux',
                    'ultra_super_lux',
                  ].contains(_draft['finishing'])) ...[
                    Text(
                      words(context, 'furnished'),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    ListingChoiceGrid(
                      children: [
                        for (final value in [null, true, false])
                          ListingChoice(
                            key: ValueKey('filter-furnished-${value ?? 'all'}'),
                            label: words(
                              context,
                              value == null
                                  ? 'all'
                                  : value
                                  ? 'furnishedOption'
                                  : 'unfurnishedOption',
                            ),
                            illustration: value == null
                                ? ''
                                : value
                                ? 'furnished'
                                : 'unfurnished',
                            selected: _draft['furnished'] == value,
                            onTap: () => _set('furnished', value?.toString()),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  _select(
                    'rental_period',
                    'rental_period',
                    [
                      'one_year',
                      'three_years',
                      'five_years',
                      'old_rent',
                      'custom',
                    ].map((key) => (key, words(context, key))).toList(),
                  ),
                ]),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
        SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              24,
              16,
              24,
              16 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Semantics(
                      liveRegion: true,
                      child: Text(
                        words(context, _error!),
                        style: TextStyle(color: scheme.error),
                      ),
                    ),
                  ),
                Row(
                  children: [
                    TextButton(
                      key: const Key('resetFilters'),
                      onPressed: () => setState(() {
                        _draft.clear();
                        _min.clear();
                        _max.clear();
                        _area.clear();
                        _error = null;
                      }),
                      child: Text(words(context, 'reset')),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FilledButton(
                        key: const Key('applyFilters'),
                        onPressed: _apply,
                        style: FilledButton.styleFrom(
                          shape: const StadiumBorder(),
                        ),
                        child: Text(words(context, 'apply')),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/config/marketplace_strings.dart';
import '../domain/property_repository.dart';
import 'discovery_bloc.dart';
import 'property_card.dart';
import 'property_filters_sheet.dart';

class DiscoveryPage extends StatefulWidget {
  final PropertyRepository repository;
  final void Function(String id) onDetails, onSave;
  const DiscoveryPage({
    super.key,
    required this.repository,
    required this.onDetails,
    required this.onSave,
  });
  @override
  State<DiscoveryPage> createState() => _DiscoveryPageState();
}

class _DiscoveryPageState extends State<DiscoveryPage> {
  late final DiscoveryBloc _bloc;
  final _query = TextEditingController();
  Map<String, dynamic> _filters = {};
  LocationCatalog? _catalog;
  int get _filterCount => _filters.entries
      .where((entry) => entry.key != 'sort' || entry.value != 'newest')
      .length;
  @override
  void initState() {
    super.initState();
    _bloc = DiscoveryBloc(widget.repository)..add(SearchProperties({}));
  }

  @override
  void dispose() {
    _query.dispose();
    _bloc.close();
    super.dispose();
  }

  void _search([int page = 1]) {
    _bloc.add(
      SearchProperties({
        ..._filters,
        if (_query.text.trim().isNotEmpty) 'q': _query.text.trim(),
      }, page),
    );
  }

  Future<LocationCatalog> _locations() async =>
      _catalog ??= await widget.repository.locations();
  Future<void> _openFilters() async {
    FocusScope.of(context).unfocus();
    final selected = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      constraints: const BoxConstraints(maxWidth: 640),
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SizedBox(
        height: MediaQuery.sizeOf(context).height * .94,
        child: PropertyFiltersSheet(
          applied: _filters,
          catalog: _catalog,
          loadLocations: _locations,
        ),
      ),
    );
    if (!mounted || selected == null) return;
    setState(() => _filters = selected);
    _search();
  }

  void _category(String? category) {
    setState(() {
      if (category == null) {
        _filters.remove('category');
      } else {
        _filters['category'] = category;
      }
    });
    _search();
  }

  Widget _searchBar(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        IconButton(
          key: const Key('openFilters'),
          tooltip: words(context, 'filters'),
          onPressed: _openFilters,
          icon: Badge(
            isLabelVisible: _filterCount > 0,
            label: Text('$_filterCount'),
            child: const Icon(Icons.tune, size: 28),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: .7),
              ),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Row(
              children: [
                const SizedBox(width: 18),
                Icon(Icons.search, color: scheme.onSurfaceVariant, size: 25),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    key: const Key('propertySearch'),
                    controller: _query,
                    maxLength: 120,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _search(),
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: words(context, 'searchHint'),
                      counterText: '',
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 19),
                      isDense: true,
                    ),
                  ),
                ),
                if (_query.text.isNotEmpty)
                  IconButton(
                    key: const Key('clearSearch'),
                    tooltip: words(context, 'reset'),
                    onPressed: () {
                      setState(_query.clear);
                      _search();
                    },
                    icon: const Icon(Icons.close, size: 20),
                  ),
                PopupMenuButton<String>(
                  key: const Key('searchType'),
                  tooltip: words(context, 'category'),
                  icon: const Icon(Icons.keyboard_arrow_down_rounded),
                  onSelected: (value) =>
                      _category(value.isEmpty ? null : value),
                  itemBuilder: (context) =>
                      [
                            '',
                            'sale_cash',
                            'sale_installments',
                            'private_rental',
                            'shared_rental',
                          ]
                          .map(
                            (key) => PopupMenuItem(
                              value: key,
                              child: Text(
                                words(context, key.isEmpty ? 'allHomes' : key),
                              ),
                            ),
                          )
                          .toList(),
                ),
                const SizedBox(width: 6),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _categories(BuildContext context) {
    const entries = [
      ('', Icons.grid_view_rounded),
      ('sale_cash', Icons.home_work_outlined),
      ('sale_installments', Icons.payments_outlined),
      ('private_rental', Icons.key_outlined),
      ('shared_rental', Icons.people_outline),
    ];
    final scheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: entries.map((entry) {
          final selected = (_filters['category'] ?? '') == entry.$1;
          return Padding(
            padding: const EdgeInsetsDirectional.only(end: 10),
            child: OutlinedButton.icon(
              key: ValueKey('quick-type-${entry.$1}'),
              onPressed: () => _category(entry.$1.isEmpty ? null : entry.$1),
              icon: Icon(entry.$2, size: 21),
              label: Text(
                words(context, entry.$1.isEmpty ? 'allHomes' : entry.$1),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 18,
                ),
                foregroundColor: selected ? scheme.onPrimary : scheme.onSurface,
                backgroundColor: selected ? scheme.primary : scheme.surface,
                side: BorderSide(
                  color: selected ? scheme.primary : scheme.outlineVariant,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    return BlocProvider.value(
      value: _bloc,
      child: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    words(context, 'findHome'),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    words(context, 'browseHint'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _searchBar(context),
                  const SizedBox(height: 24),
                  _categories(context),
                  if (_filterCount > 0) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${words(context, 'activeFilters')}: $_filterCount',
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() => _filters = {});
                            _search();
                          },
                          child: Text(words(context, 'reset')),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 28),
                  BlocBuilder<DiscoveryBloc, DiscoveryState>(
                    builder: (context, state) {
                      if (state.loading) {
                        return const Padding(
                          padding: EdgeInsets.all(48),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      if (state.failed) {
                        return Column(
                          children: [
                            Text(words(context, 'loadError')),
                            TextButton(
                              onPressed: _search,
                              child: Text(words(context, 'retry')),
                            ),
                          ],
                        );
                      }
                      final results = state.results;
                      if (results == null || results.items.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(
                                Icons.home_outlined,
                                size: 64,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                words(context, 'empty'),
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                words(context, 'emptyHint'),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('${results.total} ${ar ? 'عقار' : 'homes'}'),
                          const SizedBox(height: 16),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final columns = constraints.maxWidth >= 950
                                  ? 3
                                  : constraints.maxWidth >= 620
                                  ? 2
                                  : 1;
                              final width =
                                  (constraints.maxWidth - (columns - 1) * 16) /
                                  columns;
                              return Wrap(
                                spacing: 16,
                                runSpacing: 16,
                                children: results.items
                                    .map(
                                      (property) => SizedBox(
                                        width: width,
                                        child: PropertyCard(
                                          property: property,
                                          repository: widget.repository,
                                          onDetails: () =>
                                              widget.onDetails(property.id),
                                          onSave: () =>
                                              widget.onSave(property.id),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextButton(
                                onPressed: results.page > 1
                                    ? () => _search(results.page - 1)
                                    : null,
                                child: Text(words(context, 'previous')),
                              ),
                              Text('${results.page}'),
                              TextButton(
                                onPressed: results.page * 12 < results.total
                                    ? () => _search(results.page + 1)
                                    : null,
                                child: Text(words(context, 'next')),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

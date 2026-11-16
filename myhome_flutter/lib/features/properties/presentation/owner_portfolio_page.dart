import '../../../core/widgets/app_layout.dart';
import '../../../core/widgets/app_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/config/marketplace_strings.dart';
import '../domain/property_repository.dart';
import 'listing_page.dart';
import 'owner_portfolio_cubit.dart';
import 'property_card.dart';
import '../../auth/presentation/auth_cubit.dart';
import '../../chat/presentation/contact_pages.dart';

class OwnerPortfolioPage extends StatelessWidget {
  final PropertyRepository repository;
  final void Function(String) onDetails;
  const OwnerPortfolioPage({
    super.key,
    required this.repository,
    required this.onDetails,
  });
  @override
  Widget build(BuildContext context) => OwnerListingsPage(
    repository: repository,
    group: 'all',
    initialScope: 'all',
    onDetails: onDetails,
  );
}

class OwnerListingsPage extends StatefulWidget {
  final PropertyRepository repository;
  final String group;
  final bool history;
  final String? initialScope;
  final void Function(String) onDetails;
  const OwnerListingsPage({
    super.key,
    required this.repository,
    required this.group,
    required this.onDetails,
    this.history = false,
    this.initialScope,
  });
  @override
  State<OwnerListingsPage> createState() => _OwnerListingsPageState();
}

class _OwnerListingsPageState extends State<OwnerListingsPage> {
  late final OwnerListingsCubit _cubit;
  final _scroll = ScrollController();
  @override
  void initState() {
    super.initState();
    _cubit = OwnerListingsCubit(widget.repository, widget.group)
      ..search(
        selectedScope:
            widget.initialScope ?? (widget.history ? 'history' : 'current'),
      );
    _scroll.addListener(() {
      if (_scroll.position.extentAfter < 180 && !_cubit.state.moreFailed) {
        _cubit.more();
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    _cubit.close();
    super.dispose();
  }

  Future<void> _change(PropertySummary item, String target) async {
    if (['sold', 'rented'].contains(target)) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            words(context, target == 'sold' ? 'markSold' : 'markRented'),
          ),
          content: Text(words(context, 'closeListingConfirm')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(words(context, 'cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(words(context, 'confirm')),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    final success = await _cubit.change(item.id, target);
    if (!success && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(words(context, 'saveError'))));
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<OwnerListingsCubit, OwnerListingsState>(
    bloc: _cubit,
    builder: (context, state) => AppScaffold(
      appBar: AppBar(
        title: Text(
          '${words(context, widget.group == 'all' ? 'portfolio' : widget.group)}${state.loading ? '' : ' (${state.total})'}',
        ),
        actions: [
          IconButton(
            tooltip: words(context, 'refresh'),
            onPressed: () => _cubit.search(),
            icon: const AppIcon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton:
          (context.read<AuthCubit>().state.account?.canManageProperties ??
              false)
          ? FloatingActionButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute<bool>(
                    builder: (_) => ListingPage(repository: widget.repository),
                  ),
                );
                if (mounted) _cubit.search();
              },
              child: const Icon(Icons.add),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final scope in ['all', 'current', 'history'])
                      ChoiceChip(
                        key: ValueKey('owner-scope-$scope'),
                        label: Text(
                          words(
                            context,
                            scope == 'current' ? 'currentListings' : scope,
                          ),
                        ),
                        selected: _cubit.scope == scope,
                        onSelected: (_) => _cubit.search(selectedScope: scope),
                      ),
                  ],
                ),
                if (widget.group == 'all')
                  Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: DropdownButtonFormField<String>(
                      key: const Key('ownerGroupFilter'),
                      initialValue: _cubit.group,
                      decoration: InputDecoration(
                        labelText: words(context, 'category'),
                      ),
                      items: [
                        for (final group in [
                          'all',
                          'sale',
                          'private_rental',
                          'shared_rental',
                        ])
                          DropdownMenuItem(
                            value: group,
                            child: Text(words(context, group)),
                          ),
                      ],
                      onChanged: (value) => _cubit.search(selectedGroup: value),
                    ),
                  ),
                const SizedBox(height: 14),
                Autocomplete<String>(
                  optionsBuilder: (value) async {
                    if (value.text.trim().isEmpty) {
                      return const Iterable<String>.empty();
                    }
                    try {
                      return await widget.repository.ownerSuggestions(
                        _cubit.group,
                        value.text.trim(),
                        _cubit.scope,
                      );
                    } catch (_) {
                      return const Iterable<String>.empty();
                    }
                  },
                  onSelected: (value) => _cubit.search(text: value),
                  fieldViewBuilder: (context, controller, focus, onSubmitted) =>
                      TextField(
                        key: const Key('ownerQuickSearch'),
                        controller: controller,
                        focusNode: focus,
                        maxLength: 120,
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          labelText: words(context, 'quickSearch'),
                          counterText: '',
                          prefixIcon: const AppIcon(Icons.search),
                          suffixIcon: IconButton(
                            tooltip: words(context, 'reset'),
                            onPressed: () {
                              controller.clear();
                              _cubit.search(text: '');
                            },
                            icon: const AppIcon(Icons.close),
                          ),
                        ),
                        onSubmitted: (v) => _cubit.search(text: v.trim()),
                      ),
                ),
                if (_cubit.scope == 'current')
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: DropdownButtonFormField<String>(
                      key: ValueKey('owner-filter-${_cubit.availability}'),
                      initialValue: _cubit.availability,
                      decoration: InputDecoration(
                        labelText: words(context, 'listingVisibility'),
                      ),
                      items: ['all', 'active', 'paused']
                          .map(
                            (v) => DropdownMenuItem(
                              value: v,
                              child: Text(words(context, v)),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => _cubit.search(selectedAvailability: v),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: state.loading
                ? const Center(child: CircularProgressIndicator())
                : state.failed
                ? Center(
                    child: TextButton(
                      onPressed: () => _cubit.search(),
                      child: Text(words(context, 'retry')),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () => _cubit.search(),
                    child: ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      itemCount: state.items.length + 1,
                      itemBuilder: (context, index) {
                        if (index == state.items.length) {
                          return Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                if (state.items.isEmpty)
                                  Text(words(context, 'empty')),
                                if (state.loadingMore)
                                  const CircularProgressIndicator(),
                                if (state.cursor != null && !state.loadingMore)
                                  TextButton(
                                    key: const Key('ownerLoadMore'),
                                    onPressed: _cubit.more,
                                    child: Text(
                                      words(
                                        context,
                                        state.moreFailed
                                            ? 'retry'
                                            : 'loadThree',
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }
                        final item = state.items[index];
                        return Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: AppLayout.formWidth(context),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Wrap(
                                    spacing: 8,
                                    children: [
                                      Chip(
                                        label: Text(
                                          words(context, item.status),
                                        ),
                                      ),
                                      if (item.status == 'approved')
                                        Chip(
                                          label: Text(
                                            words(context, item.availability),
                                          ),
                                        ),
                                    ],
                                  ),
                                  Stack(
                                    children: [
                                      ColorFiltered(
                                        colorFilter: ColorFilter.matrix(
                                          item.status != 'approved' ||
                                                  item.availability != 'active'
                                              ? const <double>[
                                                  .2126,
                                                  .7152,
                                                  .0722,
                                                  0,
                                                  0,
                                                  .2126,
                                                  .7152,
                                                  .0722,
                                                  0,
                                                  0,
                                                  .2126,
                                                  .7152,
                                                  .0722,
                                                  0,
                                                  0,
                                                  0,
                                                  0,
                                                  0,
                                                  1,
                                                  0,
                                                ]
                                              : const <double>[
                                                  1,
                                                  0,
                                                  0,
                                                  0,
                                                  0,
                                                  0,
                                                  1,
                                                  0,
                                                  0,
                                                  0,
                                                  0,
                                                  0,
                                                  1,
                                                  0,
                                                  0,
                                                  0,
                                                  0,
                                                  0,
                                                  1,
                                                  0,
                                                ],
                                        ),
                                        child: PropertyCard(
                                          property: item,
                                          repository: widget.repository,
                                          onDetails: () =>
                                              widget.onDetails(item.id),
                                          onSave: () {},
                                          showSave: false,
                                        ),
                                      ),
                                      if (item.status != 'approved' ||
                                          item.availability != 'active')
                                        Positioned(
                                          top: 12,
                                          left: 12,
                                          right: 12,
                                          child: IgnorePointer(
                                            child: Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: Colors.black.withValues(
                                                  alpha: .68,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                words(
                                                  context,
                                                  item.status != 'approved'
                                                      ? item.status
                                                      : item.availability,
                                                ),
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  Wrap(
                                    alignment: WrapAlignment.spaceBetween,
                                    spacing: 12,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Text(
                                          '${words(context, 'visitorCount')}: ${item.visitorCount}',
                                        ),
                                      ),
                                      TextButton(
                                        key: ValueKey('interested-${item.id}'),
                                        onPressed: () => Navigator.push(
                                          context,
                                          MaterialPageRoute<void>(
                                            builder: (_) => ContactListPage(
                                              propertyId: item.id,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          '${words(context, 'savedCount')}: ${item.savedCount}',
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (item.status == 'approved' &&
                                      [
                                        'active',
                                        'paused',
                                      ].contains(item.availability))
                                    Wrap(
                                      alignment: WrapAlignment.spaceBetween,
                                      children: [
                                        IconButton(
                                          key: ValueKey(
                                            'visibility-${item.id}',
                                          ),
                                          tooltip: words(
                                            context,
                                            item.availability == 'paused'
                                                ? 'resumeListing'
                                                : 'pauseListing',
                                          ),
                                          onPressed: state.changing != null
                                              ? null
                                              : () => _change(
                                                  item,
                                                  item.availability == 'paused'
                                                      ? 'active'
                                                      : 'paused',
                                                ),
                                          icon: AppIcon(
                                            item.availability == 'paused'
                                                ? Icons.visibility
                                                : Icons.visibility_off_outlined,
                                          ),
                                        ),
                                        TextButton.icon(
                                          onPressed: state.changing != null
                                              ? null
                                              : () => _change(
                                                  item,
                                                  item.category.startsWith(
                                                        'sale_',
                                                      )
                                                      ? 'sold'
                                                      : 'rented',
                                                ),
                                          icon: const AppIcon(
                                            Icons.check_circle_outline,
                                          ),
                                          label: Text(
                                            words(
                                              context,
                                              item.category.startsWith('sale_')
                                                  ? 'markSold'
                                                  : 'markRented',
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    ),
  );
}

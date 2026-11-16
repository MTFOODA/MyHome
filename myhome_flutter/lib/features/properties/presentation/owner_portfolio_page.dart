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

class OwnerPortfolioPage extends StatefulWidget {
  final PropertyRepository repository;
  final void Function(String) onDetails;
  const OwnerPortfolioPage({
    super.key,
    required this.repository,
    required this.onDetails,
  });
  @override
  State<OwnerPortfolioPage> createState() => _OwnerPortfolioPageState();
}

class _OwnerPortfolioPageState extends State<OwnerPortfolioPage> {
  late Future<List<PortfolioCount>> _counts;
  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _counts = widget.repository.portfolio();
  }

  Future<void> _open(String group, {bool history = false}) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => OwnerListingsPage(
          repository: widget.repository,
          group: group,
          onDetails: widget.onDetails,
          history: history,
        ),
      ),
    );
    if (mounted) setState(_reload);
  }

  @override
  Widget build(BuildContext context) => AppScaffold(
    appBar: AppBar(title: Text(words(context, 'manageProperties'))),
    floatingActionButton:
        (context.watch<AuthCubit>().state.account?.canManageProperties ?? false)
        ? FloatingActionButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute<bool>(
                  builder: (_) => ListingPage(repository: widget.repository),
                ),
              );
              if (mounted) setState(_reload);
            },
            child: const AppIcon(Icons.add),
          )
        : null,
    body: FutureBuilder(
      future: _counts,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: TextButton(
              onPressed: () => setState(_reload),
              child: Text(words(context, 'retry')),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async {
            setState(_reload);
            await _counts;
          },
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                words(context, 'portfolioHint'),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 20),
              if (snapshot.data!.isEmpty) Text(words(context, 'empty')),
              for (final count in snapshot.data!)
                Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: AppLayout.formWidth(context),
                    ),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: AppIcon(
                                count.group == 'sale'
                                    ? Icons.sell_outlined
                                    : count.group == 'shared_rental'
                                    ? Icons.groups_outlined
                                    : Icons.home_outlined,
                              ),
                              title: Text(
                                words(context, count.group),
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              trailing: Text(
                                '${count.current}',
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineLarge,
                              ),
                            ),
                            Text(
                              '${words(context, 'publishedCount')}: ${count.published} · ${words(context, 'paused')}: ${count.paused} · ${words(context, 'awaitingCount')}: ${count.awaiting}',
                            ),
                            const SizedBox(height: 16),
                            FilledButton(
                              key: ValueKey('portfolio-${count.group}'),
                              onPressed: () => _open(count.group),
                              child: Text(words(context, 'currentListings')),
                            ),
                            TextButton.icon(
                              onPressed: () =>
                                  _open(count.group, history: true),
                              icon: const AppIcon(Icons.history),
                              label: Text(
                                '${words(context, 'history')} (${count.history})',
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
  );
}

class OwnerListingsPage extends StatefulWidget {
  final PropertyRepository repository;
  final String group;
  final bool history;
  final void Function(String) onDetails;
  const OwnerListingsPage({
    super.key,
    required this.repository,
    required this.group,
    required this.onDetails,
    this.history = false,
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
      ..search(selectedScope: widget.history ? 'history' : 'current');
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
          '${words(context, widget.group)}${state.loading ? '' : ' (${state.total})'}',
        ),
        actions: [
          IconButton(
            tooltip: words(context, 'refresh'),
            onPressed: () => _cubit.search(),
            icon: const AppIcon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                SegmentedButton<String>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(
                      value: 'current',
                      label: Text(words(context, 'currentListings')),
                    ),
                    ButtonSegment(
                      value: 'history',
                      label: Text(words(context, 'history')),
                      icon: const AppIcon(Icons.history),
                    ),
                  ],
                  selected: {_cubit.scope},
                  onSelectionChanged: (v) =>
                      _cubit.search(selectedScope: v.first),
                ),
                const SizedBox(height: 14),
                Autocomplete<String>(
                  optionsBuilder: (value) async {
                    if (value.text.trim().isEmpty) {
                      return const Iterable<String>.empty();
                    }
                    try {
                      return await widget.repository.ownerSuggestions(
                        widget.group,
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
                                      Chip(
                                        label: Text(
                                          words(context, item.availability),
                                        ),
                                      ),
                                    ],
                                  ),
                                  PropertyCard(
                                    property: item,
                                    repository: widget.repository,
                                    onDetails: () => widget.onDetails(item.id),
                                    onSave: () {},
                                    showSave: false,
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
                                                  widget.group == 'sale'
                                                      ? 'sold'
                                                      : 'rented',
                                                ),
                                          icon: const AppIcon(
                                            Icons.check_circle_outline,
                                          ),
                                          label: Text(
                                            words(
                                              context,
                                              widget.group == 'sale'
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

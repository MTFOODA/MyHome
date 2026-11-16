import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/config/marketplace_strings.dart';
import '../../properties/domain/property_repository.dart';
import '../../properties/presentation/property_photo.dart';
import '../domain/chat_repository.dart';

class ConversationList extends StatefulWidget {
  final String? selected;
  final ValueChanged<String> onSelected;
  const ConversationList({super.key, this.selected, required this.onSelected});
  @override
  State<ConversationList> createState() => _ConversationListState();
}

class _ConversationListState extends State<ConversationList> {
  final _items = <Map<String, dynamic>>[];
  String? _cursor;
  bool _loading = false, _failed = false;
  String _query = '', _category = 'all';
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool refresh = false}) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final data = await context.read<ChatRepository>().inbox(
        before: refresh ? null : _cursor,
      );
      if (!mounted) return;
      setState(() {
        if (refresh) _items.clear();
        for (final value in data['items'] as List) {
          final row = Map<String, dynamic>.from(value as Map);
          _items.removeWhere((item) => item['id'] == row['id']);
          _items.add(row);
        }
        _cursor = data['next_cursor'] as String?;
      });
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ColoredBox(
      color: colors.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  words(context, 'propertyMessages'),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 20),
                TextField(
                  key: const Key('conversationSearch'),
                  onChanged: (value) =>
                      setState(() => _query = value.trim().toLowerCase()),
                  decoration: InputDecoration(
                    hintText: words(context, 'searchMessages'),
                    prefixIcon: const Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final category in ['all', 'sale', 'rent'])
                      ChoiceChip(
                        showCheckmark: false,
                        label: Text(
                          words(
                            context,
                            category == 'all'
                                ? 'allConversations'
                                : category == 'sale'
                                ? 'saleConversations'
                                : 'rentConversations',
                          ),
                        ),
                        selected: category == _category,
                        onSelected: (_) => setState(() => _category = category),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _load(refresh: true),
              child: ListView(
                padding: const EdgeInsets.all(12),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  if (!_loading && !_failed && _items.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(words(context, 'empty')),
                    ),
                  for (final item in _items)
                    if ('${item['name']} ${item['title']}'
                            .toLowerCase()
                            .contains(_query) &&
                        (_category == 'all' ||
                            (_category == 'sale') ==
                                '${(item['property'] as Map?)?['category']}'
                                    .startsWith('sale_')))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Material(
                          color: widget.selected == item['id']
                              ? colors.primaryContainer.withValues(alpha: .6)
                              : colors.surface,
                          borderRadius: BorderRadius.circular(18),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () => widget.onSelected('${item['id']}'),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        child: Text(
                                          '${item['name']}'.characters
                                              .take(1)
                                              .toString(),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          '${item['name']}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleMedium,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    '${item['last_message'] ?? ''}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      if (item['property']
                                          case final Map property) ...[
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: SizedBox(
                                            width: 50,
                                            height: 50,
                                            child: PropertyPhoto(
                                              id:
                                                  property['cover_id']
                                                      as String?,
                                              category:
                                                  '${property['category']}',
                                              repository: context
                                                  .read<PropertyRepository>(),
                                              private:
                                                  property['cover_private'] ==
                                                  true,
                                              compact: true,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                      ],
                                      Expanded(
                                        child: Text(
                                          '${item['title']}',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  if (_loading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  if (!_loading && (_cursor != null || _failed))
                    TextButton(
                      onPressed: _load,
                      child: Text(
                        words(context, _failed ? 'retry' : 'loadMorePeople'),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Icon(Icons.shield_outlined, color: colors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    words(context, 'chatSafety'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

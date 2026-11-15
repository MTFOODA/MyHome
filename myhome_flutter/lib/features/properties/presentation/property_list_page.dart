import '../../../core/widgets/property_illustration.dart';
import 'package:flutter/material.dart';
import '../../../core/config/marketplace_strings.dart';
import '../domain/property_repository.dart';
import 'property_card.dart';
import 'listing_page.dart';

class PropertyListPage extends StatefulWidget {
  final PropertyRepository repository;
  final bool mine, embedded;
  final void Function(String) onDetails;
  const PropertyListPage({
    super.key,
    required this.repository,
    required this.onDetails,
    this.mine = false,
    this.embedded = false,
  });
  @override
  State<PropertyListPage> createState() => _PropertyListPageState();
}

class _PropertyListPageState extends State<PropertyListPage> {
  late Future<List<PropertySummary>> _items;
  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _items = widget.mine
        ? widget.repository.mine()
        : widget.repository.favorites();
  }

  @override
  Widget build(BuildContext context) {
    final body = FutureBuilder(
      future: _items,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: TextButton(
              onPressed: () => setState(_load),
              child: Text(words(context, 'retry')),
            ),
          );
        }
        final items = snapshot.data!;
        if (items.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(words(context, 'empty')),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(24),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 16),
          itemBuilder: (context, index) => Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.mine)
                    Chip(label: Text(words(context, items[index].status))),
                  PropertyCard(
                    property: items[index],
                    repository: widget.repository,
                    saved: !widget.mine,
                    showSave: !widget.mine,
                    onDetails: () => widget.onDetails(items[index].id),
                    onSave: () async {
                      try {
                        await widget.repository.unsave(items[index].id);
                        if (mounted) setState(_load);
                      } catch (_) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(words(context, 'saveError')),
                            ),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (widget.embedded) return body;
    return Scaffold(
      appBar: AppBar(
        title: Text(words(context, widget.mine ? 'manageProperties' : 'save')),
      ),
      body: body,
      floatingActionButton: widget.mine
          ? FloatingActionButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute<bool>(
                    builder: (_) => ListingPage(repository: widget.repository),
                  ),
                );
                if (mounted) setState(_load);
              },
              child: const AppImageIcon(Icons.add),
            )
          : null,
    );
  }
}

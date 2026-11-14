import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../core/config/marketplace_strings.dart';
import '../domain/property_repository.dart';

class AdminReviewPage extends StatefulWidget {
  final PropertyRepository repository;
  const AdminReviewPage({super.key, required this.repository});
  @override
  State<AdminReviewPage> createState() => _AdminReviewPageState();
}

class _AdminReviewPageState extends State<AdminReviewPage> {
  late Future<List<Map<String, dynamic>>> _queue;
  @override
  void initState() {
    super.initState();
    _queue = widget.repository.verifications();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(words(context, 'adminQueue'))),
    body: FutureBuilder(
      future: _queue,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: TextButton(
              onPressed: () =>
                  setState(() => _queue = widget.repository.verifications()),
              child: Text(words(context, 'retry')),
            ),
          );
        }
        if (snapshot.data!.isEmpty) {
          return Center(child: Text(words(context, 'empty')));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final item = snapshot.data![index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: _ReviewCard(
                repository: widget.repository,
                item: item,
                onReviewed: () =>
                    setState(() => _queue = widget.repository.verifications()),
              ),
            );
          },
        );
      },
    ),
  );
}

class _ReviewCard extends StatefulWidget {
  final PropertyRepository repository;
  final Map<String, dynamic> item;
  final VoidCallback onReviewed;
  const _ReviewCard({
    required this.repository,
    required this.item,
    required this.onReviewed,
  });
  @override
  State<_ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<_ReviewCard> {
  final _note = TextEditingController();
  bool _busy = false;
  late final Map<String, Future<List<int>>> _images;
  @override
  void initState() {
    super.initState();
    _images = {
      for (final key in ['identity_asset_id', 'ownership_asset_id'])
        widget.item[key] as String: widget.repository.privateImage(
          widget.item[key] as String,
        ),
    };
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _review(bool approved) async {
    if (_note.text.trim().length < 5) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(words(context, 'required'))));
      return;
    }
    setState(() => _busy = true);
    try {
      await widget.repository.review(
        widget.item['id'] as String,
        approved,
        _note.text.trim(),
      );
      widget.onReviewed();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(words(context, 'saveError'))));
      }
    }
    if (mounted) setState(() => _busy = false);
  }

  Widget image(String id) => FutureBuilder(
    future: _images[id],
    builder: (context, snapshot) {
      if (snapshot.hasError) return Text(words(context, 'loadError'));
      if (!snapshot.hasData) {
        return const SizedBox(
          height: 120,
          child: Center(child: CircularProgressIndicator()),
        );
      }
      return Image.memory(
        Uint8List.fromList(snapshot.data!),
        height: 250,
        fit: BoxFit.contain,
      );
    },
  );
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.item['title'] as String? ?? words(context, 'title'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if (widget.item['location'] != null)
            Text(widget.item['location'] as String),
          const SizedBox(height: 12),
          Text(
            '${words(context, 'ocrStatus')}: ${words(context, widget.item['ocrStatus'] as String? ?? 'unavailable')}',
          ),
          if (widget.item['declaredNationalId'] != null)
            SelectableText(
              '${words(context, 'nationalId')}: ${widget.item['declaredNationalId']}',
            ),
          if (widget.item['birthDate'] != null)
            Text('${words(context, 'birthDate')}: ${widget.item['birthDate']}'),
          const SizedBox(height: 16),
          Text(words(context, 'identityImage')),
          image(widget.item['identity_asset_id'] as String),
          const SizedBox(height: 16),
          Text(words(context, 'ownershipImage')),
          image(widget.item['ownership_asset_id'] as String),
          const SizedBox(height: 20),
          TextField(
            controller: _note,
            decoration: InputDecoration(
              labelText: words(context, 'reviewNote'),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            children: [
              FilledButton(
                onPressed: _busy ? null : () => _review(true),
                child: Text(words(context, 'approve')),
              ),
              OutlinedButton(
                onPressed: _busy ? null : () => _review(false),
                child: Text(words(context, 'reject')),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../core/config/marketplace_strings.dart';
import '../../../core/widgets/app_icon.dart';
import '../domain/property_repository.dart';

class PropertyPhoto extends StatefulWidget {
  final String? id;
  final bool private;
  final PropertyRepository repository;
  const PropertyPhoto({
    super.key,
    required this.id,
    required this.repository,
    this.private = false,
  });
  @override
  State<PropertyPhoto> createState() => _PropertyPhotoState();
}

class _PropertyPhotoState extends State<PropertyPhoto> {
  Future<List<int>>? _bytes;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant PropertyPhoto oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id ||
        oldWidget.private != widget.private ||
        oldWidget.repository != widget.repository) {
      _load();
    }
  }

  void _load() {
    _bytes = widget.private && widget.id != null
        ? widget.repository.privateImage(widget.id!)
        : null;
  }

  Widget _unavailable(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const FeatureSymbol('photos', size: 56),
          Text(words(context, 'photoUnavailable'), textAlign: TextAlign.center),
        ],
      ),
    ),
  );
  @override
  Widget build(BuildContext context) {
    if (widget.id == null) {
      return const Center(child: FeatureSymbol('home', size: 80));
    }
    if (!widget.private) {
      return Image.network(
        widget.repository.photoUrl(widget.id!),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _unavailable(context),
      );
    }
    return FutureBuilder<List<int>>(
      future: _bytes,
      builder: (context, snapshot) {
        if (snapshot.hasError) return _unavailable(context);
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return Image.memory(
          Uint8List.fromList(snapshot.data!),
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _unavailable(context),
        );
      },
    );
  }
}

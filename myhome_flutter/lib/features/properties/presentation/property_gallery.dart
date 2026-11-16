import 'package:flutter/material.dart';
import '../../../core/config/marketplace_strings.dart';
import '../domain/property_repository.dart';
import 'property_photo.dart';

/// Desktop mosaic and mobile swipe gallery share the protected image loader.
class PropertyGallery extends StatefulWidget {
  final List<String> photos;
  final String category;
  final bool private;
  final PropertyRepository repository;
  const PropertyGallery({
    super.key,
    required this.photos,
    required this.category,
    required this.repository,
    this.private = false,
  });
  @override
  State<PropertyGallery> createState() => _PropertyGalleryState();
}

class _PropertyGalleryState extends State<PropertyGallery> {
  int _index = 0;
  Widget photo(int index) => PropertyPhoto(
    id: widget.photos[index],
    category: widget.category,
    repository: widget.repository,
    private: widget.private,
  );
  void open(int initial) => showDialog<void>(
    context: context,
    useSafeArea: true,
    builder: (context) => _FullGallery(gallery: widget, initial: initial),
  );
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (widget.photos.isEmpty) {
        return SizedBox(
          height: 210,
          child: PropertyPhoto(
            id: null,
            category: widget.category,
            repository: widget.repository,
          ),
        );
      }
      final wide = constraints.maxWidth >= 850 && widget.photos.length > 1;
      Widget tile(int index) =>
          InkWell(onTap: () => open(index), child: photo(index));
      return ClipRRect(
        borderRadius: BorderRadius.circular(wide ? 28 : 20),
        child: SizedBox(
          height: wide ? (constraints.maxWidth * .43).clamp(360, 560) : 290,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (wide)
                Row(
                  children: [
                    Expanded(flex: 2, child: tile(0)),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: LayoutBuilder(
                        builder: (context, box) {
                          final rest = widget.photos.length - 1;
                          return GridView.count(
                            crossAxisCount: rest > 2 ? 2 : 1,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                            childAspectRatio: rest == 1
                                ? box.maxWidth / box.maxHeight
                                : (box.maxWidth / (rest > 2 ? 2 : 1)) /
                                      ((box.maxHeight - 8) / 2),
                            physics: const NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.zero,
                            children: [
                              for (
                                var index = 1;
                                index < widget.photos.length && index < 5;
                                index++
                              )
                                tile(index),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                )
              else
                PageView.builder(
                  onPageChanged: (index) => setState(() => _index = index),
                  itemCount: widget.photos.length,
                  itemBuilder: (_, index) => tile(index),
                ),
              PositionedDirectional(
                start: 16,
                bottom: 16,
                child: FilledButton.tonalIcon(
                  key: const Key('openPropertyGallery'),
                  onPressed: () => open(_index),
                  icon: const Icon(Icons.photo_library_outlined, size: 20),
                  label: Text(
                    '${words(context, 'viewAllPhotos')} (${widget.photos.length})',
                  ),
                ),
              ),
              if (!wide)
                PositionedDirectional(
                  end: 16,
                  top: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_index + 1} / ${widget.photos.length}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}

class _FullGallery extends StatefulWidget {
  final PropertyGallery gallery;
  final int initial;
  const _FullGallery({required this.gallery, required this.initial});
  @override
  State<_FullGallery> createState() => _FullGalleryState();
}

class _FullGalleryState extends State<_FullGallery> {
  late final _controller = PageController(initialPage: widget.initial);
  late int _index = widget.initial;
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void move(int delta) => _controller.animateToPage(
    _index + delta,
    duration: MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 240),
    curve: Curves.easeOut,
  );
  @override
  Widget build(BuildContext context) => Dialog.fullscreen(
    child: Scaffold(
      appBar: AppBar(
        title: Text(
          '${words(context, 'photos')} · ${_index + 1} / ${widget.gallery.photos.length}',
        ),
      ),
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            onPageChanged: (index) => setState(() => _index = index),
            itemCount: widget.gallery.photos.length,
            itemBuilder: (_, index) => InteractiveViewer(
              child: PropertyPhoto(
                id: widget.gallery.photos[index],
                category: widget.gallery.category,
                repository: widget.gallery.repository,
                private: widget.gallery.private,
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton.filledTonal(
              tooltip: MaterialLocalizations.of(context).previousPageTooltip,
              onPressed: _index > 0 ? () => move(-1) : null,
              icon: const Icon(Icons.chevron_left),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: IconButton.filledTonal(
              tooltip: MaterialLocalizations.of(context).nextPageTooltip,
              onPressed: _index + 1 < widget.gallery.photos.length
                  ? () => move(1)
                  : null,
              icon: const Icon(Icons.chevron_right),
            ),
          ),
        ],
      ),
    ),
  );
}

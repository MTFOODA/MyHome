import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_dragmarker/flutter_map_dragmarker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/config/marketplace_strings.dart';
import '../../../core/widgets/property_illustration.dart';
import '../domain/location_repository.dart';

class MapPropertyPin {
  final String id, title;
  final PropertyLocation location;
  const MapPropertyPin(this.id, this.title, this.location);
}

/// The same tile, attribution and failure behavior is used for picking and viewing.
class PropertyMap extends StatefulWidget {
  final PropertyLocation? selected;
  final ValueChanged<PropertyLocation>? onSelected;
  final List<MapPropertyPin> properties;
  final ValueChanged<String>? onProperty;
  final MapConfiguration? configuration;
  final TileProvider? tileProvider;
  const PropertyMap({
    super.key,
    this.selected,
    this.onSelected,
    this.properties = const [],
    this.onProperty,
    this.configuration,
    this.tileProvider,
  });
  @override
  State<PropertyMap> createState() => _PropertyMapState();
}

class _PropertyMapState extends State<PropertyMap> {
  final _controller = MapController();
  bool _offline = false, _dragging = false;
  int _retry = 0;
  MapConfiguration _configuration = const MapConfiguration();
  @override
  void initState() {
    super.initState();
    if (widget.configuration == null) {
      try {
        context.read<LocationRepository>().configuration().then((config) {
          if (mounted) setState(() => _configuration = config);
        });
      } catch (_) {
        /* Isolated previews use the public default configuration. */
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant PropertyMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected != null &&
        widget.selected != oldWidget.selected &&
        !_dragging) {
      _controller.move(
        LatLng(widget.selected!.latitude, widget.selected!.longitude),
        _controller.camera.zoom,
      );
    }
  }

  void _tileFailed() => scheduleMicrotask(() {
    if (mounted && !_offline) setState(() => _offline = true);
  });
  @override
  Widget build(BuildContext context) {
    final configuration = widget.configuration ?? _configuration;
    final initial =
        widget.selected ??
        widget.properties.firstOrNull?.location ??
        const PropertyLocation(30.0444, 31.2357);
    final pins = [
      for (final property in widget.properties)
        Marker(
          point: LatLng(
            property.location.latitude,
            property.location.longitude,
          ),
          width: 48,
          height: 48,
          child: Semantics(
            label: property.title,
            button: true,
            child: GestureDetector(
              onTap: () => widget.onProperty?.call(property.id),
              child: const PropertyIllustration('home', size: 48),
            ),
          ),
        ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _controller,
                  options: MapOptions(
                    initialCenter: LatLng(initial.latitude, initial.longitude),
                    initialZoom: widget.selected != null
                        ? 16
                        : widget.properties.isEmpty
                        ? 8
                        : 10,
                    minZoom: 5,
                    maxZoom: 19,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                    ),
                    onTap: widget.onSelected == null || _offline
                        ? null
                        : (_, point) => widget.onSelected!(
                            PropertyLocation(point.latitude, point.longitude),
                          ),
                  ),
                  children: [
                    TileLayer(
                      key: ValueKey(_retry),
                      urlTemplate: configuration.tileUrl,
                      userAgentPackageName: 'com.myhome.app',
                      panBuffer: 0,
                      tileProvider: widget.tileProvider,
                      errorTileCallback: (_, _, _) => _tileFailed(),
                    ),
                    MarkerLayer(markers: pins),
                    if (widget.selected != null)
                      DragMarkers(
                        markers: [
                          DragMarker(
                            key: const Key('draggablePropertyPin'),
                            point: LatLng(
                              widget.selected!.latitude,
                              widget.selected!.longitude,
                            ),
                            size: const Size(56, 56),
                            disableDrag: widget.onSelected == null || _offline,
                            builder: (_, _, _) => Semantics(
                              label: words(context, 'dragPin'),
                              child: const PropertyIllustration(
                                'location',
                                size: 56,
                              ),
                            ),
                            onDragStart: (_, _) => _dragging = true,
                            onDragUpdate: (_, point) => widget.onSelected?.call(
                              PropertyLocation(point.latitude, point.longitude),
                            ),
                            onDragEnd: (_, point) {
                              _dragging = false;
                              widget.onSelected?.call(
                                PropertyLocation(
                                  point.latitude,
                                  point.longitude,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                  ],
                ),
                if (_offline)
                  Align(
                    alignment: Alignment.topCenter,
                    child: Material(
                      color: Theme.of(context).colorScheme.errorContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(words(context, 'mapTilesUnavailable')),
                            TextButton(
                              onPressed: () => setState(() {
                                _offline = false;
                                _retry++;
                              }),
                              child: Text(words(context, 'retry')),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        // Always visible, outside the interactive viewport and all overlays.
        TextButton(
          onPressed: () => launchUrl(
            Uri.parse(configuration.attributionUrl),
            mode: LaunchMode.externalApplication,
          ),
          child: Text(
            configuration.attribution,
            textDirection: TextDirection.ltr,
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }
}

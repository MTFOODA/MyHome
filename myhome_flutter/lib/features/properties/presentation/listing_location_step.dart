import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/config/marketplace_strings.dart';
import '../../../core/widgets/app_icon.dart';
import '../domain/location_repository.dart';
import '../domain/property_repository.dart';
import 'listing_cubit.dart';
import 'location_picker_page.dart';
import 'location_option_picker.dart';

class ListingLocationStep extends StatefulWidget {
  final ListingCubit cubit;
  final LocationCatalog? catalog;
  final bool catalogFailed;
  final VoidCallback reload, changed;
  const ListingLocationStep({
    super.key,
    required this.cubit,
    required this.catalog,
    required this.catalogFailed,
    required this.reload,
    required this.changed,
  });
  @override
  State<ListingLocationStep> createState() => _ListingLocationStepState();
}

class _ListingLocationStepState extends State<ListingLocationStep> {
  late final TextEditingController _link;
  bool _busy = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _link = TextEditingController(
      text: widget.cubit.values['location_url'] as String?,
    );
  }

  @override
  void dispose() {
    _link.dispose();
    super.dispose();
  }

  Future<void> _parseLink() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final point = await context.read<LocationRepository>().parseLink(
        _link.text.trim(),
      );
      if (!mounted) return;
      if (point != null) widget.cubit.values.addAll(point.toJson());
      widget.cubit.values['location_url'] = _link.text.trim();
      setState(() => _error = point == null ? 'mapLinkNeedsPin' : null);
      widget.changed();
    } catch (_) {
      if (mounted) setState(() => _error = 'mapLinkInvalid');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _map() async {
    final point = await Navigator.push<PropertyLocation>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPickerPage(
          repository: context.read<LocationRepository>(),
          initial: PropertyLocation.fromValues(widget.cubit.values),
        ),
      ),
    );
    if (point != null && mounted) {
      widget.cubit.values.addAll(point.toJson());
      widget.changed();
    }
  }

  Widget _addressField(String field) => TextFormField(
    key: ValueKey('address-$field'),
    initialValue: widget.cubit.values[field]?.toString(),
    maxLength: field == 'street_address' ? 160 : 20,
    decoration: InputDecoration(
      labelText: words(context, field),
      counterText: '',
    ),
    textInputAction: TextInputAction.next,
    onChanged: (text) {
      widget.cubit.values[field] = field == 'street_address'
          ? text
          : ListingCubit.latinDigits(text);
      widget.changed();
    },
  );

  Widget _floorField() => DropdownButtonFormField<int>(
    key: const Key('address-floor_number'),
    initialValue: int.tryParse('${widget.cubit.values['floor_number']}'),
    decoration: InputDecoration(labelText: words(context, 'floor_number')),
    items: [
      for (var i = -5; i <= 100; i++)
        DropdownMenuItem(
          value: i,
          child: Text(i == 0 ? words(context, 'groundFloor') : '$i'),
        ),
    ],
    onChanged: (value) {
      widget.cubit.values['floor_number'] = value;
      widget.changed();
    },
  );

  @override
  Widget build(BuildContext context) {
    final cubit = widget.cubit,
        ar = Localizations.localeOf(context).languageCode == 'ar';
    final point = PropertyLocation.fromValues(cubit.values);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.catalogFailed)
          TextButton(
            onPressed: widget.reload,
            child: Text(words(context, 'retry')),
          ),
        DropdownButtonFormField<String>(
          key: const Key('listingGovernorate'),
          isExpanded: true,
          initialValue: cubit.values['governorate_id'] as String?,
          decoration: InputDecoration(labelText: words(context, 'governorate')),
          items: [
            for (final g in widget.catalog?.governorates ?? <LocationOption>[])
              DropdownMenuItem(
                value: g.id,
                child: Text(ar ? g.nameAr : g.nameEn),
              ),
          ],
          onChanged: (value) {
            cubit.values['governorate_id'] = value;
            cubit.values.remove('area_id');
            cubit.values.remove('approximate_location');
            widget.changed();
          },
        ),
        const SizedBox(height: 16),
        LocationOptionPicker(
          key: const Key('listingAreaPicker'),
          options:
              widget.catalog?.areas
                  .where(
                    (a) => a.governorateId == cubit.values['governorate_id'],
                  )
                  .toList() ??
              [],
          selected: cubit.values['area_id'] as String?,
          onChanged: (value) {
            cubit.values['area_id'] = value;
            widget.changed();
          },
        ),
        const SizedBox(height: 16),
        Text(words(context, 'areaLocationHint')),
        const SizedBox(height: 16),
        _addressField('street_address'),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth >= 650
                ? (constraints.maxWidth - 32) / 3
                : constraints.maxWidth;
            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                SizedBox(width: width, child: _addressField('building_number')),
                SizedBox(width: width, child: _floorField()),
                SizedBox(width: width, child: _addressField('unit_number')),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  words(context, 'completeAddress'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                SelectableText('${cubit.values['approximate_location'] ?? ''}'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          key: const Key('openLocationMap'),
          onPressed: _map,
          icon: const AppIcon(Icons.map_outlined),
          label: Text(words(context, 'chooseOnMap')),
        ),
        if (point != null)
          ListTile(
            leading: const AppIcon(Icons.check_circle_outline),
            title: Text(words(context, 'mapLocationAttached')),
            trailing: IconButton(
              tooltip: words(context, 'remove'),
              icon: const AppIcon(Icons.close),
              onPressed: () {
                cubit.values.remove('latitude');
                cubit.values.remove('longitude');
                widget.changed();
              },
            ),
          ),
        const SizedBox(height: 16),
        TextFormField(
          key: const Key('listingMapLink'),
          controller: _link,
          maxLength: 2048,
          decoration: InputDecoration(
            labelText: words(context, 'pasteMapLink'),
            prefixIcon: const AppIcon(Icons.link_rounded),
            suffixIcon: IconButton(
              tooltip: words(context, 'paste'),
              icon: const AppIcon(Icons.content_paste),
              onPressed: () async {
                final data = await Clipboard.getData(Clipboard.kTextPlain);
                if (mounted && data?.text != null) _link.text = data!.text!;
              },
            ),
          ),
        ),
        TextButton.icon(
          key: const Key('applyMapLink'),
          onPressed: _busy ? null : _parseLink,
          icon: const AppIcon(Icons.add_link_rounded),
          label: Text(words(context, 'applyMapLink')),
        ),
        if (_error != null) Text(words(context, _error!)),
      ],
    );
  }
}

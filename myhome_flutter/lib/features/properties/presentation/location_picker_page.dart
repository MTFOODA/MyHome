import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/config/marketplace_strings.dart';
import '../../../core/widgets/property_illustration.dart';
import '../domain/location_repository.dart';
import 'location_picker_cubit.dart';
import 'property_map.dart';

class LocationPickerPage extends StatefulWidget {
  final LocationRepository repository;
  final PropertyLocation? initial;
  const LocationPickerPage({super.key, required this.repository, this.initial});
  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  late final LocationPickerCubit _cubit;
  MapConfiguration _configuration = const MapConfiguration();
  @override
  void initState() {
    super.initState();
    _cubit = LocationPickerCubit(widget.repository, initial: widget.initial);
    widget.repository.configuration().then((value) {
      if (mounted) setState(() => _configuration = value);
    });
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<LocationPickerCubit, LocationPickerState>(
        bloc: _cubit,
        builder: (context, state) => Scaffold(
          appBar: AppBar(title: Text(words(context, 'chooseOnMap'))),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(words(context, 'mapPickerHint')),
                  const SizedBox(height: 12),
                  Expanded(
                    child: PropertyMap(
                      selected: state.selected,
                      onSelected: _cubit.choose,
                      configuration: _configuration,
                    ),
                  ),
                  if (state.error != null)
                    Text(
                      words(context, state.error!),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  Text(words(context, 'locationPermissionHint')),
                  OutlinedButton.icon(
                    key: const Key('useDeviceLocation'),
                    onPressed: state.busy ? null : _cubit.locate,
                    icon: const PropertyIllustration('location', size: 28),
                    label: Text(
                      words(
                        context,
                        state.busy ? 'locating' : 'useCurrentLocation',
                      ),
                    ),
                  ),
                  FilledButton.icon(
                    key: const Key('confirmMapLocation'),
                    onPressed: state.selected == null
                        ? null
                        : () => Navigator.pop(context, state.selected),
                    icon: const PropertyIllustration('location', size: 28),
                    label: Text(words(context, 'confirmLocation')),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

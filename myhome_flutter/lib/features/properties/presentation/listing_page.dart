import '../../../core/widgets/app_layout.dart';
import 'package:file_selector/file_selector.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/config/marketplace_strings.dart';
import '../../auth/presentation/auth_cubit.dart';
import '../domain/property_repository.dart';
import 'listing_cubit.dart';
import 'listing_pricing_step.dart';
import 'listing_choices.dart';
import 'property_facts_grid.dart';
import 'property_features_grid.dart';
import 'listing_generated_details.dart';
import 'listing_location_step.dart';
import 'listing_optional_features.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/selection_tile.dart';
import '../../../core/widgets/choice_artwork.dart';

class ListingPage extends StatefulWidget {
  final PropertyRepository repository;
  const ListingPage({super.key, required this.repository});
  @override
  State<ListingPage> createState() => _ListingPageState();
}

class _ListingPageState extends State<ListingPage> {
  late final ListingCubit _cubit;
  LocationCatalog? _catalog;
  int _step = 0;
  bool _invalid = false, _catalogFailed = false;
  bool _quoteReady = false;
  final _controllers = <String, TextEditingController>{};

  TextEditingController _controller(String key) {
    final text = _cubit.values[key]?.toString() ?? '';
    final controller = _controllers.putIfAbsent(
      key,
      () => TextEditingController(text: text),
    );
    if (controller.text != text) {
      controller.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }
    return controller;
  }

  @override
  void initState() {
    super.initState();
    _cubit = ListingCubit(widget.repository);
    _load();
  }

  Future<void> _load() async {
    try {
      final catalog = await widget.repository.locations();
      if (mounted) setState(() => _catalog = catalog);
    } catch (_) {
      if (mounted) setState(() => _catalogFailed = true);
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _cubit.close();
    super.dispose();
  }

  Widget field(String key, {bool number = false, int lines = 1}) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: TextFormField(
      key: ValueKey('${_step}_$key'),
      controller: _controller(key),
      maxLines: lines,
      keyboardType: number
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      decoration: InputDecoration(
        prefixIcon: Padding(
          padding: const EdgeInsets.all(8),
          child: FeatureSymbol(key, size: 32),
        ),
        labelText: words(
          context,
          {'approximate_location': 'location', 'price': 'ownerPrice'}[key] ??
              key,
        ),
      ),
      onChanged: (value) =>
          _set(key, number ? ListingCubit.latinDigits(value) : value),
    ),
  );
  void _set(String key, dynamic value) => setState(() {
    _cubit.setValue(key, value);
    if (key == 'finishing' &&
        !['lux', 'super_lux', 'ultra_super_lux'].contains(value)) {
      _cubit.values.remove('furnished');
    }
    updateGeneratedDetails(context, _cubit, _catalog);
    if (_invalid && _cubit.valid(_cubit.steps[_step])) _invalid = false;
  });

  Widget choices(String key, List<String> options) => ListingChoiceGrid(
    children: [
      for (final value in options)
        ListingChoice(
          key: ValueKey('choice-$key-$value'),
          label: words(context, value),
          illustration: value,
          illustrated: key != 'finishing',
          selected: _cubit.values[key] == value,
          onTap: () => _set(key, value),
        ),
    ],
  );
  Widget yesNo(String key) => ListingChoiceGrid(
    compact: key != 'furnished',
    children: [
      for (final value in [true, false])
        ListingChoice(
          key: ValueKey('answer-$key-$value'),
          label: words(
            context,
            key == 'furnished'
                ? (value ? 'furnishedOption' : 'unfurnishedOption')
                : (value ? 'yes' : 'no'),
          ),
          illustration: key == 'furnished'
              ? (value ? 'furnished' : 'unfurnished')
              : (value ? 'answerYes' : 'answerNo'),
          selected: _cubit.values[key] == value,
          onTap: () => _set(key, value),
        ),
    ],
  );

  Widget quantity(
    String key, {
    int minimum = 1,
    int maximum = 100,
    List<int> presets = const [1, 2, 3, 4],
  }) => ListingQuantity(
    field: key,
    value: int.tryParse('${_cubit.values[key]}'),
    minimum: minimum,
    maximum: maximum,
    presets: presets,
    onChanged: (value) => _set(key, '$value'),
  );

  Future<void> chooseBirthDate() async {
    final current = DateTime.tryParse(_cubit.birthDate);
    final date = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );
    if (date != null && mounted) {
      setState(
        () => _cubit.birthDate =
            '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
      );
    }
  }

  Future<void> pick(String kind) async {
    const types = [
      XTypeGroup(
        label: 'Images',
        extensions: ['jpg', 'jpeg', 'png', 'webp'],
        mimeTypes: ['image/jpeg', 'image/png', 'image/webp'],
      ),
    ];
    try {
      final files = kind == 'photo'
          ? await openFiles(acceptedTypeGroups: types)
          : [?await openFile(acceptedTypeGroups: types)];
      final images = <UploadImage>[];
      for (final file in files) {
        if (await file.length() > 8 * 1024 * 1024) {
          throw const PropertyException('IMAGE_MAX_8MB');
        }
        images.add(UploadImage(file.name, await file.readAsBytes()));
      }
      if (!mounted) return;
      setState(() {
        if (kind == 'photo') {
          _cubit.photos.addAll(images.take(12 - _cubit.photos.length));
        } else if (images.isNotEmpty) {
          if (kind == 'identity') {
            _cubit.identity = images.first;
          } else {
            _cubit.ownership = images.first;
          }
        }
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(words(context, 'invalid'))));
      }
    }
  }

  Widget content(String step) {
    switch (step) {
      case 'category':
        final account = context.read<AuthCubit>().state.account!;
        return choices(
          'category',
          account.intents
              .where((value) => value.startsWith('owner_'))
              .map((value) => value.substring(6))
              .toList(),
        );
      case 'information':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(words(context, 'automaticDetailsHint')),
            const SizedBox(height: 16),
            ListingChoiceGrid(
              children: [
                for (final kind in [
                  'apartment',
                  'studio',
                  'duplex',
                  'villa',
                  'room',
                ])
                  ListingChoice(
                    key: ValueKey('property-kind-$kind'),
                    label: words(context, kind),
                    illustration: kind,
                    selected: _cubit.propertyKind == kind,
                    onTap: () => setState(() {
                      _cubit.propertyKind = kind;
                      updateGeneratedDetails(context, _cubit, _catalog);
                      _invalid = false;
                    }),
                  ),
              ],
            ),
          ],
        );
      case 'location':
        return ListingLocationStep(
          cubit: _cubit,
          catalog: _catalog,
          catalogFailed: _catalogFailed,
          reload: _load,
          changed: () => setState(() {
            updateGeneratedDetails(context, _cubit, _catalog);
            _invalid = false;
          }),
        );
      case 'dimensions':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final area in [
                  65,
                  75,
                  85,
                  95,
                  105,
                  115,
                  125,
                  135,
                  150,
                  175,
                  200,
                ])
                  ChoiceChip(
                    key: ValueKey('area-$area'),
                    label: Text('$area ${words(context, 'squareMetres')}'),
                    selected: _cubit.values['area_m2'] == '$area',
                    onSelected: (_) => _set('area_m2', '$area'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            field('area_m2', number: true),
            choices('area_measurement', ['net', 'gross']),
            const SizedBox(height: 16),
            quantity('bedrooms', minimum: 0, presets: [0, 1, 2, 3, 4]),
            quantity('bathrooms'),
            if (_cubit.values['category'] == 'shared_rental')
              quantity('capacity', maximum: 500, presets: [1, 2, 4, 6, 8]),
          ],
        );
      case 'utilities':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final utility in ['water', 'electricity', 'gas']) ...[
              Column(
                children: [
                  ChoiceArtwork(utility, size: 64),
                  const SizedBox(height: 10),
                  Text(
                    words(context, utility),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              yesNo(utility),
              const SizedBox(height: 24),
            ],
          ],
        );
      case 'elevator':
        return Column(
          children: [
            yesNo(step),
            ListingOptionalFeatures(values: _cubit.values, onChanged: _set),
          ],
        );
      case 'negotiable':
        return yesNo(step);
      case 'finishing':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            choices('finishing', [
              'red_brick',
              'plastered',
              'lux',
              'super_lux',
              'ultra_super_lux',
            ]),
            if ([
              'lux',
              'super_lux',
              'ultra_super_lux',
            ].contains(_cubit.values['finishing'])) ...[
              const SizedBox(height: 24),
              Text(
                words(context, 'furnished'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              yesNo('furnished'),
            ],
          ],
        );
      case 'pricing':
        return ListingPricingStep(
          cubit: _cubit,
          repository: widget.repository,
          onReadyChanged: (ready) {
            if (mounted && _quoteReady != ready) {
              setState(() => _quoteReady = ready);
            }
          },
        );
      case 'beds':
        return Column(
          children: [
            quantity('total_beds', maximum: 500),
            quantity(
              'available_beds',
              minimum: 0,
              maximum: 500,
              presets: [0, 1, 2, 3, 4],
            ),
          ],
        );
      case 'photos':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(words(context, 'coverHint')),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              key: const Key('pickPropertyPhotos'),
              onPressed: _cubit.photos.length >= 12
                  ? null
                  : () => pick('photo'),
              icon: const AppIcon(Icons.add_photo_alternate_outlined),
              label: Text(words(context, 'addPhotos')),
            ),
            for (var i = 0; i < _cubit.photos.length; i++)
              ListTile(
                leading: Image.memory(
                  Uint8List.fromList(_cubit.photos[i].bytes),
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  cacheWidth: 120,
                  errorBuilder: (_, _, _) =>
                      const AppIcon(Icons.broken_image_outlined),
                ),
                title: Text('${i + 1}. ${_cubit.photos[i].name}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: i == 0
                          ? null
                          : () => setState(() {
                              final file = _cubit.photos.removeAt(i);
                              _cubit.photos.insert(i - 1, file);
                            }),
                      icon: const AppIcon(Icons.arrow_upward),
                    ),
                    IconButton(
                      tooltip: words(context, 'remove'),
                      onPressed: () =>
                          setState(() => _cubit.photos.removeAt(i)),
                      icon: const AppIcon(Icons.close),
                    ),
                  ],
                ),
              ),
          ],
        );
      case 'verification':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(words(context, 'privateDocs')),
            const SizedBox(height: 20),
            TextFormField(
              key: const Key('listingNationalId'),
              initialValue: _cubit.nationalId,
              keyboardType: TextInputType.number,
              maxLength: 14,
              decoration: InputDecoration(
                labelText: words(context, 'nationalId'),
                prefixIcon: const Padding(
                  padding: EdgeInsets.all(8),
                  child: AppIcon(Icons.badge_outlined, size: 28),
                ),
              ),
              onChanged: (value) =>
                  _cubit.nationalId = ListingCubit.latinDigits(value),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              key: const Key('chooseBirthDate'),
              onPressed: chooseBirthDate,
              icon: const ColorSymbol(Icons.calendar_month),
              label: Text(
                _cubit.birthDate.isEmpty
                    ? words(context, 'chooseBirthDate')
                    : _cubit.birthDate,
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              key: const Key('pickIdentity'),
              onPressed: () => pick('identity'),
              icon: const AppIcon(Icons.badge_outlined),
              label: Text(
                _cubit.identity?.name ?? words(context, 'identityImage'),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              key: const Key('pickOwnership'),
              onPressed: () => pick('ownership'),
              icon: const AppIcon(Icons.description_outlined),
              label: Text(
                _cubit.ownership?.name ?? words(context, 'ownershipImage'),
              ),
            ),
            const SizedBox(height: 16),
            SelectionTile(
              key: const Key('listingConsent'),
              artwork: 'consent',
              label: words(context, 'consent'),
              selected: _cubit.consent,
              onChanged: (value) => setState(() => _cubit.consent = value),
            ),
          ],
        );
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _cubit.values['title']?.toString() ?? '',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            PropertyFactsGrid(
              facts: [
                for (final key in [
                  'category',
                  'area_m2',
                  'bedrooms',
                  'bathrooms',
                  'area_measurement',
                  'finishing',
                  'furnished',
                  if (_cubit.values['category'] == 'shared_rental') 'capacity',
                ])
                  if (_cubit.values[key] != null)
                    PropertyFact(
                      [
                            'category',
                            'area_measurement',
                            'finishing',
                          ].contains(key)
                          ? '${_cubit.values[key]}'
                          : key == 'furnished'
                          ? (_cubit.values[key] == true
                                ? 'furnished'
                                : 'unfurnished')
                          : key,
                      words(context, key),
                      _cubit.values[key] is bool
                          ? words(
                              context,
                              _cubit.values[key] == true ? 'yes' : 'no',
                            )
                          : marketplaceWords.containsKey(
                              '${_cubit.values[key]}',
                            )
                          ? words(context, '${_cubit.values[key]}')
                          : '${_cubit.values[key]}',
                      muted: _cubit.values[key] == false,
                    ),
              ],
            ),
            const SizedBox(height: 24),
            PropertyFeaturesGrid(data: _cubit.values),
            for (final key in ['orientation', 'kitchen_type'])
              if (_cubit.values[key] != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    '${words(context, key)}: ${words(context, '${_cubit.values[key]}')}',
                  ),
                ),
            const SizedBox(height: 20),
            Text(
              _cubit.values['approximate_location']?.toString() ?? '',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Text('${_cubit.photos.length} ${words(context, 'photos')}'),
            Text(words(context, 'privateDocs')),
          ],
        );
    }
  }

  String locationName(String id) {
    final matches =
        _catalog?.areas.where((area) => area.id == id).toList() ?? [];
    if (matches.isEmpty) return words(context, 'area');
    return Localizations.localeOf(context).languageCode == 'ar'
        ? matches.first.nameAr
        : matches.first.nameEn;
  }

  String title(String step) => words(
    context,
    {
          'information': 'propertyKind',
          'location': 'completeAddress',
          'utilities': 'listingUtilities',
          'dimensions': 'area_m2',
          'pricing': 'pricingFinal',
          'review': 'propertyReview',
          'installments': 'sale_installments',
          'beds': 'total_beds',
        }[step] ??
        step,
  );
  @override
  Widget build(BuildContext context) =>
      BlocConsumer<ListingCubit, ListingState>(
        bloc: _cubit,
        listener: (context, state) {
          if (state.submitted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(words(context, 'submitted'))),
            );
            Navigator.pop(context, true);
          }
        },
        builder: (context, state) {
          final steps = _cubit.steps;
          final step = steps[_step.clamp(0, steps.length - 1)];
          return PopScope(
            canPop: !state.busy,
            child: AppScaffold(
              appBar: AppBar(title: Text(words(context, 'addProperty'))),
              body: SingleChildScrollView(
                child: Center(
                  child: ConstrainedBox(
                    key: const Key('listingContent'),
                    constraints: BoxConstraints(
                      maxWidth: AppLayout.formWidth(context),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(AppLayout.gutter(context)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          LinearProgressIndicator(
                            value: state.busy
                                ? state.progress
                                : (_step + 1) / steps.length,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '${_step + 1} / ${steps.length}',
                            textDirection: TextDirection.ltr,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            title(step),
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 24),
                          IgnorePointer(
                            ignoring: state.busy,
                            child: AnimatedSwitcher(
                              duration: MediaQuery.disableAnimationsOf(context)
                                  ? Duration.zero
                                  : const Duration(milliseconds: 220),
                              child: KeyedSubtree(
                                key: ValueKey(step),
                                child: content(step),
                              ),
                            ),
                          ),
                          if (_invalid || state.error != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Semantics(
                                liveRegion: true,
                                child: Text(
                                  words(
                                    context,
                                    state.error ??
                                        _cubit.validationIssue(step) ??
                                        'required',
                                  ),
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(height: 28),
                          LayoutBuilder(
                            builder: (context, constraints) => OverflowBar(
                              alignment: _step > 0
                                  ? MainAxisAlignment.spaceBetween
                                  : MainAxisAlignment.end,
                              overflowAlignment: OverflowBarAlignment.end,
                              spacing: 12,
                              overflowSpacing: 12,
                              children: [
                                if (_step > 0)
                                  SizedBox(
                                    width: AppLayout.actionWidth(
                                      context,
                                      constraints.maxWidth,
                                    ),
                                    child: TextButton.icon(
                                      icon: const AppIcon(
                                        Icons.arrow_back_rounded,
                                      ),
                                      onPressed: state.busy
                                          ? null
                                          : () => setState(() {
                                              _step--;
                                              _quoteReady = false;
                                              _invalid = false;
                                            }),
                                      label: Text(words(context, 'back')),
                                    ),
                                  ),
                                SizedBox(
                                  width: AppLayout.actionWidth(
                                    context,
                                    constraints.maxWidth,
                                  ),
                                  child: FilledButton.icon(
                                    key: const Key('listingContinue'),
                                    icon: AppIcon(
                                      _step == steps.length - 1
                                          ? Icons.verified_outlined
                                          : Icons.arrow_forward_rounded,
                                    ),
                                    onPressed:
                                        state.busy ||
                                            (step == 'pricing' && !_quoteReady)
                                        ? null
                                        : () {
                                            updateGeneratedDetails(
                                              context,
                                              _cubit,
                                              _catalog,
                                            );
                                            if (!_cubit.valid(step)) {
                                              setState(() => _invalid = true);
                                              return;
                                            }
                                            if (_step == steps.length - 1) {
                                              _cubit.submit();
                                            } else {
                                              FocusScope.of(context).unfocus();
                                              setState(() {
                                                _step++;
                                                _invalid = false;
                                              });
                                            }
                                          },
                                    label: Text(
                                      words(
                                        context,
                                        _step == steps.length - 1
                                            ? 'submitReview'
                                            : 'continue',
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
}

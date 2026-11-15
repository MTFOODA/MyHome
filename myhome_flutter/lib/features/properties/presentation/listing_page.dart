import 'package:file_selector/file_selector.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/config/marketplace_strings.dart';
import '../../auth/presentation/auth_cubit.dart';
import '../domain/property_repository.dart';
import 'listing_cubit.dart';
import 'listing_pricing_step.dart';

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
    _cubit.close();
    super.dispose();
  }

  Widget field(String key, {bool number = false, int lines = 1}) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: TextFormField(
      key: ValueKey('${_step}_$key'),
      initialValue: _cubit.values[key]?.toString(),
      maxLines: lines,
      keyboardType: number
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      decoration: InputDecoration(
        labelText: words(
          context,
          {'approximate_location': 'location', 'price': 'ownerPrice'}[key] ??
              key,
        ),
      ),
      onChanged: (value) => setState(
        () => _cubit.setValue(
          key,
          number ? ListingCubit.latinDigits(value) : value,
        ),
      ),
    ),
  );
  Widget choices(String key, List<String> options) => Wrap(
    spacing: 12,
    runSpacing: 12,
    children: options
        .map(
          (value) => ChoiceChip(
            label: Text(words(context, value)),
            selected: _cubit.values[key] == value,
            onSelected: (_) => setState(() => _cubit.setValue(key, value)),
          ),
        )
        .toList(),
  );
  Widget yesNo(String key) => Wrap(
    spacing: 16,
    children: [true, false]
        .map(
          (value) => ChoiceChip(
            label: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              child: Text(words(context, value ? 'yes' : 'no')),
            ),
            selected: _cubit.values[key] == value,
            onSelected: (_) => setState(() => _cubit.setValue(key, value)),
          ),
        )
        .toList(),
  );
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
          children: [field('title'), field('description', lines: 5)],
        );
      case 'location':
        final ar = Localizations.localeOf(context).languageCode == 'ar';
        return Column(
          children: [
            if (_catalogFailed)
              TextButton(
                onPressed: _load,
                child: Text(words(context, 'retry')),
              ),
            DropdownButtonFormField<String>(
              initialValue: _cubit.values['governorate_id'] as String?,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: words(context, 'governorate'),
              ),
              items: (_catalog?.governorates ?? [])
                  .map(
                    (g) => DropdownMenuItem(
                      value: g.id,
                      child: Text(ar ? g.nameAr : g.nameEn),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() {
                _cubit.setValue('governorate_id', value);
                _cubit.values.remove('area_id');
              }),
            ),
            const SizedBox(height: 18),
            DropdownButtonFormField<String>(
              key: ValueKey(_cubit.values['governorate_id']),
              initialValue: _cubit.values['area_id'] as String?,
              isExpanded: true,
              decoration: InputDecoration(labelText: words(context, 'area')),
              items: (_catalog?.areas ?? [])
                  .where(
                    (a) => a.governorateId == _cubit.values['governorate_id'],
                  )
                  .map(
                    (a) => DropdownMenuItem(
                      value: a.id,
                      child: Text(ar ? a.nameAr : a.nameEn),
                    ),
                  )
                  .toList(),
              onChanged: (value) =>
                  setState(() => _cubit.setValue('area_id', value)),
            ),
            const SizedBox(height: 18),
            field('approximate_location'),
            field('latitude', number: true),
            field('longitude', number: true),
          ],
        );
      case 'dimensions':
        return Column(
          children: [
            'area_m2',
            'bedrooms',
            'bathrooms',
            'capacity',
          ].map((key) => field(key, number: true)).toList(),
        );
      case 'water':
      case 'electricity':
      case 'gas':
      case 'elevator':
      case 'negotiable':
        return yesNo(step);
      case 'finishing':
        return choices('finishing', [
          'red_brick',
          'plastered',
          'lux',
          'super_lux',
        ]);
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
            field('total_beds', number: true),
            field('available_beds', number: true),
          ],
        );
      case 'photos':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(words(context, 'coverHint')),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _cubit.photos.length >= 12
                  ? null
                  : () => pick('photo'),
              icon: const Icon(Icons.add_photo_alternate_outlined),
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
                      const Icon(Icons.broken_image_outlined),
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
                      icon: const Icon(Icons.arrow_upward),
                    ),
                    IconButton(
                      tooltip: words(context, 'remove'),
                      onPressed: () =>
                          setState(() => _cubit.photos.removeAt(i)),
                      icon: const Icon(Icons.close),
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
              initialValue: _cubit.nationalId,
              keyboardType: TextInputType.number,
              maxLength: 14,
              decoration: InputDecoration(
                labelText: words(context, 'nationalId'),
              ),
              onChanged: (value) =>
                  _cubit.nationalId = ListingCubit.latinDigits(value),
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: _cubit.birthDate,
              keyboardType: TextInputType.datetime,
              decoration: InputDecoration(
                labelText: words(context, 'birthDate'),
              ),
              onChanged: (value) =>
                  _cubit.birthDate = ListingCubit.latinDigits(value),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () => pick('identity'),
              icon: const Icon(Icons.badge_outlined),
              label: Text(
                _cubit.identity?.name ?? words(context, 'identityImage'),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => pick('ownership'),
              icon: const Icon(Icons.description_outlined),
              label: Text(
                _cubit.ownership?.name ?? words(context, 'ownershipImage'),
              ),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(words(context, 'consent')),
              value: _cubit.consent,
              onChanged: (value) => setState(() => _cubit.consent = value!),
            ),
          ],
        );
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final entry in _cubit.payload().entries.where(
              (entry) => !{
                'price',
                'rental_period',
                'custom_months',
                'deposit',
                'negotiable',
                'down_payment',
                'installment_count',
                'installment_amount',
              }.contains(entry.key),
            ))
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  words(
                    context,
                    entry.key == 'area_id'
                        ? 'area'
                        : entry.key == 'approximate_location'
                        ? 'location'
                        : entry.key,
                  ),
                ),
                subtitle: Text(
                  entry.key == 'area_id'
                      ? locationName(entry.value.toString())
                      : entry.value is bool
                      ? words(context, entry.value ? 'yes' : 'no')
                      : marketplaceWords.containsKey(entry.value.toString())
                      ? words(context, entry.value.toString())
                      : entry.value.toString(),
                ),
              ),
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
          'information': 'title',
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
            child: Scaffold(
              appBar: AppBar(title: Text(words(context, 'addProperty'))),
              body: SingleChildScrollView(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          LinearProgressIndicator(
                            value: state.busy
                                ? state.progress
                                : (_step + 1) / steps.length,
                          ),
                          const SizedBox(height: 12),
                          Text('${_step + 1} / ${steps.length}'),
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
                                  words(context, state.error ?? 'required'),
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(height: 28),
                          Row(
                            children: [
                              if (_step > 0)
                                TextButton(
                                  onPressed: state.busy
                                      ? null
                                      : () => setState(() {
                                          _step--;
                                          _quoteReady = false;
                                          _invalid = false;
                                        }),
                                  child: Text(words(context, 'back')),
                                ),
                              const Spacer(),
                              FilledButton(
                                onPressed:
                                    state.busy ||
                                        (step == 'pricing' && !_quoteReady)
                                    ? null
                                    : () {
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
                                child: Text(
                                  words(
                                    context,
                                    _step == steps.length - 1
                                        ? 'submitReview'
                                        : 'continue',
                                  ),
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
            ),
          );
        },
      );
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/config/marketplace_strings.dart';
import '../../../core/widgets/app_layout.dart';
import '../../../core/widgets/choice_artwork.dart';
import '../../auth/presentation/auth_cubit.dart';
import '../../auth/presentation/intents_page.dart';
import '../../chat/presentation/chat_page.dart';
import '../../sales/domain/sales_repository.dart';
import '../../sales/presentation/sales_pages.dart';
import '../../sales/presentation/sales_strings.dart';
import '../domain/property_repository.dart';
import '../domain/location_repository.dart';
import 'property_facts_grid.dart';
import 'housing_group_page.dart';
import 'property_map.dart';
import 'property_photo.dart';

class PropertyDetailsPage extends StatefulWidget {
  final String id;
  final PropertyRepository repository;
  const PropertyDetailsPage({
    super.key,
    required this.id,
    required this.repository,
  });
  @override
  State<PropertyDetailsPage> createState() => _PropertyDetailsPageState();
}

class _PropertyDetailsPageState extends State<PropertyDetailsPage> {
  late Future<Map<String, dynamic>> _details;
  bool _saving = false;
  int _photoIndex = 0;
  final _gallery = PageController();
  @override
  void dispose() {
    _gallery.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _details = widget.repository.details(widget.id);
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _saving = true);
    try {
      await action();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is SalesFailure
                  ? salesText(context, e.code)
                  : e is PropertyException
                  ? words(context, e.code)
                  : words(context, 'saveError'),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _buy(Map<String, dynamic> data) async {
    final account = context.read<AuthCubit>().state.account!;
    final intent = {
      'sale_cash': 'buyer_cash',
      'sale_installments': 'buyer_installments',
      'private_rental': 'tenant_private',
      'shared_rental': 'tenant_shared',
    }[data['category']];
    if (!account.intents.contains(intent)) {
      await Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => const IntentsPage(settings: true),
        ),
      );
      return;
    }
    await _run(() async {
      final id = await context.read<SalesRepository>().start(widget.id);
      if (mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute<void>(builder: (_) => SalesDetailPage(id: id)),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) => AppScaffold(
    appBar: AppBar(title: Text(words(context, 'details'))),
    body: FutureBuilder<Map<String, dynamic>>(
      future: _details,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: TextButton(
              onPressed: () => setState(
                () => _details = widget.repository.details(widget.id),
              ),
              child: Text(words(context, 'retry')),
            ),
          );
        }
        final data = snapshot.data!;
        if (data['unavailable'] == true) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    data['title'] as String,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    words(
                      context,
                      data['availability'] == 'unavailable'
                          ? 'listingUnavailable'
                          : data['availability'] as String,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    words(context, 'savedUnavailableHint'),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }
        final account = context.watch<AuthCubit>().state.account;
        final owner = account?.id == data['owner_id'];
        final ar = Localizations.localeOf(context).languageCode == 'ar';
        final photos = List<String>.from(data['photo_ids'] as List? ?? []);
        final facts = <PropertyFact>[];
        String display(dynamic value) => value is bool
            ? words(context, value ? 'yes' : 'no')
            : marketplaceWords.containsKey('$value')
            ? words(context, '$value')
            : '$value';
        void fact(String key, String artwork) {
          if (data[key] != null) {
            facts.add(
              PropertyFact(
                artwork,
                words(context, key == 'property_kind' ? 'propertyKind' : key),
                display(data[key]),
                muted: data[key] == false,
              ),
            );
          }
        }

        fact('category', '${data['category']}');
        if (data['property_kind'] != null) {
          fact('property_kind', '${data['property_kind']}');
        }
        fact('area_m2', 'area_m2');
        fact('bedrooms', 'bedrooms');
        fact('bathrooms', 'bathrooms');
        if (data['area_measurement'] != null) {
          fact('area_measurement', '${data['area_measurement']}');
        }
        if (data['finishing'] != null) {
          fact('finishing', '${data['finishing']}');
        }
        if (data['furnished'] != null) {
          facts.add(
            PropertyFact(
              data['furnished'] == true ? 'furnished' : 'unfurnished',
              words(context, 'furnished'),
              words(
                context,
                data['furnished'] == true
                    ? 'furnishedOption'
                    : 'unfurnishedOption',
              ),
            ),
          );
        }
        for (final key in ['water', 'electricity', 'gas', 'elevator']) {
          fact(key, key);
        }
        if (data['rental_period'] != null) {
          fact('rental_period', '${data['rental_period']}');
        }
        if (data['category'] == 'shared_rental') {
          fact('capacity', 'capacity');
          fact('total_beds', 'total_beds');
          fact('available_beds', 'available_beds');
        }
        if (data['rental_period'] == 'custom') {
          fact('custom_months', 'custom_months');
        }
        final address =
            data[ar ? 'full_address_ar' : 'full_address_en'] ??
            data['approximate_location'] ??
            '';
        final price = data['all_in'] == false
            ? salesText(context, 'eligibilityPending')
            : '${data['price']} ${ar ? 'ج.م' : 'EGP'}';
        final content = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: SizedBox(
                height: photos.isEmpty
                    ? 210
                    : AppLayout.wide(context)
                    ? 440
                    : 260,
                child: photos.isEmpty
                    ? PropertyPhoto(
                        id: null,
                        category: data['category'] as String,
                        repository: widget.repository,
                      )
                    : PageView(
                        controller: _gallery,
                        onPageChanged: (value) =>
                            setState(() => _photoIndex = value),
                        children: [
                          for (final photo in photos)
                            PropertyPhoto(
                              id: photo,
                              category: data['category'] as String,
                              repository: widget.repository,
                              private: owner || account?.role == 'admin',
                            ),
                        ],
                      ),
              ),
            ),
            if (photos.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      tooltip: MaterialLocalizations.of(
                        context,
                      ).previousPageTooltip,
                      onPressed: _photoIndex == 0
                          ? null
                          : () => _gallery.previousPage(
                              duration: MediaQuery.disableAnimationsOf(context)
                                  ? Duration.zero
                                  : const Duration(milliseconds: 250),
                              curve: Curves.easeOut,
                            ),
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Text('${_photoIndex + 1} / ${photos.length}'),
                    IconButton(
                      tooltip: MaterialLocalizations.of(
                        context,
                      ).nextPageTooltip,
                      onPressed: _photoIndex == photos.length - 1
                          ? null
                          : () => _gallery.nextPage(
                              duration: MediaQuery.disableAnimationsOf(context)
                                  ? Duration.zero
                                  : const Duration(milliseconds: 250),
                              curve: Curves.easeOut,
                            ),
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            Text(
              data['title'] as String,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            Text(
              price,
              key: const Key('propertyFinalPrice'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 24),
            if (account != null && !owner && data['availability'] == 'active')
              Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: [
                  FilledButton(
                    key: const Key('buyProperty'),
                    onPressed: _saving || data['all_in'] != true
                        ? null
                        : () => _buy(data),
                    child: Text(
                      words(
                        context,
                        '${data['category']}'.startsWith('sale_')
                            ? 'buyProperty'
                            : 'rentProperty',
                      ),
                    ),
                  ),
                  OutlinedButton(
                    key: const Key('contactOwner'),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => ChatPage(propertyId: widget.id),
                      ),
                    ),
                    child: Text(words(context, 'contactOwner')),
                  ),
                ],
              ),
            const SizedBox(height: 24),
            PropertyFactsGrid(facts: facts),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const ChoiceArtwork('location', size: 86),
                    const SizedBox(height: 12),
                    Text(
                      words(context, 'completeAddress'),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    SelectableText('$address', textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
            if (PropertyLocation.fromValues(data) case final point?)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: SizedBox(
                    height: 300,
                    child: PropertyMap(selected: point),
                  ),
                ),
              ),
            if (data['property_kind'] == null &&
                '${data['description'] ?? ''}'.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      '${data['description']}'.replaceAll('\n', ' '),
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ),
              ),
            if (data['category'] == 'shared_rental' &&
                data['availability'] == 'active' &&
                (account?.canFindRoommates ?? false))
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: OutlinedButton(
                  onPressed: _saving
                      ? null
                      : () => _run(() async {
                          await widget.repository.apply(widget.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(words(context, 'applied')),
                              ),
                            );
                          }
                        }),
                  child: Text(words(context, 'applyHousing')),
                ),
              ),
            if (data['category'] == 'shared_rental' && owner)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: OutlinedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => HousingGroupPage(
                        propertyId: widget.id,
                        repository: widget.repository,
                      ),
                    ),
                  ),
                  child: Text(words(context, 'manageGroup')),
                ),
              ),
            if (!owner) ...[
              const SizedBox(height: 24),
              Text(
                words(context, 'saveDisclosure'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                key: const Key('saveProperty'),
                onPressed: _saving
                    ? null
                    : () => _run(() async {
                        await widget.repository.save(widget.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(words(context, 'saved'))),
                          );
                        }
                      }),
                child: Text(words(context, 'save')),
              ),
            ],
          ],
        );
        return SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: AppLayout.formWidth(context),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 420),
                  builder: (context, value, child) => Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 12 * (1 - value)),
                      child: child,
                    ),
                  ),
                  child: content,
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}

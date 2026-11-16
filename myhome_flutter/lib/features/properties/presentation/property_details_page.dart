import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/config/marketplace_strings.dart';
import '../../../core/config/price_text.dart';
import '../../../core/widgets/app_layout.dart';
import '../../auth/presentation/auth_cubit.dart';
import '../../auth/presentation/intents_page.dart';
import '../../chat/presentation/chat_page.dart';
import '../../sales/domain/sales_repository.dart';
import '../../sales/presentation/sales_pages.dart';
import '../../sales/presentation/sales_strings.dart';
import '../domain/property_repository.dart';
import '../domain/location_repository.dart';
import 'housing_group_page.dart';
import 'property_map.dart';
import 'property_gallery.dart';
import 'property_features_grid.dart';
import 'similar_properties.dart';

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

  Widget _fact(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) => SizedBox(
    width: 132,
    child: Padding(
      padding: const EdgeInsetsDirectional.only(end: 14, bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 26, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 16),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    ),
  );

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
            child: TextButton.icon(
              onPressed: () => setState(
                () => _details = widget.repository.details(widget.id),
              ),
              icon: const Icon(Icons.refresh),
              label: Text(words(context, 'retry')),
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
                    '${data['title']}',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    words(
                      context,
                      data['availability'] == 'unavailable'
                          ? 'listingUnavailable'
                          : '${data['availability']}',
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
        final address =
            data[ar ? 'full_address_ar' : 'full_address_en'] ??
            data['approximate_location'] ??
            '';
        final colors = Theme.of(context).colorScheme;
        final price = data['all_in'] == false
            ? salesText(context, 'eligibilityPending')
            : '${priceText('${data['price']}')} ${ar ? 'ج.م' : 'EGP'}';
        String display(dynamic value) => value == null
            ? words(context, 'unspecified')
            : marketplaceWords.containsKey('$value')
            ? words(context, '$value')
            : '$value';
        final summary = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                Chip(label: Text(words(context, '${data['category']}'))),
                if (data['property_kind'] != null)
                  Chip(label: Text(display(data['property_kind']))),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              '${data['title']}',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w600,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.location_on_outlined,
                  color: colors.onSurfaceVariant,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SelectableText(
                    '$address',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ],
            ),
          ],
        );
        final facts = Wrap(
          spacing: 8,
          runSpacing: 16,
          children: [
            _fact(
              context,
              Icons.square_foot,
              words(context, 'area_m2'),
              '${data['area_m2']} m²',
            ),
            _fact(
              context,
              Icons.bed_outlined,
              words(context, 'bedrooms'),
              display(data['bedrooms']),
            ),
            _fact(
              context,
              Icons.bathtub_outlined,
              words(context, 'bathrooms'),
              display(data['bathrooms']),
            ),
            if (data['floor_number'] != null)
              _fact(
                context,
                Icons.layers_outlined,
                words(context, 'floor_number'),
                data['floor_number'] == 0
                    ? words(context, 'groundFloor')
                    : display(data['floor_number']),
              ),
            _fact(
              context,
              Icons.auto_awesome_outlined,
              words(context, 'finishing'),
              display(data['finishing']),
            ),
            if (data['furnished'] != null)
              _fact(
                context,
                Icons.chair_outlined,
                words(context, 'furnished'),
                words(
                  context,
                  data['furnished'] == true
                      ? 'furnishedOption'
                      : 'unfurnishedOption',
                ),
              ),
            if (data['kitchen_type'] != null)
              _fact(
                context,
                Icons.kitchen_outlined,
                words(context, 'kitchen_type'),
                display(data['kitchen_type']),
              ),
            if (data['orientation'] != null)
              _fact(
                context,
                Icons.explore_outlined,
                words(context, 'orientation'),
                display(data['orientation']),
              ),
            if (data['area_measurement'] != null)
              _fact(
                context,
                Icons.straighten,
                words(context, 'area_measurement'),
                display(data['area_measurement']),
              ),
            if (data['rental_period'] != null)
              _fact(
                context,
                Icons.event_outlined,
                words(context, 'rental_period'),
                display(data['rental_period']),
              ),
            if (data['rental_period'] == 'custom')
              _fact(
                context,
                Icons.calendar_month_outlined,
                words(context, 'custom_months'),
                display(data['custom_months']),
              ),
            if (data['category'] == 'shared_rental')
              for (final key in ['capacity', 'total_beds', 'available_beds'])
                _fact(
                  context,
                  Icons.groups_outlined,
                  words(context, key),
                  display(data[key]),
                ),
          ],
        );
        final contact = Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border.all(color: colors.outlineVariant),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: colors.shadow.withValues(alpha: .06),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                words(context, 'finalPrice'),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                price,
                key: const Key('propertyFinalPrice'),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (data['all_in'] == true) ...[
                const SizedBox(height: 12),
                Text(
                  words(context, 'priceInclusive'),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: colors.primary),
                ),
              ],
              const Divider(height: 40),
              Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    child: Text(
                      '${data['owner_name'] ?? words(context, 'propertyOwner')}'
                          .characters
                          .take(1)
                          .toString(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${data['owner_name'] ?? words(context, 'propertyOwner')}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          words(context, 'propertyOwner'),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  if (data['ownerVerified'] == true)
                    Icon(
                      Icons.verified_outlined,
                      color: colors.primary,
                      semanticLabel: words(context, 'approved'),
                    ),
                ],
              ),
              if (account != null &&
                  !owner &&
                  data['availability'] == 'active') ...[
                const SizedBox(height: 24),
                FilledButton.icon(
                  key: const Key('contactOwner'),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => ChatPage(propertyId: widget.id),
                    ),
                  ),
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: Text(words(context, 'contactOwner')),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  key: const Key('buyProperty'),
                  onPressed: _saving || data['all_in'] != true
                      ? null
                      : () => _buy(data),
                  icon: const Icon(Icons.handshake_outlined),
                  label: Text(
                    words(
                      context,
                      '${data['category']}'.startsWith('sale_')
                          ? 'buyProperty'
                          : 'rentProperty',
                    ),
                  ),
                ),
              ],
              if (!owner) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
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
                  icon: const Icon(Icons.bookmark_border),
                  label: Text(words(context, 'save')),
                ),
                const SizedBox(height: 14),
                Text(
                  words(context, 'saveDisclosure'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        );
        final content = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PropertyGallery(
              photos: photos,
              category: '${data['category']}',
              repository: widget.repository,
              private: owner || account?.role == 'admin',
            ),
            const SizedBox(height: 36),
            LayoutBuilder(
              builder: (context, box) => box.maxWidth >= 1000
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              summary,
                              const Divider(height: 48),
                              facts,
                            ],
                          ),
                        ),
                        const SizedBox(width: 40),
                        SizedBox(width: 350, child: contact),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        summary,
                        const SizedBox(height: 24),
                        contact,
                        const Divider(height: 48),
                        facts,
                      ],
                    ),
            ),
            const Divider(height: 64),
            PropertyFeaturesGrid(data: data),
            const SizedBox(height: 40),
            if (PropertyLocation.fromValues(data) case final point?) ...[
              Text(
                words(context, 'completeAddress'),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: SizedBox(
                  height: 300,
                  child: PropertyMap(selected: point),
                ),
              ),
              const SizedBox(height: 24),
            ],
            if (data['property_kind'] == null &&
                '${data['description'] ?? ''}'.isNotEmpty) ...[
              Text(
                words(context, 'description'),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Text(
                '${data['description']}'.replaceAll('\n', ' '),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
            if (data['category'] == 'shared_rental' &&
                data['availability'] == 'active' &&
                (account?.canFindRoommates ?? false))
              Padding(
                padding: const EdgeInsets.only(top: 24),
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
                padding: const EdgeInsets.only(top: 24),
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
            const Divider(height: 64),
            SimilarProperties(
              propertyId: widget.id,
              repository: widget.repository,
              onDetails: (id) => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => PropertyDetailsPage(
                    id: id,
                    repository: widget.repository,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        );
        return ColoredBox(
          color: Theme.of(context).brightness == Brightness.light
              ? const Color(0xfff8f7f3)
              : colors.surface,
          child: SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1480),
                child: Padding(
                  padding: EdgeInsets.all(
                    AppLayout.width(context) < 600 ? 18 : 36,
                  ),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 350),
                    builder: (context, value, child) => Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 10 * (1 - value)),
                        child: child,
                      ),
                    ),
                    child: content,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}

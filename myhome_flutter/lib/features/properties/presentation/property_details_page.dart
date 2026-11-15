import '../../../core/widgets/app_layout.dart';
import '../../../core/widgets/app_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../auth/presentation/auth_cubit.dart';
import 'housing_group_page.dart';
import '../../sales/domain/sales_repository.dart';
import '../../sales/presentation/sales_pages.dart';
import '../../sales/presentation/financial_card.dart';
import '../../sales/presentation/sales_strings.dart';
import '../../../core/config/marketplace_strings.dart';
import '../domain/property_repository.dart';
import '../domain/location_repository.dart';
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
  @override
  void initState() {
    super.initState();
    _details = widget.repository.details(widget.id);
  }

  @override
  Widget build(BuildContext context) => AppScaffold(
    appBar: AppBar(title: Text(words(context, 'details'))),
    body: FutureBuilder(
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
                  const AppIcon(Icons.info_outline, size: 56),
                  const SizedBox(height: 16),
                  Text(
                    data['title'] as String,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    words(
                      context,
                      data['availability'] == 'unavailable'
                          ? 'listingUnavailable'
                          : data['availability'] as String,
                    ),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
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
        final photos = List<String>.from(data['photo_ids'] as List);
        return SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: AppLayout.formWidth(context),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (photos.isNotEmpty)
                      SizedBox(
                        height: 300,
                        child: PageView(
                          children: [
                            for (final id in photos)
                              Padding(
                                padding: const EdgeInsets.all(4),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: PropertyPhoto(
                                    id: id,
                                    repository: widget.repository,
                                    private:
                                        account?.id == data['owner_id'] ||
                                        account?.role == 'admin',
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 20),
                    if (PropertyLocation.fromValues(data)
                        case final point?) ...[
                      SizedBox(
                        height: 310,
                        child: PropertyMap(selected: point),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Text(
                      data['title'] as String,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      data['all_in'] == false
                          ? salesText(context, 'eligibilityPending')
                          : '${data['price']} ${Localizations.localeOf(context).languageCode == 'ar' ? 'ج.م' : 'EGP'}',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    Text(data['description'] as String),
                    if (data['financial'] is Map)
                      FinancialCard(
                        snapshot: Map<String, dynamic>.from(
                          data['financial'] as Map,
                        ),
                        commitmentEnabled: data['all_in'] != false,
                      ),
                    if (data['all_in'] == true &&
                        data['availability'] == 'active' &&
                        account != null &&
                        account.id != data['owner_id'] &&
                        account.intents.contains(
                          {
                            'sale_cash': 'buyer_cash',
                            'sale_installments': 'buyer_installments',
                            'private_rental': 'tenant_private',
                            'shared_rental': 'tenant_shared',
                          }[data['category']],
                        ))
                      FilledButton.icon(
                        onPressed: _saving
                            ? null
                            : () async {
                                setState(() => _saving = true);
                                try {
                                  final id = await context
                                      .read<SalesRepository>()
                                      .start(widget.id);
                                  if (context.mounted) {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute<void>(
                                        builder: (_) => SalesDetailPage(id: id),
                                      ),
                                    );
                                  }
                                } on SalesFailure catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          salesText(context, e.code),
                                        ),
                                      ),
                                    );
                                  }
                                } catch (_) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          salesText(context, 'NETWORK_ERROR'),
                                        ),
                                      ),
                                    );
                                  }
                                }
                                if (mounted) setState(() => _saving = false);
                              },
                        icon: const AppIcon(Icons.handshake_outlined),
                        label: Text(salesText(context, 'start')),
                      ),
                    const SizedBox(height: 24),
                    for (final key in [
                      'category',
                      'approximate_location',
                      'area_m2',
                      'bedrooms',
                      'bathrooms',
                      if (data['category'] == 'shared_rental') 'capacity',
                      if (data['area_measurement'] != null) 'area_measurement',
                      if (data['furnished'] != null) 'furnished',
                      'finishing',
                      'water',
                      'electricity',
                      'gas',
                      'elevator',
                      'negotiable',
                      'rental_period',
                      'custom_months',
                      'deposit',
                      'down_payment',
                      'installment_count',
                      'installment_amount',
                      'total_beds',
                      'available_beds',
                    ])
                      if (data[key] != null)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            words(
                              context,
                              key == 'approximate_location' ? 'location' : key,
                            ),
                          ),
                          subtitle: Text(
                            data[key] is bool
                                ? words(
                                    context,
                                    data[key] as bool ? 'yes' : 'no',
                                  )
                                : marketplaceWords.containsKey(
                                    data[key].toString(),
                                  )
                                ? words(context, data[key].toString())
                                : data[key].toString(),
                          ),
                        ),
                    if (data['category'] == 'shared_rental' &&
                        data['availability'] == 'active' &&
                        (account?.canFindRoommates ?? false)) ...[
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: _saving
                            ? null
                            : () async {
                                setState(() => _saving = true);
                                try {
                                  await widget.repository.apply(widget.id);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          words(context, 'applicationSent'),
                                        ),
                                      ),
                                    );
                                  }
                                } catch (_) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          words(context, 'saveError'),
                                        ),
                                      ),
                                    );
                                  }
                                }
                                if (mounted) setState(() => _saving = false);
                              },
                        child: Text(words(context, 'applyHousing')),
                      ),
                    ],
                    if (data['category'] == 'shared_rental' &&
                        account?.id == data['owner_id']) ...[
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => HousingGroupPage(
                              propertyId: widget.id,
                              repository: widget.repository,
                            ),
                          ),
                        ),
                        child: Text(words(context, 'applications')),
                      ),
                    ],
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _saving
                          ? null
                          : () async {
                              setState(() => _saving = true);
                              try {
                                await widget.repository.save(widget.id);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(words(context, 'saved')),
                                    ),
                                  );
                                }
                              } catch (_) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        words(context, 'saveError'),
                                      ),
                                    ),
                                  );
                                }
                              }
                              if (mounted) setState(() => _saving = false);
                            },
                      icon: const AppIcon(Icons.favorite_border),
                      label: Text(words(context, 'save')),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}

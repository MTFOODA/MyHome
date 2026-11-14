import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../auth/presentation/auth_cubit.dart';
import 'housing_group_page.dart';
import '../../../core/config/marketplace_strings.dart';
import '../domain/property_repository.dart';

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
  Widget build(BuildContext context) => Scaffold(
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
        final account = context.watch<AuthCubit>().state.account;
        final photos = List<String>.from(data['photo_ids'] as List);
        return SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (photos.isNotEmpty)
                      SizedBox(
                        height: 300,
                        child: PageView(
                          children: photos
                              .map(
                                (id) => Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.network(
                                      widget.repository.photoUrl(id),
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) => const Center(
                                        child: Icon(
                                          Icons.image_not_supported_outlined,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    const SizedBox(height: 20),
                    Text(
                      data['title'] as String,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${data['price']} ${Localizations.localeOf(context).languageCode == 'ar' ? 'ج.م' : 'EGP'}',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    Text(data['description'] as String),
                    const SizedBox(height: 24),
                    for (final key in [
                      'category',
                      'approximate_location',
                      'area_m2',
                      'bedrooms',
                      'bathrooms',
                      'capacity',
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
                      icon: const Icon(Icons.favorite_border),
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

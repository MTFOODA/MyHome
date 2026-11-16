import 'package:myhome_flutter/features/properties/domain/property_repository.dart';

const testProperty = PropertySummary(
  id: 'p1',
  title: 'Test apartment',
  category: 'private_rental',
  price: '5000',
  areaM2: '100',
  locationAr: 'المعادي',
  locationEn: 'Maadi',
  negotiable: false,
  bedrooms: 2,
  bathrooms: 1,
  capacity: 3,
);

class FakePropertyRepository implements PropertyRepository {
  @override
  Future<List<PropertySummary>> similar(String id) async => [];
  @override
  Future<Map<String, dynamic>> interested(String id, {String? before}) async =>
      {'items': [], 'next_cursor': null};
  @override
  Future<List<PortfolioCount>> portfolio() async => const [];
  @override
  Future<OwnerPage> ownerPage(
    String group, {
    String scope = 'current',
    String query = '',
    String availability = 'all',
    String? cursor,
  }) async => OwnerPage(items.take(3).toList(), items.length, null);
  @override
  Future<List<String>> ownerSuggestions(
    String group,
    String query,
    String scope,
  ) async => [];
  @override
  Future<void> changeAvailability(String id, String availability) async {}
  @override
  Future<Map<String, dynamic>> priceQuote(Map<String, dynamic> values) async =>
      {'requires_agreement': true};
  @override
  Future<List<Map<String, dynamic>>> groups() async => [];
  final searches = <Map<String, dynamic>>[];
  @override
  Future<List<Map<String, dynamic>>> verifications() async => [];
  @override
  Future<List<int>> privateImage(String id) async => [];
  @override
  Future<void> review(String id, bool approved, String note) async {}
  @override
  Future<void> apply(String propertyId) async {}
  @override
  Future<List<Map<String, dynamic>>> applications(String propertyId) async =>
      [];
  @override
  Future<void> accept(String applicationId) async {}
  @override
  Future<void> createGroup(String propertyId, String tenantAdminId) async {}
  List<PropertySummary> items = [];
  int detailCalls = 0, saveCalls = 0, createCalls = 0, updateCalls = 0;
  Map<String, dynamic>? submittedPayload;
  bool failSubmit = false;
  @override
  Future<LocationCatalog> locations() async => const LocationCatalog(
    [LocationOption('cairo', 'القاهرة', 'Cairo')],
    [LocationOption('maadi', 'المعادي', 'Maadi', 'cairo')],
  );
  @override
  Future<PropertyResults> discover(
    Map<String, dynamic> filters,
    int page,
  ) async {
    searches.add(Map.of(filters));
    return PropertyResults(items, items.length, page);
  }

  @override
  Future<Map<String, dynamic>> details(String id) async {
    detailCalls++;
    return {
      'title': 'Test apartment',
      'price': '5000',
      'description': 'Test property',
      'photo_ids': [],
      'category': 'private_rental',
      'owner_id': 'other-owner',
      'availability': 'active',
      'all_in': true,
      'area_m2': '100',
      'bedrooms': 2,
      'bathrooms': 1,
      'water': true,
      'electricity': true,
      'gas': false,
      'elevator': true,
      'finishing': 'lux',
      'furnished': false,
      'rental_period': 'one_year',
      'approximate_location': 'Known area',
    };
  }

  @override
  Future<List<PropertySummary>> favorites() async => items;
  @override
  Future<List<PropertySummary>> mine() async => items;
  @override
  Future<void> save(String id) async {
    saveCalls++;
  }

  @override
  Future<void> unsave(String id) async {}
  @override
  String photoUrl(String id) => 'https://example.test/$id';
  @override
  Future<String> create(Map<String, dynamic> values) async {
    createCalls++;
    submittedPayload = values;
    return 'draft';
  }

  @override
  Future<void> update(String id, Map<String, dynamic> values) async {
    updateCalls++;
    submittedPayload = values;
  }

  @override
  Future<String> upload(
    UploadImage file,
    String kind, {
    String? nationalId,
    String? birthDate,
  }) async => '$kind-${file.name}';
  @override
  Future<void> attachPhotos(String propertyId, List<String> photos) async {}
  @override
  Future<void> submit(
    String propertyId,
    String identityId,
    String ownershipId,
  ) async {
    if (failSubmit) throw const PropertyException('NETWORK_ERROR');
  }

  @override
  Future<List<Map<String, dynamic>>> roommates() async => [];
}

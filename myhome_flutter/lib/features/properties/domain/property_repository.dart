class PropertySummary {
  final String id, title, category, price, areaM2, locationAr, locationEn;
  final String? coverId;
  final bool negotiable;
  final int bedrooms, bathrooms;
  final int visitorCount, savedCount;
  final int? capacity;
  final bool coverPrivate;
  final double? latitude, longitude;
  final String? areaMeasurement;
  final String status;
  final String availability;
  final bool unavailable;
  final bool allIn;
  final String priceBasis;
  const PropertySummary({
    required this.id,
    required this.title,
    required this.category,
    required this.price,
    required this.areaM2,
    required this.locationAr,
    required this.locationEn,
    required this.negotiable,
    required this.bedrooms,
    required this.bathrooms,
    required this.capacity,
    this.coverPrivate = false,
    this.latitude,
    this.longitude,
    this.areaMeasurement,
    this.coverId,
    this.status = 'approved',
    this.availability = 'active',
    this.unavailable = false,
    this.allIn = true,
    this.priceBasis = '',
    this.visitorCount = 0,
    this.savedCount = 0,
  });
  factory PropertySummary.fromJson(Map<String, dynamic> value) =>
      PropertySummary(
        id: value['id'] as String,
        title: value['title'] as String,
        category: value['category'] as String,
        price: value['price'].toString(),
        areaM2: value['area_m2'].toString(),
        locationAr: value['location_ar'] as String,
        locationEn: value['location_en'] as String,
        negotiable: value['negotiable'] as bool,
        bedrooms: value['bedrooms'] as int,
        bathrooms: value['bathrooms'] as int,
        capacity: value['capacity'] as int?,
        coverPrivate: value['cover_private'] == true,
        latitude: double.tryParse('${value['latitude']}'),
        longitude: double.tryParse('${value['longitude']}'),
        areaMeasurement: value['area_measurement'] as String?,
        coverId: value['cover_id'] as String?,
        status: value['status'] as String? ?? 'approved',
        availability: value['availability'] as String? ?? 'active',
        unavailable: value['unavailable'] as bool? ?? false,
        allIn: value['all_in'] as bool? ?? true,
        priceBasis: value['price_basis'] as String? ?? '',
        visitorCount: value['visitor_count'] as int? ?? 0,
        savedCount: value['saved_count'] as int? ?? 0,
      );
}

class PropertyResults {
  final List<PropertySummary> items;
  final int total, page;
  const PropertyResults(this.items, this.total, this.page);
}

class OwnerPage {
  final List<PropertySummary> items;
  final int total;
  final String? nextCursor;
  const OwnerPage(this.items, this.total, this.nextCursor);
}

class PortfolioCount {
  final String group;
  final int current, published, paused, history, awaiting;
  const PortfolioCount(
    this.group,
    this.current,
    this.published,
    this.paused,
    this.history,
    this.awaiting,
  );
  factory PortfolioCount.fromJson(Map<String, dynamic> value) => PortfolioCount(
    value['group'] as String,
    value['current'] as int,
    value['published'] as int,
    value['paused'] as int,
    value['history'] as int,
    value['awaiting'] as int,
  );
}

class LocationOption {
  final String id, nameAr, nameEn;
  final String? governorateId;
  const LocationOption(this.id, this.nameAr, this.nameEn, [this.governorateId]);
  factory LocationOption.fromJson(Map<String, dynamic> value) => LocationOption(
    value['id'] as String,
    value['name_ar'] as String,
    value['name_en'] as String,
    value['governorate_id'] as String?,
  );
}

class LocationCatalog {
  final List<LocationOption> governorates, areas;
  const LocationCatalog(this.governorates, this.areas);
}

class UploadImage {
  final String name;
  final List<int> bytes;
  const UploadImage(this.name, this.bytes);
}

class PropertyException implements Exception {
  final String code;
  const PropertyException(this.code);
}

abstract class PropertyRepository {
  Future<LocationCatalog> locations();
  Future<PropertyResults> discover(Map<String, dynamic> filters, int page);
  Future<Map<String, dynamic>> details(String id);
  Future<List<PropertySummary>> similar(String id);
  Future<List<PropertySummary>> favorites();
  Future<void> save(String id);
  Future<void> unsave(String id);
  Future<List<PropertySummary>> mine();
  Future<List<PortfolioCount>> portfolio();
  Future<Map<String, dynamic>> interested(String id, {String? before});
  Future<OwnerPage> ownerPage(
    String group, {
    String scope = 'current',
    String query = '',
    String availability = 'all',
    String? cursor,
  });
  Future<List<String>> ownerSuggestions(
    String group,
    String query,
    String scope,
  );
  Future<void> changeAvailability(String id, String availability);
  Future<Map<String, dynamic>> priceQuote(Map<String, dynamic> values);
  Future<List<Map<String, dynamic>>> groups();
  String photoUrl(String id);
  Future<String> create(Map<String, dynamic> values);
  Future<void> update(String id, Map<String, dynamic> values);
  Future<String> upload(
    UploadImage file,
    String kind, {
    String? nationalId,
    String? birthDate,
  });
  Future<void> attachPhotos(String propertyId, List<String> photos);
  Future<void> submit(String propertyId, String identityId, String ownershipId);
  Future<List<Map<String, dynamic>>> roommates();
  Future<List<Map<String, dynamic>>> verifications();
  Future<List<int>> privateImage(String id);
  Future<void> review(String id, bool approved, String note);
  Future<void> apply(String propertyId);
  Future<List<Map<String, dynamic>>> applications(String propertyId);
  Future<void> accept(String applicationId);
  Future<void> createGroup(String propertyId, String tenantAdminId);
}

class PropertySummary {
  final String id, title, category, price, areaM2, locationAr, locationEn;
  final String? coverId;
  final bool negotiable;
  final int bedrooms, bathrooms, capacity;
  final String status;
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
    this.coverId,
    this.status = 'approved',
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
        capacity: value['capacity'] as int,
        coverId: value['cover_id'] as String?,
        status: value['status'] as String? ?? 'approved',
      );
}

class PropertyResults {
  final List<PropertySummary> items;
  final int total, page;
  const PropertyResults(this.items, this.total, this.page);
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
  Future<List<PropertySummary>> favorites();
  Future<void> save(String id);
  Future<void> unsave(String id);
  Future<List<PropertySummary>> mine();
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

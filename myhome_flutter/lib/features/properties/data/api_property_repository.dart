import 'package:dio/dio.dart';
import '../../auth/data/api_auth_repository.dart';
import '../domain/property_repository.dart';

class ApiPropertyRepository implements PropertyRepository {
  @override
  Future<List<Map<String, dynamic>>> verifications() => _call(
    () async => (await auth.authorizedRequest('/admin/verifications') as List)
        .map((value) => Map<String, dynamic>.from(value as Map))
        .toList(),
  );
  @override
  Future<List<int>> privateImage(String id) =>
      _call(() => auth.authorizedBytes('/private-assets/$id'));
  @override
  Future<void> review(String id, bool approved, String note) => _call(() async {
    await auth.authorizedRequest(
      '/admin/verifications/$id/review',
      method: 'POST',
      data: {'approved': approved, 'note': note},
    );
  });
  @override
  Future<void> apply(String propertyId) => _call(() async {
    await auth.authorizedRequest(
      '/properties/$propertyId/applications',
      method: 'POST',
    );
  });
  @override
  Future<List<Map<String, dynamic>>> applications(String propertyId) => _call(
    () async =>
        (await auth.authorizedRequest('/properties/$propertyId/applications')
                as List)
            .map((value) => Map<String, dynamic>.from(value as Map))
            .toList(),
  );
  @override
  Future<void> accept(String applicationId) => _call(() async {
    await auth.authorizedRequest(
      '/applications/$applicationId/accept',
      method: 'POST',
    );
  });
  @override
  Future<void> createGroup(String propertyId, String tenantAdminId) =>
      _call(() async {
        await auth.authorizedRequest(
          '/groups',
          method: 'POST',
          data: {'property_id': propertyId, 'tenant_admin_id': tenantAdminId},
        );
      });
  final Dio dio;
  final ApiAuthRepository auth;
  ApiPropertyRepository(this.dio, this.auth);
  Future<T> _call<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on DioException catch (error) {
      final data = error.response?.data;
      throw PropertyException(
        data is Map && data['detail'] is String
            ? data['detail'] as String
            : 'NETWORK_ERROR',
      );
    }
  }

  List<PropertySummary> _items(dynamic data) => (data['items'] as List)
      .map(
        (value) =>
            PropertySummary.fromJson(Map<String, dynamic>.from(value as Map)),
      )
      .toList();
  @override
  Future<LocationCatalog> locations() => _call(() async {
    final data = (await dio.get<dynamic>('/locations')).data;
    return LocationCatalog(
      (data['governorates'] as List)
          .map(
            (value) => LocationOption.fromJson(
              Map<String, dynamic>.from(value as Map),
            ),
          )
          .toList(),
      (data['areas'] as List)
          .map(
            (value) => LocationOption.fromJson(
              Map<String, dynamic>.from(value as Map),
            ),
          )
          .toList(),
    );
  });
  @override
  Future<PropertyResults> discover(Map<String, dynamic> filters, int page) =>
      _call(() async {
        final data = (await dio.get<dynamic>(
          '/properties',
          queryParameters: {...filters, 'page': page},
        )).data;
        return PropertyResults(
          _items(data),
          data['total'] as int,
          data['page'] as int,
        );
      });
  @override
  String photoUrl(String id) => '${dio.options.baseUrl}/assets/$id';
  @override
  Future<Map<String, dynamic>> details(String id) => _call(
    () async => Map<String, dynamic>.from(
      await auth.authorizedRequest('/properties/$id') as Map,
    ),
  );
  @override
  Future<List<PropertySummary>> favorites() =>
      _call(() async => _items(await auth.authorizedRequest('/favorites')));
  @override
  Future<List<PropertySummary>> mine() => _call(
    () async => _items(await auth.authorizedRequest('/properties/mine')),
  );
  @override
  Future<void> save(String id) => _call(() async {
    await auth.authorizedRequest('/favorites/$id', method: 'PUT');
  });
  @override
  Future<void> unsave(String id) => _call(() async {
    await auth.authorizedRequest('/favorites/$id', method: 'DELETE');
  });
  @override
  Future<String> create(Map<String, dynamic> values) => _call(
    () async =>
        (await auth.authorizedRequest(
              '/properties',
              method: 'POST',
              data: values,
            ))['id']
            as String,
  );
  @override
  Future<void> update(String id, Map<String, dynamic> values) =>
      _call(() async {
        await auth.authorizedRequest(
          '/properties/$id',
          method: 'PUT',
          data: values,
        );
      });
  @override
  Future<String> upload(
    UploadImage file,
    String kind, {
    String? nationalId,
    String? birthDate,
  }) => _call(() async {
    final data = FormData.fromMap({
      'kind': kind,
      'file': MultipartFile.fromBytes(file.bytes, filename: file.name),
      'national_id': ?nationalId,
      'birth_date': ?birthDate,
    });
    return (await auth.authorizedRequest(
          '/assets',
          method: 'POST',
          data: data,
        ))['id']
        as String;
  });
  @override
  Future<void> attachPhotos(String propertyId, List<String> photos) =>
      _call(() async {
        await auth.authorizedRequest(
          '/properties/$propertyId/photos',
          method: 'PUT',
          data: photos,
        );
      });
  @override
  Future<void> submit(
    String propertyId,
    String identityId,
    String ownershipId,
  ) => _call(() async {
    await auth.authorizedRequest(
      '/properties/$propertyId/submit',
      method: 'POST',
      data: {
        'identity_asset_id': identityId,
        'ownership_asset_id': ownershipId,
      },
    );
  });
  @override
  Future<List<Map<String, dynamic>>> roommates() => _call(() async {
    final data = await auth.authorizedRequest('/roommates');
    return (data['items'] as List)
        .map((value) => Map<String, dynamic>.from(value as Map))
        .toList();
  });
}

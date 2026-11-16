import 'package:dio/dio.dart';
import '../../auth/data/api_auth_repository.dart';
import '../../properties/domain/property_repository.dart' show UploadImage;
import '../domain/sales_repository.dart';

class ApiSalesRepository implements SalesRepository {
  @override
  Future<Map<String, dynamic>> dashboard() => _map('/admin/dashboard');
  final ApiAuthRepository auth;
  const ApiSalesRepository(this.auth);
  Future<T> _call<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on DioException catch (e) {
      final value = e.response?.data;
      throw SalesFailure(
        value is Map && value['detail'] is String
            ? value['detail'] as String
            : e.requestOptions.path.endsWith('/admin/staff') &&
                  value is Map &&
                  value['detail'] is List
            ? 'INVALID_ACCOUNT_INPUT'
            : 'NETWORK_ERROR',
      );
    }
  }

  Future<Map<String, dynamic>> _map(
    String path, {
    String method = 'GET',
    Map<String, dynamic>? values,
  }) => _call(
    () async => Map<String, dynamic>.from(
      await auth.authorizedRequest(path, method: method, data: values) as Map,
    ),
  );
  Future<List<Map<String, dynamic>>> _items(String path) => _call(() async {
    final data = await auth.authorizedRequest(path);
    return (data['items'] as List)
        .map((v) => Map<String, dynamic>.from(v as Map))
        .toList();
  });
  Future<void> _write(
    String path, {
    String method = 'POST',
    Map<String, dynamic>? values,
  }) => _call(() async {
    await auth.authorizedRequest(path, method: method, data: values);
  });
  @override
  Future<List<Map<String, dynamic>>> listDeals() => _items('/deals');
  @override
  Future<Map<String, dynamic>> detail(String id) => _map('/deals/$id');
  @override
  Future<String> start(String propertyId) async =>
      (await _map(
            '/deals',
            method: 'POST',
            values: {'property_id': propertyId},
          ))['id']
          as String;
  @override
  Future<void> book(String id, DateTime when) => _write(
    '/deals/$id/viewings',
    values: {'scheduled_at': when.toUtc().toIso8601String()},
  );
  @override
  Future<void> ownerConfirm(String id) => _write('/viewings/$id/owner-confirm');
  @override
  Future<void> assignViewing(String id, String staffId) => _write(
    '/admin/viewings/$id/assign',
    method: 'PUT',
    values: {'staff_id': staffId},
  );
  @override
  Future<void> completeViewing(String id, String note) =>
      _write('/viewings/$id/complete', values: {'note': note});
  @override
  Future<void> offer(String id, String amount) => _write(
    '/deals/$id/offers',
    values: {'amount': amount, 'basis': 'all_in'},
  );
  @override
  Future<void> decide(String id, bool approved) => _write(
    '/offers/$id/decision',
    method: 'PUT',
    values: {'approved': approved},
  );
  @override
  Future<void> consent(String id, String digest) => _write(
    '/deals/$id/consent',
    values: {'digest': digest, 'accepted': true},
  );
  @override
  Future<void> assignReviewer(String id, String staffId) => _write(
    '/admin/deals/$id/reviewer',
    method: 'PUT',
    values: {'staff_id': staffId},
  );
  @override
  Future<List<Map<String, dynamic>>> documents(
    String id, {
    bool eligibility = false,
  }) => _items(
    eligibility ? '/eligibility-reviews/$id/documents' : '/deals/$id/documents',
  );
  @override
  Future<List<int>> documentImage(
    String id,
    String assetId, {
    bool eligibility = false,
  }) => _call(
    () => auth.authorizedBytes(
      eligibility
          ? '/eligibility-reviews/$id/documents/$assetId'
          : '/deals/$id/documents/$assetId',
    ),
  );
  @override
  Future<void> reviewContract(
    String id,
    bool approved,
    String reference,
    String note,
  ) => _write(
    '/deals/$id/contract-review',
    values: {
      'approved': approved,
      'contract_reference': reference,
      'note': note,
    },
  );
  @override
  Future<List<int>> paymentQr(String id) =>
      _call(() => auth.authorizedBytes('/deals/$id/payment-qr'));
  @override
  Future<void> reportPayment(String id, String reference) =>
      _write('/deals/$id/payment-claims', values: {'reference': reference});
  @override
  Future<void> reviewPayment(String id, bool approved, String note) => _write(
    '/admin/payment-claims/$id/review',
    method: 'PUT',
    values: {'approved': approved, 'note': note},
  );
  @override
  Future<void> complete(String id) => _write('/admin/deals/$id/complete');
  @override
  Future<void> cancel(String id, String note) =>
      _write('/deals/$id/cancel', values: {'note': note});
  @override
  Future<List<Map<String, dynamic>>> staff() => _items('/admin/staff');
  @override
  Future<void> createStaff(Map<String, dynamic> values) =>
      _write('/admin/staff', values: values);
  @override
  Future<void> staffState(String id, bool active) =>
      _write('/admin/staff/$id', method: 'PUT', values: {'active': active});
  @override
  Future<void> publishTerms(Map<String, dynamic> values) =>
      _write('/admin/brokerage-terms', values: values);
  @override
  Future<void> uploadQr(String recipient, UploadImage image) => _call(() async {
    await auth.authorizedRequest(
      '/admin/payment-destination',
      method: 'POST',
      data: FormData.fromMap({
        'recipient_name': recipient,
        'file': MultipartFile.fromBytes(image.bytes, filename: image.name),
      }),
    );
  });
  @override
  Future<void> preparePayment(String id) =>
      _write('/admin/deals/$id/payment-destination');
  @override
  Future<List<Map<String, dynamic>>> eligibilityReviews() =>
      _items('/eligibility-reviews');
  @override
  Future<void> assignEligibility(String id, String staffId) => _write(
    '/admin/properties/$id/eligibility-reviewer',
    method: 'PUT',
    values: {'staff_id': staffId},
  );
  @override
  Future<void> reviewEligibility(
    String id,
    bool approved,
    String reference,
    String note,
  ) => _write(
    '/eligibility-reviews/$id/decision',
    values: {
      'approved': approved,
      'contract_reference': reference,
      'note': note,
    },
  );
  @override
  Future<void> proposeSpecialFee(
    String id,
    String total,
    String reason,
    String reference,
  ) => _write(
    '/admin/deals/$id/special-fees',
    values: {'total': total, 'reason': reason, 'legal_reference': reference},
  );
  @override
  Future<void> consentSpecialFee(String id, String digest, bool accepted) =>
      _write(
        '/special-fees/$id/consent',
        values: {'digest': digest, 'accepted': accepted},
      );
}

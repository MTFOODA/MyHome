import '../../properties/domain/property_repository.dart' show UploadImage;

class SalesFailure implements Exception {
  final String code;
  const SalesFailure(this.code);
}

abstract class SalesRepository {
  Future<List<Map<String, dynamic>>> listDeals();
  Future<Map<String, dynamic>> detail(String id);
  Future<String> start(String propertyId);
  Future<void> book(String dealId, DateTime when);
  Future<void> ownerConfirm(String viewingId);
  Future<void> assignViewing(String viewingId, String staffId);
  Future<void> completeViewing(String viewingId, String note);
  Future<void> offer(String dealId, String allInAmount);
  Future<void> decide(String offerId, bool approved);
  Future<void> consent(String dealId, String digest);
  Future<void> assignReviewer(String dealId, String staffId);
  Future<List<Map<String, dynamic>>> documents(
    String id, {
    bool eligibility = false,
  });
  Future<List<int>> documentImage(
    String id,
    String assetId, {
    bool eligibility = false,
  });
  Future<void> reviewContract(
    String dealId,
    bool approved,
    String reference,
    String note,
  );
  Future<List<int>> paymentQr(String dealId);
  Future<void> reportPayment(String dealId, String reference);
  Future<void> reviewPayment(String claimId, bool approved, String note);
  Future<void> complete(String dealId);
  Future<void> cancel(String dealId, String note);
  Future<List<Map<String, dynamic>>> staff();
  Future<void> createStaff(Map<String, dynamic> values);
  Future<void> staffState(String id, bool active);
  Future<void> publishTerms(Map<String, dynamic> values);
  Future<void> uploadQr(String recipient, UploadImage image);
  Future<void> preparePayment(String dealId);
  Future<List<Map<String, dynamic>>> eligibilityReviews();
  Future<void> assignEligibility(String propertyId, String staffId);
  Future<void> reviewEligibility(
    String propertyId,
    bool approved,
    String reference,
    String note,
  );
  Future<void> proposeSpecialFee(
    String dealId,
    String total,
    String reason,
    String legalReference,
  );
  Future<void> consentSpecialFee(
    String proposalId,
    String digest,
    bool accepted,
  );
}

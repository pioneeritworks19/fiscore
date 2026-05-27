part of '../../main.dart';

class SiteRepository {
  SiteRepository({CloudFunctionsService? functions})
    : _functions = functions ?? CloudFunctionsService();

  final CloudFunctionsService _functions;

  Stream<DocumentSnapshot<Map<String, dynamic>>> userProfileStream(
    String userId,
  ) {
    return FirestorePaths.user(userId).snapshots();
  }

  Future<String?> createManualSite({
    required String tenantId,
    required String siteName,
    required String addressLine1,
    required String city,
    required String state,
    required String postalCode,
  }) async {
    final result = await _functions.call('createSite', {
      'tenantId': tenantId,
      'siteName': siteName,
      'addressLine1': addressLine1,
      'city': city,
      'state': state,
      'postalCode': postalCode,
      'siteType': 'restaurant',
    });
    final siteId = result['siteId'];
    return siteId is String ? siteId : null;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> activeSitesStream(
    String tenantId, {
    Map<String, dynamic>? member,
  }) {
    final role = member?['role'] as String?;
    final accessMode = member?['siteAccessMode'] as String?;
    final hasAllSiteAccess =
        role == 'tenant_owner' ||
        role == 'admin' ||
        accessMode == null ||
        accessMode == 'all';
    if (hasAllSiteAccess) {
      return FirestorePaths.sites(
        tenantId,
      ).where('status', isEqualTo: 'active').snapshots();
    }

    final siteIds = (member?['siteIds'] as List<dynamic>? ?? [])
        .whereType<String>()
        .where((siteId) => siteId.trim().isNotEmpty)
        .take(30)
        .toList();
    if (siteIds.isEmpty) {
      return Stream<QuerySnapshot<Map<String, dynamic>>>.empty();
    }

    return FirestorePaths.sites(tenantId)
        .where(FieldPath.documentId, whereIn: siteIds)
        .where('status', isEqualTo: 'active')
        .snapshots();
  }
}

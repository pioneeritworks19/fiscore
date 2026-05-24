part of '../../main.dart';

class SiteRepository {
  Stream<DocumentSnapshot<Map<String, dynamic>>> userProfileStream(
    String userId,
  ) {
    return FirestorePaths.user(userId).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> activeSitesStream(
    String tenantId, {
    Map<String, dynamic>? member,
  }) {
    final role = member?['role'] as String?;
    final accessMode = member?['siteAccessMode'] as String?;
    final hasAllSiteAccess = role == 'tenant_owner' ||
        role == 'admin' ||
        accessMode == null ||
        accessMode == 'all';
    if (hasAllSiteAccess) {
      return FirestorePaths.sites(tenantId)
          .where('status', isEqualTo: 'active')
          .snapshots();
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

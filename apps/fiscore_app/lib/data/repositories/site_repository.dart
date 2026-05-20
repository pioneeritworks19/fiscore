part of '../../main.dart';

class SiteRepository {
  Stream<DocumentSnapshot<Map<String, dynamic>>> userProfileStream(
    String userId,
  ) {
    return FirestorePaths.user(userId).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> activeSitesStream(
    String tenantId,
  ) {
    return FirestorePaths.sites(tenantId)
        .where('status', isEqualTo: 'active')
        .snapshots();
  }
}

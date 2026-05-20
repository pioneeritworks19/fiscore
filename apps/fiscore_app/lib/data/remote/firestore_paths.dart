part of '../../main.dart';

class FirestorePaths {
  const FirestorePaths._();

  static DocumentReference<Map<String, dynamic>> user(String userId) {
    return FirebaseFirestore.instance.collection('users').doc(userId);
  }

  static CollectionReference<Map<String, dynamic>> sites(String tenantId) {
    return FirebaseFirestore.instance
        .collection('tenants')
        .doc(tenantId)
        .collection('sites');
  }

  static DocumentReference<Map<String, dynamic>> site(
    String tenantId,
    String siteId,
  ) {
    return sites(tenantId).doc(siteId);
  }

  static DocumentReference<Map<String, dynamic>> siteInspection(
    String tenantId,
    String siteId,
    String inspectionId,
  ) {
    return siteInspections(tenantId, siteId).doc(inspectionId);
  }

  static CollectionReference<Map<String, dynamic>> siteInspections(
    String tenantId,
    String siteId,
  ) {
    return site(tenantId, siteId).collection('inspections');
  }

  static CollectionReference<Map<String, dynamic>> violations(
    String tenantId,
    String siteId,
  ) {
    return site(tenantId, siteId).collection('violations');
  }

  static DocumentReference<Map<String, dynamic>> violation(
    String tenantId,
    String siteId,
    String violationId,
  ) {
    return violations(tenantId, siteId).doc(violationId);
  }

  static CollectionReference<Map<String, dynamic>> violationThreads(
    String tenantId,
    String siteId,
    String violationId,
  ) {
    return violation(tenantId, siteId, violationId).collection('threads');
  }
}

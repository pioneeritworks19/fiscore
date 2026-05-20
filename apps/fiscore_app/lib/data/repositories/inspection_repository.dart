part of '../../main.dart';

class InspectionRepository {
  Stream<QuerySnapshot<Map<String, dynamic>>> streamForSite({
    required String tenantId,
    required String siteId,
  }) {
    return FirestorePaths.siteInspections(
      tenantId,
      siteId,
    ).orderBy('inspectionDate', descending: true).snapshots();
  }
}

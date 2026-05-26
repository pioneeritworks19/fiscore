part of '../../main.dart';

class ActionItemRepository {
  Stream<QuerySnapshot<Map<String, dynamic>>> myOpenActions({
    required String tenantId,
    required String userId,
  }) {
    return FirestorePaths.actionItems(tenantId)
        .where('recipientUserId', isEqualTo: userId)
        .where('status', isEqualTo: 'open')
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> teamOpenActions({
    required String tenantId,
    required String siteId,
  }) {
    return FirestorePaths.actionItems(tenantId)
        .where('managerVisible', isEqualTo: true)
        .where('status', isEqualTo: 'open')
        .where('siteId', isEqualTo: siteId)
        .snapshots();
  }

  Future<void> markRead({
    required String tenantId,
    required String actionItemId,
  }) {
    return FirestorePaths.actionItem(tenantId, actionItemId).set({
      'readAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}

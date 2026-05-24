part of '../../main.dart';

class ViolationRepository {
  Stream<QuerySnapshot<Map<String, dynamic>>> streamForSite({
    required String tenantId,
    required String siteId,
  }) {
    return FirestorePaths.violations(
      tenantId,
      siteId,
    ).snapshots();
  }

  Future<void> saveStructuredResponse({
    required String tenantId,
    required String siteId,
    required String violationId,
    required Map<String, String> response,
    bool startWork = false,
  }) async {
    final now = FieldValue.serverTimestamp();
    final responseData = {...response, 'updatedAt': now};
    final violationRef = FirestorePaths.violation(
      tenantId,
      siteId,
      violationId,
    );
    final batch = FirebaseFirestore.instance.batch();
    final violationData = <String, dynamic>{
      ...responseData,
      'currentResponseType': 'structured_remediation',
      'syncStatus': 'synced',
      'updatedAt': now,
    };
    if (startWork) {
      violationData.addAll({
        'status': 'in_progress',
        'lifecycleStage': 'in_progress',
        'reviewStatus': 'not_submitted',
        'requiresReview': false,
      });
    }
    batch.set(violationRef, {...violationData}, SetOptions(merge: true));
    batch.set(violationRef.collection('responses').doc(), {
      ...responseData,
      'responseType': 'structured_remediation',
      'syncStatus': 'synced',
      'createdAt': now,
    });
    await batch.commit();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamThreadEntries({
    required String tenantId,
    required String siteId,
    required String violationId,
  }) {
    return FirestorePaths.violationThreads(
      tenantId,
      siteId,
      violationId,
    ).orderBy('createdAt', descending: true).snapshots();
  }

  Future<void> addThreadComment({
    required String tenantId,
    required String siteId,
    required String violationId,
    required String body,
    List<String> attachmentIds = const [],
    bool startWork = false,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final now = FieldValue.serverTimestamp();
    final entry = {
      'entryType': 'comment',
      'body': body,
      'mentionedUserIds': <String>[],
      'attachmentIds': attachmentIds,
      'statusSnapshot': null,
      'assignmentSnapshot': null,
      'createdAt': now,
      'createdBy': currentUser?.uid,
      'createdByDisplayNameSnapshot':
          currentUser?.displayName ?? currentUser?.email ?? 'FiScore user',
      'updatedAt': now,
    };

    await FirestorePaths.violationThreads(tenantId, siteId, violationId).add(
      entry,
    );
    final violationUpdate = <String, dynamic>{
      'latestThreadEntrySummary': body,
      'latestThreadEntryAt': now,
      'syncStatus': 'synced',
      'updatedAt': now,
    };
    if (startWork) {
      violationUpdate.addAll({
        'status': 'in_progress',
        'lifecycleStage': 'in_progress',
        'reviewStatus': 'not_submitted',
        'requiresReview': false,
      });
    }
    await FirestorePaths.violation(
      tenantId,
      siteId,
      violationId,
    ).set(violationUpdate, SetOptions(merge: true));
  }

  Future<void> updateStatus({
    required String tenantId,
    required String siteId,
    required String violationId,
    required String status,
    String? reviewStatus,
    String? closureReason,
  }) async {
    final now = FieldValue.serverTimestamp();
    final data = <String, dynamic>{
      'status': status,
      'lifecycleStage': status,
      'syncStatus': 'synced',
      'updatedAt': now,
    };
    if (reviewStatus != null) {
      data['reviewStatus'] = reviewStatus;
    }
    if (status == 'pending_review') {
      data['submittedForReviewAt'] = now;
      data['requiresReview'] = true;
    }
    if (status == 'closed') {
      data['closedAt'] = now;
      data['closureReason'] = closureReason ?? 'Closed by manager review.';
      data['requiresReview'] = false;
      data['reviewStatus'] = 'closed';
    }
    if (status == 'open' || status == 'in_progress') {
      data['closedAt'] = null;
      data['closedBy'] = null;
      data['requiresReview'] = false;
    }

    final violationRef = FirestorePaths.violation(
      tenantId,
      siteId,
      violationId,
    );
    final siteRef = FirestorePaths.site(tenantId, siteId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final current = await transaction.get(violationRef);
      final oldStatus = current.data()?['status'] as String? ?? 'open';
      transaction.set(violationRef, data, SetOptions(merge: true));

      final openDelta =
          (status == 'closed' ? 0 : 1) - (oldStatus == 'closed' ? 0 : 1);
      final reviewDelta =
          (status == 'pending_review' ? 1 : 0) -
          (oldStatus == 'pending_review' ? 1 : 0);
      if (openDelta != 0 || reviewDelta != 0) {
        transaction.set(siteRef, {
          if (openDelta != 0)
            'openViolationCountSnapshot': FieldValue.increment(openDelta),
          if (reviewDelta != 0)
            'pendingReviewCountSnapshot': FieldValue.increment(reviewDelta),
          'updatedAt': now,
        }, SetOptions(merge: true));
      }
    });
  }
}

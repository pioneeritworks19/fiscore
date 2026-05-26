part of '../../main.dart';

class ViolationRepository {
  ViolationRepository({CloudFunctionsService? functions})
    : _functions = functions ?? CloudFunctionsService();

  final CloudFunctionsService _functions;

  Stream<QuerySnapshot<Map<String, dynamic>>> streamForSite({
    required String tenantId,
    required String siteId,
  }) {
    return FirestorePaths.violations(tenantId, siteId).snapshots();
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

    await FirestorePaths.violationThreads(
      tenantId,
      siteId,
      violationId,
    ).add(entry);
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
    if (status == 'pending_review') {
      await _functions.call('submitViolationForReview', {
        'tenantId': tenantId,
        'siteId': siteId,
        'violationId': violationId,
      });
      return;
    }
    if (status == 'closed') {
      await _functions.call('closeViolation', {
        'tenantId': tenantId,
        'siteId': siteId,
        'violationId': violationId,
        'closureReason': closureReason,
      });
      return;
    }
    if (status == 'open') {
      await _functions.call('reopenViolation', {
        'tenantId': tenantId,
        'siteId': siteId,
        'violationId': violationId,
      });
      return;
    }
    if (status == 'in_progress' && reviewStatus == 'needs_work') {
      await sendBackForChanges(
        tenantId: tenantId,
        siteId: siteId,
        violationId: violationId,
        feedback: 'Please update the fix and submit it again.',
      );
      return;
    }
    throw StateError('Unsupported violation status transition: $status');
  }

  Future<void> sendBackForChanges({
    required String tenantId,
    required String siteId,
    required String violationId,
    required String feedback,
  }) async {
    await _functions.call('sendViolationBack', {
      'tenantId': tenantId,
      'siteId': siteId,
      'violationId': violationId,
      'feedback': feedback,
    });
  }

  Future<void> assignViolation({
    required String tenantId,
    required String siteId,
    required String violationId,
    required String assignedTo,
  }) async {
    await _functions.call('assignViolation', {
      'tenantId': tenantId,
      'siteId': siteId,
      'violationId': violationId,
      'assignedTo': assignedTo,
    });
  }

  Future<void> unassignViolation({
    required String tenantId,
    required String siteId,
    required String violationId,
  }) async {
    await _functions.call('unassignViolation', {
      'tenantId': tenantId,
      'siteId': siteId,
      'violationId': violationId,
    });
  }
}

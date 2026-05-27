part of '../../main.dart';

class InternalAuditRepository {
  InternalAuditRepository({CloudFunctionsService? functions})
    : _functions = functions ?? CloudFunctionsService();

  final CloudFunctionsService _functions;

  Stream<QuerySnapshot<Map<String, dynamic>>> checklistTemplatesStream({
    required String tenantId,
  }) {
    return FirestorePaths.checklistTemplates(
      tenantId,
    ).where('status', isEqualTo: 'active').snapshots();
  }

  Future<List<Map<String, dynamic>>> fiScoreLibraryChecklists({
    required String tenantId,
  }) async {
    final result = await _functions.call('listFiScoreLibrary', {
      'tenantId': tenantId,
      'contentType': 'checklist',
    });
    return List<Map<String, dynamic>>.from(
      (result['items'] as List? ?? const []).map(
        (item) => Map<String, dynamic>.from(item as Map),
      ),
    );
  }

  Future<void> addLibraryChecklist({
    required String tenantId,
    required String libraryItemId,
  }) async {
    await _functions.call('adoptFiScoreLibraryItem', {
      'tenantId': tenantId,
      'contentType': 'checklist',
      'libraryItemId': libraryItemId,
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamForSite({
    required String tenantId,
    required String siteId,
    int limit = 20,
  }) {
    return FirestorePaths.internalAudits(
      tenantId,
      siteId,
    ).orderBy('startedAt', descending: true).limit(limit).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> inProgressForSite({
    required String tenantId,
    required String siteId,
    int limit = 20,
  }) {
    return FirestorePaths.internalAudits(tenantId, siteId)
        .where('status', isEqualTo: 'in_progress')
        .orderBy('updatedAt', descending: true)
        .limit(limit)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> completedForSite({
    required String tenantId,
    required String siteId,
    int limit = 20,
  }) {
    return FirestorePaths.internalAudits(tenantId, siteId)
        .where('status', isEqualTo: 'completed')
        .orderBy('completedAt', descending: true)
        .limit(limit)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> assignmentsForSite({
    required String tenantId,
    required String siteId,
    required String currentUserId,
    required bool canManage,
    int limit = 50,
  }) {
    final assignments = FirestorePaths.auditAssignments(tenantId, siteId);
    if (canManage) {
      return assignments
          .where('status', whereIn: ['assigned', 'in_progress'])
          .orderBy('dueDate')
          .limit(limit)
          .snapshots();
    }
    return assignments
        .where('assignedTo', isEqualTo: currentUserId)
        .where('status', whereIn: ['assigned', 'in_progress'])
        .orderBy('dueDate')
        .limit(limit)
        .snapshots();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> auditStream({
    required String tenantId,
    required String siteId,
    required String auditId,
  }) {
    return FirestorePaths.internalAudit(tenantId, siteId, auditId).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> responseStream({
    required String tenantId,
    required String siteId,
    required String auditId,
  }) {
    return FirestorePaths.auditResponses(tenantId, siteId, auditId).snapshots();
  }

  Future<String> createAudit({
    required String tenantId,
    required String siteId,
    required String templateId,
  }) async {
    final result = await _functions.call('createInternalAudit', {
      'tenantId': tenantId,
      'siteId': siteId,
      'templateId': templateId,
    });
    return result['auditId'] as String;
  }

  Future<String> startAssignment({
    required String tenantId,
    required String siteId,
    required String assignmentId,
  }) async {
    final result = await _functions.call('createInternalAudit', {
      'tenantId': tenantId,
      'siteId': siteId,
      'assignmentId': assignmentId,
    });
    return result['auditId'] as String;
  }

  Future<void> assignCheck({
    required String tenantId,
    required String siteId,
    required String templateId,
    required String assignedTo,
    required DateTime dueDate,
    String? note,
  }) async {
    await _functions.call('assignInternalAudit', {
      'tenantId': tenantId,
      'siteId': siteId,
      'templateId': templateId,
      'assignedTo': assignedTo,
      'dueDate': dueDate.toUtc().toIso8601String(),
      'note': note?.trim() ?? '',
    });
  }

  Future<void> reassignCheck({
    required String tenantId,
    required String siteId,
    required String assignmentId,
    required String assignedTo,
  }) async {
    await _functions.call('reassignInternalAudit', {
      'tenantId': tenantId,
      'siteId': siteId,
      'assignmentId': assignmentId,
      'assignedTo': assignedTo,
    });
  }

  Future<void> cancelAssignment({
    required String tenantId,
    required String siteId,
    required String assignmentId,
  }) async {
    await _functions.call('cancelInternalAuditAssignment', {
      'tenantId': tenantId,
      'siteId': siteId,
      'assignmentId': assignmentId,
    });
  }

  Future<void> saveResponse({
    required String tenantId,
    required String siteId,
    required String auditId,
    required Map<String, dynamic> question,
    required String? answer,
    String? note,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final now = FieldValue.serverTimestamp();
    await FirestorePaths.auditResponses(
      tenantId,
      siteId,
      auditId,
    ).doc(question['id'] as String).set({
      'sectionId': question['sectionId'],
      'sectionTitleSnapshot': question['sectionTitle'],
      'questionId': question['id'],
      'questionPromptSnapshot': question['prompt'],
      'answer': answer,
      'note': note?.trim() ?? '',
      'severity': answer == 'needs_attention' ? question['failSeverity'] : null,
      'createsViolation':
          answer == 'needs_attention' && question['createsViolation'] == true,
      'answeredAt': answer == null ? null : now,
      'answeredBy': answer == null ? null : currentUser?.uid,
      'updatedAt': now,
    }, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>> submitAudit({
    required String tenantId,
    required String siteId,
    required String auditId,
  }) {
    return _functions.call('submitInternalAudit', {
      'tenantId': tenantId,
      'siteId': siteId,
      'auditId': auditId,
    });
  }
}

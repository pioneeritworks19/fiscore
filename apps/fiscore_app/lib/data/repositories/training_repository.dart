part of '../../main.dart';

class TrainingRepository {
  TrainingRepository({CloudFunctionsService? functions})
    : _functions = functions ?? CloudFunctionsService();

  final CloudFunctionsService _functions;

  Stream<QuerySnapshot<Map<String, dynamic>>> trainingsStream(String tenantId) {
    return FirestorePaths.trainings(
      tenantId,
    ).where('status', isEqualTo: 'active').snapshots();
  }

  Future<List<Map<String, dynamic>>> fiScoreLibraryTrainings(
    String tenantId,
  ) async {
    final result = await _functions.call('listFiScoreLibrary', {
      'tenantId': tenantId,
      'contentType': 'training',
    });
    return List<Map<String, dynamic>>.from(
      (result['items'] as List? ?? const []).map(
        (item) => Map<String, dynamic>.from(item as Map),
      ),
    );
  }

  Future<void> addLibraryTraining({
    required String tenantId,
    required String libraryItemId,
  }) async {
    await _functions.call('adoptFiScoreLibraryItem', {
      'tenantId': tenantId,
      'contentType': 'training',
      'libraryItemId': libraryItemId,
    });
  }

  Future<Map<String, dynamic>?> trainingById({
    required String tenantId,
    required String trainingId,
  }) async {
    final snapshot = await FirestorePaths.trainings(
      tenantId,
    ).doc(trainingId).get();
    return snapshot.data();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> assignmentsStream({
    required String tenantId,
    required String siteId,
    required String userId,
    required bool canAssign,
  }) {
    final assignments = FirestorePaths.trainingAssignments(tenantId);
    if (canAssign) {
      return assignments.where('siteId', isEqualTo: siteId).snapshots();
    }
    return assignments.where('assignedTo', isEqualTo: userId).snapshots();
  }

  Future<void> createAssignment({
    required String tenantId,
    required String siteId,
    required Map<String, dynamic> training,
    required String assignedTo,
    required String assignedToName,
    required DateTime dueDate,
    String? note,
    String? linkedViolationId,
    String? linkedViolationTitle,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    final now = FieldValue.serverTimestamp();
    await FirestorePaths.trainingAssignments(tenantId).add({
      'tenantId': tenantId,
      'siteId': siteId,
      'trainingId': training['_id'] ?? training['id'],
      'trainingVersion': training['version'],
      'trainingTitleSnapshot': training['title'],
      'trainingDescriptionSnapshot': training['description'],
      'trainingType': training['trainingType'],
      'durationMinutes': training['durationMinutes'],
      'trainingTopicsSnapshot': List<String>.from(
        training['topicSummaries'] as List? ?? const [],
      ),
      'trainingSectionsSnapshot': List<Map<String, dynamic>>.from(
        (training['sections'] as List? ?? const []).map(
          (section) => Map<String, dynamic>.from(section as Map),
        ),
      ),
      'quickCheckQuestionsSnapshot': List<Map<String, dynamic>>.from(
        (training['quickCheckQuestions'] as List? ?? const []).map(
          (question) => Map<String, dynamic>.from(question as Map),
        ),
      ),
      'hasQuickCheckSnapshot': training['hasQuickCheck'] == true,
      'linkedRiskArea': training['riskArea'],
      'assignedTo': assignedTo,
      'assignedToNameSnapshot': assignedToName,
      'assignedBy': user?.uid,
      'assignedByNameSnapshot':
          user?.displayName ?? user?.email ?? 'FiScore manager',
      'dueDate': Timestamp.fromDate(dueDate),
      'assignmentNote': note?.trim() ?? '',
      'linkedViolationId': linkedViolationId,
      'linkedViolationTitleSnapshot': linkedViolationTitle,
      'status': 'assigned',
      'progressPercent': 0,
      'createdAt': now,
      'updatedAt': now,
    });
  }

  Future<void> createAssignments({
    required String tenantId,
    required String siteId,
    required Map<String, dynamic> training,
    required Map<String, String> assignees,
    required DateTime dueDate,
    String? note,
    String? linkedViolationId,
    String? linkedViolationTitle,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    final now = FieldValue.serverTimestamp();
    final batch = FirebaseFirestore.instance.batch();
    for (final assignee in assignees.entries) {
      final reference = FirestorePaths.trainingAssignments(tenantId).doc();
      batch.set(reference, {
        'tenantId': tenantId,
        'siteId': siteId,
        'trainingId': training['_id'] ?? training['id'],
        'trainingVersion': training['version'],
        'trainingTitleSnapshot': training['title'],
        'trainingDescriptionSnapshot': training['description'],
        'trainingType': training['trainingType'],
        'durationMinutes': training['durationMinutes'],
        'trainingTopicsSnapshot': List<String>.from(
          training['topicSummaries'] as List? ?? const [],
        ),
        'trainingSectionsSnapshot': List<Map<String, dynamic>>.from(
          (training['sections'] as List? ?? const []).map(
            (section) => Map<String, dynamic>.from(section as Map),
          ),
        ),
        'quickCheckQuestionsSnapshot': List<Map<String, dynamic>>.from(
          (training['quickCheckQuestions'] as List? ?? const []).map(
            (question) => Map<String, dynamic>.from(question as Map),
          ),
        ),
        'hasQuickCheckSnapshot': training['hasQuickCheck'] == true,
        'linkedRiskArea': training['riskArea'],
        'assignedTo': assignee.key,
        'assignedToNameSnapshot': assignee.value,
        'assignedBy': user?.uid,
        'assignedByNameSnapshot':
            user?.displayName ?? user?.email ?? 'FiScore manager',
        'dueDate': Timestamp.fromDate(dueDate),
        'assignmentNote': note?.trim() ?? '',
        'linkedViolationId': linkedViolationId,
        'linkedViolationTitleSnapshot': linkedViolationTitle,
        'status': 'assigned',
        'progressPercent': 0,
        'createdAt': now,
        'updatedAt': now,
      });
    }
    await batch.commit();
  }

  Future<void> startAssignment({
    required String tenantId,
    required String assignmentId,
  }) {
    return FirestorePaths.trainingAssignments(tenantId).doc(assignmentId).set({
      'status': 'in_progress',
      'progressPercent': 1,
      'startedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> completeAssignment({
    required String tenantId,
    required String assignmentId,
    required int incorrectAnswerCount,
    required int completedTopicCount,
    required Map<String, dynamic> completionSummary,
  }) {
    return FirestorePaths.trainingAssignments(tenantId).doc(assignmentId).set({
      'status': 'completed',
      'progressPercent': 100,
      'incorrectAnswerCount': incorrectAnswerCount,
      'quickCheckCompletedAt': FieldValue.serverTimestamp(),
      'completedTopicCount': completedTopicCount,
      'completionSummarySnapshot': completionSummary,
      'completedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> cancelAssignment({
    required String tenantId,
    required String assignmentId,
  }) {
    final user = FirebaseAuth.instance.currentUser;
    return FirestorePaths.trainingAssignments(tenantId).doc(assignmentId).set({
      'status': 'cancelled',
      'cancelledAt': FieldValue.serverTimestamp(),
      'cancelledBy': user?.uid,
      'cancelledByNameSnapshot':
          user?.displayName ?? user?.email ?? 'FiScore manager',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}

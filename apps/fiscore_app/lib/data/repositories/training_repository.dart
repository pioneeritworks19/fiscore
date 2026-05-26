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
    await createAssignments(
      tenantId: tenantId,
      siteId: siteId,
      training: training,
      assignees: {assignedTo: assignedToName},
      dueDate: dueDate,
      note: note,
      linkedViolationId: linkedViolationId,
      linkedViolationTitle: linkedViolationTitle,
    );
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
    await _functions.call('assignTraining', {
      'tenantId': tenantId,
      'siteId': siteId,
      'trainingId': training['_id'] ?? training['id'],
      'assignees': assignees,
      'dueDate': dueDate.toUtc().toIso8601String(),
      'note': note?.trim() ?? '',
      'linkedViolationId': linkedViolationId,
      'linkedViolationTitle': linkedViolationTitle,
    });
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
  }) async {
    await _functions.call('completeTrainingAssignment', {
      'tenantId': tenantId,
      'assignmentId': assignmentId,
      'incorrectAnswerCount': incorrectAnswerCount,
      'completedTopicCount': completedTopicCount,
      'completionSummary': completionSummary,
    });
  }

  Future<void> cancelAssignment({
    required String tenantId,
    required String assignmentId,
  }) async {
    await _functions.call('cancelTrainingAssignment', {
      'tenantId': tenantId,
      'assignmentId': assignmentId,
    });
  }
}

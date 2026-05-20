part of '../../main.dart';

enum SyncOperationStatus {
  pending,
  syncing,
  synced,
  failed,
  conflict,
}

class SyncQueue {
  const SyncQueue();

  Future<void> enqueue({
    required String recordType,
    required String recordId,
    required String action,
    required Map<String, dynamic> payload,
  }) async {
    // The durable implementation will live here when we add an explicit local
    // database. For now, repositories write through Firestore and include
    // syncStatus fields so the data model is moving in the right direction.
  }
}

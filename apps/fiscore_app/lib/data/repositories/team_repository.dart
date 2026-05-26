part of '../../main.dart';

class TeamRepository {
  TeamRepository({CloudFunctionsService? functions})
    : _functions = functions ?? CloudFunctionsService();

  final CloudFunctionsService _functions;

  Stream<DocumentSnapshot<Map<String, dynamic>>> memberStream({
    required String tenantId,
    required String userId,
  }) {
    return FirestorePaths.member(tenantId, userId).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> membersStream(String tenantId) {
    return FirestorePaths.members(
      tenantId,
    ).orderBy('emailSnapshot').snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> invitesStream(String tenantId) {
    return FirestorePaths.invites(
      tenantId,
    ).orderBy('invitedAt', descending: true).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> activityStream(String tenantId) {
    return FirestorePaths.teamActivity(
      tenantId,
    ).orderBy('createdAt', descending: true).limit(20).snapshots();
  }

  Future<List<Map<String, dynamic>>> listMyPendingInvites() async {
    final result = await _functions.call('listMyPendingInvites', {});
    return (result['invites'] as List<dynamic>? ?? [])
        .whereType<Map<dynamic, dynamic>>()
        .map(
          (invite) =>
              invite.map((key, value) => MapEntry(key.toString(), value)),
        )
        .toList();
  }

  Future<void> createInvite({
    required String tenantId,
    required String email,
    required String role,
    required String siteAccessMode,
    required List<String> siteIds,
  }) async {
    await _functions.call('createTenantInvite', {
      'tenantId': tenantId,
      'email': email,
      'role': role,
      'siteAccessMode': siteAccessMode,
      'siteIds': siteIds,
    });
  }

  Future<void> acceptInvite({
    required String tenantId,
    required String inviteId,
  }) async {
    await _functions.call('acceptTenantInvite', {
      'tenantId': tenantId,
      'inviteId': inviteId,
    });
  }

  Future<void> cancelInvite({
    required String tenantId,
    required String inviteId,
  }) async {
    await _functions.call('cancelTenantInvite', {
      'tenantId': tenantId,
      'inviteId': inviteId,
    });
  }

  Future<void> updateInviteAccess({
    required String tenantId,
    required String inviteId,
    required String role,
    required String siteAccessMode,
    required List<String> siteIds,
  }) async {
    await _functions.call('updateTenantInviteAccess', {
      'tenantId': tenantId,
      'inviteId': inviteId,
      'role': role,
      'siteAccessMode': siteAccessMode,
      'siteIds': siteIds,
    });
  }

  Future<void> updateMemberAccess({
    required String tenantId,
    required String userId,
    required String role,
    required String siteAccessMode,
    required List<String> siteIds,
  }) async {
    await _functions.call('updateTenantMemberAccess', {
      'tenantId': tenantId,
      'userId': userId,
      'role': role,
      'siteAccessMode': siteAccessMode,
      'siteIds': siteIds,
    });
  }

  Future<void> deactivateMember({
    required String tenantId,
    required String userId,
  }) async {
    await _functions.call('deactivateTenantMember', {
      'tenantId': tenantId,
      'userId': userId,
    });
  }
}

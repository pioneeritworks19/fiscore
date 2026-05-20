part of '../../main.dart';

class Site {
  const Site({
    required this.id,
    required this.name,
    required this.address,
    required this.status,
    required this.isLinkedToMaster,
    required this.openViolationCount,
    required this.pendingReviewCount,
    required this.latestInspectionDate,
  });

  final String id;
  final String name;
  final String address;
  final String status;
  final bool isLinkedToMaster;
  final int openViolationCount;
  final int pendingReviewCount;
  final String? latestInspectionDate;

  factory Site.fromSnapshot(
    QueryDocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();
    return Site(
      id: snapshot.id,
      name: data['name'] as String? ?? 'Restaurant',
      address: _formatSiteAddress(data),
      status: data['status'] as String? ?? 'active',
      isLinkedToMaster: data['linkStatus'] == 'linked' ||
          data['masterLinkStatus'] == 'linked_to_master' ||
          data['masterRestaurantId'] != null,
      openViolationCount:
          (data['openViolationCountSnapshot'] as num?)?.toInt() ?? 0,
      pendingReviewCount:
          (data['pendingReviewCountSnapshot'] as num?)?.toInt() ?? 0,
      latestInspectionDate: data['latestInspectionDateSnapshot'] as String?,
    );
  }
}

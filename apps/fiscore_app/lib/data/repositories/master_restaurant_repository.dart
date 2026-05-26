part of '../../main.dart';

class MasterRestaurantRepository {
  MasterRestaurantRepository({CloudFunctionsService? functions})
    : _functions = functions ?? CloudFunctionsService();

  final CloudFunctionsService _functions;

  Future<List<Map<String, dynamic>>> searchRestaurants({
    required String tenantId,
    required String query,
  }) async {
    final result = await _functions.call('searchMasterRestaurants', {
      'tenantId': tenantId,
      'query': query,
    });
    final restaurants = result['restaurants'];
    return restaurants is List
        ? restaurants
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList()
        : [];
  }

  Future<String?> linkRestaurantSite({
    required String tenantId,
    required String masterRestaurantId,
  }) async {
    final result = await _functions.call('linkMasterRestaurantSite', {
      'tenantId': tenantId,
      'masterRestaurantId': masterRestaurantId,
    });
    final siteId = result['siteId'];
    return siteId is String ? siteId : null;
  }

  Future<MasterDataSyncResult> syncLinkedSiteMasterData({
    required String tenantId,
    required String siteId,
  }) async {
    final result = await _functions.call('syncLinkedSiteMasterData', {
      'tenantId': tenantId,
      'siteId': siteId,
    });
    return MasterDataSyncResult(
      importedInspectionCount: result['importedInspectionCount'] ?? 0,
      importedFindingCount: result['importedFindingCount'] ?? 0,
      openViolationCount: result['openViolationCount'] ?? 0,
    );
  }
}

class MasterDataSyncResult {
  const MasterDataSyncResult({
    required this.importedInspectionCount,
    required this.importedFindingCount,
    required this.openViolationCount,
  });

  final Object importedInspectionCount;
  final Object importedFindingCount;
  final Object openViolationCount;
}

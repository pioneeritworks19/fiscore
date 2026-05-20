part of '../../main.dart';

class TenantRepository {
  TenantRepository({
    CloudFunctionsService? functions,
  }) : _functions = functions ?? CloudFunctionsService();

  final CloudFunctionsService _functions;

  Future<void> createTenantAndOwner({
    required String tenantName,
    required String? displayName,
  }) async {
    await _functions.call('createTenantAndOwner', {
      'tenantName': tenantName,
      'displayName': displayName,
    });
  }
}

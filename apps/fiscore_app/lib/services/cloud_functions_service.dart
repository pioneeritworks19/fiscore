part of '../main.dart';

class CloudFunctionsService {
  CloudFunctionsService({FirebaseFunctions? functions})
    : _functions =
          functions ?? FirebaseFunctions.instanceFor(region: 'us-central1');

  final FirebaseFunctions _functions;

  Future<Map<String, dynamic>> call(
    String functionName,
    Map<String, dynamic> data,
  ) async {
    try {
      final callable = _functions.httpsCallable(functionName);
      final result = await callable.call<Map<String, dynamic>>(data);
      return result.data;
    } on FirebaseFunctionsException catch (error) {
      final strings = await AppLocalizations.delegate.load(
        WidgetsBinding.instance.platformDispatcher.locale,
      );
      throw AppException(
        strings.functionErrorMessage(error.code, error.message),
      );
    } catch (_) {
      final strings = await AppLocalizations.delegate.load(
        WidgetsBinding.instance.platformDispatcher.locale,
      );
      throw AppException(strings.requestFailed);
    }
  }
}

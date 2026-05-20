part of '../main.dart';

class CloudFunctionsService {
  CloudFunctionsService({
    FirebaseFunctions? functions,
  }) : _functions = functions ??
            FirebaseFunctions.instanceFor(region: 'us-central1');

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
      throw AppException(error.message ?? error.code);
    } catch (_) {
      throw const AppException('The request failed. Please try again.');
    }
  }
}

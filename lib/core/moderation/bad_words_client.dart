import 'package:cloud_functions/cloud_functions.dart';

class BadWordsClient {
  // badWordsValidate is currently deployed in us-central1.
  // Keep a fallback region to survive region-mismatch deploys.
  final FirebaseFunctions _primary;
  final FirebaseFunctions _fallback;

  BadWordsClient({FirebaseFunctions? functions})
      : _primary =
            functions ?? FirebaseFunctions.instanceFor(region: 'us-central1'),
        _fallback = FirebaseFunctions.instanceFor(region: 'asia-northeast3');

  Future<void> validateText(String text) async {
    Future<void> call(FirebaseFunctions f) async {
      final callable = f.httpsCallable('badWordsValidate');
      await callable.call({'text': text});
    }

    try {
      await call(_primary);
    } on FirebaseFunctionsException catch (e) {
      final shouldFallback = e.code == 'not-found' || e.code == 'unimplemented';
      if (!shouldFallback) rethrow;
      await call(_fallback);
    }
  }
}

import '../../../core/backend/functions_client.dart';

class InteractionsRepository {
  Future<bool> likeQuoteOnce({required String quoteId}) async {
    final callable = FunctionsClient.instance.httpsCallable('likeQuoteOnce');
    final res = await callable.call({'quoteId': quoteId});
    final data = res.data;
    final alreadyLiked = data is Map ? (data['alreadyLiked'] as bool?) : null;
    return alreadyLiked ?? false;
  }

  Future<void> incrementShareCount({required String quoteId}) async {
    final callable =
        FunctionsClient.instance.httpsCallable('incrementShareCount');
    await callable.call({'quoteId': quoteId});
  }

  Future<bool> reportMalmoiOnce({
    required String quoteId,
    required String reasonCode,
  }) async {
    final callable = FunctionsClient.instance.httpsCallable('reportMalmoiOnce');
    final res = await callable.call({
      'quoteId': quoteId,
      'reasonCode': reasonCode,
    });
    final data = res.data;
    final alreadyReported =
        data is Map ? (data['alreadyReported'] as bool?) : null;
    return alreadyReported ?? false;
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/quote_repository.dart';
import '../../data/repositories/image_repository.dart';

final dashboardStatsProvider = FutureProvider.autoDispose<Map<String, int>>((ref) async {
  final quoteRepo = ref.watch(quoteRepositoryProvider);
  final imageRepo = ref.watch(imageRepositoryProvider);

  final quoteStats = await quoteRepo.getStats();
  final imageCount = await imageRepo.getImageCount();

  return {
    ...quoteStats,
    'totalImages': imageCount,
  };
});

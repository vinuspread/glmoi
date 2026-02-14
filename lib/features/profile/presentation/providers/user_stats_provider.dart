import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/user_stats_repository.dart';

final userStatsProvider = FutureProvider.autoDispose<UserStats>((ref) async {
  final repository = ref.watch(userStatsRepositoryProvider);
  return repository.getUserStats();
});

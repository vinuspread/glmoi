import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/user_stats_repository.dart';

final userStatsProvider = StreamProvider.autoDispose<UserStats>((ref) {
  final repository = ref.watch(userStatsRepositoryProvider);
  return repository.watchUserStats();
});

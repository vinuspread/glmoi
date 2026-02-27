import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/auth_service.dart';
import '../../../quotes/data/quotes_repository.dart';
import '../../data/user_stats_repository.dart';

final userStatsProvider = StreamProvider.autoDispose<UserStats>((ref) {
  final repository = ref.watch(userStatsRepositoryProvider);
  return repository.watchUserStats();
});

final _quotesRepositoryProvider = Provider((ref) => QuotesRepository());

final myMalmoiPostsCountProvider = StreamProvider.autoDispose<int>((ref) {
  final uid = ref.watch(authUidProvider).valueOrNull;
  if (uid == null) {
    return Stream.value(0);
  }

  return ref
      .watch(_quotesRepositoryProvider)
      .watchMyMalmoiPostCountByUid(uid: uid);
});

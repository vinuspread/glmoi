import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/admob_stats_model.dart';
import '../../data/repositories/admob_repository.dart';

final admobStatsProvider = StreamProvider<AdMobStatsModel?>((ref) {
  return ref.watch(admobRepositoryProvider).watchStats();
});

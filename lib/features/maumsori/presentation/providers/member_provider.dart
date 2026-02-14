import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/member_model.dart';
import '../../data/repositories/member_repository.dart';

final membersProvider = StreamProvider<List<MemberModel>>((ref) {
  return ref.watch(memberRepositoryProvider).watchRecentMembers(limit: 500);
});

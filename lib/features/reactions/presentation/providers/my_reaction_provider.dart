import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/reactions_repository.dart';
import '../../domain/reaction_type.dart';

final reactionsRepositoryProvider = Provider((ref) => ReactionsRepository());

final myReactionProvider = StreamProvider.family<ReactionType?, String>(
  (ref, quoteId) {
    return ref
        .read(reactionsRepositoryProvider)
        .watchMyReaction(quoteId: quoteId);
  },
);

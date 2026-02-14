enum ReactionType {
  comfort,
  empathize,
  good,
  touched,
  fan,
}

String reactionTypeToFirestore(ReactionType t) {
  switch (t) {
    case ReactionType.comfort:
      return 'comfort';
    case ReactionType.empathize:
      return 'empathize';
    case ReactionType.good:
      return 'good';
    case ReactionType.touched:
      return 'touched';
    case ReactionType.fan:
      return 'fan';
  }
}

ReactionType? reactionTypeFromFirestore(String? raw) {
  switch (raw) {
    case 'comfort':
      return ReactionType.comfort;
    case 'empathize':
      return ReactionType.empathize;
    case 'good':
      return ReactionType.good;
    case 'touched':
      return ReactionType.touched;
    case 'fan':
      return ReactionType.fan;
    default:
      return null;
  }
}

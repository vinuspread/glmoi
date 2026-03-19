import 'reaction_type.dart';

typedef ReactionMenuItem = ({ReactionType type, String label});

const List<ReactionMenuItem> kReactionMenuItems = [
  (type: ReactionType.comfort, label: '위로받았어요'),
  (type: ReactionType.empathize, label: '공감해요'),
  (type: ReactionType.good, label: '멋진글이예요'),
  (type: ReactionType.touched, label: '감동했어요'),
  (type: ReactionType.fan, label: '팬이예요'),
];

String reactionAssetPath(ReactionType type) {
  switch (type) {
    case ReactionType.comfort:
      return 'assets/icons/reactions/comfort.png';
    case ReactionType.empathize:
      return 'assets/icons/reactions/empathize.png';
    case ReactionType.good:
      return 'assets/icons/reactions/good.png';
    case ReactionType.touched:
      return 'assets/icons/reactions/touched.png';
    case ReactionType.fan:
      return 'assets/icons/reactions/fan.png';
  }
}

String reactionShortLabel(ReactionType type) {
  switch (type) {
    case ReactionType.comfort:
      return '위로';
    case ReactionType.empathize:
      return '공감';
    case ReactionType.good:
      return '멋진글';
    case ReactionType.touched:
      return '감동';
    case ReactionType.fan:
      return '팬';
  }
}

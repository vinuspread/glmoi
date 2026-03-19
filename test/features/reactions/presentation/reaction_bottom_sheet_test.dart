import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:glmoi/features/reactions/domain/reaction_catalog.dart';
import 'package:glmoi/features/reactions/domain/reaction_type.dart';
import 'package:glmoi/features/reactions/presentation/widgets/reaction_bottom_sheet.dart';

void main() {
  testWidgets('ReactionBottomSheet renders all reaction rows without overflow',
      (tester) async {
    final items = [
      for (final item in kReactionMenuItems)
        ReactionBottomSheetItem(
          type: item.type,
          label: item.label,
          assetPath: reactionAssetPath(item.type),
          count: 0,
          selected: item.type == ReactionType.empathize,
          disabled: false,
          onTap: () async {},
        ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return Center(
                child: ElevatedButton(
                  onPressed: () {
                    showModalBottomSheet<void>(
                      context: context,
                      backgroundColor: Colors.transparent,
                      builder: (_) => ReactionBottomSheet(items: items),
                    );
                  },
                  child: const Text('open'),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('공감 남기기'), findsOneWidget);
    for (final item in kReactionMenuItems) {
      expect(find.text(item.label), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });
}

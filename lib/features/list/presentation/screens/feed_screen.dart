import 'package:flutter/material.dart';
import 'package:glmoi/core/theme/app_theme.dart';
import 'package:glmoi/core/widgets/feed_header_buttons.dart';
import 'package:glmoi/features/detail/presentation/screens/detail_screen.dart';
import 'package:glmoi/features/list/presentation/widgets/text_curation_card.dart';

class FeedScreen extends StatelessWidget {
  final String title;

  const FeedScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const FeedLeadingButton(),
        leadingWidth: 100,
        title: Text(title),
        backgroundColor: AppTheme.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: const [
          FeedTrailingButton(),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: 10, // Dummy count
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          return TextCurationCard(
            // Dummy data
            content: "삶이 있는 한 희망은 있다 - 키케로\n두 번째 줄 테스트 텍스트입니다.",
            author: "키케로 $index",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => DetailScreen(initialIndex: index)),
              );
            },
          );
        },
      ),
    );
  }
}

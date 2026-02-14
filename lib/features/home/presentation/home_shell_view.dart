import 'package:flutter/material.dart';

import '../../quotes/domain/quote.dart';
import '../../quotes/presentation/feed/quotes_feed_screen.dart';

class HomeShellView extends StatelessWidget {
  final int index;
  final ValueChanged<int> onIndexChanged;
  final Widget? bottomAd;

  const HomeShellView({
    super.key,
    required this.index,
    required this.onIndexChanged,
    this.bottomAd,
  });

  @override
  Widget build(BuildContext context) {
    final screens = const <Widget>[
      QuotesFeedScreen(type: QuoteType.quote, title: '한줄명언'),
      QuotesFeedScreen(type: QuoteType.thought, title: '좋은생각'),
      QuotesFeedScreen(type: QuoteType.malmoi, title: '글모이'),
    ];

    return Scaffold(
      body: IndexedStack(index: index, children: screens),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (bottomAd != null) bottomAd!,
          BottomNavigationBar(
            currentIndex: index,
            onTap: onIndexChanged,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.format_quote),
                label: '한줄명언',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.lightbulb_outline),
                label: '좋은생각',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.forum_outlined),
                label: '글모이',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

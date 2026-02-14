import 'package:flutter/material.dart';
import 'package:glmoi/core/theme/app_theme.dart';

import '../../quotes/presentation/feed/quotes_feed_screen.dart';
import '../../quotes/domain/quote.dart';

// Legacy wrapper kept for compatibility; app routing should prefer
// `HomeShellContainer` in `lib/app/home_shell_container.dart`.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  var _index = 0;

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      const QuotesFeedScreen(type: QuoteType.quote, title: '한줄명언'),
      const QuotesFeedScreen(type: QuoteType.thought, title: '좋은생각'),
      const QuotesFeedScreen(type: QuoteType.malmoi, title: '글모이'),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        selectedItemColor: AppTheme.accent,
        unselectedItemColor: AppTheme.textSecondary,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.format_quote), label: '한줄명언'),
          BottomNavigationBarItem(
              icon: Icon(Icons.lightbulb_outline), label: '좋은생각'),
          BottomNavigationBarItem(
              icon: Icon(Icons.forum_outlined), label: '글모이'),
        ],
      ),
    );
  }
}

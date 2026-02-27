import 'package:flutter/material.dart';
import 'package:glmoi/core/theme/app_theme.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade200)),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              _TextTabItem(
                iconPath: 'assets/icons/nav_quote.svg',
                label: '한줄명언',
                selected: _index == 0,
                onTap: () => setState(() => _index = 0),
              ),
              _TextTabItem(
                iconPath: 'assets/icons/nav_thought.svg',
                label: '좋은생각',
                selected: _index == 1,
                onTap: () => setState(() => _index = 1),
              ),
              _TextTabItem(
                iconPath: 'assets/icons/nav_malmoi.svg',
                label: '글모이',
                selected: _index == 2,
                onTap: () => setState(() => _index = 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TextTabItem extends StatelessWidget {
  static const double _fontSize = 17;

  final String iconPath;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TextTabItem({
    required this.iconPath,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppTheme.accent : AppTheme.textSecondary;
    final weight = selected ? FontWeight.w700 : FontWeight.w500;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 56,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                iconPath,
                width: 18,
                height: 18,
                colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                textScaler: TextScaler.noScaling,
                style: TextStyle(
                  color: color,
                  fontSize: _fontSize,
                  fontWeight: weight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

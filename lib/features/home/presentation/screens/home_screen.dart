import 'package:flutter/material.dart';
import 'package:glmoi/core/theme/app_theme.dart';
import 'package:glmoi/features/list/presentation/screens/feed_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

      body: IndexedStack(
        index: _currentIndex,
        children: const [
          FeedScreen(title: '인기글'),
          FeedScreen(title: '한줄명언'),
          FeedScreen(title: '좋은생각', isListView: true),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: AppTheme.accent,
        unselectedItemColor: AppTheme.textSecondary,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border), // Using standard icons for now
            activeIcon: Icon(Icons.favorite),
            label: '인기글',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.format_quote),
            label: '한줄명언',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.lightbulb_outline),
            label: '좋은생각',
          ),
        ],
      ),
    );
  }
}

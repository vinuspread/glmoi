import 'package:flutter/material.dart';
import 'package:glmoi/core/share/share_sheet.dart';
import 'package:glmoi/features/detail/presentation/widgets/bottom_action_bar.dart';
import 'package:glmoi/features/detail/presentation/widgets/control_bar.dart';
import 'package:glmoi/features/detail/presentation/widgets/immersive_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glmoi/core/auth/auth_service.dart';
import 'package:glmoi/features/auth/presentation/screens/login_screen.dart';

class DetailScreen extends ConsumerStatefulWidget {
  final int initialIndex;

  const DetailScreen({super.key, this.initialIndex = 0});

  @override
  ConsumerState<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends ConsumerState<DetailScreen> {
  late PageController _pageController;

  // State
  double _fontSize = 22.0;
  bool _isLiked = false;

  // Dummy Data
  final List<Map<String, String>> _dummyData = List.generate(
    10,
    (index) => {
      'content': '인생은 가까이서 보면 비극이지만 멀리서 보면 희극이다. \n행복은 습관이다, 그것을 몸에 지니라.',
      'author': '찰리 채플린 $index',
      'image': 'https://picsum.photos/id/$index/800/1200',
    },
  );

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  void _changeFontSize(double delta) {
    setState(() {
      _fontSize = (_fontSize + delta).clamp(18.0, 36.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Infinite PageView
          PageView.builder(
            controller: _pageController,
            itemBuilder: (context, index) {
              final data = _dummyData[
                  index % _dummyData.length]; // Modulo for infinite loop
              return ImmersiveCard(
                content: data['content']!,
                author: data['author']!,
                imageUrl: data['image']!,
                fontSize: _fontSize,
              );
            },
          ),

          // Top Control Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ControlBar(
              onClose: () => Navigator.pop(context),
              onDecreaseFont: () => _changeFontSize(-2),
              onIncreaseFont: () => _changeFontSize(2),
              currentFontSize: _fontSize,
            ),
          ),

          // Bottom Action Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: BottomActionBar(
              isLiked: _isLiked,
              onLike: () {
                final isLoggedIn = ref.read(authProvider);
                if (!isLoggedIn) {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()));
                  return;
                }
                setState(() => _isLiked = !_isLiked);
              },
              onShare: () async {
                final isLoggedIn = ref.read(authProvider);
                if (!isLoggedIn) {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()));
                  return;
                }
                if (_pageController.hasClients) {
                  final data = _dummyData[
                      _pageController.page!.round() % _dummyData.length];
                  await showShareSheet(
                    context: context,
                    content: data['content'] ?? '',
                    author: data['author'] ?? '',
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

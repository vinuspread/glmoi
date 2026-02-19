import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../quotes/domain/quote.dart';
import '../../quotes/presentation/feed/quotes_feed_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    final minSplashTime = Future.delayed(const Duration(seconds: 2));
    
    // Pre-fetch the initial data for the home screen (QuoteType.quote)
    // We catch errors so splash doesn't get stuck if fetch fails
    final dataFetch = ref.read(quotesFeedProvider(QuoteType.quote).future)
        .catchError((_) => <Quote>[]); 

    // Wait for both the minimum time and the data fetch
    await Future.wait([minSplashTime, dataFetch]);

    if (!mounted) return;

    context.go('/intro');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              // Top Logo
              Image.asset(
                'assets/icons/logo.png',
                width: 120,
                fit: BoxFit.contain,
              ),
              const Spacer(flex: 1),
              
              // Vertical Line
              Container(
                width: 1,
                height: 80,
                color: Colors.black, // Thin black line
              ),
              const Spacer(flex: 1),

              // Quote Text
              Column(
                children: [
                  const Icon(Icons.format_quote, size: 32, color: AppTheme.surfaceAlt), // Using a dark color for quote icon
                  const SizedBox(height: 16),
                  Text(
                    '마음의 얼룩은\n좋은 글로 지우고\n지워낸 자리에\n새로운 문장으로\n채우세요.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 18,
                      height: 1.6,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Icon(Icons.format_quote, size: 32, color: AppTheme.surfaceAlt), // Closing quote
                ],
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}

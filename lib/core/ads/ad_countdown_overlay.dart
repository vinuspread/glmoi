import 'dart:async';

import 'package:flutter/material.dart';

/// 전면광고 표시 직전 카운트다운 오버레이를 보여줍니다.
/// 오버레이가 닫힌 후 Future가 완료됩니다.
Future<void> showAdCountdownOverlay(BuildContext context) async {
  final overlay = Overlay.of(context);
  final completer = Completer<void>();

  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _AdCountdownOverlay(
      onDone: () {
        entry.remove();
        if (!completer.isCompleted) completer.complete();
      },
    ),
  );

  overlay.insert(entry);
  return completer.future;
}

class _AdCountdownOverlay extends StatefulWidget {
  final VoidCallback onDone;

  const _AdCountdownOverlay({required this.onDone});

  @override
  State<_AdCountdownOverlay> createState() => _AdCountdownOverlayState();
}

class _AdCountdownOverlayState extends State<_AdCountdownOverlay>
    with SingleTickerProviderStateMixin {
  static const _totalSeconds = 2;
  int _remaining = _totalSeconds;
  Timer? _timer;
  late AnimationController _fadeController;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeIn = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _remaining--);
      if (_remaining <= 0) {
        t.cancel();
        _fadeController.reverse().then((_) => widget.onDone());
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeIn,
      child: Material(
        color: Colors.transparent,
        child: Container(
          color: const Color(0xCC000000),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '앱의 안정적인 서비스를 위해\n광고가 노출됩니다.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  height: 1.6,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: 56,
                height: 56,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: _remaining / _totalSeconds,
                      strokeWidth: 3,
                      color: Colors.white,
                      backgroundColor: const Color(0x33FFFFFF),
                    ),
                    Text(
                      '$_remaining',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

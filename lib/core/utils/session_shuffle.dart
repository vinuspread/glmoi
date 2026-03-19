import 'dart:math';

/// 앱 실행 세션 단위로 안정적인 랜덤 순서를 만든다.
/// - 같은 세션 + 같은 아이템 id 목록: 동일 순서 유지(리빌드 점프 방지)
/// - 앱 재실행: 세션 시드가 바뀌어 순서가 달라짐
final class SessionShuffle {
  SessionShuffle._();

  static final int _sessionSeed =
      DateTime.now().microsecondsSinceEpoch ^ Random().nextInt(1 << 20);

  static List<T> reorder<T>({
    required List<T> items,
    required String key,
    required String Function(T item) idOf,
  }) {
    if (items.length <= 1) return items;

    final sorted = List<T>.of(items)
      ..sort((a, b) {
        final ha = Object.hash(key, idOf(a), _sessionSeed);
        final hb = Object.hash(key, idOf(b), _sessionSeed);
        if (ha != hb) return ha.compareTo(hb);
        return idOf(a).compareTo(idOf(b));
      });

    return sorted;
  }
}

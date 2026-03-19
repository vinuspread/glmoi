import 'package:flutter_test/flutter_test.dart';
import 'package:glmoi/core/share/kakao_talk_share_service.dart';

void main() {
  group('Kakao keyhash mismatch detection', () {
    test('detects canonical mismatch message', () {
      const text =
          'code: -401, msg: android keyhash mismatched! check out registered keyhash.';

      expect(KakaoTalkShareService.isKeyHashMismatchErrorText(text), isTrue);
    });

    test('detects compact code format', () {
      const text = 'KakaoError(code=-401, message=Unauthorized)';

      expect(KakaoTalkShareService.isKeyHashMismatchErrorText(text), isTrue);
    });

    test('detects message with mixed casing and spaces', () {
      const text = 'Code : -401 / Android KeyHash Mismatched';

      expect(KakaoTalkShareService.isKeyHashMismatchErrorText(text), isTrue);
    });

    test('does not match unrelated errors', () {
      const text = 'network timeout while opening kakao share';

      expect(KakaoTalkShareService.isKeyHashMismatchErrorText(text), isFalse);
    });

    test('does not match non-kakao 401 text', () {
      const text = 'http 401 from unrelated api gateway';

      expect(KakaoTalkShareService.isKeyHashMismatchErrorText(text), isFalse);
    });
  });
}

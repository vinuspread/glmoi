# glmoi (Android / iOS)

End-user mobile app project (renamed from legacy "maumsori").

## 현재 프로젝트 현황

상태:
- Flutter 기반 모바일 앱(안드로이드 우선) 스캐폴딩 완료
- `dev` / `prod` 2개 환경 운용(스테이징 `stg` 미사용)
- 로그인: 카카오/구글 + 비회원(둘러보기) 지원
- 정책: 비회원은 콘텐츠 읽기 가능, 좋아요/공유/글작성은 로그인 필요

구현된 주요 화면/플로우:
- Intro -> Home(하단 탭: 한줄명언/좋은생각/글모이)
- 피드(목록) -> 상세 화면
- 글모이 작성 화면(로그인 필수)

데이터:
- Firestore `quotes` 컬렉션을 읽어 피드를 구성
- 글모이 작성은 `quotes`에 user-post로 저장(운영정책에 맞춰 승인/반려 없이 `is_active`로 노출 제어)

테스트/정적분석:
- `flutter analyze` 통과
- `flutter test` 통과

## 최근 작업 내용(요약)

피드 UI 개선:
- 피드(한줄명언/좋은생각/글모이) 목록에서 좋아요/공유 버튼 제거(목록은 읽기/탭 중심)
- 한줄명언 목록: 라운드 박스(이미지 배경) + 텍스트 2줄(말줄임) 카드로 변경

상세 UI/동작:
- 상세 화면 하단에 좋아요/공유(및 신고) 액션바 유지
- 액션바는 2초 후 자동으로 숨김(화면 터치 시 다시 표시)
- 이전글/다음글 슬라이드(PageView) 이동 시 자동으로 액션바가 다시 나타나지 않음(터치로만 표시)
- 상세의 저자 표기는 `- 저자 -` 형식으로 표시(관리자 프리뷰 표기와 일치)

글모이:
- 글모이 탭에 `글 작성` 진입 버튼 추가(로그인 필요)
- 작성 화면(`/malmoi/write`) 추가 및 Firestore 저장 로직 추가
- 승인/반려 플로우 제거에 맞춰 글모이 피드에서 `is_approved` 의존 제거

글모이 (내 글 / 수정 / 삭제):
- 글모이 탭에 `내 글` 진입 추가(우측 상단 아이콘) -> `/malmoi/mine`
- 내가 작성한 글 목록 조회(로그인 사용자)
- 상세 화면에서 본인 글이면 `수정/삭제` 가능
  - 수정: `/malmoi/edit`

회원 프로필 (닉네임 필수):
- 로그인 사용자의 `닉네임(displayName)`이 없으면 앱 진입 후 팝업으로 입력 강제
- Firestore `users/{uid}` 문서에 닉네임/프로필사진/로그인 메타데이터 저장(upsert)

이메일/비밀번호 로그인/회원가입 추가:
- 로그인 화면에 이메일/비밀번호 로그인 UI 추가
- 이메일 회원가입 화면 추가(이메일/비밀번호/닉네임 + 프로필 이미지 선택(옵션))
- 프로필 이미지는 Firebase Storage(`users/{uid}/profile`) 업로드 후 `photoURL`에 반영
- 오류 메시지는 사용자 친화 텍스트로 표시(예: `Bad state: ...` 접두어 제거)

광고 (Google AdMob):
- 하단 고정 배너 + 전면(Interstitial) 2종 지원
- 광고 Unit ID는 Firestore `config/ad_config`에서 읽도록 구성(계정/Unit 교체를 앱 업데이트 없이 처리)
- 앱 동작
  - 배너: 하단에 고정 노출(활성화 시 로딩/실패 중에도 배너 영역 높이 확보)
  - 전면: 피드 카드 탭으로 상세 진입 시 N회마다 노출(설정/로드된 경우에만)

운영 기능 배포/작업:
- `glmoi-prod`에 Cloud Functions(callable) 배포: `kakaoCustomToken`, `likeQuoteOnce`, `incrementShareCount`, `reportMalmoiOnce`
- 관리자 웹(Hosting) `https://glmoi-prod.web.app`에 광고 Unit ID 입력 UI(광고 관리 화면) 배포
- 백업 생성: `data_backup/YYYYMMDD_backup.tar.gz` (빌드/캐시 산출물은 제외)

## 주요사항
- 디자인(UI)와 개발코드는 분리되어야 개발한다.
- 디자인(UI)를 별도로 고도화 할 계획을 가지고 있다.


## 코드 위치(참고)

라우팅:
- `lib/app/router.dart`

로그인:
- `lib/core/auth/auth_service.dart`
- `lib/features/auth/presentation/screens/login_screen.dart`
- `lib/features/auth/presentation/screens/email_signup_screen.dart`

피드/상세:
- `lib/features/quotes/presentation/feed/quotes_feed_screen.dart`
- `lib/features/quotes/presentation/feed/widgets/quote_feed_card.dart`
- `lib/features/quotes/presentation/detail/quote_detail_screen.dart`
- `lib/features/quotes/presentation/liked_quotes_provider.dart`

글모이 작성:
- `lib/features/malmoi/presentation/malmoi_write_screen.dart`

글모이 내 글/수정:
- `lib/features/malmoi/presentation/malmoi_my_posts_screen.dart`
- `lib/features/malmoi/presentation/malmoi_edit_screen.dart`

데이터 레이어:
- `lib/features/quotes/data/quotes_repository.dart`
- `lib/features/quotes/domain/quote.dart`

회원 프로필:
- `lib/core/auth/auth_service.dart`

광고:
- `lib/core/ads/ad_config.dart`
- `lib/core/ads/ad_config_provider.dart`
- `lib/core/ads/ad_service.dart`
- `lib/core/ads/banner_ad_widget.dart`
- `lib/core/ads/ads_providers.dart`

## Firestore Contract (Important)

End-user app reads/writes these docs/fields.

`quotes` (collection)
- Feed reads: `app_id`, `type`, `is_active`, `createdAt`
- Malmoi user-post ownership:
  - `user_uid` (canonical owner uid)
  - `user_id` (legacy owner uid, kept for compatibility)
  - `user_provider` (legacy, optional)
- Write/edit:
  - create: writes `createdAt`, `updatedAt`
  - update: updates `content`, `updatedAt`

`users` (collection)
- Document id: Firebase Auth uid (ex: `kakao:<id>`, Google uid)
- Stored fields (upsert on login / nickname update)
  - `uid`, `display_name` (required), `photo_url` (optional)
  - `provider`, `provider_user_id`
  - `createdAt`, `updatedAt`, `last_login_at`

`config/ad_config` (document)
- Remote ad settings (read by app)
  - `is_ad_enabled` (interstitial on/off)
  - `interstitial_frequency` (N)
  - `is_banner_enabled`
  - `banner_android_unit_id`, `banner_ios_unit_id`
  - `interstitial_android_unit_id`, `interstitial_ios_unit_id`

Notes:
- Firestore Rules + composite indexes are managed/deployed from the admin repo (`~/project/app-admin`).

## Environments

We use two environments (NO `stg`):
- `dev`: development/testing
- `prod`: production

Policy:
- Local development and internal testing use `dev`.
- Production releases (Play Store) use `prod`.

Android flavors:
- `dev` -> applicationId `co.vinus.glmoi.dev`
- `prod` -> applicationId `co.vinus.glmoi`

Run commands:
- `flutter run --flavor dev`
- `flutter run --flavor prod`

Build debug APKs:
- `flutter build apk --debug --flavor dev`
- `flutter build apk --debug --flavor prod`

## Dev-Only Workflow (Team Rule)

We do day-to-day development only on the `dev` flavor.

- Default run command: `flutter run --flavor dev`
- Default debug APK: `flutter build apk --debug --flavor dev`
- Use `prod` flavor only for release verification (not for regular development).

## UI / Dev Separation (MUST)

UI(디자인)와 개발 로직은 반드시 분리한다.

목표:
- UI/UX 개선 작업(사내/AI 디자인 포함)이 **presentation/theme만 수정**해서도 안전하게 진행되도록 한다.
- Firestore/Auth/Ads/라우팅 같은 동작은 UI 작업에서 절대 흔들리지 않게 한다.

절대 규칙:
- UI 작업(PR/커밋)은 아래 "UI-only scope" 밖의 코드를 변경하지 않는다.
- UI 작업에서 동작/플로우 변경이 필요하다고 느끼면, 코드는 건드리지 말고 README/이슈에 "요청사항"으로 남긴다.

UI-only scope (UI 작업은 여기만 수정):
- `lib/**/presentation/**` (screens/widgets/layout)
- `lib/core/theme/**` (colors/typography/theme)
- `assets/**` (이미 연결되어 있는 것만; pubspec 변경 금지)

Dev-logic scope (UI-only 작업에서 수정 금지):
- `lib/core/auth/**` (login/auth state)
- `lib/core/ads/**` (ads logic)
- `lib/**/data/**`, `lib/**/domain/**` (Firestore schema, repositories, models)
- `lib/app/bootstrap.dart` (app init)
- `lib/app/router.dart` (routing)
- `lib/app/profile_nickname_prompt_host.dart` (nickname prompt business flow)
- `lib/app/home_shell_container.dart` (shell wiring)
- `android/**`, `ios/**` (native)
- `pubspec.yaml` (dependencies/assets/fonts)

Notes:
- 일부 `presentation` 파일이 Riverpod provider로 repository를 생성합니다(예: `QuotesRepository`). 이런 provider wiring은 사실상 dev-logic에 가깝기 때문에, UI-only 변경에서는 **provider wiring을 유지**하고 위젯 구조/스타일만 조정합니다.
- UI에서 새로운 필드/액션이 필요하면 2단계로 진행합니다.
  1) dev-logic(data/domain/auth/ads/routing) 변경
  2) UI(presentation/theme)에서 소비

## Firebase Setup (Android)

This app is intended to read from the same Firebase projects as the admin:
- `glmoi-dev`
- `glmoi-prod`

Steps (Firebase Console):
1) Create/confirm Android apps in each Firebase project
   - Package name for prod: `co.vinus.glmoi`
   - Package name for dev: `co.vinus.glmoi.dev`
2) Download `google-services.json` for each and place them here:
    - `android/app/src/prod/google-services.json`
    - `android/app/src/dev/google-services.json`

Important:
- Firebase features require the correct `google-services.json` per flavor. If the file is missing or mismatched, `Firebase.initializeApp()` may fail at runtime even if the app builds.

Notes:
- The old `android/app/google-services.maumsori-legacy.json` is kept only as a legacy reference and is not used.

## Android App Settings

Key identifiers:
- ApplicationId (prod): `co.vinus.glmoi`
- ApplicationId (dev): `co.vinus.glmoi.dev`
- Android namespace: `co.vinus.glmoi`
- Launcher label comes from `android/app/src/main/res/values/strings.xml` (`app_name`) and is overridden per flavor in Gradle.

Kakao:
- Kakao redirect scheme currently lives in `android/app/src/main/AndroidManifest.xml`.
- If you rotate Kakao keys or change package name, confirm redirect scheme and Kakao console settings.

## Getting Started

Install deps:

```bash
flutter pub get
```

Verify (static analysis + tests):

```bash
flutter analyze
flutter test
```

Run Android (dev):

```bash
flutter run --flavor dev
```

Run Android (prod):

```bash
flutter run --flavor prod
```

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

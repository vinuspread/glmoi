# [통합 작업지시서] 글모이(Glmoi) 개별 앱 관리자 시스템

## 1. 개요 및 인프라
* **서비스명**: 글모이(Glmoi) 관리자(마음소리에서 글모이로 서비스명 변경됨)
* **기술 스택**: Flutter Web / Firebase (Auth, Firestore, Storage, Remote Config, Functions)
* **핵심 원칙**: 10개 이상의 앱 확장을 고려하여 모든 데이터에 `app_id: "maumsori"` 필드 적용

## 1-1. 글모이 설명
글모이는 사용자가 글을 직접 작성하여 등록할 수 있는 서비스(누구나 작가가 될 수 있다)
글모이에 작성된 글은 검렬없이 자동등록(신고하기 기능 있음)
글모이에 작성된 글중 베스트글은 ‘좋은생각’ 에 노출(관리자기능)
---

## 2. 글모이 관리자 메뉴 구조 (Menu Hierarchy)

### **M1. 대시보드 (Dashboard)**
- **주요 기능**: 접속자 수, 누적 가입자 수, AdMob 연동 수익 지표 요약
- **콘텐츠 지표**: 한줄명언, 좋은생각,말모이의 콘텐츠중  좋아요/공유 수 기준 인기글 TOP 15개씩 노출

### **M2. 글 목록 (Content List)**
- **구조**: 상단 탭 분리 `[한줄명언]` / `[좋은생각]` / `[글모이]`
- **기능**: 키워드 검색, 노출 상태(On/Off) 필터링, 수정/삭제 상세페이지 연결

### **M3. 이미지 등록 (Image Asset)**
- **기능**: 배경용 고해상도 이미지 대량 업로드 (Drag & Drop)
- **자동화**: 업로드 시 썸네일 생성 및 WebP 최적화 리사이징 (Functions 트리거)
- **방식**: 이미지 풀(Pool) 형태 관리 (용도 구분 없이 등록순/빈도순 정렬)

### **M4. 글 작성 (Content Composer)**
- **프로세스**: 
    1. 카테고리 선택 (한줄명언 / 좋은생각 / 글모이)
    2. 본문 작성 (TextArea, 글자 수 체크)
    3. 이미지 매칭: 이미지 풀 그리드에서 썸네일 클릭 선택
- **실시간 프리뷰**: 우측 영역에 앱 실제 렌더링 화면(폰트 24pt, 줄간격 1.6, Dim 적용) 상시 노출


### **M5. 글모이 (글 수집 및 사용자 소통)** 
- **운영 로직**: **선(先) 등록 후(後) 검수** (작성 즉시 앱 노출) 
- **신고 시스템 관리 (핵심)**: 
- **신고 목록**: 사용자가 신고한 게시글 리스트 및 사유 확인 
- **상세 조치**: 신고글 확인 후 [유지 / 수정 / 삭제 / 작성자 차단] 처리 
- **격상 기능**: 우수작 '공식 콘텐츠 격상' (카테고리 복사 및 이동) 
- **필터링**: 금지어 자동 필터링 및 악성 사용자 블랙리스트 관리


### **M6. 광고 관리 (Ad Control)**
- **빈도 제어**: 전면 광고 노출 주기 설정
- **안내 제어**: 광고 전 감성 안내 문구 및 시간 설정

### **M7. 공통 설정 (App Config)**
- **환경 설정**: 버전 정보, 강제 업데이트 여부, 점검 모드 스위치
- **약관 관리**: 서비스 이용약관 및 개인정보 처리방침 (수정 시 시스템 날짜 자동 기록)

---

## 3. 세부 설정 및 수치 정의 (Operational Specs)

### **S1. 시니어 특화 UX 설정 (Remote Config)**
| 항목 | 설정값(기본) | 입력/조작 방식 |
| :--- | :--- | :--- |
| **텍스트 기본 크기** | 24 pt | 직접 입력 (Number Input, 범위: 18~32) |
| **크기 조절 범위** | 20 ~ 40 pt | 직접 입력 (Min / Max 각각 설정) |
| **줄 간격 (Line Height)** | 1.6 | Dropdown: [1.4, 1.5, 1.6, 1.7, 1.8, 2.0] |
| **배경 딤(Dim) 강도** | 0.4 | Dropdown: [0.0 ~ 1.0 (0.1 단위)] |
| **인터랙션 속도** | 500ms | Dropdown: [Fast(300), Normal(500), Slow(800)] |

### **S2. 광고 세부 트리거 (Ad Triggers)**
| 항목 | 설정값(기본) | 입력/조작 방식 |
| :--- | :--- | :--- |
| **전면 광고 빈도** | 5 페이지 | Dropdown: [미노출, 3, 5, 7, 10, 15, 20] |
| **광고 안내 시간** | 1.5 초 | 고정값 (수정 가능한 변수로 할당) |
| **공유 후 강제 노출** | Off | Toggle Switch (On/Off) |
| **글 작성 후 강제 노출** | Off | Toggle Switch (On/Off) |
| **신규 유입 보호** | 20 페이지 | 직접 입력 (첫 접속 후 20개 글까지 광고 스킵) |

---

## 4. 개발 및 데이터 가이드라인
1. **DB 설계**: Firestore `quotes` 컬렉션 내 `is_user_post(bool)`, `is_approved(bool)` 필드로 글모이 데이터와 공식 데이터를 구분할 것.
2. **이미지 처리**: Storage 업로드 시 Firebase Extension을 통해 모바일 최적화 해상도로 변환 프로세스 구축.
3. **프리뷰 엔진**: 글 작성 화면의 프리뷰는 실제 앱의 `ThemeData`와 동일한 스타일을 적용하여 시각적 오차를 제거할 것.
4. **확장성**: 향후 타 앱 관리자로 전환이 용이하도록 `app_id` 기반의 Routing 체계를 구축할 것.

---

## 5. 사용자 앱(안드로이드) 기능 결정 사항

이 섹션은 사용자용 앱(`glmoi`, Flutter 유지 + Android만 타겟)에서 확정된 기능/정책을 기록한다.

### 5-1. 회원/인증
- **회원 범위**: 구글 로그인 + 카카오 로그인 모두 회원으로 인정
- **인증 방식(카카오)**: 카카오 로그인 성공 후 **Firebase Custom Token**을 발급받아 Firebase Auth에 로그인되어야 함
  - 목적: Firestore에서 사용자 단위(`uid`)로 좋아요/신고 1회 제한을 강제하기 위함

### 5-2. 좋아요 / 공유
- **공통 정책**: 좋아요/공유는 **회원만 가능**

좋아요:
- 1인 1회만 가능 (취소/토글 없음)
- 구현 원칙(데이터): 사용자별 좋아요 기록을 남겨 중복 클릭을 서버에서 차단

공유:
- 횟수 제한 없음
- 공유 채널: **카카오톡 공유**
- 공유 포맷: 미정 (캡처 이미지 공유 vs 텍스트 공유 중 선택 필요)

### 5-3. 신고 (글모이만)
- 적용 범위: `글모이` 콘텐츠만 신고 가능 (한줄명언/좋은생각은 신고 기능 없음)
- UX: 신고 버튼 클릭 시 팝업에서 사유 1개 선택 -> `신고하기`
- 사유 목록(`reason_code`):
  - 스팸/광고
  - 욕설/혐오
  - 음란/선정
  - 개인정보
  - 기타
- 기타 선택 시 추가 입력 없음 (사유는 반드시 위 항목 중 선택)
- 1개의 게시물에 대해 1인 1회만 신고 가능
- 관리자 확인: 신고된 게시물은 관리자 `글모이`의 `신고 게시물`에서 확인 가능해야 함
  - 참고: 신고 목록은 `report_count > 0` 필터로 노출되며, 신고 사유는 별도 신고 기록에서 조회 가능해야 함

### 관리자 작업 순서:
1. 코드 수정
2. 로컬 빌드 및 테스트 (http://localhost:5001)
3. 로컬에서 확인 완료 후
4. PROD 배포 (https://glmoi-prod.web.app)

### Dev 모드 사용 안함.
- 본 프로젝트는 무조건 Prod 모드만 진행함.

### Github 백업
GitHub 저장소 구조
https://github.com/vinuspread/glmoi
├── main (브랜치) ← glmoi 앱
└── admin (브랜치) ← app-admin 웹 대시보드


### 불필요한 정보 노출 불필요
Compaction, session summary 내용은 모니터에 노출하지 말것.

---

## 6. 마이페이지 & 설정 확장 작업 순서 (Phase 1-5)

### Phase 1: 설정 화면 - 폰트 크기 설정 (최우선)
**이유:** "여기에서 설정한 값(폰트크기)이 가장 최우선으로 반영 된다" - 전역 영향이므로 먼저 구현

**작업 내역:**
1. `SharedPreferences`에 폰트 크기 저장 (`font_scale`: 0.85/1.0/1.15/1.3)
2. `TextScaler` 전역 적용 (`MaterialApp.builder`)
3. 설정 화면에 라디오 버튼 UI 추가
4. 실시간 미리보기 (설정 변경시 즉시 반영)

**예상 수정 파일:**
- `lib/features/settings/presentation/settings_screen.dart`
- `lib/core/theme/app_theme.dart` (또는 `lib/app/app.dart`)
- `lib/core/utils/font_scale_provider.dart` (신규)

**예상 시간:** 30분

---

### Phase 2: 마이페이지 - 통계 표시 (중간 우선순위)

**작업 내역:**
1. **Firestore 쿼리 추가:**
   - 내가 쓴 글: `quotes.where('userId', isEqualTo: currentUserId).count()`
   - 담은 글: `saved_quotes.where('userId', isEqualTo: currentUserId).count()`
   - 좋아요한 글: `liked_quotes.where('userId', isEqualTo: currentUserId).count()` (컬렉션 확인 필요)
   - 공유한 글: `share_records.where('userId', isEqualTo: currentUserId).count()` (컬렉션 확인 필요)
   - 5개 감정별 통계: `reactions.where('userId', isEqualTo: currentUserId).groupBy('type').count()`

2. **UI 구현:**
   - 숫자 표시 위젯 (로딩 상태 처리)
   - 5개 감정 아이콘 + 숫자 가로 배치

**예상 수정 파일:**
- `lib/features/profile/presentation/screens/mypage_screen.dart`
- `lib/features/profile/data/repositories/user_stats_repository.dart` (신규 - Repository 필요시)
- `lib/features/profile/presentation/providers/user_stats_provider.dart` (신규)

**주의:** README 제약사항에 따라 `data/repositories`는 수정 불가 범위이므로, 기존 repository 확인 후 사용 또는 직접 Firestore 호출 결정 필요

**예상 시간:** 1시간

---

### Phase 3: 마이페이지 - 프로필 수정 동기화 (중간 우선순위)

**작업 내역:**
1. **프로필 수정시 Cloud Function 호출:**
   - 닉네임/이미지 변경 → Firebase Function 트리거
   - `quotes` 컬렉션의 `authorName`, `authorPhotoUrl` 일괄 업데이트
   - (또는 클라이언트에서 배치 업데이트 - 성능 고려 필요)

2. **UI 수정:**
   - "수정" 버튼 클릭시 로딩 상태 표시
   - 완료시 성공 메시지

**예상 작업:**
- Backend: `/Users/sungyounghan/project/app-admin/functions/src/profile.ts` (신규)
- Frontend: `lib/features/profile/presentation/screens/mypage_screen.dart`

**주의:** Backend 작업이 필요하므로 Firebase Functions 배포 포함

**예상 시간:** 1시간

---

### Phase 4: 설정 화면 - 탈퇴하기 (낮은 우선순위)

**작업 내역:**
1. 탈퇴 확인 다이얼로그
2. Firebase Auth 계정 삭제 (`user.delete()`)
3. Firestore 사용자 데이터 삭제 (Cloud Function 권장)
4. 로그인 화면으로 이동

**예상 수정 파일:**
- `lib/features/settings/presentation/settings_screen.dart`
- Backend: `/Users/sungyounghan/project/app-admin/functions/src/account.ts` (신규)

**예상 시간:** 30분

---

### Phase 5: 설정 화면 - 회사소개/이용약관 (낮은 우선순위)

**작업 내역:**
1. 정적 페이지 또는 웹뷰 링크
2. 간단한 텍스트 화면 또는 `url_launcher`

**예상 수정 파일:**
- `lib/features/settings/presentation/settings_screen.dart`
- `lib/features/settings/presentation/screens/terms_screen.dart` (신규)
- `lib/features/settings/presentation/screens/company_info_screen.dart` (신규)

**예상 시간:** 20분

---

### 작업 순서 요약 (우선순위)

| 순서 | 작업 | 예상 시간 | Backend 필요 |
|-----|-----|---------|-------------|
| 1️⃣ | **폰트 크기 설정** | 30분 | ❌ |
| 2️⃣ | **마이페이지 통계 표시** | 1시간 | ❌ (Firestore 직접 쿼리) |
| 3️⃣ | **프로필 수정 동기화** | 1시간 | ✅ (Cloud Function) |
| 4️⃣ | **탈퇴하기** | 30분 | ✅ (Cloud Function) |
| 5️⃣ | **회사소개/이용약관** | 20분 | ❌ |

**진행 방법:** 1→2→3→4→5 순서로 진행하며, 각 단계 완료 후 빌드/배포하여 검증
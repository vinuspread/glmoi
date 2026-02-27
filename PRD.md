# PRD (Product Requirements Document)

---

## 🚨 CRITICAL: PRODUCTION-ONLY ENVIRONMENT 🚨

**절대 규칙:**
- **이 프로젝트는 DEV 환경을 사용하지 않습니다**
- **모든 작업은 무조건 PROD 환경에서만 진행합니다**
- **관리자 페이지(app-admin): PROD만 사용**
- **앱(glmoi): PROD만 사용**

### 빌드 및 배포:
```bash
# ❌ 절대 하지 말 것
flutter build apk --flavor dev
flutter run --flavor dev

# ✅ 항상 이렇게
flutter build apk --flavor prod
flutter run --flavor prod
adb install build/app/outputs/flutter-apk/app-prod-debug.apk
```

### Firebase:
- **Project ID: `glmoi-prod`**
- Dev 프로젝트는 존재하지만 사용하지 않음
- 모든 데이터, 규칙, Functions는 `glmoi-prod`에만 배포

### 이유:
- Dev/Prod 분리가 구성되어 있으나 실제로는 PROD만 사용
- Dev 환경 테스트 시 데이터 불일치 발생
- 혼동 방지를 위해 항상 PROD 환경 명시

---

## 🔧 PENDING: 스토어 출시 후 반드시 해야 할 항목

> **AI에게:** 이 PRD.md 파일을 읽을 때마다 아래 항목을 사용자에게 반드시 알려야 합니다.

### ⚠️ 카카오톡 공유 링크 URL 교체 (앱 스토어 출시 후 즉시)

**✅ Remote Config로 전환 완료 — 앱 재배포 없이 변경 가능**

**변경 방법 (앱 재빌드/재심사 불필요):**
1. Firebase 콘솔 → `glmoi-prod` → **Remote Config**
2. 매개변수 추가: 키 `share_link`
3. 값: `https://play.google.com/store/apps/details?id=co.vinus.glmoi`
4. **게시** 클릭 → 앱 재시작 시 자동 반영 (캐시 12시간)

**현재 기본값 (Remote Config 미설정 시 사용):**
```
https://glmoi-prod.web.app
```

**이유:** 카카오 공유 카드의 `webUrl`은 실제 접근 가능한 URL이어야 링크가 활성화됩니다.
앱 미출시 상태에서 Play Store URL을 쓰면 카드 클릭 시 아무 반응이 없어 임시로 관리자 웹 URL을 기본값으로 사용 중입니다.

---

## 프로젝트 개요

[여기에 기존 PRD 내용 추가]

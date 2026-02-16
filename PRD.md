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

## 프로젝트 개요

[여기에 기존 PRD 내용 추가]

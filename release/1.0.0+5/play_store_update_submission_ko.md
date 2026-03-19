# Google Play 업데이트 등록 파일 (KO)

## 1) 앱 기본 정보
- 앱 이름: 글모이 (glmoi)
- 패키지명: `co.vinus.glmoi`
- 대상 스토어: Google Play Console
- 등록 유형: 기존 앱 업데이트 (신규 등록 아님)

## 2) 이번 배포 메타 정보
- 배포 일자: 2026-03-06
- 배포 트랙: 내부 테스트
- 버전명(versionName): 1.0.0
- 버전코드(versionCode): 5
- 빌드 엔트리: `prod`

참고:
- 현재 프로젝트 버전 값은 `pubspec.yaml`의 `version`에서 관리됨
- Android는 `android/app/build.gradle.kts`에서 Flutter 버전 값을 사용함

## 3) Play Console 릴리즈 노트 (복붙용)

### 짧은 버전 (권장)
- 앱 안정성을 개선하고 일부 화면의 사용성을 높였습니다.
- 콘텐츠 작성/미리보기 동작과 로그인 흐름을 개선했습니다.

### 상세 버전
- 관리자 기능의 안정성을 개선했습니다.
- 콘텐츠 미리보기 UI를 작성 화면과 일관되게 조정했습니다.
- 로그인 UX(입력/오류 안내)를 개선했습니다.
- 전반적인 성능 및 오류 처리 품질을 개선했습니다.

## 4) 업데이트 검수 체크리스트
- [ ] 앱 실행/종료 시 크래시 없음
- [ ] 로그인/로그아웃 및 세션 유지 정상 동작
- [ ] 콘텐츠 목록 -> 제목 클릭 -> 미리보기 화면 정상 동작
- [ ] 글 작성 화면 프리뷰와 목록 프리뷰 크기/비율 일치 확인
- [ ] 짧은 글/긴 글 모두 저장 정상 동작
- [ ] 광고 노출(배너/전면) 설정값 반영 확인
- [ ] 푸시/딥링크 주요 플로우 확인

## 5) 빌드 및 업로드 절차 (Android)
1. 버전 증가
   - `pubspec.yaml`의 `version` 갱신 (versionName + versionCode)
2. 프로덕션 빌드
   - `flutter build appbundle --flavor prod`
3. Play Console 업로드
   - 생성된 `.aab` 업로드 후 릴리즈 노트 입력
4. 사전 배포 검증
   - 내부/비공개 테스트 설치 후 주요 시나리오 확인

## 6) 출시 후 필수 후속 작업
- [ ] Firebase Remote Config 키 `share_link`를 Play Store URL로 설정
  - 값: `https://play.google.com/store/apps/details?id=co.vinus.glmoi`
- [ ] Remote Config 게시 후 공유 동작 재검증

## 7) 제출자 기록
- 작성자: OpenCode
- 검토자: [담당자 입력]
- 비고: 현재 저장소 버전(`pubspec.yaml`) 기준으로 작성됨. Play Console 업로드 시 기존 배포 버전과 충돌하면 `versionCode`를 증가시켜 재빌드 필요.

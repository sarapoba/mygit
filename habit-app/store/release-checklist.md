# 스토어 제출 체크리스트 — 루트 v1.0

> 코드베이스(`habit-app/app`)에서 스토어 심사 통과까지의 전 절차. 이 문서 순서대로 진행한다.
> 제출은 개발자 계정과 로컬 빌드 환경(macOS+Xcode / Android Studio)에서만 가능하다.

## 0. 사전 준비

- [ ] Apple Developer Program 등록 (연 $99, 법인/개인 결정 — D-U-N-S 필요 시 2주 여유)
- [ ] Google Play Console 등록 (1회 $25)
- [ ] 번들 ID 확정: `app.rootgarden.root` (iOS Bundle ID = Android applicationId 로 통일)
- [ ] 개인정보 처리방침 웹 URL 준비 — `privacy-policy-draft.md` 를 검토 후 정적 페이지로 호스팅 (양 스토어 필수 입력값)

## 1. 프로젝트 셋업

- [ ] `flutter create . --platforms=ios,android --org app.rootgarden --project-name root_app`
- [ ] `flutter pub get` → `dart tool/engine_check.dart` (24건 통과 확인) → `flutter test`
- [ ] Pretendard 폰트 번들 (app/README) — 라이선스 SIL OFL, 고지 불필요하나 오픈소스 라이선스 화면에 포함 권장
- [ ] 앱 아이콘: 새싹 심벌(leaf-500 #3D9A5C 배경 leaf-050) — `flutter_launcher_icons` 로 생성
  - 1024×1024 마스터 1장 → iOS 전 사이즈 + Android adaptive icon (foreground/배경 분리)
- [ ] 스플래시: `flutter_native_splash` — 배경 `#F7F9F6`(라이트)/`#0F1722`(다크) + 중앙 새싹 심벌
- [ ] 앱 표시명: iOS `CFBundleDisplayName` = "루트", Android `android:label` = "루트"

## 2. 플랫폼 설정

### iOS (`ios/Runner`)
- [ ] Deployment Target: iOS 16.0 (기획 13 §4.1)
- [ ] 권한 문구: v1.0 은 **권한을 하나도 요청하지 않음** — Info.plist 에 카메라/위치 등 어떤 Usage Description 도 넣지 않는다 (미사용 권한 문구는 리젝 사유)
- [ ] Encryption: `ITSAppUsesNonExemptEncryption = NO` (표준 HTTPS 외 암호화 없음 — v1.0 은 네트워크 자체가 없음)
- [ ] 서명: Xcode → Signing & Capabilities → 팀 선택, Automatically manage signing

### Android (`android/app`)
- [ ] `minSdk 26` / `targetSdk` 최신 (Play 정책 요구치)
- [ ] 서명 키 생성: `keytool -genkey -v -keystore root-release.jks -alias root -keyalg RSA -keysize 2048 -validity 10000` → `key.properties` 연결 (키 파일은 **절대 리포에 커밋 금지**)
- [ ] 권한: v1.0 매니페스트에 인터넷 외 권한 없음 확인 (shared_preferences 는 권한 불필요. INTERNET 도 실사용 없으므로 제거 가능)

## 3. 빌드·검증

- [ ] `flutter build ipa` / `flutter build appbundle --release`
- [ ] 실기기 검증 4종 세트 (기획 13 §6-5): ① 비행기 모드 전체 플로우 ② 자정~04:00 경계 체크 ③ 시스템 폰트 200% ④ 다크모드 전 화면
- [ ] 온보딩 중단·재실행 이어하기 확인 (07 §7)
- [ ] TestFlight 내부 테스트 / Play 내부 트랙 업로드 → 최소 3기기 스모크

## 4. 스토어 등록 정보

- [ ] App Store: `app-store-listing.md` 의 값 입력 + 스크린샷 (6.7"/6.1"/5.5" — 목업 문서 §4 화면 8종에서 선별)
- [ ] Play Store: `play-store-listing.md` 의 값 입력 + 그래픽(1024×500 피처 그래픽)
- [ ] **App Privacy (Apple) / 데이터 보안 (Google) 응답 — v1.0 기준:**
  - 수집하는 데이터: **없음** (모든 데이터 기기 내 저장, 서버·SDK·분석 도구 없음)
  - 제3자 공유: 없음 / 추적: 없음 → Apple "Data Not Collected", Google "수집 데이터 없음"
  - ⚠️ Phase 1 에서 계정·분석(Amplitude)·AI 가 붙는 순간 이 응답을 반드시 갱신할 것 (기획 12 §8)
- [ ] 연령 등급: 4+/전체이용가 (설문에서 해당 없음 일괄)
- [ ] 카테고리: 건강 및 피트니스 (또는 생산성 — A/B 불가, 건강 및 피트니스 권장: 습관 앱 탐색 트래픽)

## 5. 심사 대응 노트

- [ ] 심사 메모에 명시: "로그인 없음, 서버 통신 없음, 모든 데이터는 기기 내 저장. 데모 계정 불필요."
- [ ] Apple 4.2(최소 기능) 방어: 온보딩 개인화, 프리즈/회복 시스템, 잔디 통계 등 단순 체크리스트 이상의 기능임을 스크린샷 캡션으로 어필
- [ ] 리젝 시 대응 창구: Resolution Center 답변은 기능 설명 + 해당 기획 문서 근거로 간결하게

## 6. 출시 후 즉시 (기획 04·13 연결)

- [ ] Phase 0 게이트 측정 준비: 분석 SDK 는 v1.1 에서 — v1.0 은 스토어 콘솔 지표(설치·삭제·크래시)만 모니터링
- [ ] Sentry/Amplitude 도입 시점 = 계정·서버 도입(Phase 1)과 함께 — 개인정보 응답 갱신 동반
- [ ] 크래시 프리 목표: 베타 99.5% → 정식 99.8% (기획 05 §5.2)
- [ ] 스토어 리뷰 대응 원칙: 페이월·강제 요소가 없으므로 초기 평점 방어 유리 — 기능 요청은 Phase 1 백로그(13 §3)로 수렴

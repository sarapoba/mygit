# 루트(ROOT) — Flutter 앱 (Phase 0 / v1.0)

하루 2분, 끊기지 않는 습관. 프리즈(자동 보호)와 회복 체크(한 번은 사고)가 완벽주의 붕괴를 막는 습관 앱.
기획 원본: `habit-app/01~15` 문서. 디자인 토큰: 14 문서. 판정 규칙: 06 문서.

## 상태

| 영역 | 상태 |
|---|---|
| 도메인 엔진 (04:00 경계·스트릭·프리즈·회복·월 지급) | ✅ 구현 + 시나리오 검증 24건 통과 (`tool/engine_check.dart`) |
| 온보딩 S01~S14 (P0 변형, 단방향 상태 머신, 이어하기) | ✅ 구현 |
| 홈·체크인 상세·기록(잔디)·마이 | ✅ 구현 (Phase 0 3탭) |
| 라이트/다크 테마 (14 문서 토큰) | ✅ 구현 |
| 로컬 우선 영속화 | ✅ shared_preferences JSON (SQLite 이관 경로는 `data/store.dart` 주석) |
| 알림 | ⏳ S3 — `services/notifications.dart` 인터페이스와 연결 가이드 준비됨 |
| 홈 위젯 (iOS WidgetKit / Android Glance) | ⏳ S3 — 네이티브 모듈, Xcode/Android Studio 필요 (기획 13 §4.1) |
| 앱 아이콘·스플래시·서명·스토어 제출 | ⏳ `habit-app/store/release-checklist.md` 절차 수행 |

## 시작하기

```bash
# 0) Flutter 3.24+ 설치 (https://docs.flutter.dev/get-started)

# 1) 플랫폼 셸 생성 — lib/·pubspec 은 보존된 채 android/·ios/ 만 생성된다
cd habit-app/app
flutter create . --platforms=ios,android --org app.rootgarden --project-name root_app

# 2) 의존성
flutter pub get

# 3) 도메인 엔진 검증 (의존성 불필요, Dart 만으로 실행 가능)
dart tool/engine_check.dart

# 4) 테스트 & 실행
flutter test
flutter run
```

## 폰트 (권장)

[Pretendard](https://github.com/orioncactus/pretendard) OTF 5종(Regular/Medium/SemiBold/Bold/ExtraBold)을
`assets/fonts/` 에 넣고 `pubspec.yaml` 의 fonts 주석을 해제. 없어도 시스템 서체로 동작한다.

## 구조

```
lib/
├── main.dart / app.dart      앱 진입·탭 셸·라이프사이클(복귀 시 04:00 배치)
├── core/                     tokens(14 문서)·theme·strings(카피 SSOT)
├── domain/                   clock·models·engine — 순수 Dart, Flutter 무의존
├── data/store.dart           로컬 영속화 (JSON 스냅숏)
├── state/app_controller.dart 상태 소유자 (ChangeNotifier)
├── services/notifications.dart  S3 알림 경계 (현재 no-op)
└── ui/                       onboarding·home·detail·stats·my·components
tool/engine_check.dart        의존성 없는 엔진 시나리오 러너 (24건)
test/engine_test.dart         flutter test 용 회귀 테스트
```

## 릴리즈 차단 기준 (기획 13 §6)

1. 온보딩 완주·중단 재진입·뒤로가기 자동 테스트 실패 시 배포 금지
2. 모든 기능 PR 은 비행기 모드 시나리오 통과가 머지 조건
3. 실패·복귀·프리즈 화면 카피는 2인 승인제 — `core/strings.dart` 만 수정
4. 엣지 테스트셋(자정 직전·타임존·기기 변경·월 전환) 매 릴리즈 회귀

스토어 제출 절차 → `../store/release-checklist.md`

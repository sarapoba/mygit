/// 알림 서비스 경계 — Phase 0 S3 스코프 (13 문서).
///
/// v1.0 스토어 제출은 알림 없이도 가능하다(권한도 요청하지 않으므로 심사 이슈 없음).
/// S3 에서 `flutter_local_notifications` + `timezone` 을 붙일 때 이 인터페이스의
/// 구현체만 교체한다. 연결 가이드:
///
/// 1. pubspec: flutter_local_notifications, timezone 추가
/// 2. Android: exact alarm 권한(API 31+) — 기본은 inexact 데일리로 충분,
///    채널 1개("habit-reminder"), 아이콘 ic_stat_leaf
/// 3. iOS: UNUserNotificationCenter 권한은 반드시 프리퍼미션(07 §6) 뒤에만 요청
/// 4. 스케줄: 유저 리마인더 시각(state.ob.remind) 데일리 1건 + 21:00 스트릭 위험
///    알림(정적 템플릿, 03 §6 — 미완료 습관이 있을 때만)
/// 5. 문구는 core/strings.dart 에 추가하고 톤 게이트(13 §6-4)를 거칠 것
abstract class NotificationService {
  Future<void> scheduleDailyReminder(String hhmm);
  Future<void> cancelAll();
}

/// Phase 0 기본 구현 — 아무것도 하지 않는다.
class NoopNotificationService implements NotificationService {
  @override
  Future<void> scheduleDailyReminder(String hhmm) async {}

  @override
  Future<void> cancelAll() async {}
}

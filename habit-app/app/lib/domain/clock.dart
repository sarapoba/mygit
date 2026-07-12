/// 시간 유틸 — 하루 경계는 로컬 04:00 (기획 06 문서 §2).
/// 순수 Dart: Flutter 의존 없음(테스트 러너에서 단독 실행 가능).
class AppClock {
  AppClock({this.offset = Duration.zero});

  /// 테스트·시뮬레이션 전용 오프셋. 릴리즈 빌드에서는 항상 zero.
  Duration offset;

  DateTime now() => DateTime.now().add(offset);

  /// 현재 시각이 속한 "루트의 하루" (04:00 리셋 적용).
  String today() => localDate(now());

  int hourNow() => now().hour;

  static String localDate(DateTime t) => ymd(t.subtract(const Duration(hours: 4)));

  static String ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// 'YYYY-MM-DD' → 정오 기준 DateTime (DST 안전).
  static DateTime parse(String ds) {
    final p = ds.split('-');
    return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]), 12);
  }

  static String addDays(String ds, int n) => ymd(parse(ds).add(Duration(days: n)));

  static String monthKey(String ds) => ds.substring(0, 7);

  /// 문자열 날짜 비교 (사전순 == 시간순).
  static int cmp(String a, String b) => a.compareTo(b);

  static int weekdayOf(String ds) => parse(ds).weekday; // 월=1 … 일=7

  /// 이번 주(월요일 시작)의 월요일 날짜.
  static String weekStart(String ds) => addDays(ds, -(weekdayOf(ds) - 1));
}

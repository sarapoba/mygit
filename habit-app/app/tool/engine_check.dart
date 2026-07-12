/// 도메인 엔진 시나리오 검증 — 의존성 없이 단독 실행:
///   dart tool/engine_check.dart
/// 웹 프로토타입에서 통과한 19건 시나리오와 동일 + 직렬화 왕복 검증.
library;

import '../lib/domain/clock.dart';
import '../lib/domain/engine.dart';
import '../lib/domain/models.dart';

int failures = 0;

void check(String name, bool cond, [String detail = '']) {
  // ignore: avoid_print
  print('${cond ? 'PASS' : 'FAIL'}  $name${cond ? '' : '  <-- $detail'}');
  if (!cond) failures++;
}

void main() {
  final clock = AppClock();
  final s = AppState();
  final e = Engine(s, clock);

  // ── 온보딩 결과 재현: 습관 1개(2분 버전) + 오늘 첫 체크 ──
  s.habits.add(Habit(
      id: 'h1', name: '운동복 갈아입기', mini: '운동복 갈아입기', created: clock.today()));
  s.lastJudged = AppClock.addDays(clock.today(), -1);
  final h = s.habits.first;
  e.check(h, Grade.full);
  check('첫 체크 → 스트릭 1', e.streak(h) == 1, 'streak=${e.streak(h)}');
  check('전체 데일리 스트릭 1', e.totalStreak() == 1, 'total=${e.totalStreak()}');

  // ── D+1: 어제 DONE_F, 오늘 미체크여도 스트릭 1 유지 ──
  clock.offset += const Duration(days: 1);
  e.judgeUpTo();
  final y1 = AppClock.addDays(clock.today(), -1);
  check('어제 판정 DONE_F', s.outcomes[y1]?[h.id] == Outcome.doneFull,
      '${s.outcomes[y1]}');
  check('미체크 오늘 스트릭 1', e.streak(h) == 1, 'streak=${e.streak(h)}');

  // ── D+2: 미스 → 프리즈 자동 소모 ──
  clock.offset += const Duration(days: 1);
  e.judgeUpTo();
  final y2 = AppClock.addDays(clock.today(), -1);
  check('미스일 프리즈 자동 소모 → FROZEN', s.outcomes[y2]?[h.id] == Outcome.frozen,
      '${s.outcomes[y2]?[h.id]}');
  check('프리즈 잔액 0', s.freezeBal == 0, 'bal=${s.freezeBal}');
  check('FROZEN은 유지·+1 없음 → 스트릭 1', e.streak(h) == 1, 'streak=${e.streak(h)}');

  // ── D+3: 프리즈 없음 → 회복 대기 PENDING ──
  clock.offset += const Duration(days: 1);
  e.judgeUpTo();
  final y3 = AppClock.addDays(clock.today(), -1);
  check('프리즈 없으면 회복 대기 PENDING', s.outcomes[y3]?[h.id] == Outcome.pending,
      '${s.outcomes[y3]?[h.id]}');
  check('PENDING 중 스트릭 표시 유지 1', e.streak(h) == 1, 'streak=${e.streak(h)}');

  // ── 오늘 체크 → 회복 카드 → 수락 ──
  final ev = e.check(h, Grade.full);
  check('회복 필요 이벤트 발생', ev == CheckEvent.needsRecovery, '$ev');
  e.acceptRecovery(h.id);
  check('회복 수락 → RECOVERED', s.outcomes[y3]?[h.id] == Outcome.recovered,
      '${s.outcomes[y3]?[h.id]}');
  check('회복권 당월 사용 기록', s.recoveryUsedMonth == AppClock.monthKey(clock.today()),
      '${s.recoveryUsedMonth}');
  check('체인 유지: DONE(1)+FROZEN(0)+RECOVERED(0)+오늘(1) = 2', e.streak(h) == 2,
      'streak=${e.streak(h)}');

  // ── D+4~5: 자원 소진 상태로 이틀 미스 → 끊김 ──
  clock.offset += const Duration(days: 1);
  e.judgeUpTo();
  clock.offset += const Duration(days: 1);
  e.judgeUpTo();
  check('자원 소진 후 미스 → 스트릭 0', e.streak(h) == 0, 'streak=${e.streak(h)}');

  // ── 부분 달성 / 승격 / 언체크 ──
  var ev2 = e.check(h, Grade.partial);
  check('부분 달성도 달성 — 스트릭 1', ev2 == CheckEvent.checked && e.streak(h) == 1,
      '$ev2 streak=${e.streak(h)}');
  ev2 = e.check(h, Grade.full);
  check('부분→완전 승격', ev2 == CheckEvent.upgraded &&
          s.checks[clock.today()]?[h.id] == Grade.full, '$ev2');
  ev2 = e.check(h, Grade.full);
  check('당일 언체크 → 기록 삭제', ev2 == CheckEvent.unchecked &&
          s.checks[clock.today()]?[h.id] == null, '$ev2');
  e.check(h, Grade.full); // 되돌려 둠

  // ── 40일 경과: 월 전환 지급 + 소모 정합 ──
  clock.offset += const Duration(days: 40);
  e.judgeUpTo();
  final grants = s.freezeLog.where((l) => l.type == 'grant').length;
  final uses = s.freezeLog.where((l) => l.type == 'use').length;
  check('월 전환 시 프리즈 지급 이력 존재', grants >= 1, 'grants=$grants');
  check('지급분이 미스일에 자동 소모됨', uses + s.freezeBal >= grants,
      'uses=$uses bal=${s.freezeBal}');
  check('잔액 상한(2) 이내', s.freezeBal <= freezeCap, 'bal=${s.freezeBal}');

  // ── 다습관: 프리즈는 스트릭 긴 습관 우선 (06 엣지 9) ──
  final s2 = AppState()..freezeBal = 1;
  final c2 = AppClock();
  final e2 = Engine(s2, c2);
  final t0 = c2.today();
  // A는 3일 먼저 시작해 연속 달성(사전 판정 시딩), B는 오늘 시작
  s2.habits.addAll([
    Habit(id: 'a', name: 'A', mini: 'a', created: AppClock.addDays(t0, -3)),
    Habit(id: 'b', name: 'B', mini: 'b', created: t0),
  ]);
  for (var i = 3; i >= 1; i--) {
    s2.outcomes[AppClock.addDays(t0, -i)] = {'a': Outcome.doneFull};
  }
  s2.lastJudged = AppClock.addDays(t0, -1);
  // 오늘 둘 다 체크 → A 스트릭 4, B 스트릭 1
  s2.checks.putIfAbsent(t0, () => {})['a'] = Grade.full;
  s2.checks[t0]!['b'] = Grade.full;
  c2.offset += const Duration(days: 1);
  e2.judgeUpTo();
  check('사전 조건: A 스트릭 > B 스트릭', e2.streak(s2.habits[0]) == 4 &&
          e2.streak(s2.habits[1]) == 1,
      'A=${e2.streak(s2.habits[0])} B=${e2.streak(s2.habits[1])}');
  // 둘 다 미스인 하루 경과 → 프리즈 1개는 A(긴 쪽)에, B는 회복 대기
  c2.offset += const Duration(days: 1);
  e2.judgeUpTo();
  final yy = AppClock.addDays(c2.today(), -1);
  check('프리즈는 스트릭 긴 습관(A) 우선', s2.outcomes[yy]?['a'] == Outcome.frozen,
      'A=${s2.outcomes[yy]?['a']}');
  check('나머지(B)는 회복 대기', s2.outcomes[yy]?['b'] == Outcome.pending,
      'B=${s2.outcomes[yy]?['b']}');

  // ── 직렬화 왕복 ──
  final round = AppState.fromJson(s.toJson());
  check('JSON 왕복: 습관·잔액·판정 보존',
      round.habits.length == s.habits.length &&
          round.freezeBal == s.freezeBal &&
          round.outcomes.length == s.outcomes.length &&
          round.outcomes[y3]?[h.id] == Outcome.recovered,
      'habits=${round.habits.length} bal=${round.freezeBal}');

  // ignore: avoid_print
  print(failures == 0 ? '\n== ALL CHECKS PASSED ==' : '\n== $failures FAILURES ==');
  if (failures > 0) throw StateError('$failures failures');
}

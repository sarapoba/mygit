import 'package:flutter_test/flutter_test.dart';

import 'package:root_app/domain/clock.dart';
import 'package:root_app/domain/engine.dart';
import 'package:root_app/domain/models.dart';

/// 핵심 판정 규칙 회귀 테스트 — 전체 시나리오는 tool/engine_check.dart 참조.
/// 온보딩·스트릭 회귀 0건이 릴리즈 차단 기준 (기획 13 문서 §6-1).
void main() {
  (AppState, AppClock, Engine, Habit) setup() {
    final clock = AppClock();
    final s = AppState();
    final e = Engine(s, clock);
    final h = Habit(id: 'h1', name: '테스트', mini: '2분', created: clock.today());
    s.habits.add(h);
    s.lastJudged = AppClock.addDays(clock.today(), -1);
    return (s, clock, e, h);
  }

  test('체크 → 스트릭 1, 언체크 → 0', () {
    final (_, _, e, h) = setup();
    expect(e.check(h, Grade.full), CheckEvent.checked);
    expect(e.streak(h), 1);
    expect(e.check(h, Grade.full), CheckEvent.unchecked);
    expect(e.streak(h), 0);
  });

  test('부분 달성은 동일 인정, 승격 이벤트', () {
    final (_, _, e, h) = setup();
    expect(e.check(h, Grade.partial), CheckEvent.checked);
    expect(e.streak(h), 1);
    expect(e.check(h, Grade.full), CheckEvent.upgraded);
  });

  test('미스일 프리즈 자동 소모 → 스트릭 유지(+1 없음)', () {
    final (s, clock, e, h) = setup();
    e.check(h, Grade.full);
    clock.offset += const Duration(days: 2); // 하루 체크, 하루 미스
    e.judgeUpTo();
    final missed = AppClock.addDays(clock.today(), -1);
    expect(s.outcomes[missed]?[h.id], Outcome.frozen);
    expect(s.freezeBal, 0);
    expect(e.streak(h), 1);
  });

  test('프리즈 소진 후 미스 → 회복 대기 → 수락 시 체인 유지', () {
    final (s, clock, e, h) = setup();
    s.freezeBal = 0;
    e.check(h, Grade.full);
    clock.offset += const Duration(days: 2);
    e.judgeUpTo();
    final missed = AppClock.addDays(clock.today(), -1);
    expect(s.outcomes[missed]?[h.id], Outcome.pending);
    expect(e.check(h, Grade.full), CheckEvent.needsRecovery);
    e.acceptRecovery(h.id);
    expect(s.outcomes[missed]?[h.id], Outcome.recovered);
    expect(e.streak(h), 2);
    expect(e.recoveryLeftThisMonth, isFalse);
  });

  test('회복 대기 미이행(이틀 연속 미스) → 끊김', () {
    final (s, clock, e, h) = setup();
    s.freezeBal = 0;
    e.check(h, Grade.full);
    clock.offset += const Duration(days: 3); // 체크 1일 + 미스 2일
    e.judgeUpTo();
    expect(e.streak(h), 0);
  });

  test('직렬화 왕복 보존', () {
    final (s, clock, e, h) = setup();
    e.check(h, Grade.full);
    clock.offset += const Duration(days: 2);
    e.judgeUpTo();
    final round = AppState.fromJson(s.toJson());
    expect(round.habits.single.name, '테스트');
    expect(round.freezeBal, s.freezeBal);
    expect(round.outcomes.length, s.outcomes.length);
  });
}

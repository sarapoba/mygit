/// 판정 엔진 — 기획 06 문서 §4.2 의사코드의 구현.
/// 웹 프로토타입에서 시나리오 19건으로 검증된 로직의 Dart 포팅이며,
/// tool/engine_check.dart 로 동일 시나리오를 재검증한다.
/// 순수 Dart: Flutter 의존 없음.
library;

import 'clock.dart';
import 'models.dart';

/// 잔디 셀 표시 단계 (11 문서 GrassCalendar 5상태).
enum GrassLevel { empty, partial, done1, done2, frozen }

class Engine {
  Engine(this.state, this.clock);

  final AppState state;
  final AppClock clock;

  // ── 배치 판정: 마지막 판정일 다음 날부터 어제까지 순서대로 ──────────

  void judgeUpTo() {
    final t = clock.today();
    if (state.lastJudged == null) {
      state.lastJudged = AppClock.addDays(t, -1);
      return;
    }
    var d = AppClock.addDays(state.lastJudged!, 1);
    while (AppClock.cmp(d, t) < 0) {
      _judgeDay(d);
      state.lastJudged = d;
      d = AppClock.addDays(d, 1);
    }
  }

  void _judgeDay(String day) {
    final prev = AppClock.addDays(day, -1);

    // 월 전환 → 프리즈 정기 지급 (무료 월 1, 보유 상한 2 — 06 §4.1)
    if (AppClock.monthKey(day) != AppClock.monthKey(prev)) {
      if (state.freezeBal < freezeCap) {
        state.freezeBal++;
        state.freezeLog.insert(
            0, FreezeEntry(date: day, type: 'grant', message: '매월 1일 지급 +1'));
      } else {
        state.freezeLog.insert(
            0, FreezeEntry(date: day, type: 'skip', message: '보유 상한(2)으로 지급 소멸'));
      }
    }

    final out = state.outcomes.putIfAbsent(day, () => {});
    final prevOut = state.outcomes[prev] ?? {};
    final misses = <Habit>[];

    for (final h in state.habits) {
      if (AppClock.cmp(h.created, day) > 0) continue; // 생성 전

      // 전일 회복 대기 미이행 → 그 날은 끊김 확정 (06 §4.2: 이틀 연속 미스)
      if (prevOut[h.id] == Outcome.pending) {
        prevOut[h.id] = Outcome.missed;
      }

      final g = state.checks[day]?[h.id];
      if (g == Grade.full) {
        out[h.id] = Outcome.doneFull;
      } else if (g == Grade.partial) {
        out[h.id] = Outcome.donePartial;
      } else {
        misses.add(h);
      }
    }

    // 스트릭 긴 습관부터 자원 배분 — 잃을 것이 큰 쪽 우선 보호 (06 §4.2)
    misses.sort((a, b) => streakAt(b, day) - streakAt(a, day));

    var pendingGiven = _hasPendingAnywhere();
    for (final h in misses) {
      if (h.freezeOn && state.freezeBal > 0) {
        state.freezeBal--;
        out[h.id] = Outcome.frozen;
        state.freezeLog.insert(
            0, FreezeEntry(date: day, type: 'use', message: '「${h.name}」을 지켰어요 −1'));
      } else if (state.recoveryUsedMonth != AppClock.monthKey(AppClock.addDays(day, 1)) &&
          !pendingGiven) {
        out[h.id] = Outcome.pending; // 유저당 월 1회 — 대기 1건만 (06 §4.1)
        pendingGiven = true;
      } else {
        out[h.id] = Outcome.missed;
      }
    }
  }

  bool _hasPendingAnywhere() {
    for (final m in state.outcomes.values) {
      if (m.containsValue(Outcome.pending)) return true;
    }
    return false;
  }

  // ── 스트릭: 저장 카운터가 아닌 원장 재계산 (13 문서 §4.3) ─────────

  int streakAt(Habit h, String day) {
    var n = 0;
    var d = AppClock.addDays(day, -1);
    while (AppClock.cmp(d, h.created) >= 0) {
      final o = state.outcomes[d]?[h.id];
      if (o == Outcome.doneFull || o == Outcome.donePartial) {
        n++;
      } else if (o == Outcome.frozen || o == Outcome.recovered || o == Outcome.pending) {
        // 유지 장치 — 스트릭 유지, +1 없음 (06 §4)
      } else {
        break;
      }
      d = AppClock.addDays(d, -1);
    }
    if (state.checks[day]?[h.id] != null) n++;
    return n;
  }

  int streak(Habit h) => streakAt(h, clock.today());

  /// 전체 데일리 스트릭 — due 중 1개 이상 달성이면 +1 (06 §4.4).
  int totalStreak() {
    if (state.habits.isEmpty) return 0;
    var n = 0;
    final first = state.habits.map((h) => h.created).reduce((a, b) => AppClock.cmp(a, b) <= 0 ? a : b);
    var d = AppClock.addDays(clock.today(), -1);
    while (AppClock.cmp(d, first) >= 0) {
      var any = false;
      var broken = true;
      for (final h in state.habits) {
        if (AppClock.cmp(h.created, d) > 0) continue;
        final o = state.outcomes[d]?[h.id];
        if (o == Outcome.doneFull || o == Outcome.donePartial) {
          any = true;
          broken = false;
        } else if (o == Outcome.frozen || o == Outcome.recovered || o == Outcome.pending) {
          broken = false;
        }
      }
      if (any) {
        n++;
      } else if (broken) {
        break;
      }
      d = AppClock.addDays(d, -1);
    }
    if ((state.checks[clock.today()] ?? {}).isNotEmpty) n++;
    return n;
  }

  // ── 체크인 (06 §3·§5) ─────────────────────────────────────────

  bool pendingFor(Habit h) =>
      state.outcomes[AppClock.addDays(clock.today(), -1)]?[h.id] == Outcome.pending;

  CheckEvent check(Habit h, Grade grade) {
    final t = clock.today();
    final day = state.checks.putIfAbsent(t, () => {});
    final cur = day[h.id];

    if (cur == Grade.full && grade == Grade.full) {
      day.remove(h.id); // 당일 언체크 — 앱에서만 (06 §3)
      return CheckEvent.unchecked;
    }
    if (cur == Grade.partial && grade == Grade.full) {
      day[h.id] = Grade.full; // 부분→완전 승격 (06 §5)
      return CheckEvent.upgraded;
    }
    day[h.id] = grade;
    if (pendingFor(h)) return CheckEvent.needsRecovery; // 회복 체크 카드 (06 §4.2)
    return CheckEvent.checked;
  }

  void acceptRecovery(String habitId) {
    final y = AppClock.addDays(clock.today(), -1);
    if (state.outcomes[y]?[habitId] == Outcome.pending) {
      state.outcomes[y]![habitId] = Outcome.recovered;
      state.recoveryUsedMonth = AppClock.monthKey(clock.today());
    }
  }

  void declineRecovery(String habitId) {
    final y = AppClock.addDays(clock.today(), -1);
    if (state.outcomes[y]?[habitId] == Outcome.pending) {
      state.outcomes[y]![habitId] = Outcome.missed;
    }
  }

  bool get recoveryLeftThisMonth =>
      state.recoveryUsedMonth != AppClock.monthKey(clock.today());

  // ── 통계 (11 문서 RC-01) ──────────────────────────────────────

  GrassLevel grassLevel(String day) {
    final out = state.outcomes[day] ?? {};
    final ck = state.checks[day] ?? {};
    var due = 0, done = 0, part = 0, froz = 0;
    for (final h in state.habits) {
      if (AppClock.cmp(h.created, day) > 0) continue;
      due++;
      final o = out[h.id];
      if (o == Outcome.doneFull || (o == null && ck[h.id] == Grade.full)) {
        done++;
      } else if (o == Outcome.donePartial ||
          o == Outcome.recovered ||
          (o == null && ck[h.id] == Grade.partial)) {
        part++;
      } else if (o == Outcome.frozen) {
        froz++;
      }
    }
    if (due == 0) return GrassLevel.empty;
    if (done == due) return GrassLevel.done2;
    if (done + part == due && done > 0) return GrassLevel.done1;
    if (done + part > 0) return GrassLevel.partial;
    if (froz > 0) return GrassLevel.frozen;
    return GrassLevel.empty;
  }

  /// 이번 주(월요일 시작) 달성률 0~100.
  int weeklyRate() {
    final t = clock.today();
    final start = AppClock.weekStart(t);
    var due = 0, done = 0;
    var d = start;
    while (AppClock.cmp(d, t) <= 0) {
      for (final h in state.habits) {
        if (AppClock.cmp(h.created, d) > 0) continue;
        due++;
        final o = state.outcomes[d]?[h.id];
        final c = state.checks[d]?[h.id];
        if (o == Outcome.doneFull || o == Outcome.donePartial || c != null) done++;
      }
      d = AppClock.addDays(d, 1);
    }
    return due == 0 ? 0 : (done * 100 / due).round();
  }

  int bestStreak() {
    var best = 0;
    for (final h in state.habits) {
      final s = streak(h);
      if (s > best) best = s;
    }
    return best;
  }

  int frozenCountThisMonth() {
    final m = AppClock.monthKey(clock.today());
    return state.freezeLog
        .where((e) => e.type == 'use' && AppClock.monthKey(e.date) == m)
        .length;
  }
}

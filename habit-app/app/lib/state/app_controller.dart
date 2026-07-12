import 'package:flutter/foundation.dart';

import '../core/strings.dart';
import '../data/store.dart';
import '../domain/clock.dart';
import '../domain/engine.dart';
import '../domain/models.dart';

/// 체크 액션의 UI 반영 결과.
class CheckOutcome {
  CheckOutcome(this.event, {this.streak = 0, this.milestone});

  final CheckEvent event;
  final int streak;

  /// 7/21/66 도달 시 그 값 (OV-01 오버레이 트리거).
  final int? milestone;
}

/// 앱 상태의 단일 소유자 — 도메인 엔진 + 영속화를 묶는 ChangeNotifier.
class AppController extends ChangeNotifier {
  AppController({Store? store, AppClock? clock})
      : _store = store ?? Store(),
        clock = clock ?? AppClock();

  final Store _store;
  final AppClock clock;

  late AppState state;
  late Engine engine;
  bool ready = false;

  Future<void> init() async {
    state = await _store.load();
    engine = Engine(state, clock);
    engine.judgeUpTo();
    ready = true;
    await _persist();
    notifyListeners();
  }

  /// 포그라운드 복귀·날짜 전환 시 호출 — 04:00 배치 수행.
  Future<void> refresh() async {
    if (!ready) return;
    engine.judgeUpTo();
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() => _store.save(state);

  // ── 체크인 ──────────────────────────────────────────────

  Future<CheckOutcome> tapCheck(Habit h) => _check(h, Grade.full);

  Future<CheckOutcome> tapPartial(Habit h) => _check(h, Grade.partial);

  Future<CheckOutcome> _check(Habit h, Grade g) async {
    final ev = engine.check(h, g);
    final st = engine.streak(h);
    int? milestone;
    if ((ev == CheckEvent.checked || ev == CheckEvent.upgraded) &&
        (st == 7 || st == 21 || st == 66)) {
      milestone = st;
    }
    await _persist();
    notifyListeners();
    return CheckOutcome(ev, streak: st, milestone: milestone);
  }

  Future<void> acceptRecovery(Habit h) async {
    engine.acceptRecovery(h.id);
    await _persist();
    notifyListeners();
  }

  Future<void> declineRecovery(Habit h) async {
    engine.declineRecovery(h.id);
    await _persist();
    notifyListeners();
  }

  // ── 습관 관리 ────────────────────────────────────────────

  String? addHabit(String name, String mini) {
    if (name.trim().isEmpty) return Str.nameNeeded;
    if (mini.trim().isEmpty) return Str.miniNeeded;
    if (state.habits.length >= freeSlots) return Str.slotsFull;
    state.habits.add(Habit(
      id: 'h${state.seq++}',
      name: name.trim(),
      mini: mini.trim(),
      created: clock.today(),
    ));
    _persist();
    notifyListeners();
    return null;
  }

  Future<void> removeHabit(Habit h) async {
    state.habits.removeWhere((x) => x.id == h.id);
    await _persist();
    notifyListeners();
  }

  Future<void> toggleFreeze(Habit h, bool on) async {
    h.freezeOn = on;
    await _persist();
    notifyListeners();
  }

  // ── 온보딩 (07 — 단방향 상태 머신, 전이마다 영속화) ─────────

  void obGo(String step) {
    state.ob.step = step;
    _persist();
    notifyListeners();
  }

  void obAnswer(String key, String value, String next) {
    switch (key) {
      case 'area':
        state.ob.area = value;
      case 'time':
        state.ob.time = value;
      case 'chrono':
        state.ob.chrono = value;
    }
    obGo(next);
  }

  RoutinePick get obRoutine => RoutinePick.pick(state.ob.area!, state.ob.chrono!);

  void obCreateHabit({required bool useMini}) {
    final r = obRoutine;
    state.habits.add(Habit(
      id: 'h${state.seq++}',
      name: useMini ? r.mini : r.habit,
      mini: r.mini,
      created: clock.today(),
    ));
    obGo('first');
  }

  /// 첫 체크 — 즉시 실행형이면 실제 체크(스트릭 1일 시작),
  /// 시간 고정형이면 스타터 미션(기록 없음, 07 §4).
  void obFirstCheck() {
    if (!obRoutine.starterFirst) {
      final h = state.habits.first;
      engine.check(h, Grade.full);
    }
    obGo('remind');
  }

  void obRemind(String? time) {
    state.ob.remind = time;
    obGo('landing');
  }

  void obDone() {
    state.obDone = true;
    state.lastJudged = AppClock.addDays(clock.today(), -1);
    _persist();
    notifyListeners();
  }

  // ── 설정 ────────────────────────────────────────────────

  Future<void> setTheme(String mode) async {
    state.theme = mode;
    await _persist();
    notifyListeners();
  }

  Future<void> resetAll() async {
    await _store.wipe();
    state = AppState();
    engine = Engine(state, clock);
    notifyListeners();
  }
}

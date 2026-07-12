import 'package:flutter/material.dart';

import '../core/strings.dart';
import '../core/tokens.dart';
import '../domain/models.dart';
import '../state/app_controller.dart';
import 'components.dart';
import 'habit_detail_screen.dart';

/// HM-01 홈(오늘) — 11 §3.1. Phase 0: 정원 히어로(달성 링)+습관 리스트.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final e = controller.engine;
    final today = controller.clock.today();
    final hour = controller.clock.hourNow();
    final checks = controller.state.checks[today] ?? {};
    final habits = controller.state.habits;
    final done = habits.where((h) => checks[h.id] != null).length;
    final undone = habits.where((h) => checks[h.id] == null).toList();
    final allDone = habits.isNotEmpty && undone.isEmpty;
    final isNight = hour >= 21;

    // 미완료 우선 정렬 (11 §3.1)
    final sorted = [...habits]
      ..sort((a, b) => (checks[a.id] != null ? 1 : 0) - (checks[b.id] != null ? 1 : 0));

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: controller.refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
                AppDims.screenPad, 10, AppDims.screenPad, 100),
            children: [
              // ── 헤더: 날짜 + 자원 칩 ──
              Row(children: [
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_dateLabel(today),
                            style: t.titleLarge?.copyWith(fontSize: 20)),
                        const SizedBox(height: 1),
                        Text('${_weekdayLabel(today)}${isNight ? ' 밤' : ''}',
                            style: t.labelSmall),
                      ]),
                ),
                StreakBadge(days: e.totalStreak()),
                const SizedBox(width: 7),
                FreezeChip(count: controller.state.freezeBal),
              ]),
              const SizedBox(height: 16),

              // ── 정원 히어로: 인사 + 오늘 달성 링 (P1에 루티 합류) ──
              AppCard(
                radius: 22,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [c.leaf050, c.card],
                ),
                padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
                child: Row(children: [
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_greeting(hour, allDone),
                              style: t.titleMedium?.copyWith(height: 1.35)),
                          const SizedBox(height: 5),
                          Text(
                            habits.isEmpty
                                ? '첫 습관을 심어볼까요?'
                                : allDone
                                    ? Str.tomorrowFirst(habits.first.name)
                                    : '오늘 ${habits.length}개 중 $done개 완료',
                            style: t.labelSmall,
                          ),
                        ]),
                  ),
                  const SizedBox(width: 12),
                  ProgressRing(
                    size: 68,
                    stroke: 6,
                    progress: habits.isEmpty ? 0 : done / habits.length,
                    child: habits.isEmpty
                        ? Icon(Icons.eco_rounded, size: 22, color: c.leaf)
                        : allDone
                            ? Icon(Icons.check_rounded, size: 26, color: c.leafDeep)
                            : Text('$done/${habits.length}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: c.leafDeep,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures()
                                  ],
                                )),
                  ),
                ]),
              ),

              // ── 위험 배너 — 보호 프레이밍, 상실 어휘 금지 (11 §7-7) ──
              if (isNight && undone.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: c.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border(
                      left: BorderSide(color: c.leaf, width: 3),
                      top: BorderSide(color: c.line),
                      right: BorderSide(color: c.line),
                      bottom: BorderSide(color: c.line),
                    ),
                  ),
                  child: Row(children: [
                    Icon(Icons.eco_rounded, size: 16, color: c.leaf),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(Str.riskBanner(e.streak(undone.first) + 1),
                          style: t.bodySmall?.copyWith(color: c.ink)),
                    ),
                  ]),
                ),
              ],

              SectionLabel(
                '오늘의 습관',
                trailing: habits.length < freeSlots
                    ? _AddChip(onTap: () => showAddHabitSheet(context, controller))
                    : null,
              ),

              // ── 습관 리스트 / 빈 상태 ──
              if (habits.isEmpty)
                _EmptyGarden(onAdd: () => showAddHabitSheet(context, controller))
              else ...[
                for (final h in sorted) ...[
                  _HabitCard(controller: controller, habit: h, grade: checks[h.id]),
                  const SizedBox(height: 10),
                ],
                if (habits.length >= freeSlots)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(Str.slotsFull,
                        style: t.labelSmall, textAlign: TextAlign.center),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _greeting(int hour, bool allDone) {
    if (allDone) return Str.allDone;
    if (hour >= 4 && hour < 11) return '좋은 아침이에요';
    if (hour >= 11 && hour < 17) return '오늘도 한 걸음씩';
    if (hour >= 17 && hour < 21) return '저녁 정원에 물 줄 시간';
    return '자기 전, 2분이면 충분해요';
  }

  String _dateLabel(String ds) {
    final p = ds.split('-');
    return '${int.parse(p[1])}월 ${int.parse(p[2])}일';
  }

  String _weekdayLabel(String ds) {
    const names = ['월', '화', '수', '목', '금', '토', '일'];
    final w = DateTime.parse('${ds}T12:00:00').weekday;
    return '${names[w - 1]}요일';
  }
}

class _AddChip extends StatelessWidget {
  const _AddChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration:
            BoxDecoration(color: c.leaf050, borderRadius: BorderRadius.circular(999)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.add_rounded, size: 14, color: c.leafDeep),
          const SizedBox(width: 2),
          Text('추가',
              style: TextStyle(
                  fontSize: 11.5, fontWeight: FontWeight.w700, color: c.leafDeep)),
        ]),
      ),
    );
  }
}

/// 빈 정원 — 다음 행동 CTA 정확히 1개 (14 §7 EmptyState).
class _EmptyGarden extends StatelessWidget {
  const _EmptyGarden({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: Column(children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(color: c.leaf050, shape: BoxShape.circle),
          child: Icon(Icons.eco_rounded, size: 32, color: c.leaf),
        ),
        const SizedBox(height: 14),
        Text('아직 심은 습관이 없어요', style: t.labelLarge),
        const SizedBox(height: 4),
        Text('2분짜리 하나면 충분해요', style: t.labelSmall),
        const SizedBox(height: 16),
        SizedBox(
          width: 180,
          child: FilledButton(onPressed: onAdd, child: const Text('습관 심기')),
        ),
      ]),
    );
  }
}

class _HabitCard extends StatelessWidget {
  const _HabitCard({required this.controller, required this.habit, required this.grade});

  final AppController controller;
  final Habit habit;
  final Grade? grade;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final e = controller.engine;
    final pending = e.pendingFor(habit);
    final sub = switch (grade) {
      Grade.full => Str.doneSub,
      Grade.partial => Str.partialSub,
      null => pending ? Str.pendingSub : Str.miniHint(habit.mini),
    };

    return AppCard(
      tinted: grade != null,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: InkWell(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (context) =>
                HabitDetailScreen(controller: controller, habitId: habit.id))),
        child: Row(children: [
          CheckButton(
            size: AppDims.checkCard,
            grade: grade,
            pendingRecovery: pending,
            semanticLabel:
                '${habit.name}, ${grade == null ? '미완료, 이중 탭으로 체크' : '완료'}',
            onTap: () => handleCheck(context, controller, habit, full: true),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(habit.name,
                  style: t.labelLarge?.copyWith(
                      color: grade == Grade.full ? c.leafDeep : c.ink)),
              const SizedBox(height: 2),
              Text(sub,
                  style: t.labelSmall?.copyWith(
                      color: pending && grade == null ? c.amber : c.sub)),
            ]),
          ),
          if (grade == null) ...[
            InkWell(
              onTap: () => handleCheck(context, controller, habit, full: false),
              borderRadius: BorderRadius.circular(999),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                decoration: BoxDecoration(
                    color: c.leaf050, borderRadius: BorderRadius.circular(999)),
                child: Text(Str.miniTag,
                    style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: c.leafDeep)),
              ),
            ),
            const SizedBox(width: 9),
          ],
          StreakBadge(days: e.streak(habit), compact: true),
        ]),
      ),
    );
  }
}

/// 체크 처리 공통 — 회복 카드·마일스톤 오버레이·토스트 연결.
Future<void> handleCheck(BuildContext context, AppController controller, Habit h,
    {required bool full}) async {
  final result = await (full ? controller.tapCheck(h) : controller.tapPartial(h));
  if (!context.mounted) return;

  switch (result.event) {
    case CheckEvent.unchecked:
      toast(context, Str.uncheckToast);
    case CheckEvent.upgraded:
      toast(context, Str.upgradeToast);
    case CheckEvent.needsRecovery:
      await _showRecoverySheet(context, controller, h);
    case CheckEvent.checked:
      toast(context, full ? Str.checkedToast(result.streak) : Str.partialToast);
  }

  if (result.milestone != null && context.mounted) {
    await _showMilestone(context, result.milestone!);
  }
}

/// 회복 체크 카드 (06 §4.2 — 죄책감 문구 금지).
Future<void> _showRecoverySheet(
    BuildContext context, AppController controller, Habit h) async {
  final c = context.colors;
  final t = Theme.of(context).textTheme;
  await showAppSheet(
    context,
    Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(color: c.amber100, shape: BoxShape.circle),
        child: Icon(Icons.auto_awesome_rounded, size: 26, color: c.amber),
      ),
      const SizedBox(height: 14),
      Text(Str.recoveryTitle, style: t.titleMedium, textAlign: TextAlign.center),
      const SizedBox(height: 8),
      Text(Str.recoveryBody(h.name), style: t.bodySmall, textAlign: TextAlign.center),
      const SizedBox(height: 18),
      FilledButton(
        onPressed: () {
          controller.acceptRecovery(h);
          Navigator.of(context).pop();
          toast(context, Str.recoveryAcceptToast);
        },
        child: const Text(Str.recoveryAccept),
      ),
      const SizedBox(height: 4),
      TextButton(
        onPressed: () {
          controller.declineRecovery(h);
          Navigator.of(context).pop();
          toast(context, Str.recoveryDeclineToast);
        },
        child: const Text(Str.recoveryDecline),
      ),
    ]),
  );
}

/// OV-01 마일스톤 오버레이 — P0 최소 연출, 스킵 상시 (11 §5).
Future<void> _showMilestone(BuildContext context, int days) async {
  final c = context.colors;
  final t = Theme.of(context).textTheme;
  await showDialog<void>(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: c.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ProgressRing(
            size: 104,
            stroke: 6,
            progress: 1,
            color: c.amber,
            track: c.amber100,
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(color: c.amber100, shape: BoxShape.circle),
              child: Icon(Icons.eco_rounded, size: 34, color: c.amber),
            ),
          ),
          const SizedBox(height: 18),
          Text(Str.milestoneTitle(days),
              style: t.titleMedium, textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(Str.milestoneBody(days),
              style: t.bodySmall, textAlign: TextAlign.center),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(Str.milestoneClose),
          ),
        ]),
      ),
    ),
  );
}

/// HM-03 습관 추가 시트 — 2분 버전 필수 (06 §5).
Future<void> showAddHabitSheet(BuildContext context, AppController controller) async {
  final t = Theme.of(context).textTheme;
  final nameCtl = TextEditingController();
  final miniCtl = TextEditingController();
  await showAppSheet(
    context,
    StatefulBuilder(
      builder: (context, setState) =>
          Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(Str.addTitle, style: t.titleMedium),
        const SizedBox(height: 16),
        Text(Str.nameLabel, style: t.labelSmall),
        const SizedBox(height: 6),
        TextField(
            controller: nameCtl,
            maxLength: 20,
            decoration: const InputDecoration(
                hintText: Str.nameHint, counterText: '', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        Text(Str.miniLabel, style: t.labelSmall),
        const SizedBox(height: 6),
        TextField(
            controller: miniCtl,
            maxLength: 20,
            decoration: const InputDecoration(
                hintText: Str.miniFieldHint,
                counterText: '',
                border: OutlineInputBorder())),
        const SizedBox(height: 18),
        FilledButton(
          onPressed: () {
            final err = controller.addHabit(nameCtl.text, miniCtl.text);
            if (err != null) {
              toast(context, err);
              return;
            }
            Navigator.of(context).pop();
            toast(context, Str.habitAdded(nameCtl.text.trim()));
          },
          child: const Text(Str.addCta),
        ),
      ]),
    ),
  );
}

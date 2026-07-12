import 'package:flutter/material.dart';

import '../core/strings.dart';
import '../core/tokens.dart';
import '../domain/models.dart';
import '../state/app_controller.dart';
import 'components.dart';
import 'habit_detail_screen.dart';

/// HM-01 홈(오늘) — 11 §3.1. Phase 0: 달성 링+스트릭 배지(루티는 P1).
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final e = controller.engine;
    final today = controller.clock.today();
    final checks = controller.state.checks[today] ?? {};
    final habits = controller.state.habits;
    final undone = habits.where((h) => checks[h.id] == null).toList();
    final allDone = habits.isNotEmpty && undone.isEmpty;
    final isNight = controller.clock.hourNow() >= 21;

    // 미완료 우선 정렬 (11 §3.1)
    final sorted = [...habits]
      ..sort((a, b) => (checks[a.id] != null ? 1 : 0) - (checks[b.id] != null ? 1 : 0));

    return Scaffold(
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_dateLabel(today)),
          Text('${_weekdayLabel(today)}${isNight ? ' 밤' : ''}', style: t.labelSmall),
        ]),
        actions: [
          StreakBadge(days: e.totalStreak()),
          const SizedBox(width: 8),
          FreezeChip(count: controller.state.freezeBal),
          const SizedBox(width: AppDims.screenPad),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: controller.refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              AppDims.screenPad, 6, AppDims.screenPad, 96),
          children: [
            // 위험 배너 — 보호 프레이밍, 상실 어휘 금지 (11 §7-7)
            if (isNight && undone.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
                decoration: BoxDecoration(
                  color: c.card,
                  borderRadius: BorderRadius.circular(13),
                  border: Border(
                    left: BorderSide(color: c.leaf, width: 3),
                    top: BorderSide(color: c.line),
                    right: BorderSide(color: c.line),
                    bottom: BorderSide(color: c.line),
                  ),
                ),
                child: Row(children: [
                  Icon(Icons.eco_rounded, size: 16, color: c.leaf),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(Str.riskBanner(e.streak(undone.first) + 1),
                        style: t.bodySmall?.copyWith(color: c.ink)),
                  ),
                ]),
              ),
              const SizedBox(height: 10),
            ],
            if (allDone) ...[
              AppCard(
                tinted: true,
                padding: const EdgeInsets.all(18),
                child: Column(children: [
                  Text(Str.allDone,
                      style: t.labelLarge?.copyWith(color: c.leafDeep)),
                  const SizedBox(height: 4),
                  Text(Str.tomorrowFirst(habits.first.name), style: t.labelSmall),
                ]),
              ),
              const SizedBox(height: 10),
            ],
            for (final h in sorted) ...[
              _HabitCard(controller: controller, habit: h, grade: checks[h.id]),
              const SizedBox(height: 10),
            ],
            if (habits.length < freeSlots)
              OutlinedButton(
                onPressed: () => showAddHabitSheet(context, controller),
                child: Text(Str.addHabit(habits.length, freeSlots)),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(Str.slotsFull,
                    style: t.labelSmall, textAlign: TextAlign.center),
              ),
          ],
        ),
      ),
    );
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
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(habit.name,
                  style: t.labelLarge?.copyWith(
                      color: grade == Grade.full ? c.leafDeep : c.ink)),
              const SizedBox(height: 2),
              Text(sub, style: t.labelSmall),
            ]),
          ),
          if (grade == null) ...[
            InkWell(
              onTap: () => handleCheck(context, controller, habit, full: false),
              borderRadius: BorderRadius.circular(999),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                    color: c.leaf050, borderRadius: BorderRadius.circular(999)),
                child: Text(Str.miniTag,
                    style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: c.leafDeep)),
              ),
            ),
            const SizedBox(width: 8),
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
  final result =
      await (full ? controller.tapCheck(h) : controller.tapPartial(h));
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
  final t = Theme.of(context).textTheme;
  await showAppSheet(
    context,
    Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(Str.recoveryTitle, style: t.titleMedium),
      const SizedBox(height: 8),
      Text(Str.recoveryBody(h.name), style: t.bodySmall),
      const SizedBox(height: 16),
      FilledButton(
        onPressed: () {
          controller.acceptRecovery(h);
          Navigator.of(context).pop();
          toast(context, Str.recoveryAcceptToast);
        },
        child: const Text(Str.recoveryAccept),
      ),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(color: c.amber100, shape: BoxShape.circle),
            child: Icon(Icons.eco_rounded, size: 40, color: c.amber),
          ),
          const SizedBox(height: 16),
          Text(Str.milestoneTitle(days),
              style: t.titleMedium, textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(Str.milestoneBody(days),
              style: t.bodySmall, textAlign: TextAlign.center),
          const SizedBox(height: 18),
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
        const SizedBox(height: 14),
        Text(Str.nameLabel, style: t.labelSmall),
        const SizedBox(height: 5),
        TextField(
            controller: nameCtl,
            maxLength: 20,
            decoration: const InputDecoration(
                hintText: Str.nameHint, counterText: '', border: OutlineInputBorder())),
        const SizedBox(height: 10),
        Text(Str.miniLabel, style: t.labelSmall),
        const SizedBox(height: 5),
        TextField(
            controller: miniCtl,
            maxLength: 20,
            decoration: const InputDecoration(
                hintText: Str.miniFieldHint,
                counterText: '',
                border: OutlineInputBorder())),
        const SizedBox(height: 16),
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

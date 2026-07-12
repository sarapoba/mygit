import 'package:flutter/material.dart';

import '../core/strings.dart';
import '../core/tokens.dart';
import '../domain/clock.dart';
import '../domain/engine.dart';
import '../domain/models.dart';
import '../state/app_controller.dart';
import 'components.dart';
import 'home_screen.dart';

/// HM-02 체크인 상세 — 11 §3.2. 마일스톤 진행·대형 체크·습관별 잔디·설정.
class HabitDetailScreen extends StatelessWidget {
  const HabitDetailScreen({super.key, required this.controller, required this.habitId});

  final AppController controller;
  final String habitId;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final habit =
            controller.state.habits.where((h) => h.id == habitId).firstOrNull;
        if (habit == null) {
          // 삭제 후 pop 되기 전 프레임 방어
          return const Scaffold(body: SizedBox.shrink());
        }
        return _DetailBody(controller: controller, habit: habit);
      },
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.controller, required this.habit});

  final AppController controller;
  final Habit habit;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final e = controller.engine;
    final today = controller.clock.today();
    final grade = controller.state.checks[today]?[habit.id];
    final streak = e.streak(habit);
    final next = streak < 7 ? 7 : (streak < 21 ? 21 : 66);
    final remain = next - streak;

    return Scaffold(
      appBar: AppBar(
        title: Text(habit.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => _showSettings(context),
            tooltip: '습관 설정',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppDims.screenPad, 4, AppDims.screenPad, 40),
        children: [
          // 마일스톤 진행 — 긍정 프레임 "N일까지 M일" (09 §1.1)
          AppCard(
            child: Row(children: [
              Icon(Icons.eco_rounded, size: 14, color: c.amber),
              const SizedBox(width: 8),
              Text.rich(TextSpan(style: t.bodySmall, children: [
                TextSpan(
                    text: '$next일',
                    style: TextStyle(fontWeight: FontWeight.w700, color: c.ink)),
                TextSpan(text: streak >= 66 ? ' — 뿌리내린 습관이에요' : '까지 $remain일'),
              ])),
              const Spacer(),
              StreakBadge(days: streak, compact: true),
            ]),
          ),
          const SizedBox(height: 20),
          Center(
            child: Column(children: [
              CheckButton(
                size: AppDims.checkDetail,
                grade: grade,
                pendingRecovery: e.pendingFor(habit),
                semanticLabel: '${habit.name} 체크',
                onTap: () => handleCheck(context, controller, habit, full: true),
              ),
              const SizedBox(height: 10),
              Text('탭 한 번으로 오늘을 기록해요', style: t.labelSmall),
            ]),
          ),
          const SizedBox(height: 14),
          if (grade == null)
            OutlinedButton(
              onPressed: () => handleCheck(context, controller, habit, full: false),
              child: Text('2분 버전으로 하기 — ${habit.mini}'),
            ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('최근 12주', style: t.labelSmall?.copyWith(letterSpacing: 0.5)),
              const SizedBox(height: 10),
              GrassCalendar(
                days: 84,
                columns: 14,
                endDate: today,
                levelOf: (d) => _habitLevel(d),
              ),
            ]),
          ),
          const SizedBox(height: 10),
          AppCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('기록', style: t.labelSmall?.copyWith(letterSpacing: 0.5)),
              const SizedBox(height: 6),
              ..._recentRows(context),
            ]),
          ),
        ],
      ),
    );
  }

  /// 습관 1개 기준 잔디 단계.
  GrassLevel _habitLevel(String d) {
    final o = controller.state.outcomes[d]?[habit.id];
    final ck = controller.state.checks[d]?[habit.id];
    if (o == Outcome.doneFull || (o == null && ck == Grade.full)) return GrassLevel.done2;
    if (o == Outcome.donePartial ||
        o == Outcome.recovered ||
        (o == null && ck == Grade.partial)) {
      return GrassLevel.done1;
    }
    if (o == Outcome.frozen) return GrassLevel.frozen;
    return GrassLevel.empty;
  }

  List<Widget> _recentRows(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final rows = <Widget>[];
    var d = AppClock.addDays(controller.clock.today(), -1);
    var shown = 0;
    while (shown < 7 && AppClock.cmp(d, habit.created) >= 0) {
      final o = controller.state.outcomes[d]?[habit.id];
      if (o != null) {
        // 프리즈일은 "지켜줬어요" — 결손이 아니라 방어로 서술 (11 §3.2)
        final (label, color) = switch (o) {
          Outcome.doneFull => ('완전 달성', c.leafDeep),
          Outcome.donePartial => ('부분 달성 (2분 버전)', c.leafDeep),
          Outcome.frozen => ('❄ 프리즈가 지켜줬어요', c.ice),
          Outcome.recovered => ('회복 체크로 이어졌어요', c.leafDeep),
          Outcome.pending => ('오늘 하면 이어져요', c.amber),
          Outcome.missed => ('쉬어 간 날', c.mut),
        };
        rows.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(children: [
            Text(_shortDate(d), style: t.labelSmall),
            const SizedBox(width: 10),
            Text(label, style: t.bodySmall?.copyWith(color: color)),
          ]),
        ));
        shown++;
      }
      d = AppClock.addDays(d, -1);
    }
    if (rows.isEmpty) {
      rows.add(Text('내일이면 첫 기록이 생겨요.',
          style: Theme.of(context).textTheme.bodySmall));
    }
    return rows;
  }

  String _shortDate(String ds) {
    final p = ds.split('-');
    return '${int.parse(p[1])}/${int.parse(p[2])}';
  }

  void _showSettings(BuildContext context) {
    final t = Theme.of(context).textTheme;
    showAppSheet(
      context,
      StatefulBuilder(
        builder: (context, setState) =>
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(habit.name, style: t.titleMedium),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('프리즈 장착', style: t.labelLarge),
            subtitle: Text('놓친 날 프리즈가 자동으로 지켜요', style: t.labelSmall),
            value: habit.freezeOn,
            onChanged: (v) {
              controller.toggleFreeze(habit, v);
              setState(() {});
            },
          ),
          const SizedBox(height: 6),
          TextButton(
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text(Str.deleteHabit),
                  content: const Text(Str.deleteConfirm),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('취소')),
                    TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('보내주기')),
                  ],
                ),
              );
              if (ok == true && context.mounted) {
                await controller.removeHabit(habit);
                if (context.mounted) {
                  Navigator.of(context).pop(); // 시트 닫기
                  Navigator.of(context).pop(); // 상세 닫기
                }
              }
            },
            child: const Text(Str.deleteHabit),
          ),
        ]),
      ),
    );
  }
}

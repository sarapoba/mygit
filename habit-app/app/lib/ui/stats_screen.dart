import 'package:flutter/material.dart';

import '../core/strings.dart';
import '../core/tokens.dart';
import '../state/app_controller.dart';
import 'components.dart';

/// RC-01 기록 홈 — 11 §3.3. 잔디·스탯 타일·프리즈 이력.
/// 하락 지표에도 빨강 금지 (14 §7 StatTile 규칙).
class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final e = controller.engine;
    final today = controller.clock.today();

    return Scaffold(
      appBar: AppBar(title: const Text(Str.statsTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppDims.screenPad, 0, AppDims.screenPad, 100),
        children: [
          const SectionLabel('지난 12주'),
          AppCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              GrassCalendar(
                days: 84,
                columns: 14,
                endDate: today,
                levelOf: e.grassLevel,
              ),
              const SizedBox(height: 10),
              Row(children: [
                Icon(Icons.info_outline_rounded, size: 12, color: c.mut),
                const SizedBox(width: 5),
                Expanded(child: Text(Str.grassNote, style: t.labelSmall)),
              ]),
            ]),
          ),
          const SectionLabel('이번 주'),
          Row(children: [
            Expanded(
                child: _StatTile(
                    icon: Icons.trending_up_rounded,
                    iconColor: c.leaf,
                    value: '${e.weeklyRate()}%',
                    label: Str.tileWeekly)),
            const SizedBox(width: 10),
            Expanded(
                child: _StatTile(
                    icon: Icons.eco_rounded,
                    iconColor: c.leafDeep,
                    value: '${e.bestStreak()}일',
                    label: Str.tileBest)),
            const SizedBox(width: 10),
            Expanded(
                child: _StatTile(
                    icon: Icons.ac_unit_rounded,
                    iconColor: c.ice,
                    value: '${e.frozenCountThisMonth()}회',
                    label: Str.tileFrozen)),
          ]),
          const SectionLabel(Str.freezeLogTitle),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: controller.state.freezeLog.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(Str.freezeLogEmpty, style: t.bodySmall),
                  )
                : Column(
                    children: controller.state.freezeLog.take(8).map((l) {
                      final (icon, color) = switch (l.type) {
                        'use' => (Icons.shield_rounded, c.ice),
                        'grant' => (Icons.add_circle_rounded, c.leaf),
                        _ => (Icons.remove_circle_outline_rounded, c.mut),
                      };
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(children: [
                          Icon(icon, size: 15, color: color),
                          const SizedBox(width: 9),
                          SizedBox(
                              width: 40,
                              child: Text(_shortDate(l.date), style: t.labelSmall)),
                          Expanded(
                              child: Text(l.message,
                                  style: t.bodySmall?.copyWith(color: c.ink))),
                        ]),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  String _shortDate(String ds) {
    final p = ds.split('-');
    return '${int.parse(p[1])}/${int.parse(p[2])}';
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return AppCard(
      padding: const EdgeInsets.fromLTRB(13, 13, 13, 11),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(height: 8),
        Text(value,
            style: t.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                fontFeatures: const [FontFeature.tabularFigures()])),
        const SizedBox(height: 2),
        Text(label, style: t.labelSmall),
      ]),
    );
  }
}

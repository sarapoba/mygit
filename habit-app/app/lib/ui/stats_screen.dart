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
    final t = Theme.of(context).textTheme;
    final e = controller.engine;
    final today = controller.clock.today();

    return Scaffold(
      appBar: AppBar(title: const Text(Str.statsTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppDims.screenPad, 4, AppDims.screenPad, 96),
        children: [
          AppCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              GrassCalendar(
                days: 84,
                columns: 14,
                endDate: today,
                levelOf: e.grassLevel,
              ),
              const SizedBox(height: 9),
              Text(Str.grassNote, style: t.labelSmall),
            ]),
          ),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _tile(context, '${e.weeklyRate()}%', Str.tileWeekly)),
            const SizedBox(width: 9),
            Expanded(child: _tile(context, '${e.bestStreak()}일', Str.tileBest)),
            const SizedBox(width: 9),
            Expanded(
                child: _tile(context, '${e.frozenCountThisMonth()}회', Str.tileFrozen)),
          ]),
          const SizedBox(height: 18),
          Text(Str.freezeLogTitle,
              style: t.labelSmall?.copyWith(
                  fontWeight: FontWeight.w800, letterSpacing: 0.5)),
          const SizedBox(height: 8),
          AppCard(
            child: controller.state.freezeLog.isEmpty
                ? Text(Str.freezeLogEmpty, style: t.bodySmall)
                : Column(
                    children: controller.state.freezeLog.take(8).map((l) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(children: [
                          Text(_shortDate(l.date), style: t.labelSmall),
                          const SizedBox(width: 12),
                          Expanded(child: Text(l.message, style: t.bodySmall)),
                        ]),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, String value, String label) {
    final t = Theme.of(context).textTheme;
    return AppCard(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value,
            style: t.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                fontFeatures: const [FontFeature.tabularFigures()])),
        const SizedBox(height: 3),
        Text(label, style: t.labelSmall),
      ]),
    );
  }

  String _shortDate(String ds) {
    final p = ds.split('-');
    return '${int.parse(p[1])}/${int.parse(p[2])}';
  }
}

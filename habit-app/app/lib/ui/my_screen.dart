import 'package:flutter/material.dart';

import '../core/strings.dart';
import '../core/tokens.dart';
import '../domain/models.dart';
import '../state/app_controller.dart';
import 'components.dart';

/// MY-01 마이 — 15 §7.1. 용서 장치 현황·알림(모의)·테마·데이터.
class MyScreen extends StatelessWidget {
  const MyScreen({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final c = context.colors;
    final s = controller.state;
    final recLeft = controller.engine.recoveryLeftThisMonth;

    return Scaffold(
      appBar: AppBar(title: const Text(Str.myTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppDims.screenPad, 4, AppDims.screenPad, 96),
        children: [
          _section(context, Str.forgiveness),
          AppCard(
            child: Column(children: [
              _row(
                context,
                icon: Icons.ac_unit_rounded,
                iconColor: c.ice,
                label: Str.freezeRow,
                value: Str.freezeStatus(s.freezeBal, freezeCap),
              ),
              Divider(height: 18, color: c.line),
              _row(
                context,
                icon: Icons.eco_rounded,
                iconColor: c.leaf,
                label: Str.recoveryRow,
                value: recLeft ? Str.recoveryLeft : Str.recoveryUsed,
              ),
            ]),
          ),
          _section(context, Str.notifSection),
          AppCard(
            child: _row(
              context,
              icon: Icons.notifications_none_rounded,
              iconColor: c.sub,
              label: Str.reminderRow,
              value: s.ob.remind ?? Str.reminderNone,
            ),
          ),
          _section(context, Str.themeSection),
          AppCard(
            padding: const EdgeInsets.all(6),
            child: Row(
              children: [
                _themeButton(context, 'light', Str.themeLight),
                _themeButton(context, 'system', Str.themeSystem),
                _themeButton(context, 'dark', Str.themeDark),
              ],
            ),
          ),
          _section(context, Str.dataSection),
          AppCard(
            padding: EdgeInsets.zero,
            child: TextButton(
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    content: const Text(Str.resetConfirm),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('취소')),
                      TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('초기화')),
                    ],
                  ),
                );
                if (ok == true) await controller.resetAll();
              },
              child: const Text(Str.resetRow),
            ),
          ),
          const SizedBox(height: 24),
          Text(Str.versionLabel, style: t.labelSmall, textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _section(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 16, 2, 8),
      child: Text(title,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w800, letterSpacing: 0.5)),
    );
  }

  Widget _row(BuildContext context,
      {required IconData icon,
      required Color iconColor,
      required String label,
      required String value}) {
    final t = Theme.of(context).textTheme;
    return Row(children: [
      Icon(icon, size: 18, color: iconColor),
      const SizedBox(width: 10),
      Expanded(child: Text(label, style: t.bodyMedium)),
      Text(value, style: t.labelSmall),
    ]);
  }

  Widget _themeButton(BuildContext context, String mode, String label) {
    final c = context.colors;
    final on = controller.state.theme == mode;
    return Expanded(
      child: InkWell(
        onTap: () => controller.setTheme(mode),
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: on ? c.leaf050 : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: on ? c.leafDeep : c.sub,
            ),
          ),
        ),
      ),
    );
  }
}

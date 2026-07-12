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
            AppDims.screenPad, 0, AppDims.screenPad, 100),
        children: [
          const SectionLabel(Str.forgiveness),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Column(children: [
              _row(
                context,
                icon: Icons.ac_unit_rounded,
                iconBg: c.ice100,
                iconColor: c.ice,
                label: Str.freezeRow,
                value: Str.freezeStatus(s.freezeBal, freezeCap),
              ),
              Divider(color: c.line),
              _row(
                context,
                icon: Icons.auto_awesome_rounded,
                iconBg: c.amber100,
                iconColor: c.amber,
                label: Str.recoveryRow,
                value: recLeft ? Str.recoveryLeft : Str.recoveryUsed,
              ),
            ]),
          ),
          const SectionLabel(Str.notifSection),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: _row(
              context,
              icon: Icons.notifications_none_rounded,
              iconBg: c.leaf050,
              iconColor: c.leafDeep,
              label: Str.reminderRow,
              value: s.ob.remind ?? Str.reminderNone,
            ),
          ),
          const SectionLabel(Str.themeSection),
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
          const SectionLabel(Str.dataSection),
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
          const SizedBox(height: 28),
          Icon(Icons.eco_rounded, size: 18, color: c.mut),
          const SizedBox(height: 6),
          Text(Str.versionLabel, style: t.labelSmall, textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _row(BuildContext context,
      {required IconData icon,
      required Color iconBg,
      required Color iconColor,
      required String label,
      required String value}) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(children: [
        Container(
          width: 34,
          height: 34,
          decoration:
              BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 17, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: t.bodyMedium)),
        Text(value, style: t.labelSmall),
      ]),
    );
  }

  Widget _themeButton(BuildContext context, String mode, String label) {
    final c = context.colors;
    final on = controller.state.theme == mode;
    return Expanded(
      child: InkWell(
        onTap: () => controller.setTheme(mode),
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
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

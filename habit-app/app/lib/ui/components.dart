import 'package:flutter/material.dart';

import '../core/tokens.dart';
import '../domain/clock.dart';
import '../domain/engine.dart';
import '../domain/models.dart';

/// 체크 버튼 — 11 §5 규격: 미완료/완료/부분/회복대기 4상태 (P0).
class CheckButton extends StatelessWidget {
  const CheckButton({
    super.key,
    required this.size,
    required this.grade,
    this.pendingRecovery = false,
    this.onTap,
    this.semanticLabel,
  });

  final double size;
  final Grade? grade;
  final bool pendingRecovery;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final done = grade == Grade.full;
    final partial = grade == Grade.partial;

    return Semantics(
      button: true,
      label: semanticLabel,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: partial ? null : (done ? c.leaf : Colors.transparent),
            gradient: partial
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    stops: const [0.5, 0.5],
                    colors: [c.leaf, Colors.transparent],
                  )
                : null,
            border: Border.all(
              color: done || partial
                  ? c.leaf
                  : pendingRecovery
                      ? c.amber
                      : c.line,
              width: size >= AppDims.checkDetail ? 3 : 2.5,
            ),
          ),
          child: done || partial
              ? Icon(Icons.check_rounded,
                  size: size * 0.46, color: done ? Colors.white : c.leafDeep)
              : null,
        ),
      ),
    );
  }
}

/// 스트릭 배지 — 잎사귀 + tabular 숫자. 끊김 시 "다시 시작" (11 §7-4).
class StreakBadge extends StatelessWidget {
  const StreakBadge({super.key, required this.days, this.compact = false});

  final int days;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: 5),
      decoration: BoxDecoration(color: c.leaf050, borderRadius: BorderRadius.circular(999)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.eco_rounded, size: compact ? 12 : 14, color: c.leafDeep),
        const SizedBox(width: 3),
        Text(
          days > 0 ? '$days' : '다시 시작',
          style: TextStyle(
            fontSize: compact ? 11 : 12,
            fontWeight: FontWeight.w700,
            color: c.leafDeep,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ]),
    );
  }
}

/// 프리즈 칩 (14 §7).
class FreezeChip extends StatelessWidget {
  const FreezeChip({super.key, required this.count, this.onTap});

  final int count;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: c.ice100, borderRadius: BorderRadius.circular(999)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.ac_unit_rounded, size: 13, color: c.ice),
          const SizedBox(width: 3),
          Text('$count',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: c.ice,
                fontFeatures: const [FontFeature.tabularFigures()],
              )),
        ]),
      ),
    );
  }
}

/// 카드 컨테이너 (14 §4).
class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.tinted = false, this.padding});

  final Widget child;
  final bool tinted;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tinted ? c.leaf050 : c.card,
        borderRadius: BorderRadius.circular(AppDims.cardRadius),
        border: tinted ? null : Border.all(color: c.line),
      ),
      child: child,
    );
  }
}

/// 잔디 캘린더 — 셀 5상태, 색+아이콘 병기 (11 §5, 05 §5.3).
class GrassCalendar extends StatelessWidget {
  const GrassCalendar({
    super.key,
    required this.days,
    required this.levelOf,
    required this.endDate,
    this.columns = 12,
  });

  final int days;
  final GrassLevel Function(String date) levelOf;
  final String endDate;
  final int columns;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final start = AppClock.addDays(endDate, -(days - 1));
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns, mainAxisSpacing: 4, crossAxisSpacing: 4),
      itemCount: days,
      itemBuilder: (context, i) {
        final d = AppClock.addDays(start, i);
        final lv = levelOf(d);
        final isToday = d == endDate;
        final color = switch (lv) {
          GrassLevel.empty => c.grass0,
          GrassLevel.partial => c.grass1,
          GrassLevel.done1 => c.grass2,
          GrassLevel.done2 => c.grass3,
          GrassLevel.frozen => c.grass1,
        };
        return Semantics(
          label: '$d, ${_labelOf(lv)}',
          child: Container(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
              border: isToday ? Border.all(color: c.leaf, width: 2) : null,
            ),
            child: lv == GrassLevel.frozen
                ? Icon(Icons.ac_unit_rounded, size: 8, color: c.ice)
                : null,
          ),
        );
      },
    );
  }

  String _labelOf(GrassLevel lv) => switch (lv) {
        GrassLevel.empty => '기록 없음',
        GrassLevel.partial => '부분 달성',
        GrassLevel.done1 => '달성',
        GrassLevel.done2 => '모두 달성',
        GrassLevel.frozen => '프리즈로 보호됨',
      };
}

/// 바텀시트 헬퍼 — 14 §4 규격.
Future<T?> showAppSheet<T>(BuildContext context, Widget child) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 14,
        bottom: 22 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
              color: context.colors.line, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(height: 14),
        child,
      ]),
    ),
  );
}

void toast(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(SnackBar(content: Text(message), duration: const Duration(seconds: 2)));
}

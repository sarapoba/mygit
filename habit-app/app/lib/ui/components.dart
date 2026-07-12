import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/tokens.dart';
import '../domain/clock.dart';
import '../domain/engine.dart';
import '../domain/models.dart';

/// 체크 버튼 — 11 §5 규격 + 탭 스프링·상태 전환 애니메이션 (14 §6).
class CheckButton extends StatefulWidget {
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
  State<CheckButton> createState() => _CheckButtonState();
}

class _CheckButtonState extends State<CheckButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final done = widget.grade == Grade.full;
    final partial = widget.grade == Grade.partial;
    final ring = done || partial
        ? c.leaf
        : widget.pendingRecovery
            ? c.amber
            : c.line;

    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.88 : 1,
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutBack,
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: partial ? null : (done ? c.leaf : c.card),
              gradient: partial
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      stops: const [0.5, 0.5],
                      colors: [c.leaf, c.card],
                    )
                  : null,
              border: Border.all(
                  color: ring, width: widget.size >= AppDims.checkDetail ? 3 : 2.4),
              boxShadow: done
                  ? [
                      BoxShadow(
                        color: c.leaf.withOpacity(0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      )
                    ]
                  : null,
            ),
            child: done || partial
                ? Icon(Icons.check_rounded,
                    size: widget.size * 0.46,
                    color: done ? Colors.white : c.leafDeep)
                : null,
          ),
        ),
      ),
    );
  }
}

/// 진행 링 — 홈 히어로·상세 마일스톤용 (14 §7 StatTile 계열).
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.size,
    required this.progress,
    required this.child,
    this.stroke = 5,
    this.color,
    this.track,
  });

  final double size;
  final double progress; // 0.0 ~ 1.0
  final double stroke;
  final Color? color;
  final Color? track;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) => CustomPaint(
        painter: _RingPainter(
          progress: value,
          stroke: stroke,
          color: color ?? c.leaf,
          track: track ?? c.grass0,
        ),
        child: SizedBox(
          width: size,
          height: size,
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.stroke,
    required this.color,
    required this.track,
  });

  final double progress;
  final double stroke;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final inset = rect.deflate(stroke / 2);
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = track;
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(inset, 0, math.pi * 2, false, trackPaint);
    if (progress > 0) {
      canvas.drawArc(inset, -math.pi / 2, math.pi * 2 * progress, false, arcPaint);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
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
      decoration:
          BoxDecoration(color: c.leaf050, borderRadius: BorderRadius.circular(999)),
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
        decoration:
            BoxDecoration(color: c.ice100, borderRadius: BorderRadius.circular(999)),
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

/// 카드 — 라이트: 소프트 섀도, 다크: 헤어라인 (14 §4).
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.tinted = false,
    this.padding,
    this.radius = AppDims.cardRadius,
    this.gradient,
  });

  final Widget child;
  final bool tinted;
  final EdgeInsets? padding;
  final double radius;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: gradient != null ? null : (tinted ? c.leaf050 : c.card),
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        border: dark ? Border.all(color: c.line) : null,
        boxShadow: dark || tinted
            ? null
            : [
                BoxShadow(
                  color: c.ink.withOpacity(0.05),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: child,
    );
  }
}

/// 섹션 라벨 — 화면 리듬 통일 (15 §0).
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 22, 4, 10),
      child: Row(children: [
        Text(text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: c.sub,
            )),
        if (trailing != null) ...[const Spacer(), trailing!],
      ]),
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
          crossAxisCount: columns, mainAxisSpacing: 4.5, crossAxisSpacing: 4.5),
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
              borderRadius: BorderRadius.circular(4.5),
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
        bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
              color: context.colors.line, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(height: 16),
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

import 'dart:async';

import 'package:flutter/material.dart';

import '../core/strings.dart';
import '../core/tokens.dart';
import '../state/app_controller.dart';

/// 온보딩 — 07 문서 Phase 0 변형. 단방향 상태 머신(뒤로가기는 진단 구간만),
/// 전이마다 컨트롤러가 영속화하므로 앱 킬 후 재실행 시 이어하기가 보장된다.
class OnboardingFlow extends StatelessWidget {
  const OnboardingFlow({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final step = controller.state.ob.step;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
          child: switch (step) {
            'welcome' => _Welcome(controller: controller),
            'q1' || 'q2' || 'q3' => _Question(controller: controller, step: step),
            'analyze' => _Analyze(controller: controller),
            'recommend' => _Recommend(controller: controller),
            'shrink' => _Shrink(controller: controller),
            'first' => _FirstCheck(controller: controller),
            'remind' => _Remind(controller: controller),
            'landing' => _Landing(controller: controller),
            _ => _Welcome(controller: controller),
          },
        ),
      ),
    );
  }
}

class _SproutMark extends StatelessWidget {
  const _SproutMark();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(color: c.leaf050, shape: BoxShape.circle),
      child: Icon(Icons.eco_rounded, size: 44, color: c.leaf),
    );
  }
}

class _Welcome extends StatelessWidget {
  const _Welcome({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(children: [
      Expanded(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const _SproutMark(),
          const SizedBox(height: 20),
          Text(Str.obWelcomeTitle, style: t.titleLarge, textAlign: TextAlign.center),
          const SizedBox(height: 10),
          Text(Str.obWelcomeSub, style: t.bodySmall, textAlign: TextAlign.center),
        ]),
      ),
      FilledButton(onPressed: () => controller.obGo('q1'), child: const Text(Str.obStart)),
    ]);
  }
}

class _Question extends StatelessWidget {
  const _Question({required this.controller, required this.step});

  final AppController controller;
  final String step;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final c = context.colors;
    final (index, title, sub, options, key, next, back) = switch (step) {
      'q1' => (0, Str.obQ1, null, Diagnosis.areas, 'area', 'q2', 'welcome'),
      'q2' => (1, Str.obQ2, Str.obQ2Sub, Diagnosis.times, 'time', 'q3', 'q1'),
      _ => (2, Str.obQ3, null, Diagnosis.chronos, 'chrono', 'analyze', 'q2'),
    };

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (i) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.symmetric(horizontal: 2.5),
            width: i == index ? 18 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: i == index ? c.leaf : c.grass0,
              borderRadius: BorderRadius.circular(3),
            ),
          );
        }),
      ),
      const SizedBox(height: 22),
      Text(title, style: t.titleLarge),
      if (sub != null) ...[const SizedBox(height: 6), Text(sub, style: t.bodySmall)],
      const SizedBox(height: 18),
      ...options.map((o) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              onTap: () => controller.obAnswer(key, o.$2, next),
              borderRadius: BorderRadius.circular(AppDims.cardRadius),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
                decoration: BoxDecoration(
                  color: c.card,
                  borderRadius: BorderRadius.circular(AppDims.cardRadius),
                  border: Border.all(color: c.line),
                ),
                child: Row(children: [
                  Text(o.$1, style: const TextStyle(fontSize: 21)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(o.$2, style: t.labelLarge),
                      Text(o.$3, style: t.labelSmall),
                    ]),
                  ),
                ]),
              ),
            ),
          )),
      const Spacer(),
      TextButton(onPressed: () => controller.obGo(back), child: const Text('← 뒤로')),
    ]);
  }
}

class _Analyze extends StatefulWidget {
  const _Analyze({required this.controller});

  final AppController controller;

  @override
  State<_Analyze> createState() => _AnalyzeState();
}

class _AnalyzeState extends State<_Analyze> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // 추천은 로컬 매핑 표 계산 — 네트워크 대기 없음, 최대 1.2초 연출 후 강제 전진 (07 §7-6).
    _timer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted && widget.controller.state.ob.step == 'analyze') {
        widget.controller.obGo('recommend');
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const _SproutMark(),
        const SizedBox(height: 20),
        Text(Str.obAnalyzing, style: Theme.of(context).textTheme.titleLarge),
      ]),
    );
  }
}

class _Recommend extends StatelessWidget {
  const _Recommend({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final c = context.colors;
    final ob = controller.state.ob;
    final r = controller.obRoutine;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('${ob.chrono} × ${ob.area}',
          style: t.labelSmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 1)),
      const SizedBox(height: 8),
      Text(Str.obRecommendTitle, style: t.titleLarge),
      const SizedBox(height: 16),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(AppDims.cardRadius),
          border: Border.all(color: c.line),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('「${r.routine}」', style: t.titleMedium),
          const SizedBox(height: 6),
          Text.rich(TextSpan(style: t.bodySmall, children: [
            const TextSpan(text: '대표 습관: '),
            TextSpan(
                text: r.habit,
                style: TextStyle(fontWeight: FontWeight.w700, color: c.ink)),
            const TextSpan(text: '\n이미 수만 명이 검증한 순서예요.'),
          ])),
        ]),
      ),
      const SizedBox(height: 12),
      Text(Str.obRecommendNote, style: t.labelSmall),
      const Spacer(),
      FilledButton(
          onPressed: () => controller.obGo('shrink'), child: const Text(Str.obRecommendCta)),
    ]);
  }
}

class _Shrink extends StatelessWidget {
  const _Shrink({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final c = context.colors;
    final r = controller.obRoutine;
    final confirmMode = controller.state.ob.time == '2분';

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 12),
      Text(confirmMode ? Str.obShrinkTitleConfirm : Str.obShrinkTitle, style: t.titleLarge),
      const SizedBox(height: 10),
      Text.rich(TextSpan(style: t.bodySmall, children: [
        TextSpan(text: '「${r.habit}」 대신 '),
        TextSpan(
            text: '「${r.mini}」', style: TextStyle(fontWeight: FontWeight.w700, color: c.ink)),
        TextSpan(text: confirmMode ? '부터 시작해요.' : '로 시작할까요? 늘리는 건 언제든 할 수 있어요.'),
      ])),
      const Spacer(),
      FilledButton(
        onPressed: () => controller.obCreateHabit(useMini: true),
        child: Text(confirmMode ? Str.obShrinkCtaConfirm : Str.obShrinkCta),
      ),
      if (!confirmMode)
        TextButton(
          onPressed: () => controller.obCreateHabit(useMini: false),
          child: const Text(Str.obShrinkKeep),
        ),
    ]);
  }
}

class _FirstCheck extends StatelessWidget {
  const _FirstCheck({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final r = controller.obRoutine;
    final starter = r.starterFirst;
    final area = controller.state.ob.area!;

    return Column(children: [
      Expanded(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const _SproutMark(),
          const SizedBox(height: 20),
          Text(starter ? Str.obFirstStarter : Str.obFirstNow,
              style: t.titleLarge, textAlign: TextAlign.center),
          const SizedBox(height: 10),
          Text(
            starter
                ? '「${RoutinePick.starters[area]}」 어때요?\n스트릭과는 무관한 몸풀기 미션이에요.'
                : '「${controller.state.habits.first.mini}」 — 딱 2분이면 돼요.\n지금 체크하면 오늘부터 스트릭 1일!',
            style: t.bodySmall,
            textAlign: TextAlign.center,
          ),
        ]),
      ),
      FilledButton(onPressed: controller.obFirstCheck, child: const Text(Str.obFirstCta)),
      TextButton(
          onPressed: () => controller.obGo('remind'), child: const Text(Str.cancel)),
    ]);
  }
}

class _Remind extends StatelessWidget {
  const _Remind({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final c = context.colors;
    final def = Diagnosis.remindDefaults[controller.state.ob.chrono] ?? '12:30';

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 12),
      Text(Str.obRemindTitle, style: t.titleLarge),
      const SizedBox(height: 6),
      Text(Str.obRemindSub, style: t.bodySmall),
      const SizedBox(height: 18),
      Wrap(
        spacing: 8,
        children: ['07:00', '12:30', '20:30'].map((tm) {
          final highlighted = tm == def;
          return OutlinedButton(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 44),
              side: BorderSide(color: highlighted ? c.leaf : c.line, width: highlighted ? 2 : 1.5),
            ),
            onPressed: () => controller.obRemind(tm),
            child: Text(tm),
          );
        }).toList(),
      ),
      const Spacer(),
      TextButton(
          onPressed: () => controller.obRemind(null), child: const Text(Str.obRemindNone)),
    ]);
  }
}

class _Landing extends StatelessWidget {
  const _Landing({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final remind = controller.state.ob.remind;

    return Column(children: [
      Expanded(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const _SproutMark(),
          const SizedBox(height: 20),
          Text(Str.obLandingTitle, style: t.titleLarge, textAlign: TextAlign.center),
          const SizedBox(height: 10),
          Text(remind != null ? '내일 $remind에 만나요.' : '내일 또 만나요.',
              style: t.bodySmall, textAlign: TextAlign.center),
        ]),
      ),
      FilledButton(onPressed: controller.obDone, child: const Text(Str.obEnter)),
    ]);
  }
}

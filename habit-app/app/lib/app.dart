import 'package:flutter/material.dart';

import 'core/theme.dart';
import 'state/app_controller.dart';
import 'ui/home_screen.dart';
import 'ui/my_screen.dart';
import 'ui/onboarding_flow.dart';
import 'ui/stats_screen.dart';

class RootApp extends StatefulWidget {
  const RootApp({super.key, required this.controller});

  final AppController controller;

  @override
  State<RootApp> createState() => _RootAppState();
}

class _RootAppState extends State<RootApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 포그라운드 복귀 시 04:00 배치 — 자정을 넘긴 채 떠 있던 앱의 날짜 전환 처리.
    if (state == AppLifecycleState.resumed) {
      widget.controller.refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final c = widget.controller;
        final themeMode = switch (c.ready ? c.state.theme : 'system') {
          'light' => ThemeMode.light,
          'dark' => ThemeMode.dark,
          _ => ThemeMode.system,
        };
        return MaterialApp(
          title: '루트',
          debugShowCheckedModeBanner: false,
          theme: buildTheme(Brightness.light),
          darkTheme: buildTheme(Brightness.dark),
          themeMode: themeMode,
          home: !c.ready
              ? const Scaffold(body: SizedBox.shrink())
              : c.state.obDone
                  ? RootShell(controller: c)
                  : OnboardingFlow(controller: c),
        );
      },
    );
  }
}

/// Phase 0 탭 셸 — 홈 · 기록 · 마이 (11 §1.1).
class RootShell extends StatefulWidget {
  const RootShell({super.key, required this.controller});

  final AppController controller;

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: [
        HomeScreen(controller: widget.controller),
        StatsScreen(controller: widget.controller),
        MyScreen(controller: widget.controller),
      ]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.spa_outlined), activeIcon: Icon(Icons.spa), label: '홈'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart_rounded), label: '기록'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), activeIcon: Icon(Icons.person_rounded), label: '마이'),
        ],
      ),
    );
  }
}

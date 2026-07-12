import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models.dart';

/// 로컬 우선 영속화 (05 §5.1) — Phase 0 은 기기 로컬만.
/// JSON 스냅숏 저장. 데이터가 커지면 12 문서 스키마의 SQLite 로 이관한다
/// (도메인은 이 클래스 뒤에 숨겨져 있어 교체 비용이 UI 에 미치지 않음).
class Store {
  static const _key = 'root-app-state-v1';

  Future<AppState> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return AppState();
      return AppState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      // 손상된 저장분은 버리되 앱은 뜬다 — 달성 기록 유실보다 크래시가 더 나쁘다는
      // 원칙(05 §5.1)의 예외 지점이므로, SQLite 이관 시 백업 슬롯 2개로 보강할 것.
      return AppState();
    }
  }

  Future<void> save(AppState state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(state.toJson()));
  }

  Future<void> wipe() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

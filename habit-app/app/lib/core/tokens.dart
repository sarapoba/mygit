import 'package:flutter/material.dart';

/// 디자인 토큰 — 기획 14 문서의 값을 그대로 코드화. 임의 변경 금지.
class AppColors {
  AppColors({
    required this.bg,
    required this.card,
    required this.line,
    required this.ink,
    required this.sub,
    required this.mut,
    required this.leaf,
    required this.leafDeep,
    required this.leaf050,
    required this.leaf100,
    required this.ice,
    required this.ice100,
    required this.amber,
    required this.amber100,
    required this.plum,
    required this.grass0,
    required this.grass1,
    required this.grass2,
    required this.grass3,
  });

  final Color bg, card, line, ink, sub, mut;
  final Color leaf, leafDeep, leaf050, leaf100;
  final Color ice, ice100, amber, amber100, plum;
  final Color grass0, grass1, grass2, grass3;

  /// 시스템 에러·결제 실패 전용 — 습관·스트릭 문맥 사용 금지 (14 §2.4).
  static const Color systemRed = Color(0xFFD64545);

  /// 라이트 — "주간의 정원".
  static final light = AppColors(
    bg: const Color(0xFFF7F9F6),
    card: const Color(0xFFFFFFFF),
    line: const Color(0xFFE4EAE4),
    ink: const Color(0xFF1B2A21),
    sub: const Color(0xFF51625A),
    mut: const Color(0xFF8B9A92),
    leaf: const Color(0xFF3D9A5C),
    leafDeep: const Color(0xFF2E7D4A),
    leaf050: const Color(0xFFF1F7F2),
    leaf100: const Color(0xFFDEEEE1),
    ice: const Color(0xFF4E9CD0),
    ice100: const Color(0xFFE3F2FB),
    amber: const Color(0xFFDE9B3B),
    amber100: const Color(0xFFFBF0DC),
    plum: const Color(0xFF8B6FC7),
    grass0: const Color(0xFFEDF0EC),
    grass1: const Color(0xFFC7E5CC),
    grass2: const Color(0xFF7CC98F),
    grass3: const Color(0xFF3D9A5C),
  );

  /// 다크 — "밤의 정원" (반전이 아닌 전용 팔레트, 14 §2.3).
  static final dark = AppColors(
    bg: const Color(0xFF0F1722),
    card: const Color(0xFF18232F),
    line: const Color(0xFF243140),
    ink: const Color(0xFFE8F0EA),
    sub: const Color(0xFF9FB0A6),
    mut: const Color(0xFF5F7069),
    leaf: const Color(0xFF4FB874),
    leafDeep: const Color(0xFF3D9A5C),
    leaf050: const Color(0xFF16241C),
    leaf100: const Color(0xFF1E3527),
    ice: const Color(0xFF6FB6E4),
    ice100: const Color(0xFF16283B),
    amber: const Color(0xFFE4AC58),
    amber100: const Color(0xFF2E2617),
    plum: const Color(0xFFA48BE0),
    grass0: const Color(0xFF1C2833),
    grass1: const Color(0xFF28513A),
    grass2: const Color(0xFF35784E),
    grass3: const Color(0xFF4FB874),
  );
}

/// 형태·간격 토큰 (14 §4).
class AppDims {
  static const double screenPad = 20;
  static const double cardRadius = 16;
  static const double sheetRadius = 22;
  static const double buttonRadius = 15;
  static const double buttonHeight = 52;
  static const double checkCard = 52; // 홈 카드 체크 버튼
  static const double checkDetail = 92; // 상세 화면 체크 버튼
  static const double minTouch = 44;
}

/// AppColors 를 위젯 트리에서 얻기 위한 확장.
extension AppColorsX on BuildContext {
  AppColors get colors =>
      Theme.of(this).brightness == Brightness.dark ? AppColors.dark : AppColors.light;
}

import 'package:flutter/material.dart';

import 'tokens.dart';

/// Pretendard 를 assets/fonts 에 넣고 pubspec 의 fonts 섹션을 활성화하면
/// 자동 적용된다(README 참조). 없으면 플랫폼 기본 서체로 폴백.
const String _fontFamily = 'Pretendard';

ThemeData buildTheme(Brightness brightness) {
  final c = brightness == Brightness.dark ? AppColors.dark : AppColors.light;

  final scheme = ColorScheme(
    brightness: brightness,
    primary: c.leaf,
    onPrimary: Colors.white,
    secondary: c.ice,
    onSecondary: Colors.white,
    error: AppColors.systemRed,
    onError: Colors.white,
    surface: c.card,
    onSurface: c.ink,
    outline: c.line,
  );

  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: c.bg,
    fontFamily: _fontFamily,
    fontFamilyFallback: const ['Apple SD Gothic Neo', 'Noto Sans KR', 'sans-serif'],
    splashFactory: InkSparkle.splashFactory,
  );

  return base.copyWith(
    textTheme: base.textTheme.copyWith(
      // 14 문서 §3 타입 스케일
      displaySmall: TextStyle(fontSize: 30, height: 38 / 30, fontWeight: FontWeight.w700, color: c.ink),
      titleLarge: TextStyle(fontSize: 22, height: 30 / 22, fontWeight: FontWeight.w700, color: c.ink),
      titleMedium: TextStyle(fontSize: 18, height: 26 / 18, fontWeight: FontWeight.w600, color: c.ink),
      bodyMedium: TextStyle(fontSize: 15, height: 23 / 15, fontWeight: FontWeight.w400, color: c.ink),
      labelLarge: TextStyle(fontSize: 15, height: 23 / 15, fontWeight: FontWeight.w600, color: c.ink),
      bodySmall: TextStyle(fontSize: 13, height: 19 / 13, fontWeight: FontWeight.w400, color: c.sub),
      labelSmall: TextStyle(fontSize: 11, height: 15 / 11, fontWeight: FontWeight.w500, color: c.sub, letterSpacing: 0.2),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: c.bg,
      foregroundColor: c.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
          fontSize: 18, fontWeight: FontWeight.w700, color: c.ink, fontFamily: _fontFamily),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: c.leaf,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(AppDims.buttonHeight),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDims.buttonRadius)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, fontFamily: _fontFamily),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: c.ink,
        side: BorderSide(color: c.line, width: 1.5),
        minimumSize: const Size.fromHeight(AppDims.buttonHeight),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDims.buttonRadius)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, fontFamily: _fontFamily),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: c.sub),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: c.card,
      selectedItemColor: c.leafDeep,
      unselectedItemColor: c.mut,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
      unselectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppDims.sheetRadius))),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: c.ink,
      contentTextStyle: TextStyle(
          fontSize: 13, fontWeight: FontWeight.w600, color: c.bg, fontFamily: _fontFamily),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    ),
    dividerTheme: DividerThemeData(color: c.line, thickness: 1, space: 1),
  );
}

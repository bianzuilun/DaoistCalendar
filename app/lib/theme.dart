import 'package:flutter/material.dart';

/// 道历视觉：宣纸底、松烟墨、朱砂印。
ThemeData daoTheme() {
  final base = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: T.paper,
    colorScheme: ColorScheme.fromSeed(
      seedColor: T.accent,
      primary: T.accent,
      onPrimary: Colors.white,
      surface: T.card,
      surfaceTint: Colors.transparent,
    ),
    splashColor: T.accent.withValues(alpha: 0.08),
    highlightColor: T.accent.withValues(alpha: 0.04),
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(bodyColor: T.ink, displayColor: T.ink),
    appBarTheme: const AppBarTheme(
      backgroundColor: T.paper,
      foregroundColor: T.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: T.ink,
      ),
    ),
    dividerTheme: const DividerThemeData(color: T.line, thickness: 0.6),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) => Colors.white),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return T.accent;
        return const Color(0xFFE4DCCE);
      }),
      trackOutlineColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return Colors.transparent;
        return const Color(0xFFD5CBBA);
      }),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: T.ink,
      contentTextStyle: const TextStyle(color: Color(0xFFF6F1E8)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}

class T {
  static const paper = Color(0xFFF3EEE4);
  static const paperDeep = Color(0xFFE9E0D0);
  static const card = Color(0xFFFFFCF8);
  static const ink = Color(0xFF2A2622);
  static const inkSoft = Color(0xFF5C564C);
  static const accent = Color(0xFF9C3B32);
  static const line = Color(0xFFE3D8C6);
  static const muted = Color(0xFF8A8376);
  static const jieqi = Color(0xFF3E6B5A);
  static const jieqiBg = Color(0xFFE4F0EA);

  static const cardShadow = <BoxShadow>[
    BoxShadow(
      color: Color(0x1460493A),
      blurRadius: 20,
      offset: Offset(0, 8),
    ),
  ];

  static const display = TextStyle(
    fontSize: 34,
    height: 1.12,
    fontWeight: FontWeight.w700,
    color: ink,
    letterSpacing: 0.6,
  );

  static const title = TextStyle(
    fontSize: 26,
    height: 1.2,
    fontWeight: FontWeight.w700,
    color: ink,
    letterSpacing: 0.4,
  );

  static const heading = TextStyle(
    fontSize: 16,
    height: 1.3,
    fontWeight: FontWeight.w600,
    color: ink,
  );

  static const kicker = TextStyle(
    fontSize: 12,
    height: 1.2,
    fontWeight: FontWeight.w600,
    color: accent,
    letterSpacing: 1.4,
  );

  static const body = TextStyle(
    fontSize: 14,
    height: 1.65,
    color: inkSoft,
  );

  static const bodyMuted = TextStyle(
    fontSize: 13,
    height: 1.45,
    color: muted,
  );

  static const caption = TextStyle(
    fontSize: 12,
    height: 1.4,
    color: muted,
  );

  static const section = TextStyle(
    fontSize: 12,
    height: 1.2,
    fontWeight: FontWeight.w600,
    color: muted,
    letterSpacing: 1.1,
  );
}

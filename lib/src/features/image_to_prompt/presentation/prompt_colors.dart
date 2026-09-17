import 'package:flutter/material.dart';

class PromptColors {
  final bool dark;
  const PromptColors(this.dark);

  Color get page => dark ? const Color(0xFF141019) : const Color(0xFFF8F7F3);
  Color get card => dark ? const Color(0xFF1F1B2B) : Colors.white;
  Color get ink => dark ? const Color(0xFFF4F1FB) : const Color(0xFF16121F);
  Color get muted => dark ? const Color(0xFFA39DB5) : const Color(0xFF6B6577);
  Color get line => dark ? const Color(0xFF2E2A3D) : const Color(0xFFE7E1F2);
  Color get field => dark ? const Color(0xFF272234) : const Color(0xFFEBE7F7);
  Color get iconBox => dark ? const Color(0xFF2E2940) : const Color(0xFFF2EEFB);
  Color get accentSoft => dark ? const Color(0xFF2C2540) : const Color(0xFFEFE9FB);
  Color get accentText => dark ? const Color(0xFFB69BF5) : const Color(0xFF6D28D9);
  Color get trackOff => dark ? const Color(0xFF3A3450) : const Color(0xFFD9D3E8);

  static const primary = Color(0xFF7C3AED);
  static const idle = Color(0xFF8A82A0);
  static const danger = Color(0xFFD14343);

  static const accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF8B3DFF), Color(0xFF5B16E0)],
  );

  static BoxShadow get cardShadow => BoxShadow(
        color: const Color(0xFF3C1E78).withValues(alpha: 0.15),
        blurRadius: 26,
        offset: const Offset(0, 10),
      );
}

import 'package:flutter/material.dart';

abstract final class AppColors {
  // Background / Surface
  static const background = Color(0xFF0e1416);
  static const surfaceDim = Color(0xFF0e1416);
  static const surfaceContainerLowest = Color(0xFF090f11);
  static const surfaceContainerLow = Color(0xFF161d1e);
  static const surfaceContainer = Color(0xFF1a2122);
  static const surfaceContainerHigh = Color(0xFF242b2d);
  static const surfaceContainerHighest = Color(0xFF2f3638);
  static const surfaceBright = Color(0xFF343a3c);
  static const surfaceVariant = Color(0xFF2f3638);
  static const surfaceTint = Color(0xFF2fd9f4);

  // Primary (Cyan)
  static const primary = Color(0xFF8aebff);
  static const onPrimary = Color(0xFF00363e);
  static const primaryContainer = Color(0xFF22d3ee);
  static const onPrimaryContainer = Color(0xFF005763);
  static const inversePrimary = Color(0xFF006877);
  static const primaryFixed = Color(0xFFa2eeff);
  static const primaryFixedDim = Color(0xFF2fd9f4);
  static const onPrimaryFixed = Color(0xFF001f25);
  static const onPrimaryFixedVariant = Color(0xFF004e5a);

  // Secondary (Amber)
  static const secondary = Color(0xFFffb95f);
  static const onSecondary = Color(0xFF472a00);
  static const secondaryContainer = Color(0xFFee9800);
  static const onSecondaryContainer = Color(0xFF5b3800);
  static const secondaryFixed = Color(0xFFffddb8);
  static const secondaryFixedDim = Color(0xFFffb95f);
  static const onSecondaryFixed = Color(0xFF2a1700);
  static const onSecondaryFixedVariant = Color(0xFF653e00);

  // Tertiary
  static const tertiary = Color(0xFFcfdef6);
  static const onTertiary = Color(0xFF233144);
  static const tertiaryContainer = Color(0xFFb3c2d9);
  static const onTertiaryContainer = Color(0xFF425063);
  static const tertiaryFixed = Color(0xFFd5e3fc);
  static const tertiaryFixedDim = Color(0xFFb9c7df);
  static const onTertiaryFixed = Color(0xFF0d1c2e);
  static const onTertiaryFixedVariant = Color(0xFF3a485b);

  // On-surface
  static const onSurface = Color(0xFFdde4e5);
  static const onSurfaceVariant = Color(0xFFbbc9cd);
  static const inverseSurface = Color(0xFFdde4e5);
  static const inverseOnSurface = Color(0xFF2b3233);
  static const onBackground = Color(0xFFdde4e5);

  // Outline
  static const outline = Color(0xFF859397);
  static const outlineVariant = Color(0xFF3c494c);

  // Error
  static const error = Color(0xFFffb4ab);
  static const onError = Color(0xFF690005);
  static const errorContainer = Color(0xFF93000a);
  static const onErrorContainer = Color(0xFFffdad6);

  // Semantic shorthands
  static const shieldColor = primary;       // Cyan for shields
  static const hullColor = secondary;       // Amber for hull
  static const activeGlow = primaryContainer; // #22d3ee glow border
  static const scanlineBorder = Color(0xFF475569);
  static const hudBackdrop = Color(0xFF090f11); // ~0a0e1a Level 0
  static const cyanTint = Color(0x0D8aebff); // 5% cyan tint
}

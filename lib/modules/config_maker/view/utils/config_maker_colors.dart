import 'package:flutter/material.dart';

class ConfigMakerColors {
  final bool isLight;

  const ConfigMakerColors(this.isLight);

  factory ConfigMakerColors.of(BuildContext context) {
    return ConfigMakerColors(Theme.of(context).brightness == Brightness.light);
  }

  // ── Core Containers & Surfaces ──
  Color get mainBg => isLight ? const Color(0xFFF1F5F9) : const Color(0xFF0C0F1D);
  Color get canvasBg => isLight ? const Color(0xFFF8FAFC) : const Color(0xFF12162B);
  Color get cardBg => isLight ? Colors.white : const Color(0xFF13172E);
  Color get cardBorder => isLight ? const Color(0xFFE2E8F0) : const Color(0xFF20274B);
  Color get innerSurface => isLight ? const Color(0xFFF8FAFC) : const Color(0xFF181C38);
  Color get innerBorder => isLight ? const Color(0xFFE2E8F0) : const Color(0xFF232A4D);
  Color get workAreaCardBg => isLight ? const Color(0xFFFAFAFA) : const Color(0xFF0C0F1D);

  // ── Header & App Bar ──
  Color get headerBg => isLight ? Colors.white : const Color(0xFF0C0F1D);
  Color get headerButtonBg => isLight ? Colors.white : const Color(0xFF181C38);
  Color get headerButtonBorder => isLight ? const Color(0xFFCBD5E1) : const Color(0xFF2B335C);
  Color get headerIconColor => isLight ? const Color(0xFF0F172A) : Colors.white;

  // ── Text & Typography ──
  Color get textPrimary => isLight ? const Color(0xFF0F172A) : Colors.white;
  Color get textSecondary => isLight ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
  Color get textMuted => isLight ? const Color(0xFF64748B) : const Color(0xFF8E9BB4);
  Color get deviceIdText => isLight ? const Color(0xFF7E22CE) : const Color(0xFFC084FC);

  // ── Navigation & Tabs ──
  Color get sideTabBorder => isLight ? const Color(0xFFCBD5E1) : const Color(0xFF334155);
  Color get sideTabUnselectedText => isLight ? const Color(0xFFE2E8F0) : Colors.white;
  Color get sideTabSelectedBg => Colors.white;
  Color get sideTabSelectedText => isLight ? const Color(0xFF0F172A) : Colors.black;

  // ── Bottom Sheet / Site Tab Bar ──
  Color get bottomTabBarBg => isLight ? const Color(0xFFE2E8F0) : const Color(0xFF0F172A);
  Color get bottomTabActiveBg => isLight ? Colors.white : const Color(0xFF1E293B);
  Color get bottomTabInactiveBg => isLight ? const Color(0xFFCBD5E1) : const Color(0xFF334155);
  Color get bottomTabActiveText => isLight ? const Color(0xFF0F172A) : Colors.white;
  Color get bottomTabInactiveText => isLight ? const Color(0xFF475569) : Colors.white70;

  // ── Side Sheet ──
  Color get sideSheetBg => isLight ? Colors.white : const Color(0xFF0F172A);
  Color get sideSheetHeaderBg => isLight ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B);
  Color get sideSheetBorder => isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155);

  // ── Canvas Grid & Controls ──
  Color get gridLineColor => isLight ? const Color(0xFFCBD5E1) : const Color(0xFF20274B);
  Color get controlsBg => isLight ? Colors.white : const Color(0xFF181C38);
  Color get controlsBorder => isLight ? const Color(0xFFE2E8F0) : const Color(0xFF2B335C);
  Color get controlsDivider => isLight ? const Color(0xFFE2E8F0) : const Color(0xFF2B335C);
  Color get controlsIconColor => isLight ? const Color(0xFF0F172A) : Colors.white;

  // ── Canvas Toolbar ──
  Color get toolbarBg => isLight ? Colors.white : const Color(0xFF0C0F1D);
  Color get toolbarBorder => isLight ? const Color(0xFFE2E8F0) : const Color(0xFF1E2648);
  Color get toolbarButtonBg => isLight ? const Color(0xFFF8FAFC) : const Color(0xFF181C38);
  Color get toolbarButtonBorder => isLight ? const Color(0xFFCBD5E1) : const Color(0xFF2B335C);
  Color get toolbarButtonText => isLight ? const Color(0xFF0F172A) : Colors.white;
  Color get toolbarButtonIcon => isLight ? const Color(0xFF0284C7) : const Color(0xFF38BDF8);

  // ── Accents & Special Sections ──
  Color get accentGreen => const Color(0xFF10B981);
  Color get detachedBg => isLight ? const Color(0xFFFFFBEB) : const Color(0xFF13172E);
  Color get detachedBorder => isLight ? const Color(0xFFFDE68A) : const Color(0xFF3B2A12);
  Color get detachedBadgeBg => isLight ? const Color(0xFFFEF3C7) : const Color(0xFF3B2A12);
  Color get detachedText => isLight ? const Color(0xFFD97706) : const Color(0xFFF59E0B);

  // ── Cards & Pins ──
  Color get circleBg => isLight ? const Color(0xFFF1F5F9) : const Color(0xFF0A2035);
  Color get unassignedBadgeBg => isLight ? const Color(0xFFF1F5F9) : const Color(0xFF12162B);
  Color get unassignedBadgeBorder => isLight ? const Color(0xFFE2E8F0) : const Color(0xFF2A3258);
  Color get unassignedBadgeText => isLight ? const Color(0xFF64748B) : const Color(0xFF8E9BB4);

  // ── Connector Pin Tile Specific ──
  Color get pinSelectedBg => isLight ? const Color(0xFFF3E8FF) : const Color(0xFF2E1752);
  Color get pinSelectedBorder => const Color(0xFF7C3AED);
  Color get pinAssignedBg => isLight ? Colors.white : const Color(0xFF181C38);
  Color get pinAssignedBorder => isLight ? const Color(0xFFE2E8F0) : const Color(0xFF2A3258);
  Color get pinUnassignedBg => isLight ? const Color(0xFFF8FAFC) : const Color(0xFF151931);
  Color get pinUnassignedBorder => isLight ? const Color(0xFFE2E8F0) : const Color(0xFF202747);
  Color get pinAssignedText => isLight ? const Color(0xFF0F172A) : Colors.white;
  Color get pinUnassignedText => isLight ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

  // ── Stepper / Counter Field ──
  Color get stepperBg => isLight ? const Color(0xFFF8FAFC) : const Color(0xFF12162B);
  Color get stepperBorder => isLight ? const Color(0xFFCBD5E1) : const Color(0xFF2A3258);
  Color get stepperMinusActive => isLight ? const Color(0xFF475569) : const Color(0xFF8E9BB4);
  Color get stepperMinusDisabled => isLight ? const Color(0xFFCBD5E1) : const Color(0xFF2A3258);
  Color get stepperValueText => isLight ? const Color(0xFF7E22CE) : const Color(0xFFC084FC);
  Color get stepperValueEditingText => isLight ? const Color(0xFF0F172A) : Colors.white;
}

typedef ConnectionColors = ConfigMakerColors;

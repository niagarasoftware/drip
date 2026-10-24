import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Premium Purple Palette
const Color primaryDark = Color(0xFF642ABD);
const Color primary = Color(0xFF642ABD); // Primary Purple
const Color primaryLight = Color(0xFF06B6D4); // Secondary Cyan
const Color accentColor = Color(0xFF10B981); // Accent Emerald
const Color primaryBackground = Color(0xFFF8FAFC); // Light Background
const Color darkBackground = Color(0xFF0C0F1D); // Deep Navy Dark Background
const Color primaryTextColor = Color(0xFF1E293B); // Text Light
const Color secondaryTextColor = Color(0xFF8E9BB4);
const Color darkTextColor = Color(0xFFFFFFFF); // Text Dark
const Color lightCard = Color(0xFFFFFFFF); // Light Card
const Color darkCard = Color(0xFF13172E); // Dark Slate Card

class OroTheme {
  static ThemeData lightTheme = ThemeData.light().copyWith(
    primaryColorDark: primaryDark,
    primaryColor: primary,
    primaryColorLight: primaryLight,
    scaffoldBackgroundColor: primaryBackground,
    appBarTheme: AppBarTheme(
      backgroundColor: primary,
      titleTextStyle: const TextStyle(color: Colors.white, fontSize: 22),
      iconTheme: const IconThemeData(
        color: Colors.white,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(0),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: primary,
      elevation: 1,
      labelType: NavigationRailLabelType.all,
      indicatorColor: primaryLight,
      unselectedIconTheme: const IconThemeData(color: Colors.white54),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryLight;
          }
          return primaryLight.withOpacity(0.1);
        }),
        foregroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return primaryTextColor;
        }),
        iconColor: WidgetStateProperty.resolveWith<Color?>(
          (states) => states.contains(WidgetState.selected) ? Colors.white : primaryTextColor,
        ),
        side: WidgetStateProperty.resolveWith<BorderSide>(
          (states) => BorderSide(
            color: primaryLight,
            width: 1,
          ),
        ),
        shape: WidgetStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
          ),
        ),
        textStyle: WidgetStateProperty.all(const TextStyle(
          fontSize: 13,
        )),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: lightCard,
    ),
    textTheme: TextTheme(
      titleLarge: GoogleFonts.roboto(fontSize: 22, color: primaryTextColor),
      titleMedium: GoogleFonts.roboto(fontSize: 14, color: primaryTextColor),
      titleSmall: GoogleFonts.roboto(fontSize: 12, color: primaryTextColor),

      headlineLarge: GoogleFonts.roboto(fontSize: 15, color: primaryTextColor, fontWeight: FontWeight.bold),
      headlineSmall: GoogleFonts.roboto(fontSize: 13, color: primaryTextColor, fontWeight: FontWeight.bold),
      labelLarge: GoogleFonts.roboto(fontSize: 15, color: primaryTextColor, fontWeight: FontWeight.bold),
      labelSmall: GoogleFonts.roboto(fontSize: 13, color: secondaryTextColor),

      bodyLarge: GoogleFonts.roboto(fontSize: 15, color: primaryTextColor),
      bodyMedium: GoogleFonts.roboto(fontSize: 13, color: primaryTextColor, fontWeight: FontWeight.bold),
      bodySmall: GoogleFonts.roboto(fontSize: 12, color: primaryTextColor, fontWeight: FontWeight.bold),
    ),
    cardTheme: CardThemeData(
      color: lightCard,
      shadowColor: Colors.black.withOpacity(0.1),
      surfaceTintColor: primaryLight,
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5.0),
      ),
    ),
    cardColor: lightCard,
    colorScheme: ColorScheme.fromSeed(
      primary: primary,
      secondary: primaryLight,
      tertiary: accentColor,
      surface: lightCard,
      background: primaryBackground,
      error: Colors.red,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: primaryTextColor,
      onBackground: primary.withOpacity(0.1),
      onError: Colors.white,
      seedColor: primary,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: OutlinedButton.styleFrom(
        backgroundColor: primaryLight,
        foregroundColor: Colors.white,
        iconColor: Colors.white,
        side: BorderSide.none,
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData.dark().copyWith(
    primaryColorDark: primaryDark,
    primaryColor: primary,
    primaryColorLight: primaryLight,
    scaffoldBackgroundColor: darkBackground,
    appBarTheme: AppBarTheme(
      backgroundColor: darkCard,
      titleTextStyle: TextStyle(color: darkTextColor, fontSize: 22),
      iconTheme: IconThemeData(
        color: darkTextColor,
      ),
    ),
    tabBarTheme: TabBarThemeData(
      indicatorColor: accentColor,
      labelColor: darkTextColor,
      unselectedLabelColor: Colors.white54,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.transparent,
        foregroundColor: primaryLight,
        side: BorderSide(color: primaryLight),
      ),
    ),
    dialogBackgroundColor: darkCard,
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(0),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: darkCard,
      elevation: 0,
      labelType: NavigationRailLabelType.all,
      indicatorColor: primary,
      unselectedIconTheme: const IconThemeData(color: Colors.white54),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) {
            return primary;
          }
          return darkCard;
        }),
        foregroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return darkTextColor;
        }),
        iconColor: WidgetStateProperty.resolveWith<Color?>(
          (states) => states.contains(WidgetState.selected) ? Colors.white : darkTextColor,
        ),
        side: WidgetStateProperty.resolveWith<BorderSide>(
          (states) => BorderSide(
            color: states.contains(WidgetState.selected) ? primaryLight : Colors.grey,
            width: 0.5,
          ),
        ),
        shape: WidgetStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
          ),
        ),
      ),
    ),
    textTheme: TextTheme(
      titleLarge: GoogleFonts.roboto(fontSize: 22, color: darkTextColor),
      titleMedium: GoogleFonts.roboto(fontSize: 14, color: darkTextColor),
      titleSmall: GoogleFonts.roboto(fontSize: 12, color: darkTextColor),

      headlineLarge: GoogleFonts.roboto(fontSize: 15, color: darkTextColor, fontWeight: FontWeight.bold),
      headlineSmall: GoogleFonts.roboto(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.bold),
      labelLarge: GoogleFonts.roboto(fontSize: 15, color: darkTextColor, fontWeight: FontWeight.bold),
      labelSmall: GoogleFonts.roboto(fontSize: 13, color: Colors.grey),

      bodyLarge: GoogleFonts.roboto(fontSize: 15, color: darkTextColor),
      bodyMedium: GoogleFonts.roboto(fontSize: 13, color: darkTextColor, fontWeight: FontWeight.bold),
      bodySmall: GoogleFonts.roboto(fontSize: 12, color: darkTextColor, fontWeight: FontWeight.bold),
    ),
    cardTheme: CardThemeData(
      color: darkCard,
      shadowColor: Colors.black,
      surfaceTintColor: primary,
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5.0),
      ),
    ),
    cardColor: darkCard,
    colorScheme: ColorScheme.fromSeed(
      brightness: Brightness.dark,
      primary: primary,
      secondary: primaryLight,
      tertiary: accentColor,
      surface: darkCard,
      background: darkBackground,
      error: Colors.red,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: darkTextColor,
      onBackground: darkTextColor,
      onError: Colors.white,
      seedColor: primary,
    ),
  );
}

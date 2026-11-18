import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';


Color primaryDark = const Color(0xFF004265);
Color primary = const Color(0xFF004265);
Color primaryLight = const Color(0xFF008CD7);
Color primaryBackground = const Color(0xFFEFEFEF);
Color primaryTextColor = const Color(0xFF3C3C3C);
Color secondaryTextColor = const Color(0xFF7E7E7E);


class SmartCommTheme {
  static ThemeData lightTheme = ThemeData.light().copyWith(
    primaryColorDark: primaryDark,
    primaryColor: primary,
    primaryColorLight: primaryLight,
    scaffoldBackgroundColor:  primaryBackground,
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
        foregroundColor: Colors.black,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8), // Add border radius
        ),
      ),
    ),
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(0)
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
        },
        ),
        foregroundColor: WidgetStateProperty.resolveWith<Color?>(
              (states) {
            if (states.contains(WidgetState.selected)) {
              return Colors.white;
            }
            return Colors.black;
          },
        ),
        iconColor: WidgetStateProperty.resolveWith<Color?>(
              (states) => states.contains(WidgetState.selected) ? Colors.white : Colors.black,
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
    popupMenuTheme: const PopupMenuThemeData(
        color: Colors.white,
    ),
    textTheme: TextTheme(
      titleLarge: GoogleFonts.roboto(fontSize: 22, color: Colors.black),
      titleMedium: GoogleFonts.roboto(fontSize: 14, color: Colors.black),
      titleSmall: GoogleFonts.roboto(fontSize: 12, color: Colors.black),

      headlineLarge: GoogleFonts.roboto(fontSize: 15, color: const Color(0xFF1E1E1E), fontWeight: FontWeight.bold), // siva
      headlineSmall: GoogleFonts.roboto(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.bold), // siva
      labelLarge: GoogleFonts.roboto(fontSize: 15, color: const Color(0xFF1E1E1E), fontWeight: FontWeight.bold), // siva
      labelSmall: GoogleFonts.roboto(fontSize: 13, color: const Color(0xFF3C3C3C)), // siva


      bodyLarge: GoogleFonts.roboto(fontSize: 15, color: Colors.black87),
      bodyMedium: GoogleFonts.roboto(fontSize: 13, color: Colors.black, fontWeight: FontWeight.bold),
      bodySmall: GoogleFonts.roboto(fontSize: 12, color: Colors.black, fontWeight: FontWeight.bold),
    ),
    cardTheme: CardThemeData(
      color: Colors.grey[100],
      shadowColor: Colors.black,
      surfaceTintColor: Colors.teal[200],
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5.0),
      ),
    ),
    cardColor: Colors.white,
    colorScheme: ColorScheme.fromSeed(
      primary: primary, // siva
      secondary: primaryLight, // siva
      surface: Colors.white,
      background: primaryBackground, // siva
      error: Colors.red,
      // onPrimary: primary, // siva
      onSecondary: Colors.white, // siva
      onSurface: Colors.black,
      onBackground: primary.withOpacity(0.1), // siva
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
    primaryColorDark: primary,
    primaryColor: primary,
    primaryColorLight: primaryLight,
    scaffoldBackgroundColor:  primaryBackground,
    appBarTheme: AppBarTheme(
      backgroundColor: primary,
      titleTextStyle: const TextStyle(color: Colors.white, fontSize: 22),
      iconTheme: const IconThemeData(
        color: Colors.white,
      ),
    ),
    tabBarTheme: const TabBarThemeData(
      indicatorColor: Colors.white70,
      labelColor: Colors.white70,
      unselectedLabelColor: Colors.white54,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.black,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    /*inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.blue)),
      labelStyle: const TextStyle(color: Colors.blue),
    ),*/
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.transparent,
        foregroundColor: primary,
        side: const BorderSide(color: Colors.white),
      ),
    ),
    dialogBackgroundColor: Colors.white,
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(0)
      ),
    ),
    navigationRailTheme: const NavigationRailThemeData(
      backgroundColor: Color(0xFF036673),
      elevation: 0,
      labelType: NavigationRailLabelType.all,
      indicatorColor: Color(0x6438D3E8),
      unselectedIconTheme: IconThemeData(color: Colors.white54),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) {
            return lightTheme.primaryColor.withAlpha(1);
          }
          return Colors.grey[300];
        },
        ),
        foregroundColor: WidgetStateProperty.resolveWith<Color?>(
              (states) {
            if (states.contains(WidgetState.selected)) {
              return Colors.white;
            }
            return Colors.black;
          },
        ),
        iconColor: WidgetStateProperty.resolveWith<Color?>(
              (states) => states.contains(WidgetState.selected) ? Colors.white : Colors.black,
        ),
        side: WidgetStateProperty.resolveWith<BorderSide>(
              (states) => BorderSide(
            color: states.contains(WidgetState.selected) ? Colors.blueGrey : Colors.grey,
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
      titleLarge: GoogleFonts.roboto(fontSize: 22, color: Colors.black),
      titleMedium: GoogleFonts.roboto(fontSize: 14, color: Colors.black),
      titleSmall: GoogleFonts.roboto(fontSize: 12, color: Colors.black),

      headlineLarge: GoogleFonts.roboto(fontSize: 15, color: Colors.white70, fontWeight: FontWeight.bold), // siva
      headlineSmall: GoogleFonts.roboto(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.bold), // siva
      labelLarge: GoogleFonts.roboto(fontSize: 15, color: Colors.white70, fontWeight: FontWeight.bold), // siva
      labelSmall: GoogleFonts.roboto(fontSize: 13, color: Colors.grey), // siva


      bodyLarge: GoogleFonts.roboto(fontSize: 15, color: Colors.black87),
      bodyMedium: GoogleFonts.roboto(fontSize: 13, color: Colors.black, fontWeight: FontWeight.bold),
      bodySmall: GoogleFonts.roboto(fontSize: 12, color: Colors.black, fontWeight: FontWeight.bold),
    ),
    cardTheme: CardThemeData(
      color: Colors.white24,
      shadowColor: Colors.black,
      surfaceTintColor: Colors.teal[200],
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5.0),
      ),
    ),
    colorScheme: ColorScheme.fromSeed(
      primary: primary, // siva
      secondary: primaryLight, // siva
      surface: Colors.white,
      background: Colors.white, // siva
      error: Colors.red,
      onPrimary: primaryLight, // siva
      onSecondary: Colors.white, // siva
      onSurface: Colors.black,
      onBackground: primaryLight.withOpacity(0.1), // siva
      onError: Colors.white,
      seedColor: primaryDark,
    ),
  );
}
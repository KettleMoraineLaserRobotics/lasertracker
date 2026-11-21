import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

final TextTheme laserTextTheme = TextTheme(
  displayLarge: GoogleFonts.aldrich(fontSize: 26, fontWeight: FontWeight.w700),
  displayMedium: GoogleFonts.aldrich(fontSize: 22, fontWeight: FontWeight.w600),
  displaySmall: GoogleFonts.aldrich(fontSize: 20, fontWeight: FontWeight.w500),

  titleLarge: GoogleFonts.exo2(fontSize: 22, fontWeight: FontWeight.w700),
  titleMedium: GoogleFonts.exo2(fontSize: 16, fontWeight: FontWeight.w600),
  titleSmall: GoogleFonts.exo2(fontSize: 14, fontWeight: FontWeight.w500),

  bodyLarge: GoogleFonts.exo2(fontSize: 16, fontWeight: FontWeight.w400),
  bodyMedium: GoogleFonts.exo2(fontSize: 14, fontWeight: FontWeight.w400),
  bodySmall: GoogleFonts.exo2(fontSize: 12, fontWeight: FontWeight.w400),

  labelLarge: GoogleFonts.exo2(fontSize: 14, fontWeight: FontWeight.w600),
  labelMedium: GoogleFonts.exo2(fontSize: 12, fontWeight: FontWeight.w500),
  labelSmall: GoogleFonts.exo2(fontSize: 11, fontWeight: FontWeight.w500),
);

final ColorScheme _darkScheme = ColorScheme.fromSeed(
  seedColor: const Color(0xff00ff92),
  primary: const Color(0xff00ff92),
  brightness: Brightness.dark,
);

final ThemeData darkTheme = ThemeData(
  colorScheme: _darkScheme,

  textTheme: laserTextTheme,

  appBarTheme: AppBarTheme(
    titleTextStyle: GoogleFonts.aldrich(fontSize: 36, fontWeight: FontWeight.w500, color: Colors.white),
    backgroundColor: _darkScheme.surface,
    surfaceTintColor: Colors.transparent,
    elevation: 4,
    centerTitle: true,
    iconTheme: const IconThemeData(color: Colors.white),
  ),

  navigationRailTheme: const NavigationRailThemeData(
    labelType: NavigationRailLabelType.all,
    indicatorColor: Color.fromARGB(48, 116, 249, 156),
    selectedIconTheme: IconThemeData(color: Color(0xff00ff92)),
  ),

  navigationBarTheme: const NavigationBarThemeData(
    indicatorColor: Color.fromARGB(50, 0, 255, 145),
    iconTheme: WidgetStatePropertyAll(IconThemeData(color: Color(0xff00ff92))),
  ),

  inputDecorationTheme: const InputDecorationTheme(
    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xff00ff92), width: 2)),
    floatingLabelStyle: TextStyle(color: Colors.white),
    hintStyle: TextStyle(color: Colors.white54),
  ),

  sliderTheme: SliderThemeData(
    activeTrackColor: const Color(0xff00ff92),
    thumbColor: const Color(0xFFFFFFFF),
    inactiveTrackColor: Colors.grey.shade800,
    valueIndicatorColor: Colors.white,
  ),

  checkboxTheme: CheckboxThemeData(
    fillColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return const Color(0xFF74F99C);
      }
      return null;
    }),
    checkColor: WidgetStateProperty.all(Colors.white),
  ),

  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return const Color(0xFFFFFFFF);
      }
      return null;
    }),
    trackColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return const Color(0xFF74F99C).withValues(alpha: 0.5);
      }
      return null;
    }),
  ),

  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: Colors.white,
      backgroundColor: Color(0x00FFFFFF),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      foregroundColor: _darkScheme.onPrimaryContainer,
      backgroundColor: _darkScheme.primaryContainer,
    ),
  ),
);

const Color _trackerGreen = Color(0xff00995a);

final ColorScheme _lightScheme = ColorScheme.fromSeed(
  seedColor: const Color(0xff00ff92),
  primary: _trackerGreen,
  surface: Colors.white,
  primaryContainer: const Color(0xffb1f1c1),
  onPrimaryContainer: const Color(0xff12512e),
  brightness: Brightness.light,
  dynamicSchemeVariant: DynamicSchemeVariant.content,
);

final ThemeData lightTheme = ThemeData(
  colorScheme: _lightScheme,

  textTheme: laserTextTheme,

  appBarTheme: AppBarTheme(
    titleTextStyle: GoogleFonts.aldrich(fontSize: 36, fontWeight: FontWeight.w500, color: Colors.black),
    backgroundColor: _lightScheme.surface,
    surfaceTintColor: Colors.transparent,
    elevation: 4,
    centerTitle: true,
    iconTheme: const IconThemeData(color: Colors.black),
  ),

  navigationRailTheme: NavigationRailThemeData(
    labelType: NavigationRailLabelType.all,
    indicatorColor: _lightScheme.primaryContainer,
    unselectedIconTheme: IconThemeData(color: _trackerGreen),
    selectedIconTheme: const IconThemeData(color: _trackerGreen),
  ),

  navigationBarTheme: NavigationBarThemeData(
    indicatorColor: _lightScheme.primaryContainer,
    iconTheme: const WidgetStatePropertyAll(IconThemeData(color: _trackerGreen)),
  ),

  inputDecorationTheme: const InputDecorationTheme(
    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: _trackerGreen, width: 2)),
    floatingLabelStyle: TextStyle(color: Colors.black),
    hintStyle: TextStyle(color: Colors.black54),
  ),

  sliderTheme: SliderThemeData(
    activeTrackColor: _trackerGreen,
    thumbColor: _trackerGreen,
    inactiveTrackColor: Colors.grey.shade300,
    valueIndicatorColor: Colors.black87,
  ),

  checkboxTheme: CheckboxThemeData(
    fillColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return _trackerGreen;
      }
      return null;
    }),
    checkColor: WidgetStateProperty.all(Colors.white),
  ),

  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return const Color(0xFFFFFFFF);
      }
      return null;
    }),
    trackColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return _trackerGreen;
      }
      return null;
    }),
  ),

  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: Colors.black,
      backgroundColor: Color(0x00FFFFFF),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      // same green as the FABs
      foregroundColor: _lightScheme.onPrimaryContainer,
      backgroundColor: _lightScheme.primaryContainer,
    ),
  ),
);

// App colors (sampled from the group's Figma prototype). Change them here and every screen updates.
import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF148340);
  static const primaryDark = Color(0xFF0B5E30);
  static const primaryLight = Color(0xFFE3F4EA);
  static const bg = Color(0xFFF9F7FF);
  static const card = Color(0xFFFFFFFF);
  static const ink = Color(0xFF14231B);
  static const mute = Color(0xFF66766D);
  static const line = Color(0xFFE4E7EE);
  static const red = Color(0xFFD92D20);
  static const redLight = Color(0xFFFDECEA);
  static const amber = Color(0xFFB7791F);
  static const amberLight = Color(0xFFFDF3DC);
  static const orange = Color(0xFFC2410C);
  static const orangeLight = Color(0xFFFFEDD5);
  static const grey = Color(0xFFEEF1EF);
}

// Text size options in Profile > Accessibility
const Map<String, double> textScales = {
  'Small': 0.9,
  'Medium': 1.0,
  'Large': 1.15,
  'Extra Large': 1.3,
};

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary, primary: AppColors.primary),
    fontFamily: 'Roboto',
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bg,
      foregroundColor: AppColors.ink,
      elevation: 0,
      centerTitle: true,
    ),
  );
}

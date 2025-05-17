import 'package:flutter/material.dart';

class AppColors {
  // Primary colors
  static const Color primary = Color(0xFF043E68); // Your brand color
  static const Color primaryContainer = Color(0xFFCCE6FF);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFF001D31);

  // Secondary colors
  static const Color secondary = Color(0xFF535F70);
  static const Color secondaryContainer = Color(0xFFD7E3F7);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onSecondaryContainer = Color(0xFF101C2B);

  // Tertiary colors
  static const Color tertiary = Color(0xFF785000);
  static const Color tertiaryContainer = Color(0xFFFFDDB3);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color onTertiaryContainer = Color(0xFF261800);

  // Neutral colors
  static const Color background = Color(0xFFFBFCFE);
  static const Color surface = Color(0xFFFBFCFE);
  static const Color surfaceVariant = Color(0xFFDEE3EA);
  static const Color onSurface = Color(0xFF191C1E);
  static const Color onSurfaceVariant = Color.fromARGB(255, 238, 240, 242);
  static const Color outline = Color(0xFF71787E);

  // Error colors
  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD4);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color onErrorContainer = Color(0xFF410001);

  // Light theme color scheme
  static ColorScheme get lightScheme => ColorScheme(
        brightness: Brightness.light,
        primary: primary,
        onPrimary: onPrimary,
        primaryContainer: primaryContainer,
        onPrimaryContainer: onPrimaryContainer,
        secondary: secondary,
        onSecondary: onSecondary,
        secondaryContainer: secondaryContainer,
        onSecondaryContainer: onSecondaryContainer,
        tertiary: tertiary,
        onTertiary: onTertiary,
        tertiaryContainer: tertiaryContainer,
        onTertiaryContainer: onTertiaryContainer,
        error: error,
        errorContainer: errorContainer,
        onError: onError,
        onErrorContainer: onErrorContainer,
        background: background,
        onBackground: onSurface,
        surface: surface,
        onSurface: onSurface,
        surfaceContainerHighest: surfaceVariant,
        onSurfaceVariant: onSurfaceVariant,
        surfaceContainer: surfaceVariant,
        outline: outline,
        outlineVariant: outline,
        shadow: Colors.black,
      );

  // Dark theme color scheme
  static ColorScheme get darkScheme => ColorScheme(
        brightness: Brightness.dark,
        primary: Color(0xFF9ACAFF),
        onPrimary: Color(0xFF003152),
        primaryContainer: Color(0xFF004879),
        onPrimaryContainer: Color(0xFFCCE6FF),
        secondary: Color(0xFFB7C7DC),
        onSecondary: Color(0xFF263140),
        secondaryContainer: Color(0xFF3C4858),
        onSecondaryContainer: Color(0xFFD7E3F7),
        tertiary: Color(0xFFE6B871),
        onTertiary: Color(0xFF422900),
        tertiaryContainer: Color(0xFF5B3F00),
        onTertiaryContainer: Color(0xFFFFDDB3),
        error: Color(0xFFFFB4AB),
        errorContainer: Color(0xFF93000A),
        onError: Color(0xFF680003),
        onErrorContainer: Color(0xFFFFDAD4),
        background: Color(0xFF191C1E),
        onBackground: Color(0xFFE2E2E5),
        surface: Color(0xFF191C1E),
        onSurface: Color(0xFFE2E2E5),
        surfaceContainerHighest: Color(0xFF41474D),
        onSurfaceVariant: Color(0xFFC1C7CE),
        surfaceContainer: surfaceVariant,
        outline: Color(0xFF8B9198),
        outlineVariant: Color(0xFF8B9198),
        shadow: Colors.black,
      );

  // Helper methods to get colors from the current theme
  static Color getPrimary(BuildContext context) {
    return Theme.of(context).colorScheme.primary;
  }

  static Color getSecondary(BuildContext context) {
    return Theme.of(context).colorScheme.secondary;
  }

  static Color getTertiary(BuildContext context) {
    return Theme.of(context).colorScheme.tertiary;
  }

  static Color getSurface(BuildContext context) {
    return Theme.of(context).colorScheme.surface;
  }

  static Color getBackground(BuildContext context) {
    return Theme.of(context).colorScheme.background;
  }

  static Color getError(BuildContext context) {
    return Theme.of(context).colorScheme.error;
  }
}
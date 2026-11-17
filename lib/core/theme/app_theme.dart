import 'package:material_ui/material_ui.dart';
import 'package:territory_predictive_insights/domain/alert.dart';
import 'package:territory_predictive_insights/domain/entities.dart';

class AppSpacing {
  const AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
}

class AppRadius {
  const AppRadius._();

  static const double card = 16;
  static const double chip = 12;
}

/// Cores semânticas. Sempre acompanhadas de ícone e texto (nunca só cor).
class AppColors {
  const AppColors._();

  static const Color seed = Color(0xFF0F766E);

  static Color severity(Severity s, Brightness b) {
    final dark = b == Brightness.dark;
    switch (s) {
      case Severity.high:
        return dark ? const Color(0xFFFDA29B) : const Color(0xFFB42318);
      case Severity.medium:
        return dark ? const Color(0xFFFEC84B) : const Color(0xFFB54708);
      case Severity.low:
        return dark ? const Color(0xFF84CAFF) : const Color(0xFF175CD3);
    }
  }

  static Color confidence(ConfidenceLevel l, Brightness b) {
    final dark = b == Brightness.dark;
    switch (l) {
      case ConfidenceLevel.high:
        return dark ? const Color(0xFF6CE9A6) : const Color(0xFF027A48);
      case ConfidenceLevel.medium:
        return dark ? const Color(0xFFFEC84B) : const Color(0xFFB54708);
      case ConfidenceLevel.low:
        return dark ? const Color(0xFFFDA29B) : const Color(0xFFB42318);
    }
  }

  static Color good(Brightness b) =>
      b == Brightness.dark ? const Color(0xFF6CE9A6) : const Color(0xFF027A48);

  static Color bad(Brightness b) =>
      b == Brightness.dark ? const Color(0xFFFDA29B) : const Color(0xFFB42318);
}

/// Tokens extras de tema (alto contraste).
class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({required this.highContrast});

  final bool highContrast;

  @override
  AppTokens copyWith({bool? highContrast}) =>
      AppTokens(highContrast: highContrast ?? this.highContrast);

  @override
  AppTokens lerp(ThemeExtension<AppTokens>? other, double t) =>
      other is AppTokens ? (t < 0.5 ? this : other) : this;
}

class AppTheme {
  const AppTheme._();

  static ThemeData build({required Brightness brightness, required bool highContrast}) {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.seed,
      brightness: brightness,
      contrastLevel: highContrast ? 1.0 : 0.0,
    );
    final dark = brightness == Brightness.dark;
    final background = highContrast
        ? (dark ? Colors.black : Colors.white)
        : scheme.surface;
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: background,
        indicatorColor: scheme.primaryContainer,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.chip),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.chip),
          ),
        ),
      ),
      extensions: [AppTokens(highContrast: highContrast)],
    );
  }
}

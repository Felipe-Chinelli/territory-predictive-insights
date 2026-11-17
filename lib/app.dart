import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:territory_predictive_insights/core/routes.dart';
import 'package:territory_predictive_insights/core/theme/app_theme.dart';
import 'package:territory_predictive_insights/data/local_store.dart';
import 'package:territory_predictive_insights/data/territory_repository.dart';
import 'package:territory_predictive_insights/data/weather_source.dart';
import 'package:territory_predictive_insights/state/occurrences_controller.dart';
import 'package:territory_predictive_insights/state/settings_controller.dart';
import 'package:territory_predictive_insights/state/territory_controller.dart';

class TerritoryApp extends StatelessWidget {
  const TerritoryApp({super.key, required this.store});

  final LocalStore store;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsController>(
          create: (_) => SettingsController(store)..load(),
        ),
        ChangeNotifierProvider<OccurrencesController>(
          create: (_) => OccurrencesController(store)..load(),
        ),
        ChangeNotifierProvider<TerritoryController>(
          create: (ctx) => TerritoryController(
            repository: TerritoryRepository(weatherSource: WeatherSource(store: store)),
            settings: ctx.read<SettingsController>(),
            store: store,
          )..load(),
        ),
      ],
      child: const _AppView(),
    );
  }
}

class _AppView extends StatelessWidget {
  const _AppView();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    return MaterialApp(
      title: 'Territory Predictive Insights',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(brightness: Brightness.light, highContrast: settings.highContrast),
      darkTheme: AppTheme.build(brightness: Brightness.dark, highContrast: settings.highContrast),
      themeMode: settings.themeMode,
      initialRoute: settings.consentGiven ? AppRoutes.home : AppRoutes.consent,
      onGenerateRoute: AppRoutes.onGenerateRoute,
      builder: (context, child) {
        final system = MediaQuery.textScalerOf(context).scale(1.0);
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(system * settings.textScale),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}

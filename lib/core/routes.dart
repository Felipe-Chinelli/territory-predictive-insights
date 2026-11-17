import 'package:material_ui/material_ui.dart';
import 'package:territory_predictive_insights/domain/entities.dart';
import 'package:territory_predictive_insights/ui/screens/alert_detail_screen.dart';
import 'package:territory_predictive_insights/ui/screens/consent_screen.dart';
import 'package:territory_predictive_insights/ui/screens/home_shell.dart';
import 'package:territory_predictive_insights/ui/screens/indicator_detail_screen.dart';
import 'package:territory_predictive_insights/ui/screens/methodology_screen.dart';
import 'package:territory_predictive_insights/ui/screens/occurrence_form_screen.dart';

class IndicatorArgs {
  const IndicatorArgs({required this.category, this.regionId});

  final ServiceCategory category;
  final String? regionId;
}

class AlertArgs {
  const AlertArgs({required this.alertId});

  final String alertId;
}

/// Rotas nomeadas do app.
class AppRoutes {
  const AppRoutes._();

  static const String consent = '/consent';
  static const String home = '/home';
  static const String indicator = '/indicator';
  static const String alert = '/alert';
  static const String occurrenceNew = '/occurrence/new';
  static const String methodology = '/methodology';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final args = settings.arguments;
    final Widget page;
    switch (settings.name) {
      case consent:
        page = const ConsentScreen();
      case home:
        page = const HomeShell();
      case indicator:
        page = args is IndicatorArgs
            ? IndicatorDetailScreen(args: args)
            : const _NotFound();
      case alert:
        page = args is AlertArgs ? AlertDetailScreen(args: args) : const _NotFound();
      case occurrenceNew:
        page = const OccurrenceFormScreen();
      case methodology:
        page = const MethodologyScreen();
      default:
        page = const _NotFound();
    }
    return MaterialPageRoute<dynamic>(settings: settings, builder: (_) => page);
  }
}

class _NotFound extends StatelessWidget {
  const _NotFound();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Página não encontrada')),
      body: const Center(child: Text('Esta tela não existe.')),
    );
  }
}

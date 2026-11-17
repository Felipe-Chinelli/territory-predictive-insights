import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:territory_predictive_insights/core/routes.dart';
import 'package:territory_predictive_insights/state/territory_controller.dart';
import 'package:territory_predictive_insights/ui/screens/alerts_screen.dart';
import 'package:territory_predictive_insights/ui/screens/dashboards_screen.dart';
import 'package:territory_predictive_insights/ui/screens/occurrences_screen.dart';
import 'package:territory_predictive_insights/ui/screens/overview_screen.dart';
import 'package:territory_predictive_insights/ui/screens/settings_screen.dart';

/// Estrutura principal: navegação inferior com 5 áreas.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  static const _titles = ['Visão geral', 'Painéis', 'Alertas', 'Ocorrências', 'Ajustes'];
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pending = context.select<TerritoryController, int>((c) => c.pendingCount);
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index]),
        actions: [
          IconButton(
            tooltip: 'Atualizar dados',
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<TerritoryController>().load(),
          ),
          IconButton(
            tooltip: 'Metodologia e limitações',
            icon: const Icon(Icons.info_outline),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.methodology),
          ),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: [
          OverviewScreen(onSeeAlerts: () => setState(() => _index = 2)),
          const DashboardsScreen(),
          const AlertsScreen(),
          const OccurrencesScreen(),
          const SettingsScreen(),
        ],
      ),
      floatingActionButton: _index == 3
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.occurrenceNew),
              icon: const Icon(Icons.add),
              label: const Text('Registrar'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Início',
          ),
          const NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Painéis',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: pending > 0,
              label: Text('$pending'),
              child: const Icon(Icons.notifications_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: pending > 0,
              label: Text('$pending'),
              child: const Icon(Icons.notifications),
            ),
            label: 'Alertas',
          ),
          const NavigationDestination(
            icon: Icon(Icons.edit_note_outlined),
            selectedIcon: Icon(Icons.edit_note),
            label: 'Ocorrências',
          ),
          const NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Ajustes',
          ),
        ],
      ),
    );
  }
}

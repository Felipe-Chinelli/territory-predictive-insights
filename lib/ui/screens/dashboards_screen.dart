import 'package:material_ui/material_ui.dart';
import 'package:territory_predictive_insights/ui/screens/climate_dashboard.dart';
import 'package:territory_predictive_insights/ui/screens/demand_dashboard.dart';
import 'package:territory_predictive_insights/ui/screens/territory_dashboard.dart';

/// Três painéis distintos: demanda, territórios e clima × demanda.
class DashboardsScreen extends StatelessWidget {
  const DashboardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const DefaultTabController(
      length: 3,
      child: Column(
        children: [
          TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: 'Demanda', icon: Icon(Icons.show_chart)),
              Tab(text: 'Territórios', icon: Icon(Icons.map_outlined)),
              Tab(text: 'Clima × demanda', icon: Icon(Icons.water_drop_outlined)),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                DemandDashboard(),
                TerritoryDashboard(),
                ClimateDashboard(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

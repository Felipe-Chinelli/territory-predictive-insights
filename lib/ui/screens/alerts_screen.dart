import 'package:material_ui/material_ui.dart';
import 'package:territory_predictive_insights/core/routes.dart';
import 'package:territory_predictive_insights/domain/alert.dart';
import 'package:territory_predictive_insights/domain/entities.dart';
import 'package:territory_predictive_insights/ui/widgets/alert_tile.dart';
import 'package:territory_predictive_insights/ui/widgets/banners.dart';
import 'package:territory_predictive_insights/ui/widgets/responsive_body.dart';
import 'package:territory_predictive_insights/ui/widgets/state_views.dart';
import 'package:territory_predictive_insights/ui/widgets/territory_view.dart';

enum _AlertFilter {
  all('Todos'),
  pending('Aguardam decisão'),
  high('Críticos'),
  medium('Moderados'),
  low('Atenção');

  const _AlertFilter(this.label);

  final String label;
}

/// Lista de alertas com filtros (estado local) sobre o estado global.
class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  _AlertFilter _filter = _AlertFilter.all;

  bool _matches(PredictiveAlert a, HumanDecision? decision) {
    switch (_filter) {
      case _AlertFilter.all:
        return true;
      case _AlertFilter.pending:
        return decision == null;
      case _AlertFilter.high:
        return a.severity == Severity.high;
      case _AlertFilter.medium:
        return a.severity == Severity.medium;
      case _AlertFilter.low:
        return a.severity == Severity.low;
    }
  }

  @override
  Widget build(BuildContext context) {
    return TerritoryView(
      builder: (context, c, data) {
        final visible = [
          for (final a in c.alerts)
            if (_matches(a, c.decisionFor(a))) a,
        ];
        return ResponsiveBody(
          onRefresh: c.load,
          children: [
            const HumanDecisionBanner(),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final f in _AlertFilter.values)
                  ChoiceChip(
                    label: Text(f.label),
                    selected: _filter == f,
                    onSelected: (_) => setState(() => _filter = f),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (visible.isEmpty)
              SizedBox(
                height: 320,
                child: EmptyView(
                  icon: Icons.notifications_off_outlined,
                  title: c.alerts.isEmpty ? 'Nenhum alerta com os limiares atuais' : 'Nenhum alerta neste filtro',
                  message: c.alerts.isEmpty
                      ? 'Os indicadores estão dentro do esperado. Você pode ajustar os limiares em Ajustes.'
                      : 'Escolha outro filtro para ver os demais alertas.',
                  actionLabel: c.alerts.isEmpty ? null : 'Mostrar todos',
                  onAction: c.alerts.isEmpty ? null : () => setState(() => _filter = _AlertFilter.all),
                ),
              )
            else
              for (final a in visible)
                AlertTile(
                  alert: a,
                  decision: c.decisionFor(a),
                  onTap: () => Navigator.pushNamed(
                    context,
                    AppRoutes.alert,
                    arguments: AlertArgs(alertId: a.id),
                  ),
                ),
          ],
        );
      },
    );
  }
}

import 'package:material_ui/material_ui.dart';
import 'package:territory_predictive_insights/core/routes.dart';
import 'package:territory_predictive_insights/core/utils/formatters.dart';
import 'package:territory_predictive_insights/data/territory_catalog.dart';
import 'package:territory_predictive_insights/domain/entities.dart';
import 'package:territory_predictive_insights/domain/forecaster.dart';
import 'package:territory_predictive_insights/domain/stats.dart';
import 'package:territory_predictive_insights/state/territory_controller.dart';
import 'package:territory_predictive_insights/ui/widgets/alert_tile.dart';
import 'package:territory_predictive_insights/ui/widgets/app_card.dart';
import 'package:territory_predictive_insights/ui/widgets/charts.dart';
import 'package:territory_predictive_insights/ui/widgets/kpi_card.dart';
import 'package:territory_predictive_insights/ui/widgets/responsive_body.dart';
import 'package:territory_predictive_insights/ui/widgets/section_header.dart';
import 'package:territory_predictive_insights/ui/widgets/territory_view.dart';

/// Detalhe de um indicador (categoria de serviço, opcionalmente de uma região).
class IndicatorDetailScreen extends StatelessWidget {
  const IndicatorDetailScreen({super.key, required this.args});

  final IndicatorArgs args;

  @override
  Widget build(BuildContext context) {
    final category = args.category;
    final regionName = args.regionId == null
        ? null
        : TerritoryCatalog.regions.firstWhere((r) => r.id == args.regionId).name;
    final title = regionName == null ? category.label : '${category.label} · $regionName';
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: TerritoryView(
        builder: (context, c, data) => _content(context, c, data, title),
      ),
    );
  }

  Widget _content(
    BuildContext context,
    TerritoryController c,
    TerritoryData data,
    String title,
  ) {
    final category = args.category;
    final region = args.regionId == null ? null : data.regionById(args.regionId!);

    final series = data.series(category: category, regionId: region?.id);
    final n = series.length;
    const shown = 42;
    final forecast = data.forecastDemand(category: category, regionId: region?.id);
    final last7 = Stats.sum(series.sublist(n - 7));
    final prev7 = Stats.sum(series.sublist(n - 14, n - 7));
    final trend = prev7 == 0 ? 0.0 : (last7 - prev7) / prev7 * 100;
    final sla = data.slaStats(category: category, regionId: region?.id, lastDays: 28);
    final related = [
      for (final a in c.alerts)
        if (a.category == category && (region == null || a.region.id == region.id)) a,
    ];
    final byRegion = [
      for (final r in data.regions)
        (r, data.slaStats(category: category, regionId: r.id, lastDays: 28).opened),
    ]..sort((a, b) => (b.$2 / b.$1.population).compareTo(a.$2 / a.$1.population));

    return ResponsiveBody(
      children: [
        SectionHeader(
          title: 'Chamados por dia',
          subtitle: 'Últimas 6 semanas e previsão de 7 dias · prazo da categoria: ${category.slaHours} h',
        ),
        AppCard(
          child: TimeSeriesChart(
            line: [...series.sublist(n - shown), ...forecast.values],
            forecastFrom: shown,
            firstDate: data.dates[n - shown],
            semanticLabel:
                'Gráfico de linha: chamados de $title nas últimas 6 semanas, previsão de ${fmtInt(forecast.total)} chamados nos próximos 7 dias.',
          ),
        ),
        const SizedBox(height: 12),
        AdaptiveWrap(
          children: [
            KpiCard(
              label: 'Últimos 7 dias',
              value: fmtInt(last7),
              icon: Icons.calendar_view_week,
              trendPct: trend,
              caption: 'vs. 7 dias anteriores',
            ),
            KpiCard(
              label: 'Previsão 7 dias',
              value: fmtInt(forecast.total),
              icon: Icons.auto_graph,
              caption: forecast.reliableBacktest
                  ? 'confiança ${fmtPct(forecast.confidence * 100)} (erro ${fmtPct(forecast.wape * 100)})'
                  : 'histórico insuficiente',
            ),
            KpiCard(
              label: 'No prazo (28 dias)',
              value: sla.rate == null ? '—' : fmtPct(sla.rate! * 100),
              icon: Icons.timer_outlined,
              upIsBad: false,
              caption: 'meta da categoria: ${category.slaHours} h',
            ),
            KpiCard(
              label: 'Tempo médio',
              value: sla.avgHours == null ? '—' : '${fmtInt(sla.avgHours!)} h',
              icon: Icons.schedule,
              caption: 'últimos 28 dias',
            ),
          ],
        ),
        if (region == null) ...[
          const SectionHeader(
            title: 'Por região',
            subtitle: 'Chamados por 1.000 habitantes (28 dias) · toque para filtrar',
          ),
          AppCard(
            child: BarList(
              items: [
                for (final e in byRegion)
                  BarItem(
                    label: e.$1.name,
                    value: e.$2 / e.$1.population * 1000,
                    valueLabel: '${fmtNum(e.$2 / e.$1.population * 1000, decimals: 1)} /mil hab.',
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRoutes.indicator,
                      arguments: IndicatorArgs(category: category, regionId: e.$1.id),
                    ),
                  ),
              ],
            ),
          ),
        ],
        const SectionHeader(title: 'Alertas relacionados'),
        if (related.isEmpty)
          const AppCard(child: Text('Nenhum alerta ativo para este indicador com os limiares atuais.'))
        else
          for (final a in related)
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
  }
}

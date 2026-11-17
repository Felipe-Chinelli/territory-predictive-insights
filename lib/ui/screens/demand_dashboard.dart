import 'package:material_ui/material_ui.dart';
import 'package:territory_predictive_insights/core/routes.dart';
import 'package:territory_predictive_insights/core/utils/formatters.dart';
import 'package:territory_predictive_insights/domain/entities.dart';
import 'package:territory_predictive_insights/domain/stats.dart';
import 'package:territory_predictive_insights/ui/widgets/app_card.dart';
import 'package:territory_predictive_insights/ui/widgets/badges.dart';
import 'package:territory_predictive_insights/ui/widgets/category_style.dart';
import 'package:territory_predictive_insights/ui/widgets/charts.dart';
import 'package:territory_predictive_insights/ui/widgets/kpi_card.dart';
import 'package:territory_predictive_insights/ui/widgets/responsive_body.dart';
import 'package:territory_predictive_insights/ui/widgets/section_header.dart';
import 'package:territory_predictive_insights/ui/widgets/territory_view.dart';

/// Painel 1: demanda total por serviços, histórico e previsão.
class DemandDashboard extends StatelessWidget {
  const DemandDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return TerritoryView(
      builder: (context, c, data) {
        final total = data.series();
        final n = total.length;
        const shown = 42;
        final history = total.sublist(n - shown);
        final forecast = c.totalForecast;
        final future = forecast?.values ?? const <double>[];
        final last7 = Stats.sum(total.sublist(n - 7));
        final forecastTotal = forecast?.total ?? 0.0;
        final delta = last7 == 0 ? 0.0 : (forecastTotal - last7) / last7 * 100;
        final peak = future.isEmpty ? 0.0 : future.reduce((a, b) => a > b ? a : b);

        return ResponsiveBody(
          onRefresh: c.load,
          children: [
            const SectionHeader(
              title: 'Chamados por dia',
              subtitle: 'Últimas 6 semanas e previsão dos próximos 7 dias',
            ),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TimeSeriesChart(
                    line: [...history, ...future],
                    forecastFrom: history.length,
                    firstDate: data.dates[n - shown],
                    semanticLabel:
                        'Gráfico de linha: chamados por dia nas últimas 6 semanas e previsão de ${fmtInt(forecastTotal)} chamados nos próximos 7 dias, '
                        'variação de ${fmtPct(delta, sign: true)} sobre a última semana.',
                  ),
                  const SizedBox(height: 8),
                  const ChartLegend(
                    items: [
                      ('Observado', Icons.show_chart),
                      ('Previsto (tracejado)', Icons.more_horiz),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            AdaptiveWrap(
              children: [
                KpiCard(
                  label: 'Previsão 7 dias',
                  value: fmtInt(forecastTotal),
                  icon: Icons.auto_graph,
                  trendPct: delta,
                  caption: 'vs. últimos 7 dias (${fmtInt(last7)})',
                ),
                KpiCard(
                  label: 'Confiança do modelo',
                  value: fmtPct((forecast?.confidence ?? 0) * 100),
                  icon: Icons.verified_outlined,
                  caption: forecast != null && forecast.reliableBacktest
                      ? 'erro no backtest (WAPE): ${fmtPct(forecast.wape * 100)}'
                      : 'histórico insuficiente',
                ),
                KpiCard(
                  label: 'Pico previsto (dia)',
                  value: fmtInt(peak),
                  icon: Icons.vertical_align_top,
                  caption: 'chamados em um único dia',
                ),
              ],
            ),
            const SectionHeader(
              title: 'Por tipo de serviço',
              subtitle: 'Últimas 4 semanas · toque para detalhar',
            ),
            for (final cat in ServiceCategory.values) _CategoryCard(data: data, category: cat),
          ],
        );
      },
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.data, required this.category});

  final TerritoryData data;
  final ServiceCategory category;

  @override
  Widget build(BuildContext context) {
    final series = data.series(category: category);
    final n = series.length;
    final last7 = Stats.sum(series.sublist(n - 7));
    final prev7 = Stats.sum(series.sublist(n - 14, n - 7));
    final trend = prev7 == 0 ? 0.0 : (last7 - prev7) / prev7 * 100;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        onTap: () => Navigator.pushNamed(
          context,
          AppRoutes.indicator,
          arguments: IndicatorArgs(category: category),
        ),
        semanticLabel:
            '${category.label}: ${fmtInt(last7)} chamados em 7 dias, tendência ${TrendPill.describe(trend)}. Toque para ver detalhes.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(iconForCategory(category), color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(child: Text(category.label, style: Theme.of(context).textTheme.titleSmall)),
                TrendPill(pct: trend),
              ],
            ),
            const SizedBox(height: 8),
            TimeSeriesChart(
              line: series.sublist(n - 28),
              height: 56,
              showAxes: false,
              semanticLabel: 'Mini gráfico das últimas 4 semanas de ${category.label}',
            ),
            Text('${fmtInt(last7)} chamados em 7 dias', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

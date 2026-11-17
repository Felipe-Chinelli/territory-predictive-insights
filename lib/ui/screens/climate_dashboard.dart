import 'package:material_ui/material_ui.dart';
import 'package:territory_predictive_insights/core/utils/formatters.dart';
import 'package:territory_predictive_insights/domain/entities.dart';
import 'package:territory_predictive_insights/domain/stats.dart';
import 'package:territory_predictive_insights/ui/widgets/app_card.dart';
import 'package:territory_predictive_insights/ui/widgets/banners.dart';
import 'package:territory_predictive_insights/ui/widgets/charts.dart';
import 'package:territory_predictive_insights/ui/widgets/kpi_card.dart';
import 'package:territory_predictive_insights/ui/widgets/responsive_body.dart';
import 'package:territory_predictive_insights/ui/widgets/section_header.dart';
import 'package:territory_predictive_insights/ui/widgets/territory_view.dart';

/// Painel 3: relação entre chuva e chamados sensíveis ao clima (drenagem e vias).
class ClimateDashboard extends StatelessWidget {
  const ClimateDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return TerritoryView(
      builder: (context, c, data) {
        final theme = Theme.of(context);
        final drainage = data.series(category: ServiceCategory.drainage);
        final roads = data.series(category: ServiceCategory.roads);
        final sensitive = [for (var i = 0; i < drainage.length; i++) drainage[i] + roads[i]];
        final rainPast = data.rainHistory;
        final rainFuture = data.rainForecast;
        final n = sensitive.length;
        const shown = 42;
        final rainShown = rainPast.sublist(n - shown);

        final r = Stats.pearson(rainPast, sensitive);
        final wetDays = <double>[];
        final dryDays = <double>[];
        for (var i = 0; i < n; i++) {
          if (rainPast[i] >= 10) {
            wetDays.add(sensitive[i]);
          } else if (rainPast[i] < 1) {
            dryDays.add(sensitive[i]);
          }
        }
        final wetMean = Stats.mean(wetDays);
        final dryMean = Stats.mean(dryDays);
        final uplift = dryMean > 0 && wetDays.isNotEmpty ? (wetMean - dryMean) / dryMean * 100 : null;
        final rain7 = Stats.sum(rainPast.sublist(n - 7));
        final rainNext = Stats.sum(rainFuture);
        final tempMax = data.futureWeather.isEmpty
            ? 0.0
            : data.futureWeather.map((w) => w.tempMaxC).reduce((a, b) => a > b ? a : b);

        return ResponsiveBody(
          onRefresh: c.load,
          children: [
            DataSourceBanner(data: data),
            const SectionHeader(
              title: 'Chuva × chamados de drenagem e vias',
              subtitle: 'Linha: chamados por dia · barras: chuva (mm)',
            ),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TimeSeriesChart(
                    line: sensitive.sublist(n - shown),
                    bars: [...rainShown, ...rainFuture],
                    forecastFrom: shown,
                    firstDate: data.dates[n - shown],
                    semanticLabel:
                        'Gráfico: chamados de drenagem e vias por dia e chuva em milímetros nas últimas 6 semanas, '
                        'com ${fmtNum(rainNext)} milímetros de chuva previstos para os próximos 7 dias.',
                  ),
                  const SizedBox(height: 8),
                  const ChartLegend(
                    items: [
                      ('Chamados', Icons.show_chart),
                      ('Chuva (barras)', Icons.bar_chart),
                      ('Área sombreada: previsão do tempo', Icons.wb_cloudy_outlined),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            AdaptiveWrap(
              children: [
                KpiCard(
                  label: 'Chuva (7 dias)',
                  value: '${fmtNum(rain7)} mm',
                  icon: Icons.water_drop_outlined,
                  caption: 'acumulado recente',
                ),
                KpiCard(
                  label: 'Chuva prevista',
                  value: '${fmtNum(rainNext)} mm',
                  icon: Icons.cloud_queue,
                  caption: 'próximos 7 dias',
                ),
                KpiCard(
                  label: 'Temp. máx. prevista',
                  value: '${fmtNum(tempMax)} °C',
                  icon: Icons.thermostat,
                  caption: 'próximos 7 dias',
                ),
                KpiCard(
                  label: 'Correlação chuva × chamados',
                  value: r == null ? '—' : fmtNum(r, decimals: 2),
                  icon: Icons.insights,
                  caption: 'Pearson, 60 dias',
                ),
              ],
            ),
            const SizedBox(height: 12),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('O que isso significa?', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 6),
                  Text(
                    uplift == null
                        ? 'Ainda não há dias de chuva forte (≥ 10 mm) suficientes no período para comparar.'
                        : 'Em dias com chuva ≥ 10 mm, chamados de drenagem e vias foram '
                            '${fmtPct(uplift.abs())} ${uplift >= 0 ? 'maiores' : 'menores'} que em dias secos '
                            '(${fmtNum(wetMean, decimals: 1)} vs. ${fmtNum(dryMean, decimals: 1)} por dia).',
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Correlação não implica causalidade: feriados, obras e subnotificação também afetam os chamados.',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SectionHeader(title: 'Próximos 7 dias', subtitle: 'Previsão do tempo'),
            AppCard(
              child: Column(
                children: [
                  for (final w in data.futureWeather)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Semantics(
                        label: '${weekdayShort(w.date)} ${fmtDay(w.date)}: ${fmtNum(w.rainMm)} milímetros de chuva, máxima de ${fmtNum(w.tempMaxC)} graus',
                        excludeSemantics: true,
                        child: Row(
                          children: [
                            SizedBox(width: 84, child: Text('${weekdayShort(w.date)} ${fmtDay(w.date)}')),
                            const Icon(Icons.water_drop_outlined, size: 16),
                            const SizedBox(width: 4),
                            Expanded(child: Text('${fmtNum(w.rainMm)} mm')),
                            Text('${fmtNum(w.tempMaxC)} °C'),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

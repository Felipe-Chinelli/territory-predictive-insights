import 'package:material_ui/material_ui.dart';
import 'package:territory_predictive_insights/core/routes.dart';
import 'package:territory_predictive_insights/core/theme/app_theme.dart';
import 'package:territory_predictive_insights/core/utils/formatters.dart';
import 'package:territory_predictive_insights/data/territory_catalog.dart';
import 'package:territory_predictive_insights/domain/entities.dart';
import 'package:territory_predictive_insights/domain/social_impact.dart';
import 'package:territory_predictive_insights/domain/stats.dart';
import 'package:territory_predictive_insights/ui/widgets/alert_tile.dart';
import 'package:territory_predictive_insights/ui/widgets/app_card.dart';
import 'package:territory_predictive_insights/ui/widgets/badges.dart';
import 'package:territory_predictive_insights/ui/widgets/banners.dart';
import 'package:territory_predictive_insights/ui/widgets/category_style.dart';
import 'package:territory_predictive_insights/ui/widgets/kpi_card.dart';
import 'package:territory_predictive_insights/ui/widgets/responsive_body.dart';
import 'package:territory_predictive_insights/ui/widgets/section_header.dart';
import 'package:territory_predictive_insights/ui/widgets/territory_view.dart';

/// Visão geral: KPIs, benefício social, alertas prioritários e indicadores.
class OverviewScreen extends StatelessWidget {
  const OverviewScreen({super.key, required this.onSeeAlerts});

  final VoidCallback onSeeAlerts;

  @override
  Widget build(BuildContext context) {
    return TerritoryView(
      builder: (context, c, data) {
        final theme = Theme.of(context);
        final total = data.series();
        final n = total.length;
        final last7 = Stats.sum(total.sublist(n - 7));
        final prev7 = Stats.sum(total.sublist(n - 14, n - 7));
        final trend = prev7 == 0 ? 0.0 : (last7 - prev7) / prev7 * 100;
        final sla = data.slaStats(lastDays: 28);
        final slaPrev = data.slaStats(lastDays: 28, skipDays: 28);
        final impact = c.impact ?? SocialImpact.compute(data, c.alerts, c.decisions);
        final topAlerts = c.alerts.take(3).toList();

        return ResponsiveBody(
          onRefresh: c.load,
          children: [
            Semantics(
              header: true,
              child: Text(
                TerritoryCatalog.name,
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            Text(
              'Município fictício · ${fmtInt(TerritoryCatalog.totalPopulation)} habitantes · ${data.regions.length} regiões',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.md),
            DataSourceBanner(data: data),
            const SizedBox(height: AppSpacing.sm),
            const HumanDecisionBanner(),
            const SizedBox(height: AppSpacing.md),
            AdaptiveWrap(
              children: [
                KpiCard(
                  label: 'Chamados (7 dias)',
                  value: fmtInt(last7),
                  icon: Icons.support_agent,
                  trendPct: trend,
                  caption: 'vs. 7 dias anteriores',
                ),
                KpiCard(
                  label: 'No prazo (28 dias)',
                  value: fmtPct((sla.rate ?? 0) * 100),
                  icon: Icons.timer_outlined,
                  upIsBad: false,
                  trendPct: slaPrev.rate == null ? null : ((sla.rate ?? 0) - slaPrev.rate!) * 100,
                  caption: 'variação em pontos percentuais',
                ),
                KpiCard(
                  label: 'Tempo médio de resposta',
                  value: '${fmtInt(sla.avgHours ?? 0)} h',
                  icon: Icons.schedule,
                  caption: 'últimos 28 dias',
                ),
                KpiCard(
                  label: 'Alertas ativos',
                  value: '${c.alerts.length}',
                  icon: Icons.notifications_active_outlined,
                  caption: '${c.pendingCount} aguardando decisão humana',
                  onTap: onSeeAlerts,
                ),
              ],
            ),
            const SectionHeader(
              title: 'Benefício social',
              subtitle: 'Como a análise se relaciona ao bem-estar da população',
            ),
            AppCard(child: _SocialImpactCard(impact: impact)),
            SectionHeader(
              title: 'Alertas prioritários',
              trailing: TextButton(onPressed: onSeeAlerts, child: const Text('Ver todos')),
            ),
            if (topAlerts.isEmpty)
              const AppCard(child: Text('Nenhum alerta com os limiares atuais.'))
            else
              for (final a in topAlerts)
                AlertTile(
                  alert: a,
                  decision: c.decisionFor(a),
                  onTap: () => Navigator.pushNamed(context, AppRoutes.alert, arguments: AlertArgs(alertId: a.id)),
                ),
            const SectionHeader(
              title: 'Indicadores por serviço',
              subtitle: 'Toque para ver o detalhe do indicador',
            ),
            for (final cat in ServiceCategory.values)
              _CategoryRow(data: data, category: cat),
          ],
        );
      },
    );
  }
}

class _SocialImpactCard extends StatelessWidget {
  const _SocialImpactCard({required this.impact});

  final SocialImpact impact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final slaDelta = impact.slaRatePrev == null ? null : (impact.slaRate - impact.slaRatePrev!) * 100;
    final rows = <(IconData, String, String)>[
      (
        Icons.task_alt,
        'Chamados resolvidos no prazo: ${fmtPct(impact.slaRate * 100)}',
        slaDelta == null
            ? 'Sem período anterior para comparar.'
            : '${fmtPct(slaDelta, decimals: 1, sign: true)} p.p. em relação aos 28 dias anteriores.',
      ),
      (
        Icons.balance,
        'Equidade entre regiões: diferença de ${fmtNum(impact.equityGapPp, decimals: 1)} p.p.',
        impact.worstRegion == null || impact.bestRegion == null
            ? 'Sem dados suficientes.'
            : 'Menor prazo cumprido: ${impact.worstRegion!.name}. Maior: ${impact.bestRegion!.name}.',
      ),
      (
        Icons.groups_outlined,
        'População em regiões com alerta já revisado: ${fmtInt(impact.populationReviewed)}',
        'de ${fmtInt(impact.populationTotal)} habitantes. A revisão humana é o que transforma alerta em ação.',
      ),
    ];
    return Column(
      children: [
        for (final r in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExcludeSemantics(child: Icon(r.$1, color: theme.colorScheme.primary)),
                const SizedBox(width: AppSpacing.sm + 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.$2, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                      Text(
                        r.$3,
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.data, required this.category});

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
        child: Row(
          children: [
            Icon(iconForCategory(category), color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(category.label, style: Theme.of(context).textTheme.titleSmall),
                  Text('${fmtInt(last7)} chamados em 7 dias', style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            TrendPill(pct: trend),
          ],
        ),
      ),
    );
  }
}

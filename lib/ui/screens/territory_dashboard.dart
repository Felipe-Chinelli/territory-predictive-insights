import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:territory_predictive_insights/core/theme/app_theme.dart';
import 'package:territory_predictive_insights/core/utils/formatters.dart';
import 'package:territory_predictive_insights/domain/entities.dart';
import 'package:territory_predictive_insights/domain/stats.dart';
import 'package:territory_predictive_insights/state/settings_controller.dart';
import 'package:territory_predictive_insights/ui/widgets/app_card.dart';
import 'package:territory_predictive_insights/ui/widgets/charts.dart';
import 'package:territory_predictive_insights/ui/widgets/responsive_body.dart';
import 'package:territory_predictive_insights/ui/widgets/section_header.dart';
import 'package:territory_predictive_insights/ui/widgets/territory_view.dart';

/// Painel 2: comparação entre regiões (demanda per capita e prazo de atendimento).
class TerritoryDashboard extends StatefulWidget {
  const TerritoryDashboard({super.key});

  @override
  State<TerritoryDashboard> createState() => _TerritoryDashboardState();
}

class _TerritoryDashboardState extends State<TerritoryDashboard> {
  // Estado local: filtro de região selecionado.
  String? _regionId;

  @override
  Widget build(BuildContext context) {
    final slaMin = context.select<SettingsController, int>((s) => s.thresholds.slaMinPct);
    final brightness = Theme.of(context).brightness;
    return TerritoryView(
      builder: (context, c, data) {
        final selected = _regionId == null ? null : data.regionById(_regionId!);

        BarItem demandItem(String label, int population, int opened) => BarItem(
              label: label,
              value: opened / population * 1000,
              valueLabel: '${fmtNum(opened / population * 1000, decimals: 1)} /mil hab.',
            );

        final regionDemand = [
          for (final r in data.regions)
            (r, data.slaStats(regionId: r.id, lastDays: 28).opened),
        ]..sort((a, b) => (b.$2 / b.$1.population).compareTo(a.$2 / a.$1.population));

        final regionSla = [
          for (final r in data.regions) (r, data.slaStats(regionId: r.id, lastDays: 28).rate ?? 0.0),
        ]..sort((a, b) => a.$2.compareTo(b.$2));

        return ResponsiveBody(
          onRefresh: c.load,
          children: [
            const SectionHeader(title: 'Região', subtitle: 'Filtre para detalhar uma região'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Todas'),
                  selected: _regionId == null,
                  onSelected: (_) => setState(() => _regionId = null),
                ),
                for (final r in data.regions)
                  ChoiceChip(
                    label: Text(r.name),
                    selected: _regionId == r.id,
                    onSelected: (_) => setState(() => _regionId = r.id),
                  ),
              ],
            ),
            if (selected == null) ...[
              const SectionHeader(
                title: 'Demanda por 1.000 habitantes',
                subtitle: 'Chamados abertos nos últimos 28 dias',
              ),
              AppCard(
                child: BarList(
                  items: [for (final e in regionDemand) demandItem(e.$1.name, e.$1.population, e.$2)],
                ),
              ),
              SectionHeader(
                title: 'Chamados resolvidos no prazo',
                subtitle: 'Últimos 28 dias · meta mínima de $slaMin%',
              ),
              AppCard(
                child: BarList(
                  maxValue: 1,
                  items: [
                    for (final e in regionSla)
                      BarItem(
                        label: e.$1.name,
                        value: e.$2,
                        valueLabel: e.$2 * 100 < slaMin
                            ? '${fmtPct(e.$2 * 100)} · abaixo da meta'
                            : fmtPct(e.$2 * 100),
                        color: e.$2 * 100 < slaMin
                            ? AppColors.severity(Severity.high, brightness)
                            : null,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const AppCard(
                child: Text(
                  'Equidade: comparar regiões por habitante evita favorecer só quem mais registra chamados. '
                  'Regiões com menor acesso ao canal de atendimento podem estar subnotificadas.',
                ),
              ),
            ] else ...[
              SectionHeader(
                title: selected.name,
                subtitle: '${fmtInt(selected.population)} habitantes · ${selected.profile}',
              ),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Chamados por dia (6 semanas)', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    TimeSeriesChart(
                      line: data.series(regionId: selected.id).sublist(data.dates.length - 42),
                      firstDate: data.dates[data.dates.length - 42],
                      semanticLabel: 'Gráfico de linha: chamados por dia em ${selected.name} nas últimas 6 semanas',
                    ),
                  ],
                ),
              ),
              const SectionHeader(title: 'Por serviço', subtitle: 'Chamados por 1.000 habitantes (28 dias)'),
              AppCard(
                child: BarList(
                  items: [
                    for (final cat in ServiceCategory.values)
                      demandItem(
                        cat.label,
                        selected.population,
                        data.slaStats(category: cat, regionId: selected.id, lastDays: 28).opened,
                      ),
                  ],
                ),
              ),
              const SectionHeader(title: 'Prazo por serviço', subtitle: 'Resolvidos no prazo (28 dias)'),
              AppCard(
                child: BarList(
                  maxValue: 1,
                  items: [
                    for (final cat in ServiceCategory.values)
                      () {
                        final rate =
                            data.slaStats(category: cat, regionId: selected.id, lastDays: 28).rate ?? 0.0;
                        final below = rate * 100 < slaMin;
                        return BarItem(
                          label: cat.label,
                          value: rate,
                          valueLabel: below ? '${fmtPct(rate * 100)} · abaixo da meta' : fmtPct(rate * 100),
                          color: below ? AppColors.severity(Severity.high, brightness) : null,
                        );
                      }(),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Total em 28 dias: ${fmtInt(Stats.sum(data.series(regionId: selected.id).sublist(data.dates.length - 28)))} chamados.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        );
      },
    );
  }
}

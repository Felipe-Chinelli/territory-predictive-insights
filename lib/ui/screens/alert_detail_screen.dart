import 'package:material_ui/material_ui.dart';
import 'package:territory_predictive_insights/core/routes.dart';
import 'package:territory_predictive_insights/core/theme/app_theme.dart';
import 'package:territory_predictive_insights/core/utils/formatters.dart';
import 'package:territory_predictive_insights/domain/alert.dart';
import 'package:territory_predictive_insights/domain/entities.dart';
import 'package:territory_predictive_insights/domain/forecaster.dart';
import 'package:territory_predictive_insights/state/territory_controller.dart';
import 'package:territory_predictive_insights/ui/widgets/app_card.dart';
import 'package:territory_predictive_insights/ui/widgets/badges.dart';
import 'package:territory_predictive_insights/ui/widgets/banners.dart';
import 'package:territory_predictive_insights/ui/widgets/category_style.dart';
import 'package:territory_predictive_insights/ui/widgets/charts.dart';
import 'package:territory_predictive_insights/ui/widgets/responsive_body.dart';
import 'package:territory_predictive_insights/ui/widgets/section_header.dart';
import 'package:territory_predictive_insights/ui/widgets/state_views.dart';
import 'package:territory_predictive_insights/ui/widgets/territory_view.dart';

/// Detalhe do alerta: evidências, confiança, limitações e decisão humana.
class AlertDetailScreen extends StatelessWidget {
  const AlertDetailScreen({super.key, required this.args});

  final AlertArgs args;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalhe do alerta')),
      body: TerritoryView(
        builder: (context, c, data) {
          final alert = c.alertById(args.alertId);
          if (alert == null) {
            return const EmptyView(
              icon: Icons.search_off,
              title: 'Alerta não encontrado',
              message: 'Este alerta não está mais ativo com os dados e limiares atuais.',
            );
          }
          return _AlertBody(alert: alert, controller: c, data: data);
        },
      ),
    );
  }
}

class _AlertBody extends StatelessWidget {
  const _AlertBody({required this.alert, required this.controller, required this.data});

  final PredictiveAlert alert;
  final TerritoryController controller;
  final TerritoryData data;

  Future<void> _decide(BuildContext context, DecisionStatus status) async {
    final noteController = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(status == DecisionStatus.accepted ? 'Aceitar para análise' : 'Descartar alerta'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sua decisão fica registrada neste aparelho. Adicione uma justificativa (opcional):'),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              maxLength: 160,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Justificativa',
                border: OutlineInputBorder(),
                helperText: 'Não inclua dados pessoais.',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirmar')),
        ],
      ),
    );
    final note = noteController.text;
    noteController.dispose();
    if (confirmed == true) {
      await controller.decide(alert, status, note: note);
      messenger.showSnackBar(SnackBar(content: Text('Decisão registrada: ${status.label}.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final decision = controller.decisionFor(alert);
    final isForecast = alert.kind == AlertKind.forecast;

    // Série de contexto (mesma categoria e região) + previsão para o alerta de demanda.
    const shown = 42;
    final series = data.series(category: alert.category, regionId: alert.region.id);
    final n = series.length;
    final result = isForecast
        ? data.forecastDemand(category: alert.category, regionId: alert.region.id)
        : null;
    final line = [...series.sublist(n - shown), ...?result?.values];

    return ResponsiveBody(
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SeverityChip(severity: alert.severity),
                  Text(alert.kind.label, style: theme.textTheme.labelMedium),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(iconForCategory(alert.category), color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(alert.headline, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(alert.summary),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  ConfidenceBadge(confidence: alert.confidence),
                  DecisionChip(decision: decision),
                ],
              ),
            ],
          ),
        ),
        const SectionHeader(title: 'Histórico e previsão'),
        AppCard(
          child: TimeSeriesChart(
            line: line,
            forecastFrom: result == null ? null : shown,
            firstDate: data.dates[n - shown],
            semanticLabel:
                'Gráfico de linha: chamados de ${alert.category.label} em ${alert.region.name} nas últimas 6 semanas'
                '${isForecast ? ', com previsão tracejada dos próximos 7 dias' : ''}.',
          ),
        ),
        const SectionHeader(title: 'Por que este alerta? (evidências)'),
        AppCard(child: _BulletList(items: alert.evidence, icon: Icons.fact_check_outlined)),
        const SectionHeader(title: 'Nível de confiança'),
        AppCard(child: _ConfidenceMeter(alert: alert)),
        const SectionHeader(
          title: 'Limitações e vieses',
          subtitle: 'Quando esta previsão pode não ser confiável',
        ),
        AppCard(child: _BulletList(items: alert.limitations, icon: Icons.warning_amber_rounded)),
        const SectionHeader(title: 'Sugestão para análise'),
        AppCard(child: Text(alert.suggestedAction)),
        const SizedBox(height: AppSpacing.md),
        const HumanDecisionBanner(),
        const SectionHeader(title: 'Decisão do gestor'),
        AppCard(
          child: decision == null
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Este alerta ainda não foi avaliado por uma pessoa.'),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () => _decide(context, DecisionStatus.accepted),
                      icon: const Icon(Icons.check),
                      label: const Text('Aceitar para análise'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () => _decide(context, DecisionStatus.dismissed),
                      icon: const Icon(Icons.block),
                      label: const Text('Descartar'),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${decision.status.label} em ${fmtDateTime(decision.decidedAt)}',
                      style: theme.textTheme.titleSmall,
                    ),
                    if (decision.note != null) ...[
                      const SizedBox(height: 6),
                      Text('Justificativa: ${decision.note}'),
                    ],
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => controller.clearDecision(alert),
                      icon: const Icon(Icons.undo),
                      label: const Text('Desfazer decisão'),
                    ),
                  ],
                ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => Navigator.pushNamed(
            context,
            AppRoutes.indicator,
            arguments: IndicatorArgs(category: alert.category, regionId: alert.region.id),
          ),
          icon: const Icon(Icons.analytics_outlined),
          label: const Text('Ver indicador relacionado'),
        ),
      ],
    );
  }
}

class _BulletList extends StatelessWidget {
  const _BulletList({required this.items, required this.icon});

  final List<String> items;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExcludeSemantics(child: Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary)),
                const SizedBox(width: 10),
                Expanded(child: Text(item)),
              ],
            ),
          ),
      ],
    );
  }
}

class _ConfidenceMeter extends StatelessWidget {
  const _ConfidenceMeter({required this.alert});

  final PredictiveAlert alert;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = AppColors.confidence(alert.confidenceLevel, theme.brightness);
    final how = alert.kind == AlertKind.forecast
        ? 'Calculada como 1 − WAPE: o modelo é usado para "prever" os últimos 7 dias já conhecidos e o erro '
            'obtido reduz a confiança. Limitada a 95%, pois nenhuma previsão é certa.'
        : 'Baseada no tamanho da amostra de chamados dos últimos 14 dias (mais chamados, mais confiança; máximo de 90%).';
    return Semantics(
      label: 'Confiança ${alert.confidenceLevel.label}, ${fmtPct(alert.confidence * 100)}. $how',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${fmtPct(alert.confidence * 100)} · ${alert.confidenceLevel.label}',
            style: theme.textTheme.titleMedium?.copyWith(color: color, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: alert.confidence),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (context, v, _) => ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: v,
                minHeight: 12,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(how, style: theme.textTheme.bodySmall),
          if (alert.confidence < 0.5) ...[
            const SizedBox(height: 8),
            Text(
              'Confiança baixa: use apenas como ponto de partida para investigação.',
              style: theme.textTheme.bodySmall?.copyWith(color: color, fontWeight: FontWeight.w700),
            ),
          ],
        ],
      ),
    );
  }
}

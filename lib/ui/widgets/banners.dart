import 'package:material_ui/material_ui.dart';
import 'package:territory_predictive_insights/core/theme/app_theme.dart';
import 'package:territory_predictive_insights/core/utils/formatters.dart';
import 'package:territory_predictive_insights/domain/entities.dart';

/// Aviso permanente: alertas apoiam, mas não substituem, a decisão humana.
class HumanDecisionBanner extends StatelessWidget {
  const HumanDecisionBanner({super.key});

  static const String message =
      'Apoio à decisão: os alertas indicam probabilidades, não certezas. Eles apoiam, '
      'mas não substituem, a decisão humana. A decisão final é sempre do gestor público.';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      label: message,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: scheme.primaryContainer,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.how_to_reg, color: scheme.onPrimaryContainer),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onPrimaryContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Informa a origem dos dados (demanda sintética + clima real/cache/simulado).
class DataSourceBanner extends StatelessWidget {
  const DataSourceBanner({super.key, required this.data});

  final TerritoryData data;

  String get _weatherText {
    final at = data.weatherFetchedAt;
    switch (data.weatherOrigin) {
      case WeatherOrigin.live:
        return 'Clima em tempo real (Open-Meteo)${at == null ? '' : ', atualizado em ${fmtDateTime(at)}'}.';
      case WeatherOrigin.cache:
        return 'Sem conexão: usando clima salvo${at == null ? '' : ' em ${fmtDateTime(at)}'}.';
      case WeatherOrigin.synthetic:
        return 'Sem conexão e sem cache: clima simulado.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final offline = data.weatherOrigin != WeatherOrigin.live;
    final text = 'Demanda por serviços: dados sintéticos (simulação). $_weatherText';
    return Semantics(
      container: true,
      label: text,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm + 4),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(AppRadius.chip),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              offline ? Icons.cloud_off_outlined : Icons.cloud_done_outlined,
              size: 18,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                text,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

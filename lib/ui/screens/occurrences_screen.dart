import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:territory_predictive_insights/core/routes.dart';
import 'package:territory_predictive_insights/core/utils/formatters.dart';
import 'package:territory_predictive_insights/data/territory_catalog.dart';
import 'package:territory_predictive_insights/domain/occurrence.dart';
import 'package:territory_predictive_insights/state/load_status.dart';
import 'package:territory_predictive_insights/state/occurrences_controller.dart';
import 'package:territory_predictive_insights/ui/widgets/app_card.dart';
import 'package:territory_predictive_insights/ui/widgets/category_style.dart';
import 'package:territory_predictive_insights/ui/widgets/responsive_body.dart';
import 'package:territory_predictive_insights/ui/widgets/state_views.dart';

/// Ocorrências registradas pelo cidadão neste aparelho.
class OccurrencesScreen extends StatelessWidget {
  const OccurrencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<OccurrencesController>();
    if (controller.status == LoadStatus.loading) {
      return const LoadingView(message: 'Carregando ocorrências…');
    }
    if (controller.items.isEmpty) {
      return EmptyView(
        icon: Icons.inbox_outlined,
        title: 'Nenhuma ocorrência registrada',
        message: 'Registre um problema do seu bairro. Seus dados ficam apenas neste aparelho '
            'e informações pessoais são removidas automaticamente.',
        actionLabel: 'Registrar ocorrência',
        onAction: () => Navigator.pushNamed(context, AppRoutes.occurrenceNew),
      );
    }
    return ResponsiveBody(
      children: [
        for (final o in controller.items)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _OccurrenceCard(occurrence: o),
          ),
      ],
    );
  }
}

class _OccurrenceCard extends StatelessWidget {
  const _OccurrenceCard({required this.occurrence});

  final Occurrence occurrence;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final region = TerritoryCatalog.regions.firstWhere(
      (r) => r.id == occurrence.regionId,
      orElse: () => TerritoryCatalog.regions.first,
    );
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(iconForCategory(occurrence.category), color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(occurrence.category.label, style: theme.textTheme.titleSmall),
              ),
              IconButton(
                tooltip: 'Excluir ocorrência ${occurrence.id}',
                icon: const Icon(Icons.delete_outline),
                onPressed: () => context.read<OccurrencesController>().remove(occurrence.id),
              ),
            ],
          ),
          Text(
            '${occurrence.id} · ${region.name} · urgência ${occurrence.urgency.label.toLowerCase()} · ${fmtDateTime(occurrence.createdAt)}',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Text(occurrence.description),
          if (occurrence.redacted) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const ExcludeSemantics(child: Icon(Icons.shield_outlined, size: 16)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text('Dados pessoais removidos automaticamente.', style: theme.textTheme.bodySmall),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

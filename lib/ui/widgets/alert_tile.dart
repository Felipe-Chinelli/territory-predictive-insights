import 'package:material_ui/material_ui.dart';
import 'package:territory_predictive_insights/domain/alert.dart';
import 'package:territory_predictive_insights/ui/widgets/app_card.dart';
import 'package:territory_predictive_insights/ui/widgets/badges.dart';
import 'package:territory_predictive_insights/ui/widgets/category_style.dart';

class AlertTile extends StatelessWidget {
  const AlertTile({super.key, required this.alert, required this.decision, required this.onTap});

  final PredictiveAlert alert;
  final HumanDecision? decision;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = decision == null ? 'aguardando decisão humana' : decision!.status.label;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        onTap: onTap,
        semanticLabel:
            'Alerta ${alert.severity.label}. ${alert.headline}. Confiança ${alert.confidenceLevel.label}. $status. Toque para ver detalhes.',
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
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(iconForCategory(alert.category), size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    alert.headline,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
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
    );
  }
}

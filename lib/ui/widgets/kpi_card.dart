import 'package:material_ui/material_ui.dart';
import 'package:territory_predictive_insights/ui/widgets/app_card.dart';
import 'package:territory_predictive_insights/ui/widgets/badges.dart';

class KpiCard extends StatelessWidget {
  const KpiCard({
    super.key,
    required this.label,
    required this.value,
    this.caption,
    this.icon,
    this.trendPct,
    this.upIsBad = true,
    this.onTap,
  });

  final String label;
  final String value;
  final String? caption;
  final IconData? icon;
  final double? trendPct;
  final bool upIsBad;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final parts = <String>[
      '$label: $value',
      if (trendPct != null) 'tendência ${TrendPill.describe(trendPct!)}',
      if (caption != null) caption!,
    ];
    return AppCard(
      onTap: onTap,
      semanticLabel: parts.join('. '),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(value, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          if (trendPct != null) ...[
            const SizedBox(height: 6),
            Align(alignment: Alignment.centerLeft, child: TrendPill(pct: trendPct!, upIsBad: upIsBad)),
          ],
          if (caption != null) ...[
            const SizedBox(height: 6),
            Text(caption!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ],
      ),
    );
  }
}

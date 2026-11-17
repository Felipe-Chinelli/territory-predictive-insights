import 'package:material_ui/material_ui.dart';
import 'package:territory_predictive_insights/core/theme/app_theme.dart';
import 'package:territory_predictive_insights/core/utils/formatters.dart';
import 'package:territory_predictive_insights/domain/alert.dart';
import 'package:territory_predictive_insights/domain/entities.dart';

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color, required this.icon});

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withAlpha(140)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(child: Icon(icon, size: 14, color: color)),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class SeverityChip extends StatelessWidget {
  const SeverityChip({super.key, required this.severity});

  final Severity severity;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.severity(severity, Theme.of(context).brightness);
    final icon = switch (severity) {
      Severity.high => Icons.priority_high,
      Severity.medium => Icons.warning_amber_rounded,
      Severity.low => Icons.info_outline,
    };
    return Semantics(
      label: 'Severidade ${severity.label}',
      excludeSemantics: true,
      child: _Pill(label: severity.label, color: color, icon: icon),
    );
  }
}

class ConfidenceBadge extends StatelessWidget {
  const ConfidenceBadge({super.key, required this.confidence});

  final double confidence;

  @override
  Widget build(BuildContext context) {
    final level = confidenceLevelOf(confidence);
    final color = AppColors.confidence(level, Theme.of(context).brightness);
    final text = 'Confiança ${level.label} · ${fmtPct(confidence * 100)}';
    return Semantics(
      label: text,
      excludeSemantics: true,
      child: _Pill(label: text, color: color, icon: Icons.verified_outlined),
    );
  }
}

class DecisionChip extends StatelessWidget {
  const DecisionChip({super.key, required this.decision});

  /// `null` significa que ainda aguarda decisão humana.
  final HumanDecision? decision;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final d = decision;
    if (d == null) {
      return Semantics(
        label: 'Aguardando decisão humana',
        excludeSemantics: true,
        child: _Pill(label: 'Aguarda decisão', color: scheme.onSurfaceVariant, icon: Icons.hourglass_empty),
      );
    }
    final accepted = d.status == DecisionStatus.accepted;
    return Semantics(
      label: 'Decisão: ${d.status.label}',
      excludeSemantics: true,
      child: _Pill(
        label: d.status.label,
        color: accepted ? AppColors.good(Theme.of(context).brightness) : scheme.onSurfaceVariant,
        icon: accepted ? Icons.check_circle_outline : Icons.block,
      ),
    );
  }
}

/// Variação percentual com seta e texto (nunca apenas cor).
class TrendPill extends StatelessWidget {
  const TrendPill({super.key, required this.pct, this.upIsBad = true});

  final double pct;
  final bool upIsBad;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final scheme = Theme.of(context).colorScheme;
    final stable = pct.abs() < 2;
    final up = pct > 0;
    final bad = up == upIsBad;
    final color = stable
        ? scheme.onSurfaceVariant
        : (bad ? AppColors.bad(brightness) : AppColors.good(brightness));
    final icon = stable ? Icons.trending_flat : (up ? Icons.trending_up : Icons.trending_down);
    return _Pill(label: stable ? 'Estável' : fmtPct(pct, sign: true), color: color, icon: icon);
  }

  static String describe(double pct) {
    if (pct.abs() < 2) {
      return 'estável';
    }
    return pct > 0 ? 'alta de ${fmtPct(pct)}' : 'queda de ${fmtPct(pct.abs())}';
  }
}

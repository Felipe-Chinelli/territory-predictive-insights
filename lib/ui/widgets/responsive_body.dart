import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:territory_predictive_insights/core/theme/app_theme.dart';

/// Lista rolável centralizada com largura máxima (celular e tablet).
class ResponsiveBody extends StatelessWidget {
  const ResponsiveBody({super.key, required this.children, this.onRefresh});

  final List<Widget> children;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    final list = ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.lg),
      children: children,
    );
    final body = onRefresh == null ? list : RefreshIndicator(onRefresh: onRefresh!, child: list);
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 760), child: body),
    );
  }
}

/// Distribui filhos em colunas conforme a largura disponível.
class AdaptiveWrap extends StatelessWidget {
  const AdaptiveWrap({
    super.key,
    required this.children,
    this.minItemWidth = 160,
    this.spacing = 12,
  });

  final List<Widget> children;
  final double minItemWidth;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = math.max(1, ((constraints.maxWidth + spacing) / (minItemWidth + spacing)).floor());
        final itemWidth = (constraints.maxWidth - spacing * (cols - 1)) / cols;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [for (final c in children) SizedBox(width: itemWidth, child: c)],
        );
      },
    );
  }
}

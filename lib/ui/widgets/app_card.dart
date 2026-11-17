import 'package:material_ui/material_ui.dart';
import 'package:territory_predictive_insights/core/theme/app_theme.dart';

/// Cartão padrão do app (borda reforçada no modo de alto contraste).
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  /// Quando informado, leitores de tela leem só este texto (resumo do cartão).
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final highContrast = theme.extension<AppTokens>()?.highContrast ?? false;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.card),
      side: BorderSide(
        color: highContrast ? theme.colorScheme.onSurface : theme.colorScheme.outlineVariant,
        width: highContrast ? 1.5 : 1,
      ),
    );
    final content = Padding(padding: padding, child: child);
    final card = Material(
      color: theme.colorScheme.surfaceContainerLow,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: onTap == null ? content : InkWell(onTap: onTap, child: content),
    );
    if (semanticLabel == null) {
      return card;
    }
    return Semantics(
      container: true,
      button: onTap != null,
      label: semanticLabel,
      excludeSemantics: true,
      onTap: onTap,
      child: card,
    );
  }
}

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:territory_predictive_insights/domain/entities.dart';
import 'package:territory_predictive_insights/state/load_status.dart';
import 'package:territory_predictive_insights/state/territory_controller.dart';
import 'package:territory_predictive_insights/ui/widgets/state_views.dart';

/// Trata carregamento, erro e conteúdo pronto do [TerritoryController].
class TerritoryView extends StatelessWidget {
  const TerritoryView({super.key, required this.builder});

  final Widget Function(
    BuildContext context,
    TerritoryController controller,
    TerritoryData data,
  ) builder;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TerritoryController>();
    final data = controller.data;
    final Widget child;
    if (controller.status == LoadStatus.loading) {
      child = const LoadingView(key: ValueKey('loading'));
    } else if (controller.status == LoadStatus.error || data == null) {
      child = ErrorView(
        key: const ValueKey('error'),
        message: controller.errorMessage ?? 'Não foi possível carregar os dados.',
        onRetry: controller.load,
      );
    } else {
      child = KeyedSubtree(
        key: const ValueKey('ready'),
        child: builder(context, controller, data),
      );
    }
    return AnimatedSwitcher(duration: const Duration(milliseconds: 250), child: child);
  }
}

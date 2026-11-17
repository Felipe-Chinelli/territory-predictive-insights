import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:territory_predictive_insights/core/routes.dart';
import 'package:territory_predictive_insights/core/theme/app_theme.dart';
import 'package:territory_predictive_insights/data/territory_catalog.dart';
import 'package:territory_predictive_insights/state/settings_controller.dart';
import 'package:territory_predictive_insights/ui/widgets/app_card.dart';
import 'package:territory_predictive_insights/ui/widgets/responsive_body.dart';

/// Tela de boas-vindas com consentimento explícito (privacidade).
class ConsentScreen extends StatefulWidget {
  const ConsentScreen({super.key});

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  bool _accepted = false;

  Future<void> _continue() async {
    final settings = context.read<SettingsController>();
    final navigator = Navigator.of(context);
    await settings.giveConsent();
    navigator.pushReplacementNamed(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: ResponsiveBody(
          children: [
            const SizedBox(height: AppSpacing.lg),
            ExcludeSemantics(
              child: Icon(Icons.insights, size: 56, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: AppSpacing.md),
            Semantics(
              header: true,
              child: Text('Territory Predictive Insights', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Central de inteligência territorial de ${TerritoryCatalog.name}: antecipa a demanda por '
              'serviços públicos para apoiar gestores e informar cidadãos.',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sua privacidade', style: theme.textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.sm),
                  const _Bullet('Não pedimos nome, CPF, telefone, e-mail nem endereço exato.'),
                  const _Bullet('Ocorrências ficam somente neste aparelho, com dados pessoais removidos automaticamente.'),
                  const _Bullet('A localização é apenas a região (bairro/zona), nunca coordenadas.'),
                  const _Bullet('Os alertas apoiam, mas não substituem, a decisão humana.'),
                  const _Bullet('Você pode apagar tudo e revogar o consentimento em Ajustes.'),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            CheckboxListTile(
              value: _accepted,
              onChanged: (v) => setState(() => _accepted = v ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              title: const Text('Li e concordo com o uso dos dados descrito acima.'),
            ),
            const SizedBox(height: AppSpacing.sm),
            FilledButton(
              onPressed: _accepted ? _continue : null,
              child: const Text('Entrar no painel'),
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.methodology),
              child: const Text('Ver metodologia e limitações'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ExcludeSemantics(child: Icon(Icons.check, size: 18)),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

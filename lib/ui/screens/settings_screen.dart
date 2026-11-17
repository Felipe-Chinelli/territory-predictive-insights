import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:territory_predictive_insights/core/routes.dart';
import 'package:territory_predictive_insights/core/utils/validators.dart';
import 'package:territory_predictive_insights/domain/alert.dart';
import 'package:territory_predictive_insights/state/occurrences_controller.dart';
import 'package:territory_predictive_insights/state/settings_controller.dart';
import 'package:territory_predictive_insights/state/territory_controller.dart';
import 'package:territory_predictive_insights/ui/widgets/app_card.dart';
import 'package:territory_predictive_insights/ui/widgets/responsive_body.dart';
import 'package:territory_predictive_insights/ui/widgets/section_header.dart';

/// Ajustes: aparência/acessibilidade, limiares de alerta, privacidade e demo.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _erase(BuildContext context) async {
    final settings = context.read<SettingsController>();
    final occurrences = context.read<OccurrencesController>();
    final territory = context.read<TerritoryController>();
    final navigator = Navigator.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Apagar meus dados?'),
        content: const Text(
          'Isso remove ocorrências, decisões registradas e o consentimento deste aparelho.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Apagar')),
        ],
      ),
    );
    if (ok != true) {
      return;
    }
    await settings.eraseUserData();
    occurrences.clearAll();
    territory.forgetDecisions();
    navigator.pushNamedAndRemoveUntil(AppRoutes.consent, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final territory = context.watch<TerritoryController>();
    final theme = Theme.of(context);
    return ResponsiveBody(
      children: [
        const SectionHeader(title: 'Aparência e acessibilidade'),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tema', style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(value: ThemeMode.system, label: Text('Sistema'), icon: Icon(Icons.brightness_auto)),
                  ButtonSegment(value: ThemeMode.light, label: Text('Claro'), icon: Icon(Icons.light_mode)),
                  ButtonSegment(value: ThemeMode.dark, label: Text('Escuro'), icon: Icon(Icons.dark_mode)),
                ],
                selected: {settings.themeMode},
                onSelectionChanged: (s) => settings.setThemeMode(s.first),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Alto contraste'),
                subtitle: const Text('Cores e bordas mais fortes'),
                value: settings.highContrast,
                onChanged: settings.setHighContrast,
              ),
              Text('Tamanho do texto: ${(settings.textScale * 100).round()}%', style: theme.textTheme.labelLarge),
              Slider(
                value: settings.textScale,
                min: 0.85,
                max: 1.6,
                divisions: 15,
                label: '${(settings.textScale * 100).round()}%',
                semanticFormatterCallback: (v) => '${(v * 100).round()} por cento',
                onChanged: settings.setTextScale,
              ),
            ],
          ),
        ),
        const SectionHeader(
          title: 'Limiares de alerta',
          subtitle: 'Definidos pelo gestor; alterar recalcula os alertas',
        ),
        const AppCard(child: _ThresholdsForm()),
        const SectionHeader(title: 'Privacidade'),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ocorrências e decisões ficam apenas neste aparelho. Textos livres passam por remoção '
                'automática de CPF, telefone e e-mail antes de serem salvos.',
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _erase(context),
                icon: const Icon(Icons.delete_forever_outlined),
                label: const Text('Apagar meus dados e revogar consentimento'),
              ),
            ],
          ),
        ),
        const SectionHeader(title: 'Sobre e demonstração'),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.menu_book_outlined),
                title: const Text('Metodologia, métricas e limitações'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pushNamed(context, AppRoutes.methodology),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.wifi_off),
                title: const Text('Simular falha de rede'),
                subtitle: const Text('Para demonstrar o estado de erro. Desative para voltar ao normal.'),
                value: territory.simulateFailure,
                onChanged: territory.setSimulateFailure,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ThresholdsForm extends StatefulWidget {
  const _ThresholdsForm();

  @override
  State<_ThresholdsForm> createState() => _ThresholdsFormState();
}

class _ThresholdsFormState extends State<_ThresholdsForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _attention;
  late final TextEditingController _critical;
  late final TextEditingController _sla;

  @override
  void initState() {
    super.initState();
    final t = context.read<SettingsController>().thresholds;
    _attention = TextEditingController(text: '${t.attentionPct}');
    _critical = TextEditingController(text: '${t.criticalPct}');
    _sla = TextEditingController(text: '${t.slaMinPct}');
  }

  @override
  void dispose() {
    _attention.dispose();
    _critical.dispose();
    _sla.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }
    final settings = context.read<SettingsController>();
    final messenger = ScaffoldMessenger.of(context);
    await settings.setThresholds(
      AlertThresholds(
        attentionPct: int.parse(_attention.text.trim()),
        criticalPct: int.parse(_critical.text.trim()),
        slaMinPct: int.parse(_sla.text.trim()),
      ),
    );
    messenger.showSnackBar(const SnackBar(content: Text('Limiares salvos. Alertas recalculados.')));
  }

  void _reset() {
    const d = AlertThresholds.defaults;
    _attention.text = '${d.attentionPct}';
    _critical.text = '${d.criticalPct}';
    _sla.text = '${d.slaMinPct}';
    _formKey.currentState?.validate();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _attention,
            keyboardType: TextInputType.number,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: (v) => Validators.percent(v, min: 5, max: 200),
            decoration: const InputDecoration(
              labelText: 'Atenção: aumento previsto de demanda (%)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _critical,
            keyboardType: TextInputType.number,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: (v) => Validators.critical(v, _attention.text),
            decoration: const InputDecoration(
              labelText: 'Crítico: aumento previsto de demanda (%)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _sla,
            keyboardType: TextInputType.number,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: (v) => Validators.percent(v, min: 30, max: 100),
            decoration: const InputDecoration(
              labelText: 'Meta mínima de chamados no prazo (%)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Salvar limiares'),
              ),
              OutlinedButton(onPressed: _reset, child: const Text('Restaurar padrão')),
            ],
          ),
        ],
      ),
    );
  }
}

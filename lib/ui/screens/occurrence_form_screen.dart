import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:territory_predictive_insights/core/utils/validators.dart';
import 'package:territory_predictive_insights/data/territory_catalog.dart';
import 'package:territory_predictive_insights/domain/entities.dart';
import 'package:territory_predictive_insights/state/occurrences_controller.dart';
import 'package:territory_predictive_insights/ui/widgets/category_style.dart';
import 'package:territory_predictive_insights/ui/widgets/responsive_body.dart';

/// Formulário de registro de ocorrência pelo cidadão (com validação).
class OccurrenceFormScreen extends StatefulWidget {
  const OccurrenceFormScreen({super.key});

  @override
  State<OccurrenceFormScreen> createState() => _OccurrenceFormScreenState();
}

class _OccurrenceFormScreenState extends State<OccurrenceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _description = TextEditingController();

  ServiceCategory? _category;
  String? _regionId;
  Urgency _urgency = Urgency.medium;
  bool _saving = false;

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }
    form.save();
    final controller = context.read<OccurrencesController>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _saving = true);
    final created = await controller.add(
      category: _category!,
      regionId: _regionId!,
      urgency: _urgency,
      description: _description.text,
    );
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          'Ocorrência ${created.id} registrada'
          '${created.redacted ? ' (dados pessoais removidos do texto)' : ''}.',
        ),
      ),
    );
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final errorStyle = TextStyle(color: theme.colorScheme.error);
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar ocorrência')),
      body: ResponsiveBody(
        children: [
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Informe a região (não o endereço exato). Não precisamos do seu nome nem de contato.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                FormField<ServiceCategory>(
                  validator: (v) => Validators.requiredChoice(v, 'Selecione uma categoria.'),
                  onSaved: (v) => _category = v,
                  builder: (state) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Categoria *', style: theme.textTheme.labelLarge),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final c in ServiceCategory.values)
                            ChoiceChip(
                              avatar: Icon(iconForCategory(c), size: 18),
                              label: Text(c.label),
                              selected: state.value == c,
                              onSelected: (_) => state.didChange(c),
                            ),
                        ],
                      ),
                      if (state.hasError)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(state.errorText!, style: errorStyle),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                FormField<String>(
                  validator: (v) => Validators.requiredChoice(v, 'Selecione a região.'),
                  onSaved: (v) => _regionId = v,
                  builder: (state) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Região *', style: theme.textTheme.labelLarge),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final r in TerritoryCatalog.regions)
                            ChoiceChip(
                              label: Text(r.name),
                              selected: state.value == r.id,
                              onSelected: (_) => state.didChange(r.id),
                            ),
                        ],
                      ),
                      if (state.hasError)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(state.errorText!, style: errorStyle),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text('Urgência', style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                SegmentedButton<Urgency>(
                  segments: [
                    for (final u in Urgency.values) ButtonSegment<Urgency>(value: u, label: Text(u.label)),
                  ],
                  selected: {_urgency},
                  onSelectionChanged: (s) => setState(() => _urgency = s.first),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _description,
                  validator: Validators.description,
                  maxLength: 280,
                  maxLines: 4,
                  textInputAction: TextInputAction.newline,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: const InputDecoration(
                    labelText: 'Descreva o problema *',
                    helperText: 'Dados pessoais (CPF, telefone, e-mail) são removidos automaticamente.',
                    helperMaxLines: 2,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  key: const Key('submit-occurrence'),
                  onPressed: _saving ? null : _submit,
                  icon: const Icon(Icons.send),
                  label: const Text('Registrar ocorrência'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

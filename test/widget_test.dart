import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:territory_predictive_insights/data/local_store.dart';
import 'package:territory_predictive_insights/state/occurrences_controller.dart';
import 'package:territory_predictive_insights/ui/screens/occurrence_form_screen.dart';
import 'package:territory_predictive_insights/ui/widgets/banners.dart';

void main() {
  testWidgets('aviso de decisão humana é exibido', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: HumanDecisionBanner())),
    );
    expect(find.textContaining('decisão final é sempre do gestor'), findsOneWidget);
  });

  testWidgets('formulário vazio mostra mensagens de erro e não envia', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = await LocalStore.open();
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => OccurrencesController(store)..load(),
        child: const MaterialApp(home: OccurrenceFormScreen()),
      ),
    );

    await tester.tap(find.byKey(const Key('submit-occurrence')));
    await tester.pump();

    expect(find.text('Selecione uma categoria.'), findsOneWidget);
    expect(find.text('Selecione a região.'), findsOneWidget);
    expect(find.text('Descreva o problema para registrar a ocorrência.'), findsOneWidget);
  });

  testWidgets('formulário válido registra a ocorrência com dados anonimizados', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = await LocalStore.open();
    final controller = OccurrencesController(store)..load();
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ChangeNotifierProvider<OccurrencesController>.value(
        value: controller,
        child: const MaterialApp(home: OccurrenceFormScreen()),
      ),
    );

    await tester.tap(find.text('Iluminação pública'));
    await tester.tap(find.text('Centro'));
    await tester.enterText(
      find.byType(TextFormField),
      'Poste apagado na praça, falar com maria@email.com',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('submit-occurrence')));
    await tester.pumpAndSettle();

    expect(controller.items.length, 1);
    expect(controller.items.first.description.contains('@'), isFalse);
    expect(controller.items.first.redacted, isTrue);
  });
}

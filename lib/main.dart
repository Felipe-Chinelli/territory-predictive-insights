import 'package:material_ui/material_ui.dart';
import 'package:territory_predictive_insights/app.dart';
import 'package:territory_predictive_insights/data/local_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await LocalStore.open();
  runApp(TerritoryApp(store: store));
}

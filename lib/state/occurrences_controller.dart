import 'package:flutter/foundation.dart';
import 'package:territory_predictive_insights/core/utils/anonymizer.dart';
import 'package:territory_predictive_insights/data/local_store.dart';
import 'package:territory_predictive_insights/domain/entities.dart';
import 'package:territory_predictive_insights/domain/occurrence.dart';
import 'package:territory_predictive_insights/state/load_status.dart';

/// Estado das ocorrências registradas pelo cidadão (salvas só no aparelho).
class OccurrencesController extends ChangeNotifier {
  OccurrencesController(this._store);

  final LocalStore _store;

  LoadStatus status = LoadStatus.loading;
  List<Occurrence> items = const [];

  void load() {
    items = _store.readOccurrences();
    status = LoadStatus.ready;
    notifyListeners();
  }

  Future<Occurrence> add({
    required ServiceCategory category,
    required String regionId,
    required Urgency urgency,
    required String description,
  }) async {
    final original = description.trim();
    final clean = Anonymizer.redact(original);
    final now = DateTime.now();
    final occurrence = Occurrence(
      id: 'AV-${now.millisecondsSinceEpoch.toRadixString(36).toUpperCase()}',
      createdAt: now,
      regionId: regionId,
      category: category,
      urgency: urgency,
      description: clean,
      redacted: clean != original,
    );
    items = [occurrence, ...items];
    notifyListeners();
    await _store.saveOccurrences(items);
    return occurrence;
  }

  Future<void> remove(String id) async {
    items = items.where((o) => o.id != id).toList();
    notifyListeners();
    await _store.saveOccurrences(items);
  }

  void clearAll() {
    items = const [];
    notifyListeners();
  }
}

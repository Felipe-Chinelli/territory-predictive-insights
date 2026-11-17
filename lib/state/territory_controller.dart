import 'package:flutter/foundation.dart';
import 'package:territory_predictive_insights/core/utils/anonymizer.dart';
import 'package:territory_predictive_insights/data/local_store.dart';
import 'package:territory_predictive_insights/data/territory_repository.dart';
import 'package:territory_predictive_insights/domain/alert.dart';
import 'package:territory_predictive_insights/domain/alert_engine.dart';
import 'package:territory_predictive_insights/domain/entities.dart';
import 'package:territory_predictive_insights/domain/forecaster.dart';
import 'package:territory_predictive_insights/domain/social_impact.dart';
import 'package:territory_predictive_insights/state/load_status.dart';
import 'package:territory_predictive_insights/state/settings_controller.dart';

/// Estado global do território: dados, alertas e decisões humanas.
/// Compartilhado por Visão geral, Painéis, Alertas e telas de detalhe.
class TerritoryController extends ChangeNotifier {
  TerritoryController({
    required this.repository,
    required this.settings,
    required LocalStore store,
    AlertEngine engine = const AlertEngine(),
  })  : _store = store,
        _engine = engine,
        _thresholds = settings.thresholds,
        _decisions = {for (final d in store.readDecisions()) d.alertKey: d} {
    settings.addListener(_onSettingsChanged);
  }

  final TerritoryRepository repository;
  final SettingsController settings;
  final LocalStore _store;
  final AlertEngine _engine;

  AlertThresholds _thresholds;
  Map<String, HumanDecision> _decisions;
  bool _simulateFailure = false;

  LoadStatus status = LoadStatus.loading;
  String? errorMessage;
  TerritoryData? data;
  List<PredictiveAlert> alerts = const [];
  ForecastResult? totalForecast;
  SocialImpact? impact;

  bool get simulateFailure => _simulateFailure;

  Map<String, HumanDecision> get decisions => Map.unmodifiable(_decisions);

  HumanDecision? decisionFor(PredictiveAlert alert) => _decisions[alert.key];

  int get pendingCount => alerts.where((a) => !_decisions.containsKey(a.key)).length;

  PredictiveAlert? alertById(String id) {
    for (final a in alerts) {
      if (a.id == id) {
        return a;
      }
    }
    return null;
  }

  Future<void> load() async {
    status = LoadStatus.loading;
    errorMessage = null;
    notifyListeners();
    try {
      data = await repository.load(forceFailure: _simulateFailure);
      _recompute();
      status = LoadStatus.ready;
    } on DataLoadException catch (e) {
      status = LoadStatus.error;
      errorMessage = e.message;
    } catch (_) {
      status = LoadStatus.error;
      errorMessage = 'Não foi possível carregar os dados do território. Tente novamente.';
    }
    notifyListeners();
  }

  Future<void> setSimulateFailure(bool value) {
    _simulateFailure = value;
    return load();
  }

  Future<void> decide(
    PredictiveAlert alert,
    DecisionStatus decision, {
    String? note,
  }) async {
    final clean = note == null ? '' : Anonymizer.redact(note.trim());
    _decisions[alert.key] = HumanDecision(
      alertKey: alert.key,
      alertId: alert.id,
      status: decision,
      note: clean.isEmpty ? null : clean,
      decidedAt: DateTime.now(),
    );
    _refreshImpact();
    notifyListeners();
    await _store.saveDecisions(_decisions.values.toList());
  }

  Future<void> clearDecision(PredictiveAlert alert) async {
    _decisions.remove(alert.key);
    _refreshImpact();
    notifyListeners();
    await _store.saveDecisions(_decisions.values.toList());
  }

  void forgetDecisions() {
    _decisions = {};
    _refreshImpact();
    notifyListeners();
  }

  void _onSettingsChanged() {
    if (settings.thresholds != _thresholds) {
      _thresholds = settings.thresholds;
      _recompute();
      notifyListeners();
    }
  }

  void _recompute() {
    final d = data;
    if (d == null) {
      return;
    }
    alerts = _engine.generate(d, _thresholds);
    totalForecast = d.forecastDemand();
    _refreshImpact();
  }

  void _refreshImpact() {
    final d = data;
    if (d != null) {
      impact = SocialImpact.compute(d, alerts, _decisions);
    }
  }

  @override
  void dispose() {
    settings.removeListener(_onSettingsChanged);
    super.dispose();
  }
}

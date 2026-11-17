import 'package:material_ui/material_ui.dart';
import 'package:territory_predictive_insights/data/local_store.dart';
import 'package:territory_predictive_insights/domain/alert.dart';

/// Estado global de preferências, acessibilidade, consentimento e limiares.
class SettingsController extends ChangeNotifier {
  SettingsController(this._store);

  final LocalStore _store;

  ThemeMode themeMode = ThemeMode.system;
  bool highContrast = false;
  double textScale = 1.0;
  bool consentGiven = false;
  AlertThresholds thresholds = AlertThresholds.defaults;

  void load() {
    themeMode = ThemeMode.values.firstWhere(
      (m) => m.name == _store.themeModeName,
      orElse: () => ThemeMode.system,
    );
    highContrast = _store.highContrast;
    textScale = _store.textScale.clamp(0.85, 1.6).toDouble();
    consentGiven = _store.consent;
    thresholds = _store.readThresholds();
  }

  Future<void> giveConsent() async {
    consentGiven = true;
    notifyListeners();
    await _store.setConsent(true);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode = mode;
    notifyListeners();
    await _store.setThemeModeName(mode.name);
  }

  Future<void> setHighContrast(bool value) async {
    highContrast = value;
    notifyListeners();
    await _store.setHighContrast(value);
  }

  Future<void> setTextScale(double value) async {
    textScale = value;
    notifyListeners();
    await _store.setTextScale(value);
  }

  Future<void> setThresholds(AlertThresholds value) async {
    thresholds = value;
    notifyListeners();
    await _store.saveThresholds(value);
  }

  /// Revoga o consentimento e apaga ocorrências e decisões salvas no aparelho.
  Future<void> eraseUserData() async {
    consentGiven = false;
    await _store.eraseUserData();
    notifyListeners();
  }
}

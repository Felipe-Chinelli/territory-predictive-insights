import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:territory_predictive_insights/domain/alert.dart';
import 'package:territory_predictive_insights/domain/occurrence.dart';

/// Persistência local (SharedPreferences): configurações, ocorrências,
/// decisões humanas e cache do clima. Mantém o app útil sem conexão.
class LocalStore {
  LocalStore(this._prefs);

  final SharedPreferences _prefs;

  static Future<LocalStore> open() async =>
      LocalStore(await SharedPreferences.getInstance());

  static const _kConsent = 'consent_given';
  static const _kTheme = 'theme_mode';
  static const _kContrast = 'high_contrast';
  static const _kTextScale = 'text_scale';
  static const _kThresholds = 'alert_thresholds';
  static const _kOccurrences = 'occurrences';
  static const _kDecisions = 'decisions';
  static const _kWeather = 'weather_cache';

  // Configurações
  bool get consent => _prefs.getBool(_kConsent) ?? false;
  Future<void> setConsent(bool v) async {
    await _prefs.setBool(_kConsent, v);
  }

  String get themeModeName => _prefs.getString(_kTheme) ?? 'system';
  Future<void> setThemeModeName(String v) async {
    await _prefs.setString(_kTheme, v);
  }

  bool get highContrast => _prefs.getBool(_kContrast) ?? false;
  Future<void> setHighContrast(bool v) async {
    await _prefs.setBool(_kContrast, v);
  }

  double get textScale => _prefs.getDouble(_kTextScale) ?? 1.0;
  Future<void> setTextScale(double v) async {
    await _prefs.setDouble(_kTextScale, v);
  }

  AlertThresholds readThresholds() {
    final json = _readMap(_kThresholds);
    return json == null ? AlertThresholds.defaults : AlertThresholds.fromJson(json);
  }

  Future<void> saveThresholds(AlertThresholds t) => _writeJson(_kThresholds, t.toJson());

  // Ocorrências
  List<Occurrence> readOccurrences() =>
      [for (final m in _readList(_kOccurrences)) Occurrence.fromJson(m)];

  Future<void> saveOccurrences(List<Occurrence> items) =>
      _writeJson(_kOccurrences, [for (final o in items) o.toJson()]);

  // Decisões humanas
  List<HumanDecision> readDecisions() =>
      [for (final m in _readList(_kDecisions)) HumanDecision.fromJson(m)];

  Future<void> saveDecisions(List<HumanDecision> items) =>
      _writeJson(_kDecisions, [for (final d in items) d.toJson()]);

  // Cache do clima
  Map<String, dynamic>? readWeatherCache() => _readMap(_kWeather);

  Future<void> saveWeatherCache(Map<String, dynamic> json) =>
      _writeJson(_kWeather, json);

  /// Apaga dados pessoais e de uso (consentimento, ocorrências, decisões).
  Future<void> eraseUserData() async {
    await _prefs.remove(_kConsent);
    await _prefs.remove(_kOccurrences);
    await _prefs.remove(_kDecisions);
  }

  Map<String, dynamic>? _readMap(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) {
      return null;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } on FormatException {
      // Conteúdo corrompido: ignora e usa o padrão.
    }
    return null;
  }

  List<Map<String, dynamic>> _readList(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) {
      return const [];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return [
          for (final e in decoded)
            if (e is Map) Map<String, dynamic>.from(e),
        ];
      }
    } on FormatException {
      // Conteúdo corrompido: ignora.
    }
    return const [];
  }

  Future<void> _writeJson(String key, Object value) async {
    await _prefs.setString(key, jsonEncode(value));
  }
}

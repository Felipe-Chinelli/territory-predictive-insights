import 'package:flutter_test/flutter_test.dart';
import 'package:territory_predictive_insights/data/synthetic_generator.dart';
import 'package:territory_predictive_insights/data/territory_catalog.dart';
import 'package:territory_predictive_insights/domain/alert.dart';
import 'package:territory_predictive_insights/domain/alert_engine.dart';
import 'package:territory_predictive_insights/domain/entities.dart';

TerritoryData _buildData() {
  final weather = SyntheticWeather.generate(DateTime(2026, 11, 16));
  final past = weather.where((w) => !w.isForecast).toList();
  return TerritoryData(
    regions: TerritoryCatalog.regions,
    records: const SyntheticDemandGenerator().generate(past),
    weather: weather,
    weatherOrigin: WeatherOrigin.synthetic,
  );
}

void main() {
  final data = _buildData();
  const engine = AlertEngine();

  group('dados sintéticos', () {
    test('são determinísticos para o mesmo dia', () {
      final other = _buildData();
      expect(other.records.length, data.records.length);
      expect(other.records.first.opened, data.records.first.opened);
      expect(other.records.last.opened, data.records.last.opened);
    });

    test('cobrem 60 dias, 5 regiões e 5 categorias', () {
      expect(data.pastWeather.length, 60);
      expect(data.futureWeather.length, 7);
      expect(data.records.length, 60 * 5 * 5);
    });
  });

  group('AlertEngine', () {
    test('gera alertas com limiares padrão', () {
      final alerts = engine.generate(data, AlertThresholds.defaults);
      expect(alerts, isNotEmpty);
    });

    test('todo alerta traz justificativa, confiança e limitações', () {
      final alerts = engine.generate(data, AlertThresholds.defaults);
      for (final a in alerts) {
        expect(a.evidence, isNotEmpty, reason: a.id);
        expect(a.limitations, isNotEmpty, reason: a.id);
        expect(a.suggestedAction, isNotEmpty, reason: a.id);
        expect(a.confidence, inInclusiveRange(0.0, 1.0), reason: a.id);
      }
    });

    test('alertas de previsão só aparecem acima do limiar de atenção', () {
      const t = AlertThresholds();
      final alerts = engine.generate(data, t).where((a) => a.kind == AlertKind.forecast);
      for (final a in alerts) {
        expect(a.deltaPct!, greaterThanOrEqualTo(t.attentionPct.toDouble()), reason: a.id);
      }
    });

    test('limiares muito altos eliminam os alertas', () {
      const strict = AlertThresholds(attentionPct: 500, criticalPct: 600, slaMinPct: 30);
      expect(engine.generate(data, strict), isEmpty);
    });

    test('lista vem ordenada por severidade', () {
      final alerts = engine.generate(data, AlertThresholds.defaults);
      for (var i = 1; i < alerts.length; i++) {
        expect(alerts[i - 1].severity.rank, greaterThanOrEqualTo(alerts[i].severity.rank));
      }
    });

    test('chave do alerta muda por dia (decisão humana é diária)', () {
      final alerts = engine.generate(data, AlertThresholds.defaults);
      expect(alerts.first.key, contains('@2026-11-16'));
    });
  });

  group('AlertThresholds', () {
    test('serializa e compara', () {
      const t = AlertThresholds(attentionPct: 25, criticalPct: 50, slaMinPct: 80);
      expect(AlertThresholds.fromJson(t.toJson()), t);
      expect(t == AlertThresholds.defaults, isFalse);
    });
  });
}

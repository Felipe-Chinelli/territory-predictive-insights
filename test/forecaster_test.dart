import 'package:flutter_test/flutter_test.dart';
import 'package:territory_predictive_insights/core/utils/dates.dart';
import 'package:territory_predictive_insights/domain/forecaster.dart';
import 'package:territory_predictive_insights/domain/stats.dart';

void main() {
  final start = DateTime(2026, 9, 1);
  final dates = [for (var i = 0; i < 60; i++) addDays(start, i)];
  final futureDates = [for (var i = 60; i < 67; i++) addDays(start, i)];
  final noRain = List<double>.filled(60, 0.0);
  final futureNoRain = List<double>.filled(7, 0.0);

  group('DemandForecaster', () {
    test('extrapola uma tendência linear', () {
      final demand = [for (var i = 0; i < 60; i++) 10 + 0.5 * i];
      final r = const DemandForecaster().forecast(
        dates: dates,
        demand: demand,
        rain: noRain,
        futureDates: futureDates,
        futureRain: futureNoRain,
      );
      expect(r.values.length, 7);
      expect(r.values.first, closeTo(40, 4));
      expect(r.wape, lessThan(0.1));
      expect(r.confidence, greaterThan(0.85));
      expect(r.dailyTrendPct, greaterThan(0));
    });

    test('série constante mantém o nível', () {
      final demand = List<double>.filled(60, 20.0);
      final r = const DemandForecaster().forecast(
        dates: dates,
        demand: demand,
        rain: noRain,
        futureDates: futureDates,
        futureRain: futureNoRain,
      );
      expect(r.total, closeTo(140, 5));
    });

    test('aprende o efeito da chuva e o usa na previsão', () {
      final rain = [for (var i = 0; i < 60; i++) i % 5 == 0 ? 30.0 : 0.0];
      final demand = [for (var i = 0; i < 60; i++) 10 * (1 + 0.02 * rain[i])];
      final futureRain = [30.0, 0.0, 0.0, 0.0, 0.0, 30.0, 0.0];
      final r = const DemandForecaster().forecast(
        dates: dates,
        demand: demand,
        rain: rain,
        futureDates: futureDates,
        futureRain: futureRain,
      );
      expect(r.rainSensitivity, greaterThan(0.005));
    });

    test('histórico curto zera a confiança', () {
      final r = const DemandForecaster().forecast(
        dates: dates.sublist(0, 10),
        demand: List<double>.filled(10, 5.0),
        rain: List<double>.filled(10, 0.0),
        futureDates: futureDates,
        futureRain: futureNoRain,
      );
      expect(r.confidence, 0.0);
    });
  });

  group('Stats', () {
    test('wape', () {
      expect(Stats.wape([10, 10], [10, 10]), 0.0);
      expect(Stats.wape([5, 5], [10, 10]), closeTo(0.5, 1e-9));
    });

    test('pearson', () {
      expect(Stats.pearson([1, 2, 3, 4], [2, 4, 6, 8]), closeTo(1.0, 1e-9));
      expect(Stats.pearson([1, 1, 1], [1, 2, 3]), isNull);
    });
  });
}

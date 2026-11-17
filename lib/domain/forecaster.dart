import 'dart:math' as math;

import 'package:territory_predictive_insights/domain/entities.dart';
import 'package:territory_predictive_insights/domain/stats.dart';

class ForecastResult {
  const ForecastResult({
    required this.values,
    required this.wape,
    required this.rainSensitivity,
    required this.dailyTrendPct,
    required this.reliableBacktest,
  });

  /// Demanda prevista por dia para o horizonte.
  final List<double> values;

  /// Erro do backtest (últimos 7 dias): soma|erro| / soma(real).
  final double wape;

  /// Aumento fracionário de chamados por mm de chuva (ex.: 0,03 = +3%/mm).
  final double rainSensitivity;

  /// Tendência diária em % ao dia sobre o nível atual.
  final double dailyTrendPct;

  final bool reliableBacktest;

  double get total => Stats.sum(values);

  /// Confiança = 1 − WAPE (limitada a 95%); zero se o backtest não é possível.
  double get confidence =>
      reliableBacktest ? Stats.clamp(1 - wape, 0.0, 0.95) : 0.0;
}

/// Modelo explicável: tendência linear + sazonalidade semanal + efeito da chuva.
class DemandForecaster {
  const DemandForecaster({this.trainDays = 35, this.horizon = 7});

  final int trainDays;
  final int horizon;

  ForecastResult forecast({
    required List<DateTime> dates,
    required List<double> demand,
    required List<double> rain,
    required List<DateTime> futureDates,
    required List<double> futureRain,
  }) {
    final n = demand.length;
    final h = math.min(math.min(futureDates.length, futureRain.length), horizon);
    if (n < 14 || dates.length != n || rain.length != n) {
      return ForecastResult(
        values: List<double>.filled(h, Stats.mean(demand)),
        wape: 1.0,
        rainSensitivity: 0.0,
        dailyTrendPct: 0.0,
        reliableBacktest: false,
      );
    }
    final start = math.max(0, n - trainDays);
    final model = _Model.fit(
      dates.sublist(start),
      demand.sublist(start),
      rain.sublist(start),
    );
    final next = n - start;
    final values = [
      for (var k = 0; k < h; k++)
        model.predict(futureDates[k], next + k, futureRain[k]),
    ];

    var wape = 1.0;
    var reliable = false;
    final split = n - horizon;
    if (split >= 21) {
      final bStart = math.max(0, split - trainDays);
      final bModel = _Model.fit(
        dates.sublist(bStart, split),
        demand.sublist(bStart, split),
        rain.sublist(bStart, split),
      );
      final preds = [
        for (var i = split; i < n; i++)
          bModel.predict(dates[i], i - bStart, rain[i]),
      ];
      wape = Stats.wape(preds, demand.sublist(split));
      reliable = true;
    }
    return ForecastResult(
      values: values,
      wape: wape,
      rainSensitivity: model.beta,
      dailyTrendPct: model.dailyTrendPct(n - start),
      reliableBacktest: reliable,
    );
  }
}

class _Model {
  _Model({
    required this.factors,
    required this.a,
    required this.b,
    required this.c,
    required this.beta,
  });

  final List<double> factors;
  final double a;
  final double b;
  final double c;
  final double beta;

  factory _Model.fit(List<DateTime> dates, List<double> y, List<double> rain) {
    final n = y.length;
    final mean = Stats.mean(y);
    if (n == 0 || mean <= 0) {
      return _Model(
        factors: List<double>.filled(7, 1.0),
        a: 0.0,
        b: 0.0,
        c: 1.0,
        beta: 0.0,
      );
    }
    final sums = List<double>.filled(7, 0.0);
    final counts = List<int>.filled(7, 0);
    for (var i = 0; i < n; i++) {
      final w = dates[i].weekday - 1;
      sums[w] += y[i];
      counts[w]++;
    }
    final factors = [
      for (var w = 0; w < 7; w++)
        counts[w] == 0 ? 1.0 : Stats.clamp(sums[w] / counts[w] / mean, 0.2, 3.0),
    ];
    final deseasonalized = [
      for (var i = 0; i < n; i++) y[i] / factors[dates[i].weekday - 1],
    ];
    final t = [for (var i = 0; i < n; i++) i.toDouble()];
    final line = Stats.linearFit(t, deseasonalized);

    final ratio = <double>[];
    final rr = <double>[];
    for (var i = 0; i < n; i++) {
      final fitted =
          (line.intercept + line.slope * i) * factors[dates[i].weekday - 1];
      if (fitted < 0.5) {
        continue;
      }
      ratio.add(y[i] / fitted);
      rr.add(math.min(rain[i], 50.0));
    }
    var beta = 0.0;
    var c = 1.0;
    if (ratio.length >= 14) {
      final fit = Stats.linearFit(rr, ratio);
      beta = Stats.clamp(fit.slope, 0.0, 0.12);
      c = Stats.mean(ratio) - beta * Stats.mean(rr);
    }
    return _Model(
      factors: factors,
      a: line.intercept,
      b: line.slope,
      c: c,
      beta: beta,
    );
  }

  double predict(DateTime date, int t, double rainMm) {
    final r = math.min(rainMm, 50.0);
    final mult = Stats.clamp(c + beta * r, 0.4, 3.0);
    return math.max(0.0, (a + b * t) * factors[date.weekday - 1] * mult);
  }

  double dailyTrendPct(int n) {
    final level = a + b * (n - 1);
    return level > 0.1 ? b / level * 100 : 0.0;
  }
}

extension DemandForecasting on TerritoryData {
  /// Previsão da demanda (opcionalmente filtrada) para os próximos 7 dias.
  ForecastResult forecastDemand({
    ServiceCategory? category,
    String? regionId,
    DemandForecaster forecaster = const DemandForecaster(),
  }) {
    return forecaster.forecast(
      dates: dates,
      demand: series(category: category, regionId: regionId),
      rain: rainHistory,
      futureDates: futureDates,
      futureRain: rainForecast,
    );
  }
}

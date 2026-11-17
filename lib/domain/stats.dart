import 'dart:math' as math;

/// Funções estatísticas simples usadas pelo modelo e pelos painéis.
class Stats {
  const Stats._();

  static double sum(Iterable<double> v) {
    var s = 0.0;
    for (final x in v) {
      s += x;
    }
    return s;
  }

  static double mean(List<double> v) => v.isEmpty ? 0.0 : sum(v) / v.length;

  static double clamp(double v, double lo, double hi) =>
      math.min(hi, math.max(lo, v));

  /// Regressão linear por mínimos quadrados: y = intercept + slope * x.
  static ({double intercept, double slope}) linearFit(
    List<double> x,
    List<double> y,
  ) {
    final n = math.min(x.length, y.length);
    if (n < 2) {
      return (intercept: n == 0 ? 0.0 : y.first, slope: 0.0);
    }
    var sx = 0.0;
    var sy = 0.0;
    for (var i = 0; i < n; i++) {
      sx += x[i];
      sy += y[i];
    }
    final mx = sx / n;
    final my = sy / n;
    var sxx = 0.0;
    var sxy = 0.0;
    for (var i = 0; i < n; i++) {
      sxx += (x[i] - mx) * (x[i] - mx);
      sxy += (x[i] - mx) * (y[i] - my);
    }
    if (sxx < 1e-9) {
      return (intercept: my, slope: 0.0);
    }
    final slope = sxy / sxx;
    return (intercept: my - slope * mx, slope: slope);
  }

  /// Correlação de Pearson; `null` quando não há variação suficiente.
  static double? pearson(List<double> x, List<double> y) {
    final n = math.min(x.length, y.length);
    if (n < 3) {
      return null;
    }
    final mx = mean(x.sublist(0, n));
    final my = mean(y.sublist(0, n));
    var sxx = 0.0;
    var syy = 0.0;
    var sxy = 0.0;
    for (var i = 0; i < n; i++) {
      sxx += (x[i] - mx) * (x[i] - mx);
      syy += (y[i] - my) * (y[i] - my);
      sxy += (x[i] - mx) * (y[i] - my);
    }
    if (sxx < 1e-9 || syy < 1e-9) {
      return null;
    }
    return sxy / math.sqrt(sxx * syy);
  }

  /// Erro percentual absoluto ponderado: soma|erro| / soma(real).
  static double wape(List<double> predicted, List<double> actual) {
    final n = math.min(predicted.length, actual.length);
    var err = 0.0;
    var total = 0.0;
    for (var i = 0; i < n; i++) {
      err += (predicted[i] - actual[i]).abs();
      total += actual[i].abs();
    }
    return total == 0 ? 1.0 : err / total;
  }
}

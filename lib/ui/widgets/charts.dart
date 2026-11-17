import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:territory_predictive_insights/core/utils/dates.dart';
import 'package:territory_predictive_insights/core/utils/formatters.dart';
import 'package:territory_predictive_insights/domain/stats.dart';

/// Gráfico de série temporal desenhado com CustomPainter (sem dependências).
///
/// - [line]: valores observados (e, opcionalmente, previstos ao final).
/// - [forecastFrom]: índice a partir do qual os dados são previsão (tracejado).
/// - [bars]: série secundária em barras (ex.: chuva), podendo ser mais longa que [line].
class TimeSeriesChart extends StatelessWidget {
  const TimeSeriesChart({
    super.key,
    required this.line,
    required this.semanticLabel,
    this.forecastFrom,
    this.bars,
    this.firstDate,
    this.height = 180,
    this.showAxes = true,
  });

  final List<double> line;
  final String semanticLabel;
  final int? forecastFrom;
  final List<double>? bars;
  final DateTime? firstDate;
  final double height;
  final bool showAxes;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: semanticLabel,
      image: true,
      child: ExcludeSemantics(
        child: SizedBox(
          height: height,
          child: CustomPaint(
            size: Size.infinite,
            painter: _TimeSeriesPainter(
              line: line,
              forecastFrom: forecastFrom,
              bars: bars,
              firstDate: firstDate,
              showAxes: showAxes,
              lineColor: scheme.primary,
              barColor: scheme.tertiary,
              gridColor: scheme.outlineVariant,
              textColor: scheme.onSurfaceVariant,
              forecastTint: scheme.secondaryContainer,
            ),
          ),
        ),
      ),
    );
  }
}

class _TimeSeriesPainter extends CustomPainter {
  _TimeSeriesPainter({
    required this.line,
    required this.forecastFrom,
    required this.bars,
    required this.firstDate,
    required this.showAxes,
    required this.lineColor,
    required this.barColor,
    required this.gridColor,
    required this.textColor,
    required this.forecastTint,
  });

  final List<double> line;
  final int? forecastFrom;
  final List<double>? bars;
  final DateTime? firstDate;
  final bool showAxes;
  final Color lineColor;
  final Color barColor;
  final Color gridColor;
  final Color textColor;
  final Color forecastTint;

  @override
  void paint(Canvas canvas, Size size) {
    final barValues = bars ?? const <double>[];
    final n = math.max(line.length, barValues.length);
    if (n < 2) {
      return;
    }
    final left = showAxes ? 34.0 : 2.0;
    final bottom = showAxes ? 20.0 : 2.0;
    const top = 6.0;
    const right = 6.0;
    final w = size.width - left - right;
    final h = size.height - top - bottom;
    if (w <= 0 || h <= 0) {
      return;
    }
    double xAt(int i) => left + w * i / (n - 1);

    final maxLine = line.isEmpty ? 1.0 : line.reduce(math.max);
    final maxY = math.max(1.0, maxLine * 1.1);
    double yAt(double v) => top + h * (1 - v / maxY);
    final split = forecastFrom ?? n;

    // Faixa de previsão.
    if (split < n) {
      final rect = Rect.fromLTRB(xAt(split), top, size.width - right, top + h);
      canvas.drawRect(rect, Paint()..color = forecastTint.withAlpha(90));
      if (showAxes) {
        _text(canvas, 'previsão', Offset(xAt(split) + 3, top + 1), 60);
      }
    }

    // Grade e eixo Y.
    final grid = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    if (showAxes) {
      for (var g = 0; g <= 3; g++) {
        final y = top + h * g / 3;
        canvas.drawLine(Offset(left, y), Offset(size.width - right, y), grid);
        _text(canvas, fmtNum(maxY * (1 - g / 3)), Offset(0, y - 6), left - 4, TextAlign.right);
      }
    } else {
      canvas.drawLine(Offset(left, top + h), Offset(size.width - right, top + h), grid);
    }

    // Barras (série secundária).
    if (barValues.isNotEmpty) {
      final maxBar = math.max(1.0, barValues.reduce(math.max));
      final barW = math.max(1.5, w / n * 0.6);
      for (var i = 0; i < barValues.length; i++) {
        final bh = barValues[i] / maxBar * h * 0.4;
        final isForecast = i >= split;
        final paint = Paint()..color = barColor.withAlpha(isForecast ? 110 : 190);
        canvas.drawRect(
          Rect.fromLTWH(xAt(i) - barW / 2, top + h - bh, barW, bh),
          paint,
        );
      }
    }

    // Linha observada (sólida) com área, e parte prevista (tracejada).
    final solidEnd = math.min(line.length, split);
    if (solidEnd >= 2) {
      final path = Path()..moveTo(xAt(0), yAt(line[0]));
      for (var i = 1; i < solidEnd; i++) {
        path.lineTo(xAt(i), yAt(line[i]));
      }
      final area = Path.from(path)
        ..lineTo(xAt(solidEnd - 1), top + h)
        ..lineTo(xAt(0), top + h)
        ..close();
      canvas.drawPath(area, Paint()..color = lineColor.withAlpha(28));
      canvas.drawPath(
        path,
        Paint()
          ..color = lineColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..strokeJoin = StrokeJoin.round,
      );
    }
    if (line.length > split && split >= 1) {
      final path = Path()..moveTo(xAt(split - 1), yAt(line[split - 1]));
      for (var i = split; i < line.length; i++) {
        path.lineTo(xAt(i), yAt(line[i]));
      }
      canvas.drawPath(
        _dashed(path),
        Paint()
          ..color = lineColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2,
      );
    }
    if (solidEnd >= 1) {
      canvas.drawCircle(Offset(xAt(solidEnd - 1), yAt(line[solidEnd - 1])), 3.5, Paint()..color = lineColor);
    }

    // Eixo X.
    final start = firstDate;
    if (showAxes && start != null) {
      for (final i in <int>{0, (n - 1) ~/ 2, n - 1}) {
        final label = fmtDay(addDays(start, i));
        final dx = (xAt(i) - 18).clamp(0.0, size.width - 36).toDouble();
        _text(canvas, label, Offset(dx, size.height - 14), 36, TextAlign.center);
      }
    }
  }

  Path _dashed(Path source) {
    final out = Path();
    for (final metric in source.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        out.addPath(metric.extractPath(d, math.min(d + 6, metric.length)), Offset.zero);
        d += 10;
      }
    }
    return out;
  }

  void _text(Canvas canvas, String s, Offset o, double width, [TextAlign align = TextAlign.left]) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: TextStyle(color: textColor, fontSize: 10)),
      textDirection: TextDirection.ltr,
      textAlign: align,
    )..layout(minWidth: width, maxWidth: width);
    tp.paint(canvas, o);
  }

  @override
  bool shouldRepaint(covariant _TimeSeriesPainter old) => true;
}

/// Legenda simples (observado / previsto / barras).
class ChartLegend extends StatelessWidget {
  const ChartLegend({super.key, required this.items});

  final List<(String, IconData)> items;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 16,
      runSpacing: 4,
      children: [
        for (final item in items)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ExcludeSemantics(child: Icon(item.$2, size: 16, color: scheme.onSurfaceVariant)),
              const SizedBox(width: 4),
              Text(item.$1, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
      ],
    );
  }
}

class BarItem {
  const BarItem({
    required this.label,
    required this.value,
    required this.valueLabel,
    this.color,
    this.onTap,
  });

  final String label;
  final double value;
  final String valueLabel;
  final Color? color;
  final VoidCallback? onTap;
}

/// Lista de barras horizontais animadas.
class BarList extends StatelessWidget {
  const BarList({super.key, required this.items, this.maxValue});

  final List<BarItem> items;
  final double? maxValue;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final max = maxValue ?? items.fold<double>(1.0, (m, i) => math.max(m, i.value));
    return Column(
      children: [
        for (final item in items)
          Semantics(
            label: '${item.label}: ${item.valueLabel}',
            button: item.onTap != null,
            excludeSemantics: true,
            onTap: item.onTap,
            child: InkWell(
              onTap: item.onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(item.label, style: Theme.of(context).textTheme.bodyMedium)),
                        Text(
                          item.valueLabel,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: Stats.clamp(item.value / max, 0.0, 1.0)),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutCubic,
                      builder: (context, v, _) => ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: v,
                          minHeight: 10,
                          backgroundColor: scheme.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation<Color>(item.color ?? scheme.primary),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

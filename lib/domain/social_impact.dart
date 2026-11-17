import 'package:territory_predictive_insights/domain/alert.dart';
import 'package:territory_predictive_insights/domain/entities.dart';

/// Indicadores de benefício social derivados dos dados e das decisões humanas.
class SocialImpact {
  const SocialImpact({
    required this.slaRate,
    required this.slaRatePrev,
    required this.avgHours,
    required this.avgHoursPrev,
    required this.equityGapPp,
    required this.bestRegion,
    required this.worstRegion,
    required this.populationReviewed,
    required this.populationTotal,
  });

  final double slaRate;
  final double? slaRatePrev;
  final double avgHours;
  final double? avgHoursPrev;

  /// Diferença, em pontos percentuais, entre a melhor e a pior região em prazo.
  final double equityGapPp;
  final Region? bestRegion;
  final Region? worstRegion;

  /// População das regiões com ao menos um alerta já revisado por um gestor.
  final int populationReviewed;
  final int populationTotal;

  static SocialImpact compute(
    TerritoryData data,
    List<PredictiveAlert> alerts,
    Map<String, HumanDecision> decisions,
  ) {
    final cur = data.slaStats(lastDays: 28);
    final prev = data.slaStats(lastDays: 28, skipDays: 28);

    Region? best;
    Region? worst;
    double? bestRate;
    double? worstRate;
    for (final r in data.regions) {
      final rate = data.slaStats(regionId: r.id, lastDays: 28).rate;
      if (rate == null) {
        continue;
      }
      if (bestRate == null || rate > bestRate) {
        bestRate = rate;
        best = r;
      }
      if (worstRate == null || rate < worstRate) {
        worstRate = rate;
        worst = r;
      }
    }

    final reviewedRegions = <String>{
      for (final a in alerts)
        if (decisions.containsKey(a.key)) a.region.id,
    };
    var populationReviewed = 0;
    var populationTotal = 0;
    for (final r in data.regions) {
      populationTotal += r.population;
      if (reviewedRegions.contains(r.id)) {
        populationReviewed += r.population;
      }
    }

    return SocialImpact(
      slaRate: cur.rate ?? 0.0,
      slaRatePrev: prev.rate,
      avgHours: cur.avgHours ?? 0.0,
      avgHoursPrev: prev.avgHours,
      equityGapPp: (bestRate != null && worstRate != null)
          ? (bestRate - worstRate) * 100
          : 0.0,
      bestRegion: best,
      worstRegion: worst,
      populationReviewed: populationReviewed,
      populationTotal: populationTotal,
    );
  }
}

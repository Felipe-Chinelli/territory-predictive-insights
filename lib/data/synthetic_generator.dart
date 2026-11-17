import 'dart:math' as math;

import 'package:territory_predictive_insights/core/utils/dates.dart';
import 'package:territory_predictive_insights/data/territory_catalog.dart';
import 'package:territory_predictive_insights/domain/entities.dart';
import 'package:territory_predictive_insights/domain/stats.dart';

double _gauss(math.Random r) {
  final u1 = 1 - r.nextDouble();
  final u2 = r.nextDouble();
  return math.sqrt(-2 * math.log(u1)) * math.cos(2 * math.pi * u2);
}

/// Clima sintético, usado apenas quando não há internet nem cache.
class SyntheticWeather {
  const SyntheticWeather._();

  static List<WeatherDay> generate(DateTime now, {int pastDays = 60, int futureDays = 7}) {
    final today = dayOnly(now);
    final days = <WeatherDay>[];
    for (var k = -pastDays; k < futureDays; k++) {
      final date = addDays(today, k);
      final rng = math.Random(epochDay(date) * 131 + 17);
      final wet = rng.nextDouble() < 0.34;
      var rain = wet ? -math.log(1 - rng.nextDouble()) * 9.0 : 0.0;
      // Cenário de demonstração: frente fria nos próximos dias.
      if (k == 2) {
        rain = 28.0;
      } else if (k == 3) {
        rain = 41.0;
      }
      days.add(
        WeatherDay(
          date: date,
          rainMm: rain,
          tempMaxC: 24 + 4 * math.sin(k / 3.0) + rng.nextDouble() * 2,
          isForecast: k >= 0,
        ),
      );
    }
    return days;
  }
}

/// Gera chamados sintéticos (determinísticos) coerentes com o clima informado.
///
/// Os dados simulam a estrutura de uma central de atendimento 156:
/// sazonalidade semanal, efeito da chuva, tendências locais e prazos (SLA).
class SyntheticDemandGenerator {
  const SyntheticDemandGenerator();

  static const _baseRate = <ServiceCategory, double>{
    ServiceCategory.lighting: 1.1,
    ServiceCategory.waste: 2.2,
    ServiceCategory.roads: 1.0,
    ServiceCategory.health: 1.6,
    ServiceCategory.drainage: 0.9,
  };

  static const _rainBeta = <ServiceCategory, double>{
    ServiceCategory.lighting: 0.003,
    ServiceCategory.waste: 0.004,
    ServiceCategory.roads: 0.01,
    ServiceCategory.health: 0.0,
    ServiceCategory.drainage: 0.015,
  };

  // Seg..Dom
  static const _weekday = [1.15, 1.15, 1.1, 1.1, 1.05, 0.8, 0.6];

  // Crescimento diário nas últimas 3 semanas (cenários de demonstração).
  static const _growth = <String, double>{
    'norte|drainage': 0.035,
    'jardim|waste': 0.02,
    'centro|roads': 0.018,
    'centro|lighting': -0.004,
  };

  static const _regionSla = <String, double>{
    'centro': 0.90,
    'norte': 0.80,
    'jardim': 0.84,
    'industrial': 0.88,
    'rural': 0.80,
  };

  static const _slaPenalty = <String, double>{
    'rural|health': 0.20,
    'norte|drainage': 0.12,
  };

  List<DailyRecord> generate(List<WeatherDay> past) {
    final n = past.length;
    final records = <DailyRecord>[];
    final regions = TerritoryCatalog.regions;
    for (var i = 0; i < n; i++) {
      final day = past[i];
      final epoch = epochDay(day.date);
      final rain = math.min(day.rainMm, 50.0);
      for (var ri = 0; ri < regions.length; ri++) {
        final region = regions[ri];
        for (var ci = 0; ci < ServiceCategory.values.length; ci++) {
          final category = ServiceCategory.values[ci];
          final key = '${region.id}|${category.name}';
          final rng = math.Random(epoch * 1009 + ri * 31 + ci * 7);
          final base = region.population / 10000 * _baseRate[category]!;
          final growth = (_growth[key] ?? 0.0) * math.max(0, i - (n - 21));
          final mean = base *
              _weekday[day.date.weekday - 1] *
              (1 + _rainBeta[category]! * rain) *
              (1 + growth);
          final opened = math.max(0, (mean + math.sqrt(mean) * _gauss(rng)).round());

          final rng2 = math.Random(epoch * 7919 + ri * 53 + ci * 11);
          final pSla = Stats.clamp(
            _regionSla[region.id]! - (_slaPenalty[key] ?? 0.0) + 0.03 * _gauss(rng2),
            0.05,
            0.99,
          );
          final resolved = math.min(
            opened,
            math.max(
              0,
              (opened * pSla + _gauss(rng2) * math.sqrt(opened * pSla * (1 - pSla))).round(),
            ),
          );
          final hours = category.slaHours *
              (0.45 + (1 - pSla) * 1.6) *
              (1 + 0.05 * _gauss(rng2));
          records.add(
            DailyRecord(
              date: day.date,
              regionId: region.id,
              category: category,
              opened: opened,
              resolvedInSla: resolved,
              avgResponseHours: hours,
            ),
          );
        }
      }
    }
    return records;
  }
}

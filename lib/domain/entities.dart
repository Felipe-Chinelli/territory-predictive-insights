import 'dart:math' as math;

/// Categorias de serviço público monitoradas.
enum ServiceCategory {
  lighting('Iluminação pública', 72),
  waste('Coleta de resíduos', 48),
  roads('Vias e pavimentação', 120),
  health('Saúde (UBS)', 48),
  drainage('Drenagem e esgoto', 72);

  const ServiceCategory(this.label, this.slaHours);

  final String label;

  /// Prazo-alvo (SLA) de atendimento, em horas.
  final int slaHours;
}

class Region {
  const Region({
    required this.id,
    required this.name,
    required this.population,
    required this.profile,
  });

  final String id;
  final String name;
  final int population;
  final String profile;
}

enum Severity {
  low('Atenção'),
  medium('Moderado'),
  high('Crítico');

  const Severity(this.label);

  final String label;

  int get rank => index;
}

enum Urgency {
  low('Baixa'),
  medium('Média'),
  high('Alta');

  const Urgency(this.label);

  final String label;
}

enum WeatherOrigin { live, cache, synthetic }

class WeatherDay {
  const WeatherDay({
    required this.date,
    required this.rainMm,
    required this.tempMaxC,
    required this.isForecast,
  });

  final DateTime date;
  final double rainMm;
  final double tempMaxC;
  final bool isForecast;
}

/// Chamados de um dia, para uma região e categoria.
class DailyRecord {
  const DailyRecord({
    required this.date,
    required this.regionId,
    required this.category,
    required this.opened,
    required this.resolvedInSla,
    required this.avgResponseHours,
  });

  final DateTime date;
  final String regionId;
  final ServiceCategory category;
  final int opened;
  final int resolvedInSla;
  final double avgResponseHours;
}

class SlaStats {
  const SlaStats({
    required this.opened,
    required this.inSla,
    required this.hourSum,
  });

  final int opened;
  final int inSla;
  final double hourSum;

  double? get rate => opened == 0 ? null : inSla / opened;

  double? get avgHours => opened == 0 ? null : hourSum / opened;
}

/// Conjunto de dados do território: clima + demanda por serviços.
class TerritoryData {
  TerritoryData({
    required this.regions,
    required this.records,
    required List<WeatherDay> weather,
    required this.weatherOrigin,
    this.weatherFetchedAt,
  })  : pastWeather = (weather.where((w) => !w.isForecast).toList()
          ..sort((a, b) => a.date.compareTo(b.date))),
        futureWeather = (weather.where((w) => w.isForecast).toList()
          ..sort((a, b) => a.date.compareTo(b.date)));

  final List<Region> regions;
  final List<DailyRecord> records;
  final List<WeatherDay> pastWeather;
  final List<WeatherDay> futureWeather;
  final WeatherOrigin weatherOrigin;
  final DateTime? weatherFetchedAt;

  List<DateTime> get dates => [for (final w in pastWeather) w.date];

  List<DateTime> get futureDates => [for (final w in futureWeather) w.date];

  List<double> get rainHistory => [for (final w in pastWeather) w.rainMm];

  List<double> get rainForecast => [for (final w in futureWeather) w.rainMm];

  Region regionById(String id) => regions.firstWhere((r) => r.id == id);

  /// Chamados abertos por dia (alinhado a [dates]).
  List<double> series({ServiceCategory? category, String? regionId}) {
    final byDate = <DateTime, double>{};
    for (final r in records) {
      if (category != null && r.category != category) {
        continue;
      }
      if (regionId != null && r.regionId != regionId) {
        continue;
      }
      byDate[r.date] = (byDate[r.date] ?? 0.0) + r.opened;
    }
    return [for (final w in pastWeather) byDate[w.date] ?? 0.0];
  }

  /// Agrega chamados/SLA em uma janela de [lastDays] dias, pulando [skipDays] finais.
  SlaStats slaStats({
    ServiceCategory? category,
    String? regionId,
    required int lastDays,
    int skipDays = 0,
  }) {
    final end = pastWeather.length - skipDays;
    final start = math.max(0, end - lastDays);
    if (end <= start) {
      return const SlaStats(opened: 0, inSla: 0, hourSum: 0);
    }
    final window = <DateTime>{
      for (var i = start; i < end; i++) pastWeather[i].date,
    };
    var opened = 0;
    var inSla = 0;
    var hours = 0.0;
    for (final r in records) {
      if (!window.contains(r.date)) {
        continue;
      }
      if (category != null && r.category != category) {
        continue;
      }
      if (regionId != null && r.regionId != regionId) {
        continue;
      }
      opened += r.opened;
      inSla += r.resolvedInSla;
      hours += r.avgResponseHours * r.opened;
    }
    return SlaStats(opened: opened, inSla: inSla, hourSum: hours);
  }
}

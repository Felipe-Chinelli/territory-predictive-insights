import 'package:territory_predictive_insights/data/synthetic_generator.dart';
import 'package:territory_predictive_insights/data/territory_catalog.dart';
import 'package:territory_predictive_insights/data/weather_source.dart';
import 'package:territory_predictive_insights/domain/entities.dart';

class DataLoadException implements Exception {
  const DataLoadException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Combina clima (API real, com cache) e demanda (sintética e determinística).
class TerritoryRepository {
  TerritoryRepository({
    required this.weatherSource,
    this.generator = const SyntheticDemandGenerator(),
    this.simulatedLatency = const Duration(milliseconds: 700),
  });

  final WeatherSource weatherSource;
  final SyntheticDemandGenerator generator;
  final Duration simulatedLatency;

  Future<TerritoryData> load({bool forceFailure = false}) async {
    await Future<void>.delayed(simulatedLatency);
    if (forceFailure) {
      throw const DataLoadException(
        'Falha simulada de rede. Desative a simulação em Ajustes e tente novamente.',
      );
    }
    final bundle = await weatherSource.fetch(DateTime.now());
    final past = bundle.days.where((d) => !d.isForecast).toList();
    final records = generator.generate(past);
    return TerritoryData(
      regions: TerritoryCatalog.regions,
      records: records,
      weather: bundle.days,
      weatherOrigin: bundle.origin,
      weatherFetchedAt: bundle.fetchedAt,
    );
  }
}

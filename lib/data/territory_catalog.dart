import 'package:territory_predictive_insights/domain/entities.dart';

/// Território fictício usado na demonstração (dados sintéticos).
class TerritoryCatalog {
  const TerritoryCatalog._();

  static const String name = 'Aurora do Vale';

  static const List<Region> regions = [
    Region(id: 'centro', name: 'Centro', population: 42000, profile: 'Urbana central, comércio e serviços'),
    Region(id: 'norte', name: 'Vila Norte', population: 68000, profile: 'Urbana densa, encostas e córregos'),
    Region(id: 'jardim', name: 'Jardim das Flores', population: 55000, profile: 'Residencial em expansão'),
    Region(id: 'industrial', name: 'Parque Industrial', population: 23000, profile: 'Industrial e logística'),
    Region(id: 'rural', name: 'Zona Rural Sul', population: 18000, profile: 'Rural, estradas vicinais'),
  ];

  static int get totalPopulation =>
      regions.fold(0, (sum, r) => sum + r.population);
}

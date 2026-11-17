import 'package:material_ui/material_ui.dart';
import 'package:territory_predictive_insights/domain/entities.dart';

IconData iconForCategory(ServiceCategory c) => switch (c) {
      ServiceCategory.lighting => Icons.lightbulb_outline,
      ServiceCategory.waste => Icons.delete_outline,
      ServiceCategory.roads => Icons.add_road,
      ServiceCategory.health => Icons.local_hospital_outlined,
      ServiceCategory.drainage => Icons.water_drop_outlined,
    };

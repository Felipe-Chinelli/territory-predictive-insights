import 'package:territory_predictive_insights/domain/entities.dart';

/// Ocorrência registrada pelo cidadão. Não guarda nome, contato nem endereço.
class Occurrence {
  const Occurrence({
    required this.id,
    required this.createdAt,
    required this.regionId,
    required this.category,
    required this.urgency,
    required this.description,
    required this.redacted,
  });

  final String id;
  final DateTime createdAt;
  final String regionId;
  final ServiceCategory category;
  final Urgency urgency;
  final String description;

  /// Indica que dados pessoais foram removidos do texto original.
  final bool redacted;

  Map<String, dynamic> toJson() => {
        'id': id,
        'at': createdAt.toIso8601String(),
        'region': regionId,
        'category': category.name,
        'urgency': urgency.name,
        'description': description,
        'redacted': redacted,
      };

  factory Occurrence.fromJson(Map<String, dynamic> json) => Occurrence(
        id: json['id'] as String,
        createdAt: DateTime.tryParse(json['at'] as String? ?? '') ?? DateTime.now(),
        regionId: json['region'] as String,
        category: ServiceCategory.values.firstWhere(
          (c) => c.name == json['category'],
          orElse: () => ServiceCategory.roads,
        ),
        urgency: Urgency.values.firstWhere(
          (u) => u.name == json['urgency'],
          orElse: () => Urgency.medium,
        ),
        description: json['description'] as String? ?? '',
        redacted: json['redacted'] as bool? ?? false,
      );
}

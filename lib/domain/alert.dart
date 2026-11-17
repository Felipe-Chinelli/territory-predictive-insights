import 'package:territory_predictive_insights/core/utils/formatters.dart';
import 'package:territory_predictive_insights/domain/entities.dart';

enum AlertKind {
  forecast('Previsão de demanda'),
  sla('Regra de prazo (SLA)');

  const AlertKind(this.label);

  final String label;
}

enum ConfidenceLevel {
  low('baixa'),
  medium('média'),
  high('alta');

  const ConfidenceLevel(this.label);

  final String label;
}

ConfidenceLevel confidenceLevelOf(double c) {
  if (c >= 0.75) {
    return ConfidenceLevel.high;
  }
  if (c >= 0.5) {
    return ConfidenceLevel.medium;
  }
  return ConfidenceLevel.low;
}

enum DecisionStatus {
  accepted('Aceito para análise'),
  dismissed('Descartado');

  const DecisionStatus(this.label);

  final String label;
}

/// Limiares configuráveis pelo gestor.
class AlertThresholds {
  const AlertThresholds({
    this.attentionPct = 20,
    this.criticalPct = 40,
    this.slaMinPct = 70,
  });

  static const AlertThresholds defaults = AlertThresholds();

  final int attentionPct;
  final int criticalPct;
  final int slaMinPct;

  AlertThresholds copyWith({int? attentionPct, int? criticalPct, int? slaMinPct}) =>
      AlertThresholds(
        attentionPct: attentionPct ?? this.attentionPct,
        criticalPct: criticalPct ?? this.criticalPct,
        slaMinPct: slaMinPct ?? this.slaMinPct,
      );

  Map<String, dynamic> toJson() => {
        'attention': attentionPct,
        'critical': criticalPct,
        'slaMin': slaMinPct,
      };

  factory AlertThresholds.fromJson(Map<String, dynamic> json) => AlertThresholds(
        attentionPct: (json['attention'] as num?)?.toInt() ?? 20,
        criticalPct: (json['critical'] as num?)?.toInt() ?? 40,
        slaMinPct: (json['slaMin'] as num?)?.toInt() ?? 70,
      );

  @override
  bool operator ==(Object other) =>
      other is AlertThresholds &&
      other.attentionPct == attentionPct &&
      other.criticalPct == criticalPct &&
      other.slaMinPct == slaMinPct;

  @override
  int get hashCode => Object.hash(attentionPct, criticalPct, slaMinPct);
}

class PredictiveAlert {
  const PredictiveAlert({
    required this.id,
    required this.kind,
    required this.region,
    required this.category,
    required this.severity,
    required this.confidence,
    required this.issuedOn,
    required this.headline,
    required this.summary,
    required this.evidence,
    required this.limitations,
    required this.suggestedAction,
    this.forecastWeek,
    this.baselineWeek,
    this.deltaPct,
    this.slaRate,
    this.wape,
  });

  final String id;
  final AlertKind kind;
  final Region region;
  final ServiceCategory category;
  final Severity severity;

  /// Confiança de 0 a 1.
  final double confidence;
  final DateTime issuedOn;
  final String headline;
  final String summary;
  final List<String> evidence;
  final List<String> limitations;
  final String suggestedAction;
  final double? forecastWeek;
  final double? baselineWeek;
  final double? deltaPct;
  final double? slaRate;
  final double? wape;

  /// Identifica o alerta num dia específico (decisões humanas são por dia).
  String get key => '$id@${isoDay(issuedOn)}';

  ConfidenceLevel get confidenceLevel => confidenceLevelOf(confidence);
}

/// Registro da decisão humana sobre um alerta.
class HumanDecision {
  const HumanDecision({
    required this.alertKey,
    required this.alertId,
    required this.status,
    required this.decidedAt,
    this.note,
  });

  final String alertKey;
  final String alertId;
  final DecisionStatus status;
  final DateTime decidedAt;
  final String? note;

  Map<String, dynamic> toJson() => {
        'key': alertKey,
        'id': alertId,
        'status': status.name,
        'note': note,
        'at': decidedAt.toIso8601String(),
      };

  factory HumanDecision.fromJson(Map<String, dynamic> json) => HumanDecision(
        alertKey: json['key'] as String,
        alertId: json['id'] as String,
        status: DecisionStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => DecisionStatus.dismissed,
        ),
        note: json['note'] as String?,
        decidedAt: DateTime.tryParse(json['at'] as String? ?? '') ?? DateTime.now(),
      );
}

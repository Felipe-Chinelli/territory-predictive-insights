import 'package:territory_predictive_insights/core/utils/formatters.dart';
import 'package:territory_predictive_insights/domain/alert.dart';
import 'package:territory_predictive_insights/domain/entities.dart';
import 'package:territory_predictive_insights/domain/forecaster.dart';
import 'package:territory_predictive_insights/domain/stats.dart';

/// Gera alertas a partir de previsões (demanda) e regras (prazo de atendimento).
///
/// Todo alerta é apenas uma sugestão: a decisão final é sempre humana.
class AlertEngine {
  const AlertEngine({
    this.forecaster = const DemandForecaster(),
    this.minWeeklyVolume = 20,
    this.minSlaSample = 20,
  });

  final DemandForecaster forecaster;
  final double minWeeklyVolume;
  final int minSlaSample;

  List<PredictiveAlert> generate(TerritoryData data, AlertThresholds thresholds) {
    if (data.pastWeather.length < 28 || data.futureWeather.isEmpty) {
      return const [];
    }
    final issuedOn = data.futureWeather.first.date;
    final alerts = <PredictiveAlert>[];
    for (final region in data.regions) {
      for (final category in ServiceCategory.values) {
        final f = _forecastAlert(data, region, category, thresholds, issuedOn);
        if (f != null) {
          alerts.add(f);
        }
        final s = _slaAlert(data, region, category, thresholds, issuedOn);
        if (s != null) {
          alerts.add(s);
        }
      }
    }
    alerts.sort((a, b) {
      final bySeverity = b.severity.rank.compareTo(a.severity.rank);
      return bySeverity != 0 ? bySeverity : b.confidence.compareTo(a.confidence);
    });
    return alerts;
  }

  PredictiveAlert? _forecastAlert(
    TerritoryData data,
    Region region,
    ServiceCategory category,
    AlertThresholds t,
    DateTime issuedOn,
  ) {
    final series = data.series(category: category, regionId: region.id);
    final baselineWeek = Stats.sum(series.sublist(series.length - 28)) / 4;
    if (baselineWeek < minWeeklyVolume) {
      return null;
    }
    final result = data.forecastDemand(
      category: category,
      regionId: region.id,
      forecaster: forecaster,
    );
    final forecastWeek = result.total;
    final deltaPct = (forecastWeek - baselineWeek) / baselineWeek * 100;
    if (deltaPct < t.attentionPct) {
      return null;
    }
    final severity = deltaPct >= t.criticalPct
        ? Severity.high
        : deltaPct >= (t.attentionPct + t.criticalPct) / 2
            ? Severity.medium
            : Severity.low;
    final confidence = result.confidence;
    final rainWeek = Stats.sum(data.rainForecast.take(7));

    final evidence = <String>[
      'Previsão de ${fmtInt(forecastWeek)} chamados nos próximos 7 dias, contra média de '
          '${fmtInt(baselineWeek)} por semana nas últimas 4 semanas (${fmtPct(deltaPct, sign: true)}).',
    ];
    if (result.dailyTrendPct.abs() >= 0.5) {
      evidence.add(
        'Tendência recente de ${fmtPct(result.dailyTrendPct, decimals: 1, sign: true)} '
        'ao dia na demanda desta região e categoria.',
      );
    }
    if (result.rainSensitivity > 0.003 && rainWeek >= 10) {
      evidence.add(
        'Chuva prevista de ${fmtNum(rainWeek)} mm nos próximos 7 dias; historicamente, '
        'cada 10 mm está associado a ${fmtPct(result.rainSensitivity * 1000, sign: true)} de chamados.',
      );
    }
    evidence.add(
      result.reliableBacktest
          ? 'Backtest nos últimos 7 dias: erro (WAPE) de ${fmtPct(result.wape * 100)}, '
              'o que resulta em confiança de ${fmtPct(confidence * 100)}.'
          : 'Histórico insuficiente para backtest; a confiança foi zerada por precaução.',
    );

    final limitations = <String>[
      if (confidence < 0.6)
        'Confiança ${confidenceLevelOf(confidence).label}: a variação diária é alta em relação ao volume. '
            'Trate como indício, não como fato.',
      if (baselineWeek < 25)
        'Volume semanal pequeno (${fmtInt(baselineWeek)} chamados): poucas ocorrências deixam a previsão instável.',
      if (rainWeek > 0)
        'A previsão de chuva tem incerteza que cresce a cada dia, e o modelo assume que a relação '
            'chuva → demanda continua igual.',
      'Modelo simples (tendência linear, sazonalidade semanal e chuva): não captura feriados, obras ou campanhas.',
      'Os dados de demanda são sintéticos (demonstração acadêmica) e não representam um município real.',
      'Viés de subnotificação: regiões com menor acesso ao canal de atendimento registram menos chamados '
          'do que a necessidade real${region.id == 'rural' ? ' (especialmente na zona rural)' : ''}.',
    ];

    return PredictiveAlert(
      id: 'forecast_${region.id}_${category.name}',
      kind: AlertKind.forecast,
      region: region,
      category: category,
      severity: severity,
      confidence: confidence,
      issuedOn: issuedOn,
      headline: '${category.label}: demanda deve subir ${fmtPct(deltaPct)} em ${region.name}',
      summary:
          'Previsão de ${fmtInt(forecastWeek)} chamados nos próximos 7 dias (média recente: ${fmtInt(baselineWeek)}/semana).',
      evidence: evidence,
      limitations: limitations,
      suggestedAction: _forecastAction(category),
      forecastWeek: forecastWeek,
      baselineWeek: baselineWeek,
      deltaPct: deltaPct,
      wape: result.reliableBacktest ? result.wape : null,
    );
  }

  PredictiveAlert? _slaAlert(
    TerritoryData data,
    Region region,
    ServiceCategory category,
    AlertThresholds t,
    DateTime issuedOn,
  ) {
    final cur = data.slaStats(category: category, regionId: region.id, lastDays: 14);
    final rate = cur.rate;
    if (rate == null || cur.opened < minSlaSample) {
      return null;
    }
    final pct = rate * 100;
    if (pct >= t.slaMinPct) {
      return null;
    }
    final prev = data.slaStats(
      category: category,
      regionId: region.id,
      lastDays: 14,
      skipDays: 14,
    );
    final gap = t.slaMinPct - pct;
    final severity = gap >= 15
        ? Severity.high
        : gap >= 7
            ? Severity.medium
            : Severity.low;
    final confidence = Stats.clamp(cur.opened / 80, 0.2, 0.9);

    final evidence = <String>[
      'Apenas ${fmtPct(pct)} dos ${fmtInt(cur.opened)} chamados dos últimos 14 dias foram resolvidos '
          'no prazo (meta mínima configurada: ${t.slaMinPct}%).',
      if (prev.rate != null) 'Nos 14 dias anteriores, o índice foi de ${fmtPct(prev.rate! * 100)}.',
      'Tempo médio de resposta: ${fmtInt(cur.avgHours ?? 0)} h (prazo da categoria: ${category.slaHours} h).',
    ];
    final limitations = <String>[
      'Chamados recentes ainda em aberto podem ser concluídos no prazo; o índice pode estar subestimado.',
      'Amostra de ${fmtInt(cur.opened)} chamados: a confiança cresce com o volume observado.',
      'O prazo mede velocidade, não a qualidade do atendimento.',
      'Os dados de demanda são sintéticos (demonstração acadêmica) e não representam um município real.',
    ];

    return PredictiveAlert(
      id: 'sla_${region.id}_${category.name}',
      kind: AlertKind.sla,
      region: region,
      category: category,
      severity: severity,
      confidence: confidence,
      issuedOn: issuedOn,
      headline: '${category.label}: prazo de atendimento abaixo da meta em ${region.name}',
      summary: '${fmtPct(pct)} dos chamados resolvidos no prazo (meta: ${t.slaMinPct}%).',
      evidence: evidence,
      limitations: limitations,
      suggestedAction:
          'Avaliar as causas do atraso (equipe, material, fluxo) e se a meta de prazo é adequada à realidade da região.',
      slaRate: rate,
    );
  }

  static String _forecastAction(ServiceCategory c) => switch (c) {
        ServiceCategory.lighting =>
          'Avaliar reforço da equipe de manutenção de iluminação e priorizar vistorias preventivas.',
        ServiceCategory.waste =>
          'Avaliar ajuste de rotas e frequência de coleta e revisar pontos de descarte irregular.',
        ServiceCategory.roads =>
          'Avaliar vistoria preventiva de vias e programação de reparos antes do pico previsto.',
        ServiceCategory.health =>
          'Avaliar ampliação de horários de agendamento e remanejamento de equipes nas UBS.',
        ServiceCategory.drainage =>
          'Avaliar limpeza preventiva de bocas de lobo e galerias e prontidão das equipes de drenagem.',
      };
}

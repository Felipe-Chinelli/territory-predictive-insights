import 'package:material_ui/material_ui.dart';
import 'package:territory_predictive_insights/ui/widgets/app_card.dart';
import 'package:territory_predictive_insights/ui/widgets/banners.dart';
import 'package:territory_predictive_insights/ui/widgets/responsive_body.dart';
import 'package:territory_predictive_insights/ui/widgets/section_header.dart';

/// Metodologia, métricas, vieses e condições de não confiabilidade.
class MethodologyScreen extends StatelessWidget {
  const MethodologyScreen({super.key});

  static const _sections = <(String, List<String>)>[
    (
      'Origem dos dados',
      [
        'Demanda por serviços: dados sintéticos e determinísticos que simulam uma central de atendimento 156 '
            '(sazonalidade semanal, efeito da chuva e tendências locais). Não representam um município real.',
        'Clima: API pública Open-Meteo (chuva e temperatura), com cache local. Sem internet e sem cache, o app usa clima simulado e avisa.',
        'Ocorrências do cidadão: salvas apenas no aparelho, sem identificação pessoal.',
      ],
    ),
    (
      'Como os alertas são gerados',
      [
        'Previsão de demanda: tendência linear + sazonalidade por dia da semana + efeito da chuva, ajustados nas últimas 5 semanas por região e serviço.',
        'Um alerta de previsão surge quando a previsão dos próximos 7 dias supera a média semanal das últimas 4 semanas acima do limiar configurado.',
        'Regra de prazo (SLA): alerta quando a parcela de chamados resolvidos no prazo, nos últimos 14 dias, fica abaixo da meta mínima.',
      ],
    ),
    (
      'Métricas',
      [
        'WAPE (erro percentual absoluto ponderado) em backtest: o modelo "prevê" os últimos 7 dias conhecidos e o erro é medido.',
        'Confiança = 1 − WAPE, limitada a 95%. Alertas de prazo usam o tamanho da amostra (máximo de 90%).',
        'Benefício social: chamados no prazo, tempo médio de resposta, diferença de prazo entre regiões (equidade) e população em regiões com alerta revisado.',
      ],
    ),
    (
      'Limitações e vieses',
      [
        'Modelo simples: não captura feriados, obras, campanhas ou eventos extremos.',
        'Subnotificação: regiões com menos acesso ao canal tendem a registrar menos chamados que a necessidade real.',
        'Volumes pequenos geram previsões instáveis; por isso há volume mínimo para gerar alertas.',
        'Correlação entre chuva e chamados não prova causalidade.',
      ],
    ),
    (
      'Quando a previsão NÃO é confiável',
      [
        'Confiança baixa (abaixo de 50%) ou histórico menor que 3 semanas.',
        'Previsão de chuva muito incerta ou mudança brusca de comportamento (ex.: nova obra ou campanha).',
        'Regiões ou serviços com poucas ocorrências por semana.',
      ],
    ),
    (
      'Decisão humana e privacidade',
      [
        'Nenhuma ação é tomada automaticamente. O gestor aceita ou descarta cada alerta, e a decisão fica registrada.',
        'Não coletamos nome, CPF, telefone, e-mail nem localização exata. Textos livres têm dados pessoais removidos antes de salvar.',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Metodologia e limitações')),
      body: ResponsiveBody(
        children: [
          const HumanDecisionBanner(),
          for (final section in _sections) ...[
            SectionHeader(title: section.$1),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final item in section.$2)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ExcludeSemantics(
                            child: Icon(Icons.circle, size: 8, color: theme.colorScheme.primary),
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: Text(item)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

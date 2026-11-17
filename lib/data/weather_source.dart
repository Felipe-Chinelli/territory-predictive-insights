import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:territory_predictive_insights/core/utils/dates.dart';
import 'package:territory_predictive_insights/core/utils/formatters.dart';
import 'package:territory_predictive_insights/data/local_store.dart';
import 'package:territory_predictive_insights/data/synthetic_generator.dart';
import 'package:territory_predictive_insights/domain/entities.dart';

class WeatherBundle {
  const WeatherBundle({required this.days, required this.origin, this.fetchedAt});

  final List<WeatherDay> days;
  final WeatherOrigin origin;
  final DateTime? fetchedAt;
}

/// Clima real via Open-Meteo (API pública, sem chave). Ordem de tentativa:
/// internet → cache local → clima sintético.
class WeatherSource {
  WeatherSource({required this.store, http.Client? client})
      : _client = client ?? http.Client();

  final LocalStore store;
  final http.Client _client;

  // Referência climática: região metropolitana de São Paulo.
  static const double latitude = -23.55;
  static const double longitude = -46.63;

  Future<WeatherBundle> fetch(DateTime now) async {
    try {
      final live = await _fetchLive(now);
      await store.saveWeatherCache(_toJson(live));
      return live;
    } catch (_) {
      // Sem internet ou resposta inválida: cai para o cache e depois para o sintético.
    }
    final cached = _fromCache();
    if (cached != null) {
      return cached;
    }
    return WeatherBundle(
      days: SyntheticWeather.generate(now),
      origin: WeatherOrigin.synthetic,
    );
  }

  Future<WeatherBundle> _fetchLive(DateTime now) async {
    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': '$latitude',
      'longitude': '$longitude',
      'daily': 'precipitation_sum,temperature_2m_max',
      'past_days': '60',
      'forecast_days': '7',
      'timezone': 'America/Sao_Paulo',
    });
    final response = await _client.get(uri).timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) {
      throw const FormatException('Resposta inesperada da API de clima');
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final daily = json['daily'] as Map<String, dynamic>;
    final times = (daily['time'] as List).cast<String>();
    final rain = daily['precipitation_sum'] as List;
    final temp = daily['temperature_2m_max'] as List;
    final today = dayOnly(now);
    final days = <WeatherDay>[];
    for (var i = 0; i < times.length; i++) {
      final date = dayOnly(DateTime.parse(times[i]));
      days.add(
        WeatherDay(
          date: date,
          rainMm: (rain[i] as num?)?.toDouble() ?? 0.0,
          tempMaxC: (temp[i] as num?)?.toDouble() ?? 0.0,
          isForecast: !date.isBefore(today),
        ),
      );
    }
    if (!_isComplete(days)) {
      throw const FormatException('Série de clima incompleta');
    }
    return WeatherBundle(days: days, origin: WeatherOrigin.live, fetchedAt: now);
  }

  /// Exige histórico suficiente para o modelo (8 semanas) e dias de previsão.
  static bool _isComplete(List<WeatherDay> days) =>
      days.where((d) => !d.isForecast).length >= 56 &&
      days.where((d) => d.isForecast).length >= 7;

  Map<String, dynamic> _toJson(WeatherBundle b) => {
        'fetchedAt': b.fetchedAt?.toIso8601String(),
        'days': [
          for (final d in b.days)
            {'d': isoDay(d.date), 'r': d.rainMm, 't': d.tempMaxC, 'f': d.isForecast},
        ],
      };

  WeatherBundle? _fromCache() {
    final json = store.readWeatherCache();
    if (json == null) {
      return null;
    }
    try {
      final days = [
        for (final e in (json['days'] as List).cast<Map<String, dynamic>>())
          WeatherDay(
            date: dayOnly(DateTime.parse(e['d'] as String)),
            rainMm: (e['r'] as num).toDouble(),
            tempMaxC: (e['t'] as num).toDouble(),
            isForecast: e['f'] as bool,
          ),
      ];
      if (!_isComplete(days)) {
        return null;
      }
      return WeatherBundle(
        days: days,
        origin: WeatherOrigin.cache,
        fetchedAt: DateTime.tryParse(json['fetchedAt'] as String? ?? ''),
      );
    } catch (_) {
      return null;
    }
  }
}

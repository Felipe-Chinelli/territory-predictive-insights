/// Formatadores puros (sem Flutter) para números e datas em pt-BR.
String _two(int n) => n.toString().padLeft(2, '0');

String fmtNum(double v, {int decimals = 0}) =>
    v.toStringAsFixed(decimals).replaceAll('.', ',');

String fmtInt(num v) {
  final s = v.round().abs().toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) {
      buf.write('.');
    }
    buf.write(s[i]);
  }
  return '${v.round() < 0 ? '-' : ''}$buf';
}

/// Formata um percentual já em escala 0–100.
String fmtPct(double pct, {int decimals = 0, bool sign = false}) {
  final s = pct.abs().toStringAsFixed(decimals).replaceAll('.', ',');
  final prefix = pct < 0 ? '−' : (sign && pct > 0 ? '+' : '');
  return '$prefix$s%';
}

String fmtDay(DateTime d) => '${_two(d.day)}/${_two(d.month)}';

String fmtDate(DateTime d) => '${fmtDay(d)}/${d.year}';

String fmtDateTime(DateTime d) =>
    '${fmtDate(d)} ${_two(d.hour)}:${_two(d.minute)}';

String isoDay(DateTime d) => '${d.year}-${_two(d.month)}-${_two(d.day)}';

const _weekdays = ['seg', 'ter', 'qua', 'qui', 'sex', 'sáb', 'dom'];

String weekdayShort(DateTime d) => _weekdays[d.weekday - 1];

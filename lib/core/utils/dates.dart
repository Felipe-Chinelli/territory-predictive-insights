/// Utilidades de data seguras contra horário de verão (sempre meia-noite local).
DateTime dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

DateTime addDays(DateTime d, int n) => DateTime(d.year, d.month, d.day + n);

/// Número de dias desde 2020-01-01, usado como semente determinística.
int epochDay(DateTime d) =>
    DateTime.utc(d.year, d.month, d.day).difference(DateTime.utc(2020)).inDays;

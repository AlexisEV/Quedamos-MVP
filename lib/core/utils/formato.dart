import 'package:intl/intl.dart';

// montos en soles con punto decimal y coma de miles, como se usan en peru
final _soles = NumberFormat('#,##0.00', 'en_US');

String formatearSoles(num monto) => 'S/ ${_soles.format(monto)}';

// america/lima no tiene horario de verano desde 1994: utc menos 5 horas
const _desfaseLima = Duration(hours: -5);

const _dias = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];
const _meses = [
  'ene',
  'feb',
  'mar',
  'abr',
  'may',
  'jun',
  'jul',
  'ago',
  'sep',
  'oct',
  'nov',
  'dic',
];

// fecha y hora de pared en lima, como un datetime utc con los campos de lima
DateTime aHoraLima(DateTime instante) => instante.toUtc().add(_desfaseLima);

// instante utc que corresponde a una fecha y hora de pared elegida en lima
DateTime desdeHoraLima(int anio, int mes, int dia, int hora, int minuto) =>
    DateTime.utc(anio, mes, dia, hora, minuto).subtract(_desfaseLima);

// ejemplo: vie 23 oct 2026, 20:00 (hora de lima)
String formatearFechaHoraLima(DateTime instante) {
  final lima = aHoraLima(instante);
  final hora = lima.hour.toString().padLeft(2, '0');
  final minuto = lima.minute.toString().padLeft(2, '0');
  return '${_dias[lima.weekday - 1]} ${lima.day} ${_meses[lima.month - 1]} '
      '${lima.year}, $hora:$minuto';
}

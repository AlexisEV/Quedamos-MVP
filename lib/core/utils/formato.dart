import 'package:intl/intl.dart';

// montos en soles con punto decimal y coma de miles, como se usan en peru
final _soles = NumberFormat('#,##0.00', 'en_US');

String formatearSoles(num monto) => 'S/ ${_soles.format(monto)}';

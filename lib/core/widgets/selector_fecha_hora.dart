import 'package:flutter/material.dart';

import '../utils/formato.dart';

// fecha y hora de pared en lima con reloj de 12 h, aunque el telefono use otra zona
// devuelve el instante utc elegido o null si se cancela
Future<DateTime?> elegirFechaHoraLima(
  BuildContext context, {
  DateTime? actual,
  required String tituloFecha,
  required String tituloHora,
}) async {
  final hoyLima = aHoraLima(DateTime.now());
  final actualLima = actual == null ? null : aHoraLima(actual);
  final primerDia = DateTime(hoyLima.year, hoyLima.month, hoyLima.day);
  final inicial = actualLima == null
      ? primerDia
      : DateTime(actualLima.year, actualLima.month, actualLima.day);
  final fecha = await showDatePicker(
    context: context,
    initialDate: inicial.isBefore(primerDia) ? primerDia : inicial,
    firstDate: primerDia,
    lastDate: primerDia.add(const Duration(days: 365)),
    helpText: tituloFecha,
  );
  if (fecha == null || !context.mounted) return null;
  final hora = await showTimePicker(
    context: context,
    initialTime: actualLima == null
        ? const TimeOfDay(hour: 20, minute: 0)
        : TimeOfDay(hour: actualLima.hour, minute: actualLima.minute),
    helpText: tituloHora,
    // es usa 24 h; es_us mantiene los textos en espanol con reloj de 12 h y a.m./p.m.
    builder: (context, hijo) => Localizations.override(
      context: context,
      locale: const Locale('es', 'US'),
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
        child: hijo!,
      ),
    ),
  );
  if (hora == null) return null;
  return desdeHoraLima(
    fecha.year,
    fecha.month,
    fecha.day,
    hora.hour,
    hora.minute,
  );
}

import '../../../core/utils/formato.dart';
import '../../itinerario/data/actividad_model.dart';
import '../../itinerario/data/estimacion_presupuesto.dart';
import '../data/plan_model.dart';

// texto plano del plan acordado para la hoja de compartir; sin enlace de acceso (rf09)
String textoResumenCompartido({
  required PlanModel plan,
  required List<ActividadModel> actividades,
  EstimacionPresupuesto? estimacion,
}) {
  final lineas = <String>[
    'Salida «${plan.nombre}» en Quedamos',
    'Código: ${plan.codigoInvitacion}',
    '',
    'Itinerario (hora de Lima):',
  ];
  for (final (i, actividad) in actividades.indexed) {
    final inicio = actividad.inicio;
    lineas.add(
      '${i + 1}. ${inicio == null ? 'Sin fecha/hora' : formatearFechaHoraLima(inicio)}'
      ' · ${actividad.nombreLugar ?? 'Lugar no disponible'}',
    );
    lineas.add(
      '   ${actividad.direccion == null ? 'Dirección desconocida' : 'Dirección: ${actividad.direccion}'}',
    );
  }
  lineas
    ..add('')
    ..add('Presupuesto por persona: ${formatearSoles(plan.presupuestoSoles)}');
  if (estimacion != null) {
    // la estimacion no es una garantia; sin precio se marca incompleta
    final incompleta = estimacion.incompleta ? ' (incompleta)' : '';
    lineas.add(
      'Estimado por persona$incompleta: '
      '${formatearSoles(estimacion.totalEstimado)}, solo actividades',
    );
  }
  return lineas.join('\n');
}

import 'package:app/core/utils/formato.dart';
import 'package:app/core/utils/uuid.dart';
import 'package:app/features/salidas/data/plan_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('SalidaModel lee la fila de participaciones con el plan embebido', () {
    final salida = SalidaModel.fromJson({
      'rol': 'administrador',
      'es_creador': true,
      'planes': {
        'id': 'p1',
        'nombre': 'Café del domingo',
        'estado': 'en_votacion',
        'presupuesto_soles': 30,
        'max_propuestas_por_persona': 3,
        'max_candidatos': 6,
        'max_selecciones': 3,
        'max_actividades': 3,
        'codigo_invitacion': 'AQP48X',
        'creado_por': 'u1',
        'created_at': '2026-10-22T14:00:00+00:00',
        'participaciones': [
          {'count': 4},
        ],
      },
    });

    expect(salida.esAdministrador, isTrue);
    expect(salida.totalParticipantes, 4);
    expect(salida.plan.estado, EstadoPlan.enVotacion);
    expect(salida.plan.presupuestoSoles, 30.0);
  });

  test('formatea soles con dos decimales', () {
    expect(formatearSoles(70), 'S/ 70.00');
    expect(formatearSoles(1234.5), 'S/ 1,234.50');
  });

  test('genera uuid v4 con formato valido y distintos', () {
    final formato = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    );
    final a = generarUuidV4();
    expect(formato.hasMatch(a), isTrue);
    expect(generarUuidV4(), isNot(a));
  });
}

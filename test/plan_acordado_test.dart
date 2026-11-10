import 'package:app/app/theme/app_theme.dart';
import 'package:app/core/utils/formato.dart';
import 'package:app/features/itinerario/data/actividad_model.dart';
import 'package:app/features/itinerario/data/estimacion_presupuesto.dart';
import 'package:app/features/itinerario/data/itinerario_repository.dart';
import 'package:app/features/lugares/data/propuestas_repository.dart';
import 'package:app/features/salidas/data/plan_model.dart';
import 'package:app/features/salidas/data/salidas_repository.dart';
import 'package:app/features/salidas/presentation/detalle_plan_screen.dart';
import 'package:app/features/salidas/presentation/resumen_compartido.dart';
import 'package:app/features/votacion/data/votacion_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'fakes.dart';

// sabado 14 nov 2026 a las 16:00 y 18:00 en lima (utc menos 5)
final _inicio1 = DateTime.utc(2026, 11, 14, 21);
final _inicio2 = DateTime.utc(2026, 11, 14, 23);

List<ActividadModel> _actividades(String planId) => [
  ActividadModel(
    id: 'a1',
    planId: planId,
    lugarId: 'l1',
    posicion: 1,
    inicio: _inicio1,
    nombreLugar: 'Chaqchao',
    direccion: 'Calle Santa Catalina 204',
    precioEstimadoPen: 25,
  ),
  ActividadModel(
    id: 'a2',
    planId: planId,
    lugarId: 'l2',
    posicion: 2,
    inicio: _inicio2,
    nombreLugar: 'BAWi',
  ),
];

// scrollable de la lista del detalle; el codigo seleccionable tiene el suyo
Finder _lista() => find
    .descendant(of: find.byType(ListView), matching: find.byType(Scrollable))
    .first;

void main() {
  group('resumen compartido', () {
    test('fecha larga en hora de lima', () {
      expect(
        formatearFechaLargaLima(_inicio1),
        'Sábado 14 de noviembre 2026, 16:00',
      );
    });

    test('incluye plan, codigo, actividades, direcciones y presupuesto', () {
      final texto = textoResumenCompartido(
        plan: planDePrueba(
          nombre: 'Prueba hora',
          estado: EstadoPlan.confirmado,
        ),
        actividades: _actividades('p1'),
        estimacion: const EstimacionPresupuesto(
          presupuestoSoles: 70,
          totalEstimado: 25,
          actividades: 2,
          sinPrecio: 1,
          incompleta: true,
          excede: false,
        ),
      );
      expect(texto, contains('Salida «Prueba hora» en Quedamos'));
      expect(texto, contains('Código: AQP48X'));
      expect(texto, contains('1. sáb 14 nov 2026, 16:00 · Chaqchao'));
      expect(texto, contains('Dirección: Calle Santa Catalina 204'));
      expect(texto, contains('2. sáb 14 nov 2026, 18:00 · BAWi'));
      expect(texto, contains('Dirección desconocida'));
      expect(texto, contains('Presupuesto por persona: S/ 70.00'));
      expect(texto, contains('Estimado por persona (incompleta): S/ 25.00'));
      // sin enlace de acceso (rf09)
      expect(texto, isNot(contains('http')));
    });
  });

  Future<void> montar(WidgetTester tester, EstadoPlan estado) async {
    final salidas = FakeSalidasRepository()
      ..salidas.add(
        SalidaModel(
          plan: planDePrueba(estado: estado, maxActividades: 2),
          miRol: RolPlan.administrador,
          esCreador: true,
          totalParticipantes: 2,
        ),
      );
    final votacion = FakeVotacionRepository(salidas);
    votacion.candidatosPorPlan['p1'] = ['l1', 'l2'];
    votacion.totalesCerrados.addAll({'cl1': 2, 'cl2': 1});
    votacion.seleccionados.addAll({'cl1', 'cl2'});
    final itinerario = FakeItinerarioRepository(salidas);
    itinerario.actividadesPorPlan['p1'] = _actividades('p1');

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<SalidasRepository>.value(value: salidas),
          Provider<PropuestasRepository>.value(
            value: FakePropuestasRepository(),
          ),
          Provider<VotacionRepository>.value(value: votacion),
          Provider<ItinerarioRepository>.value(value: itinerario),
        ],
        child: MaterialApp(
          theme: AppTheme.claro,
          home: const DetallePlanScreen(planId: 'p1'),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  // con el tema real: los botones de la fila del codigo no deben romper el dibujo
  testWidgets('el plan confirmado muestra inicio, compartir y direcciones', (
    tester,
  ) async {
    await montar(tester, EstadoPlan.confirmado);

    expect(tester.takeException(), isNull);
    expect(find.text('Sábado 14 de noviembre 2026, 16:00'), findsOneWidget);
    expect(find.textContaining('Presupuesto acordado'), findsOneWidget);
    expect(find.byTooltip('Compartir resumen'), findsOneWidget);
    expect(find.text('Copiar código'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Dirección desconocida'),
      200,
      scrollable: _lista(),
    );
    expect(find.text('Dirección: Calle Santa Catalina 204'), findsOneWidget);
    expect(find.text('Itinerario confirmado.'), findsOneWidget);
    expect(find.text('Resultado de la votación'), findsNothing);
    expect(find.text('Límites del plan'), findsNothing);
  });

  testWidgets('antes de confirmar no hay compartir ni fecha de inicio', (
    tester,
  ) async {
    await montar(tester, EstadoPlan.preparandoItinerario);

    expect(tester.takeException(), isNull);
    expect(find.textContaining('Presupuesto por persona'), findsWidgets);
    expect(find.textContaining('Presupuesto acordado'), findsNothing);
    expect(find.byTooltip('Compartir resumen'), findsNothing);
    expect(find.text('Sábado 14 de noviembre 2026, 16:00'), findsNothing);

    await tester.scrollUntilVisible(
      find.text('Límites del plan'),
      300,
      scrollable: _lista(),
    );
    expect(find.text('Límites del plan'), findsOneWidget);
  });
}

import 'package:app/app/theme/app_theme.dart';
import 'package:app/core/errors/app_exception.dart';
import 'package:app/features/itinerario/data/actividad_model.dart';
import 'package:app/features/itinerario/data/cambio_plan_model.dart';
import 'package:app/features/itinerario/data/itinerario_repository.dart';
import 'package:app/features/itinerario/presentation/reemplazar_actividad_screen.dart';
import 'package:app/features/itinerario/presentation/reemplazar_actividad_view_model.dart';
import 'package:app/features/lugares/data/lugar_model.dart';
import 'package:app/features/lugares/data/lugares_repository.dart';
import 'package:app/features/lugares/data/propuestas_repository.dart';
import 'package:app/features/salidas/data/plan_model.dart';
import 'package:app/features/salidas/data/salidas_repository.dart';
import 'package:app/features/salidas/presentation/detalle_plan_screen.dart';
import 'package:app/features/salidas/presentation/detalle_plan_view_model.dart';
import 'package:app/features/votacion/data/votacion_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'fakes.dart';

// sabado 14 nov 2026 a las 16:00 y 18:00 en lima (utc menos 5)
final _inicio1 = DateTime.utc(2026, 11, 14, 21);
final _inicio2 = DateTime.utc(2026, 11, 14, 23);

class _Escenario {
  _Escenario({RolPlan rol = RolPlan.administrador}) {
    salidas.salidas.add(
      SalidaModel(
        plan: planDePrueba(
          nombre: 'Prueba hora',
          estado: EstadoPlan.confirmado,
          maxActividades: 2,
        ),
        miRol: rol,
        esCreador: rol == RolPlan.administrador,
        totalParticipantes: 2,
      ),
    );
    votacion.candidatosPorPlan['p1'] = ['l1', 'l2', 'l3', 'l4'];
    votacion.totalesCerrados.addAll({'cl1': 3, 'cl2': 2, 'cl3': 1, 'cl4': 2});
    votacion.seleccionados.addAll({'cl1', 'cl2'});
    itinerario.precios.addAll({'l5': 20, 'l7': 10});
    itinerario.actividadesPorPlan['p1'] = [
      ActividadModel(
        id: 'a1',
        planId: 'p1',
        lugarId: 'l1',
        posicion: 1,
        inicio: _inicio1,
        nombreLugar: 'Chaqchao',
        zona: ZonaLugar.centroHistorico,
        categoria: CategoriaLugar.cafesYPostres,
        precioEstimadoPen: 25,
      ),
      ActividadModel(
        id: 'a2',
        planId: 'p1',
        lugarId: 'l2',
        posicion: 2,
        inicio: _inicio2,
        nombreLugar: 'BAWi',
      ),
    ];
  }

  final salidas = FakeSalidasRepository();
  late final votacion = FakeVotacionRepository(salidas);
  late final itinerario = FakeItinerarioRepository(salidas);
  final lugares = FakeLugaresRepository([
    lugarDePrueba(id: 'l1', nombre: 'Chaqchao'),
    lugarDePrueba(id: 'l2', nombre: 'BAWi'),
    lugarDePrueba(id: 'l3', nombre: 'Lugar l3'),
    lugarDePrueba(
      id: 'l5',
      nombre: 'Café Cinco',
      zona: ZonaLugar.centroHistorico,
      categoria: CategoriaLugar.cafesYPostres,
      precioEstimadoPen: 20,
    ),
    lugarDePrueba(
      id: 'l6',
      nombre: 'Bar Seis',
      categoria: CategoriaLugar.bares,
    ),
    lugarDePrueba(
      id: 'l7',
      nombre: 'Café Siete',
      zona: ZonaLugar.centroHistorico,
      categoria: CategoriaLugar.cafesYPostres,
      precioEstimadoPen: 10,
    ),
  ]);

  ReemplazarActividadViewModel reemplazo() => ReemplazarActividadViewModel(
    salidas,
    votacion,
    lugares,
    itinerario,
    planId: 'p1',
    actividadId: 'a1',
  );

  DetallePlanViewModel detalle() => DetallePlanViewModel(
    salidas,
    FakePropuestasRepository(),
    votacion,
    'p1',
    itinerario: itinerario,
  );

  Widget app(Widget home) => MultiProvider(
    providers: [
      Provider<SalidasRepository>.value(value: salidas),
      Provider<PropuestasRepository>.value(value: FakePropuestasRepository()),
      Provider<VotacionRepository>.value(value: votacion),
      Provider<ItinerarioRepository>.value(value: itinerario),
      Provider<LugaresRepository>.value(value: lugares),
    ],
    child: MaterialApp(theme: AppTheme.claro, home: home),
  );
}

// scrollable de la lista principal; el codigo seleccionable tiene el suyo
Finder _lista() => find
    .descendant(of: find.byType(ListView), matching: find.byType(Scrollable))
    .first;

void main() {
  group('ReemplazarActividadViewModel', () {
    test('lista votacion por votos y catalogo filtrado sin repetir', () async {
      final e = _Escenario();
      final vm = e.reemplazo();
      await vm.cargar();

      expect(vm.puedeReemplazar, isTrue);
      expect(vm.deVotacion.map((a) => a.lugarId), ['l4', 'l3']);
      expect(vm.deVotacion.first.votos, 2);
      // chips precargados con la zona y categoria de la actividad actual
      expect(vm.zona, ZonaLugar.centroHistorico);
      expect(vm.categoria, CategoriaLugar.cafesYPostres);
      expect(vm.catalogo.map((a) => a.lugarId), ['l7', 'l5']);

      vm
        ..elegirZona(null)
        ..elegirCategoria(null);
      // sin lugares del itinerario ni de la votacion; precio desconocido al final
      expect(vm.catalogo.map((a) => a.lugarId), ['l7', 'l5', 'l6']);
    });

    test('proyecta el total y confirma el reemplazo', () async {
      final e = _Escenario();
      final vm = e.reemplazo();
      await vm.cargar();
      final siete = vm.catalogo.firstWhere((a) => a.lugarId == 'l7');

      expect(vm.totalCon(siete), 10);
      // bawi sigue sin precio
      expect(vm.incompletaCon(siete), isTrue);
      expect(vm.excesoCon(siete), 0);

      vm.elegir('l7');
      expect(await vm.confirmar(), isTrue);
      final a1 = e.itinerario.actividadesPorPlan['p1']!.first;
      expect(a1.lugarId, 'l7');
      expect(a1.posicion, 1);
      expect(a1.inicio, _inicio1);
      expect(
        e.itinerario.cambiosPorPlan['p1']!.single.tipo,
        TipoCambio.reemplazo,
      );
    });

    test('un error conserva el itinerario confirmado', () async {
      final e = _Escenario();
      e.itinerario.errorReemplazo = const AppException(
        MensajesError.sinConexion,
      );
      final vm = e.reemplazo();
      await vm.cargar();
      vm.elegir('l4');

      expect(await vm.confirmar(), isFalse);
      expect(vm.errorGuardado, MensajesError.sinConexion);
      expect(e.itinerario.actividadesPorPlan['p1']!.first.lugarId, 'l1');
      expect(e.itinerario.cambiosPorPlan['p1'], isNull);
    });

    test('un participante no puede reemplazar', () async {
      final vm = _Escenario(rol: RolPlan.participante).reemplazo();
      await vm.cargar();
      expect(vm.puedeReemplazar, isFalse);
      vm.elegir('l4');
      expect(await vm.confirmar(), isFalse);
    });
  });

  group('DetallePlanViewModel cambios y cancelacion', () {
    test('cambia el horario y lo registra en el historial', () async {
      final e = _Escenario();
      final vm = e.detalle();
      await vm.cargar();
      expect(vm.puedeCambiarItinerario, isTrue);

      final nuevo = DateTime.now().toUtc().add(const Duration(days: 3));
      expect(await vm.cambiarHorario(vm.actividades[1], nuevo), isTrue);
      expect(vm.actividades[1].inicio, nuevo);
      expect(vm.cambios.single.tipo, TipoCambio.horario);
      expect(vm.cambios.single.inicioAnterior, _inicio2);
    });

    test('un horario pasado se rechaza y conserva el anterior', () async {
      final e = _Escenario();
      final vm = e.detalle();
      await vm.cargar();

      final pasado = DateTime.now().toUtc().subtract(const Duration(hours: 1));
      expect(await vm.cambiarHorario(vm.actividades[0], pasado), isFalse);
      expect(vm.errorHorario, MensajesError.inicioEnPasado);
      expect(vm.actividades[0].inicio, _inicio1);
    });

    test('el admin cancela y el plan queda cancelado', () async {
      final e = _Escenario();
      final vm = e.detalle();
      await vm.cargar();
      expect(vm.puedeCancelar, isTrue);

      expect(await vm.cancelarPlan(), isTrue);
      expect(vm.cancelado, isTrue);
      expect(vm.puedeGestionar, isFalse);
      expect(vm.puedeResponderAsistencia, isFalse);
      // conserva el itinerario para consulta
      expect(vm.actividades, hasLength(2));
    });

    test('un error al cancelar deja el plan como estaba', () async {
      final e = _Escenario();
      e.salidas.errorCancelar = const AppException(MensajesError.sinConexion);
      final vm = e.detalle();
      await vm.cargar();

      expect(await vm.cancelarPlan(), isFalse);
      expect(vm.errorCancelacion, MensajesError.sinConexion);
      expect(vm.confirmado, isTrue);
    });

    test('un participante no cambia ni cancela', () async {
      final vm = _Escenario(rol: RolPlan.participante).detalle();
      await vm.cargar();
      expect(vm.puedeCambiarItinerario, isFalse);
      expect(vm.puedeCancelar, isFalse);
      expect(await vm.cancelarPlan(), isFalse);
    });
  });

  // con el tema real: los botones de las pantallas nuevas no deben romper el dibujo
  testWidgets('p07 muestra actual, alternativas y nuevo total al elegir', (
    tester,
  ) async {
    final e = _Escenario();
    await tester.pumpWidget(
      e.app(const ReemplazarActividadScreen(planId: 'p1', actividadId: 'a1')),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('ACTIVIDAD A SUSTITUIR'), findsOneWidget);
    expect(find.text('Elige una opción'), findsOneWidget);
    final boton = find.ancestor(
      of: find.text('Confirmar cambio de actividad'),
      matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
    );
    expect(tester.widget<ButtonStyleButton>(boton).onPressed, isNull);

    await tester.scrollUntilVisible(find.text('Café Siete'), 300);
    await tester.tap(find.text('Café Siete'));
    await tester.pump();

    expect(find.text('Nuevo total: S/ 10.00 (incompleto)'), findsOneWidget);
    expect(tester.widget<ButtonStyleButton>(boton).onPressed, isNotNull);
  });

  testWidgets('el admin ve las filas de cambio y cancela con dialogo', (
    tester,
  ) async {
    final e = _Escenario();
    await tester.pumpWidget(e.app(const DetallePlanScreen(planId: 'p1')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.scrollUntilVisible(
      find.text('Cancelar esta salida'),
      300,
      scrollable: _lista(),
    );
    expect(find.text('Reemplazar o cambiar actividad'), findsOneWidget);
    expect(find.text('Modificar fecha y hora'), findsOneWidget);

    await tester.ensureVisible(find.text('Cancelar esta salida'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar esta salida'));
    await tester.pumpAndSettle();
    expect(find.text('¿Cancelar Prueba hora?'), findsOneWidget);
    await tester.tap(find.text('Cancelar salida'));
    await tester.pumpAndSettle();

    expect(e.salidas.cancelados, 1);
    await tester.scrollUntilVisible(
      find.textContaining('Salida cancelada el'),
      -300,
      scrollable: _lista(),
    );
    expect(find.textContaining('Salida cancelada el'), findsOneWidget);
    expect(find.text('Copiar código'), findsNothing);
    expect(find.text('Tu asistencia'), findsNothing);
    expect(find.text('Gestión de administrador'), findsNothing);
  });

  testWidgets('el historial aparece en el detalle confirmado', (tester) async {
    final e = _Escenario();
    await e.itinerario.reemplazarActividad(actividadId: 'a1', lugarId: 'l7');
    await tester.pumpWidget(e.app(const DetallePlanScreen(planId: 'p1')));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Cambios del plan'),
      300,
      scrollable: _lista(),
    );
    expect(find.text('Actividad reemplazada'), findsOneWidget);
    expect(find.text('Chaqchao → Lugar l7'), findsOneWidget);
  });

  testWidgets('el participante no ve las filas de cambio', (tester) async {
    final e = _Escenario(rol: RolPlan.participante);
    await tester.pumpWidget(e.app(const DetallePlanScreen(planId: 'p1')));
    await tester.pumpAndSettle();

    expect(find.text('Reemplazar o cambiar actividad'), findsNothing);
    expect(find.text('Cancelar esta salida'), findsNothing);
  });
}

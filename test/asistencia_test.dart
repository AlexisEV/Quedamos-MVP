import 'package:app/app/theme/app_theme.dart';
import 'package:app/core/errors/app_exception.dart';
import 'package:app/features/itinerario/data/actividad_model.dart';
import 'package:app/features/itinerario/data/itinerario_repository.dart';
import 'package:app/features/lugares/data/propuestas_repository.dart';
import 'package:app/features/salidas/data/participante_model.dart';
import 'package:app/features/salidas/data/plan_model.dart';
import 'package:app/features/salidas/data/salidas_repository.dart';
import 'package:app/features/salidas/presentation/detalle_plan_screen.dart';
import 'package:app/features/salidas/presentation/detalle_plan_view_model.dart';
import 'package:app/features/votacion/data/votacion_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'fakes.dart';

final _plazoVoto = DateTime.utc(2026, 11, 1, 1);

// plan p1 con el usuario u1 y otros dos integrantes; u3 ya respondio no asistire
({
  FakeSalidasRepository salidas,
  FakeVotacionRepository votacion,
  FakeItinerarioRepository itinerario,
})
_escenario({
  EstadoPlan estado = EstadoPlan.confirmado,
  RolPlan miRol = RolPlan.participante,
  DateTime? plazoAsistencia,
}) {
  final salidas = FakeSalidasRepository()
    ..salidas.add(
      SalidaModel(
        plan: planDePrueba(
          estado: estado,
          maxActividades: 1,
          fechaLimiteVoto: _plazoVoto,
          fechaLimiteAsistencia: plazoAsistencia,
        ),
        miRol: miRol,
        esCreador: false,
        totalParticipantes: 3,
      ),
    )
    ..participantesPorPlan['p1'] = [
      participanteDePrueba('u2', rol: RolPlan.administrador, esCreador: true),
      participanteDePrueba('u1', rol: miRol, minuto: 1),
      participanteDePrueba(
        'u3',
        minuto: 2,
        asistencia: EstadoAsistencia.noAsistire,
      ),
    ];
  final votacion = FakeVotacionRepository(salidas);
  final itinerario = FakeItinerarioRepository(salidas)
    ..actividadesPorPlan['p1'] = [
      ActividadModel(
        id: 'a1',
        planId: 'p1',
        lugarId: 'l1',
        posicion: 1,
        inicio: DateTime.utc(2026, 11, 14, 21),
        nombreLugar: 'Chaqchao',
      ),
    ];
  return (salidas: salidas, votacion: votacion, itinerario: itinerario);
}

DetallePlanViewModel _vm(
  ({
    FakeSalidasRepository salidas,
    FakeVotacionRepository votacion,
    FakeItinerarioRepository itinerario,
  })
  e,
) => DetallePlanViewModel(
  e.salidas,
  FakePropuestasRepository(),
  e.votacion,
  'p1',
  itinerario: e.itinerario,
);

void main() {
  group('asistencia en el view model', () {
    test('responde, cambia y actualiza los conteos tras el servidor', () async {
      final e = _escenario();
      final vm = _vm(e);
      await vm.cargar();

      expect(vm.puedeResponderAsistencia, isTrue);
      expect(vm.miAsistencia, EstadoAsistencia.pendiente);
      expect(vm.conteoAsistencia(EstadoAsistencia.pendiente), 2);

      expect(await vm.responderAsistencia(EstadoAsistencia.asistire), isTrue);
      expect(vm.miAsistencia, EstadoAsistencia.asistire);
      expect(vm.conteoAsistencia(EstadoAsistencia.asistire), 1);
      expect(vm.conteoAsistencia(EstadoAsistencia.pendiente), 1);

      expect(await vm.responderAsistencia(EstadoAsistencia.noAsistire), isTrue);
      expect(vm.miAsistencia, EstadoAsistencia.noAsistire);
      expect(vm.conteoAsistencia(EstadoAsistencia.noAsistire), 2);
      expect(e.salidas.respuestas, [
        EstadoAsistencia.asistire,
        EstadoAsistencia.noAsistire,
      ]);
    });

    test(
      'un error conserva la respuesta anterior y permite reintentar',
      () async {
        final e = _escenario();
        final vm = _vm(e);
        await vm.cargar();
        e.salidas.errorAsistencia = const AppException(
          MensajesError.sinConexion,
        );

        expect(
          await vm.responderAsistencia(EstadoAsistencia.asistire),
          isFalse,
        );
        expect(vm.miAsistencia, EstadoAsistencia.pendiente);
        expect(vm.errorAsistencia, MensajesError.sinConexion);
        expect(vm.respondiendo, isNull);

        e.salidas.errorAsistencia = null;
        expect(await vm.responderAsistencia(EstadoAsistencia.asistire), isTrue);
        expect(vm.errorAsistencia, isNull);
        expect(vm.miAsistencia, EstadoAsistencia.asistire);
      },
    );

    test(
      'no se responde antes de confirmar ni se vuelve a pendiente',
      () async {
        final e = _escenario(estado: EstadoPlan.preparandoItinerario);
        final vm = _vm(e);
        await vm.cargar();

        expect(vm.puedeResponderAsistencia, isFalse);
        expect(
          await vm.responderAsistencia(EstadoAsistencia.asistire),
          isFalse,
        );

        final confirmado = _vm(_escenario());
        await confirmado.cargar();
        expect(
          await confirmado.responderAsistencia(EstadoAsistencia.pendiente),
          isFalse,
        );
        expect(e.salidas.respuestas, isEmpty);
      },
    );

    test('el admin fija y quita el plazo conservando el de voto', () async {
      final e = _escenario(miRol: RolPlan.administrador);
      final vm = _vm(e);
      await vm.cargar();
      final plazo = DateTime.utc(2030, 1, 1, 17);

      expect(vm.puedeDefinirPlazoAsistencia, isTrue);
      expect(await vm.definirPlazoAsistencia(plazo), isTrue);
      expect(vm.plazoAsistencia, plazo);
      expect(vm.salida!.plan.fechaLimiteVoto, _plazoVoto);
      expect(vm.plazoAsistenciaVencido, isFalse);

      expect(await vm.definirPlazoAsistencia(null), isTrue);
      expect(vm.plazoAsistencia, isNull);
      expect(vm.salida!.plan.fechaLimiteVoto, _plazoVoto);
    });

    test('un participante no define el plazo', () async {
      final vm = _vm(_escenario());
      await vm.cargar();
      expect(vm.puedeDefinirPlazoAsistencia, isFalse);
      expect(await vm.definirPlazoAsistencia(DateTime.utc(2030)), isFalse);
    });

    test('el plazo vencido se indica pero no bloquea', () async {
      final e = _escenario(plazoAsistencia: DateTime.utc(2026, 1, 1));
      final vm = _vm(e);
      await vm.cargar();
      expect(vm.plazoAsistenciaVencido, isTrue);
      expect(await vm.responderAsistencia(EstadoAsistencia.asistire), isTrue);
    });
  });

  Future<FakeSalidasRepository> montar(
    WidgetTester tester, {
    EstadoPlan estado = EstadoPlan.confirmado,
    RolPlan miRol = RolPlan.participante,
    DateTime? plazoAsistencia,
  }) async {
    final e = _escenario(
      estado: estado,
      miRol: miRol,
      plazoAsistencia: plazoAsistencia,
    );
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<SalidasRepository>.value(value: e.salidas),
          Provider<PropuestasRepository>.value(
            value: FakePropuestasRepository(),
          ),
          Provider<VotacionRepository>.value(value: e.votacion),
          Provider<ItinerarioRepository>.value(value: e.itinerario),
        ],
        child: MaterialApp(
          theme: AppTheme.claro,
          home: const DetallePlanScreen(planId: 'p1'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return e.salidas;
  }

  Finder lista() => find
      .descendant(of: find.byType(ListView), matching: find.byType(Scrollable))
      .first;

  // con el tema real: los botones de la fila no deben romper el dibujo
  testWidgets('el participante responde y ve el grupo con chips', (
    tester,
  ) async {
    final salidas = await montar(
      tester,
      plazoAsistencia: DateTime.utc(2026, 1, 1),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Tu asistencia'), findsOneWidget);
    expect(find.textContaining('Pendiente', findRichText: true), findsWidgets);
    expect(find.textContaining('Plazo vencido'), findsOneWidget);

    await tester.ensureVisible(find.text('Asistiré'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Asistiré'));
    await tester.pumpAndSettle();
    expect(salidas.respuestas, [EstadoAsistencia.asistire]);
    expect(find.text('Respuesta guardada.'), findsOneWidget);
    expect(
      find.textContaining('Asistirás', findRichText: true),
      findsOneWidget,
    );

    await tester.scrollUntilVisible(
      find.text('1 asistirá'),
      300,
      scrollable: lista(),
    );
    expect(find.text('1 pendiente'), findsOneWidget);
    // la barra del grupo tiene un segmento visible por cada respuesta con integrantes
    final segmentos = tester.widgetList<Expanded>(
      find.descendant(
        of: find.byType(ClipRRect),
        matching: find.ancestor(
          of: find.byType(ColoredBox),
          matching: find.byType(Expanded),
        ),
      ),
    );
    expect(segmentos.length, 3);
    for (final caja
        in find
            .descendant(
              of: find.byType(ClipRRect),
              matching: find.byType(ColoredBox),
            )
            .evaluate()) {
      expect(caja.size!.height, 8);
    }
    expect(find.text('1 no asistirá'), findsOneWidget);
    expect(find.textContaining('propuestas'), findsNothing);
    expect(find.text('Plazo de asistencia'), findsNothing);
  });

  testWidgets(
    'el error de guardado se muestra sin dar la respuesta por hecha',
    (tester) async {
      final salidas = await montar(tester);
      salidas.errorAsistencia = const AppException(MensajesError.sinConexion);

      await tester.ensureVisible(find.text('No asistiré'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('No asistiré'));
      await tester.pumpAndSettle();
      expect(find.text(MensajesError.sinConexion), findsOneWidget);
      expect(find.text('Respuesta guardada.'), findsNothing);
      expect(
        find.textContaining('No asistirás', findRichText: true),
        findsNothing,
      );
    },
  );

  testWidgets('el admin ve la fila del plazo de asistencia', (tester) async {
    await montar(tester, miRol: RolPlan.administrador);

    await tester.scrollUntilVisible(
      find.text('Plazo de asistencia'),
      300,
      scrollable: lista(),
    );
    expect(tester.takeException(), isNull);
    expect(
      find.text('Sin plazo · opcional, no bloquea respuestas'),
      findsOneWidget,
    );
  });

  testWidgets('antes de confirmar no hay asistencia y siguen las propuestas', (
    tester,
  ) async {
    await montar(tester, estado: EstadoPlan.preparandoItinerario);

    expect(find.text('Tu asistencia'), findsNothing);
    await tester.scrollUntilVisible(
      find.text('Participantes (3)'),
      300,
      scrollable: lista(),
    );
    expect(find.textContaining('propuestas'), findsWidgets);
    expect(find.text('1 asistirá'), findsNothing);
  });
}

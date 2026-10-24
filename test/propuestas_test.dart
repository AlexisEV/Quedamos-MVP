import 'package:app/core/errors/app_exception.dart';
import 'package:app/features/lugares/data/propuesta_model.dart';
import 'package:app/features/lugares/presentation/destino_propuesta.dart';
import 'package:app/features/lugares/presentation/proponer_view_model.dart';
import 'package:app/features/salidas/data/plan_model.dart';
import 'package:app/features/salidas/presentation/detalle_plan_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

SalidaModel salida(PlanModel plan, {RolPlan rol = RolPlan.participante}) =>
    SalidaModel(
      plan: plan,
      miRol: rol,
      esCreador: false,
      totalParticipantes: 2,
    );

void main() {
  test('PropuestaModel lee lugar y autor embebidos y tolera lugar oculto', () {
    final completa = PropuestaModel.fromJson({
      'id': 'pr1',
      'plan_id': 'p1',
      'lugar_id': 'l1',
      'propuesto_por': 'u2',
      'created_at': '2026-10-25T12:00:00Z',
      'lugares': {'nombre': 'Bar', 'categoria': 'bares'},
      'perfiles': {'nombre_visible': ' Ana '},
    });
    final oculta = PropuestaModel.fromJson({
      'id': 'pr2',
      'plan_id': 'p1',
      'lugar_id': 'l2',
      'propuesto_por': 'u2',
      'created_at': '2026-10-25T12:00:00Z',
      'lugares': null,
      'perfiles': null,
    });

    expect(completa.nombreLugar, 'Bar');
    expect(completa.nombreAutor, 'Ana');
    expect(oculta.nombreLugar, isNull);
    expect(oculta.categoria, isNull);
  });

  group('ProponerViewModel', () {
    late DestinoPropuesta destino;
    late FakePropuestasRepository repositorio;
    final plan = planDePrueba(id: 'p1', nombre: 'Sábado');

    setUp(() {
      destino = DestinoPropuesta();
      repositorio = FakePropuestasRepository(salidas: [salida(plan)]);
    });

    test('sin destino no hay plan actual; proponer lo fija y guarda', () async {
      final vm = ProponerViewModel(repositorio, destino, 'l1');
      await vm.cargar();
      expect(vm.destinoActual, isNull);

      final guardado = await vm.proponer(vm.destinos.single);

      expect(guardado, isTrue);
      expect(destino.planId, 'p1');
      expect(repositorio.llamadasProponer, ['p1:l1']);
      await pumpEventQueue();
      expect(vm.destinoActual!.yaPropuesto('l1'), isTrue);
      expect(vm.destinoActual!.misPropuestas, 1);
    });

    test('un lugar ya propuesto o el limite no llaman al servidor', () async {
      repositorio.propuestas.add(
        propuestaDePrueba(lugarId: 'l1', propuestoPor: 'u2'),
      );
      final vm = ProponerViewModel(repositorio, destino, 'l1');
      await vm.cargar();
      expect(await vm.proponer(vm.destinos.single), isFalse);

      repositorio.propuestas
        ..clear()
        ..addAll([
          for (var i = 0; i < 3; i++)
            propuestaDePrueba(id: 'x$i', lugarId: 'o$i'),
        ]);
      await vm.cargar();
      expect(vm.destinoActual!.limiteAlcanzado, isTrue);
      expect(await vm.proponer(vm.destinoActual!), isFalse);
      expect(repositorio.llamadasProponer, isEmpty);
    });

    test('un error del servidor no se muestra como exito', () async {
      repositorio.errorProponer = const AppException(
        MensajesError.lugarYaPropuesto,
      );
      final vm = ProponerViewModel(repositorio, destino, 'l1');
      await vm.cargar();

      final guardado = await vm.proponer(vm.destinos.single);

      expect(guardado, isFalse);
      expect(vm.errorEnvio, MensajesError.lugarYaPropuesto);
      expect(vm.enviando, isFalse);
    });

    test('un destino que ya no recibe propuestas se limpia', () async {
      destino.fijar(planDePrueba(id: 'p9', nombre: 'Votando'));
      final vm = ProponerViewModel(repositorio, destino, 'l1');

      await vm.cargar();

      expect(destino.hayDestino, isFalse);
      expect(vm.destinoActual, isNull);
    });
  });

  group('DetallePlanViewModel con propuestas', () {
    late FakeSalidasRepository salidas;
    late FakePropuestasRepository propuestas;

    setUp(() {
      salidas = FakeSalidasRepository()
        ..salidas.addAll([
          salida(planDePrueba(id: 'p1')),
          salida(planDePrueba(id: 'p2'), rol: RolPlan.administrador),
          salida(
            planDePrueba(id: 'p3', estado: EstadoPlan.enVotacion),
            rol: RolPlan.administrador,
          ),
        ]);
      propuestas = FakePropuestasRepository();
      for (final planId in ['p1', 'p2', 'p3']) {
        propuestas.propuestas.addAll([
          propuestaDePrueba(id: '$planId-a', planId: planId, lugarId: 'a'),
          propuestaDePrueba(
            id: '$planId-b',
            planId: planId,
            lugarId: 'b',
            propuestoPor: 'u2',
          ),
        ]);
      }
    });

    test('carga las propuestas y cuenta las de cada persona', () async {
      final vm = DetallePlanViewModel(salidas, propuestas, 'p1');
      await vm.cargar();

      expect(vm.propuestas, hasLength(2));
      expect(vm.misPropuestas, 1);
      expect(vm.propuestasDe('u2'), 1);
    });

    test(
      'solo el autor o un administrador retiran, y solo al recibir',
      () async {
        final participante = DetallePlanViewModel(salidas, propuestas, 'p1');
        final admin = DetallePlanViewModel(salidas, propuestas, 'p2');
        final votando = DetallePlanViewModel(salidas, propuestas, 'p3');
        await Future.wait([
          participante.cargar(),
          admin.cargar(),
          votando.cargar(),
        ]);

        bool puede(DetallePlanViewModel vm, String lugarId) => vm.puedeRetirar(
          vm.propuestas.firstWhere((p) => p.lugarId == lugarId),
        );
        expect(puede(participante, 'a'), isTrue);
        expect(puede(participante, 'b'), isFalse);
        expect(puede(admin, 'b'), isTrue);
        expect(puede(votando, 'a'), isFalse);
        expect(votando.recibePropuestas, isFalse);
      },
    );

    test('retirar quita la propuesta solo si el servidor confirma', () async {
      final vm = DetallePlanViewModel(salidas, propuestas, 'p1');
      await vm.cargar();
      final propia = vm.propuestas.firstWhere((p) => p.lugarId == 'a');

      propuestas.errorRetirar = const AppException(
        MensajesError.faseNoPermitePropuestas,
      );
      expect(await vm.retirarPropuesta(propia), isFalse);
      expect(vm.propuestas, hasLength(2));
      expect(vm.errorPropuestas, MensajesError.faseNoPermitePropuestas);

      propuestas.errorRetirar = null;
      expect(await vm.retirarPropuesta(propia), isTrue);
      expect(vm.propuestas.map((p) => p.lugarId), ['b']);
      expect(vm.misPropuestas, 0);
    });

    test('se recarga cuando se propone desde la ficha', () async {
      propuestas.salidas.add(salida(planDePrueba(id: 'p1')));
      final vm = DetallePlanViewModel(salidas, propuestas, 'p1');
      await vm.cargar();

      await propuestas.proponer(planId: 'p1', lugarId: 'c');
      await pumpEventQueue();

      expect(vm.propuestas, hasLength(3));
      expect(vm.misPropuestas, 2);
    });
  });
}

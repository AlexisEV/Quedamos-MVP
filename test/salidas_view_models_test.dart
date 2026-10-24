import 'package:app/core/errors/app_exception.dart';
import 'package:app/features/salidas/data/plan_model.dart';
import 'package:app/features/salidas/presentation/crear_plan_view_model.dart';
import 'package:app/features/salidas/presentation/detalle_plan_view_model.dart';
import 'package:app/features/salidas/presentation/mis_salidas_view_model.dart';
import 'package:app/features/salidas/presentation/unirse_view_model.dart';
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
  late FakeSalidasRepository repositorio;

  setUp(() => repositorio = FakeSalidasRepository());

  group('MisSalidasViewModel', () {
    test('separa activas y canceladas', () async {
      repositorio.salidas.addAll([
        salida(planDePrueba(id: 'a')),
        salida(planDePrueba(id: 'b', estado: EstadoPlan.confirmado)),
        salida(planDePrueba(id: 'c', estado: EstadoPlan.cancelado)),
      ]);
      final vm = MisSalidasViewModel(repositorio);

      await vm.cargar();

      expect(vm.activas.map((s) => s.plan.id), ['a', 'b']);
      expect(vm.canceladas.map((s) => s.plan.id), ['c']);
      expect(vm.vacio, isFalse);
      vm.dispose();
    });

    test('sin planes queda vacio y con error expone el mensaje', () async {
      final vm = MisSalidasViewModel(repositorio);
      await vm.cargar();
      expect(vm.vacio, isTrue);

      repositorio.error = const AppException(MensajesError.sinConexion);
      await vm.cargar();
      expect(vm.error, MensajesError.sinConexion);
      vm.dispose();
    });

    test('se recarga cuando se crea un plan', () async {
      final vm = MisSalidasViewModel(repositorio);
      await vm.cargar();
      expect(vm.activas, isEmpty);

      await CrearPlanViewModel(repositorio)
          .crear(nombre: 'Nuevo', presupuestoSoles: 50);
      await pumpEventQueue();

      expect(vm.activas.map((s) => s.plan.nombre), ['Nuevo']);
      vm.dispose();
    });
  });

  group('CrearPlanViewModel', () {
    test('inicia con los valores 3, 6, 3, 3', () {
      final vm = CrearPlanViewModel(repositorio);
      expect(vm.valor(LimitePlan.propuestas), 3);
      expect(vm.valor(LimitePlan.candidatos), 6);
      expect(vm.valor(LimitePlan.selecciones), 3);
      expect(vm.valor(LimitePlan.actividades), 3);
    });

    test('no sale de los rangos', () {
      final vm = CrearPlanViewModel(repositorio);
      for (var i = 0; i < 10; i++) {
        vm.subir(LimitePlan.propuestas);
        vm.bajar(LimitePlan.candidatos);
      }
      expect(vm.valor(LimitePlan.propuestas), 5);
      expect(vm.valor(LimitePlan.candidatos), 2);
      expect(vm.puedeSubir(LimitePlan.propuestas), isFalse);
      expect(vm.puedeBajar(LimitePlan.candidatos), isFalse);
    });

    test(
      'selecciones mayores que candidatos se senala y no se guarda',
      () async {
        final vm = CrearPlanViewModel(repositorio);
        for (var i = 0; i < 4; i++) {
          vm.bajar(LimitePlan.candidatos);
        }
        expect(vm.errorLimites, MensajesError.seleccionesMayoresQueCandidatos);

        final plan = await vm.crear(nombre: 'Plan', presupuestoSoles: 10);

        expect(plan, isNull);
        expect(repositorio.creados, isEmpty);
      },
    );

    test('envia nombre, presupuesto y limites', () async {
      final vm = CrearPlanViewModel(repositorio);
      vm.subir(LimitePlan.actividades);

      final plan = await vm.crear(nombre: '  Café  ', presupuestoSoles: 30.5);

      expect(plan, isNotNull);
      final enviado = repositorio.creados.single;
      expect(enviado.nombre, '  Café  ');
      expect(enviado.presupuestoSoles, 30.5);
      expect(enviado.maxActividades, 4);
      expect(vm.enviando, isFalse);
    });

    test('un reintento tras un error usa el mismo id y no duplica', () async {
      final vm = CrearPlanViewModel(repositorio);
      repositorio.error = const AppException(MensajesError.sinConexion);

      expect(await vm.crear(nombre: 'Plan', presupuestoSoles: 10), isNull);
      expect(vm.error, MensajesError.sinConexion);

      repositorio.error = null;
      await vm.crear(nombre: 'Plan', presupuestoSoles: 10);
      await vm.crear(nombre: 'Plan', presupuestoSoles: 10);

      final ids = repositorio.creados.map((n) => n.id).toSet();
      expect(ids, hasLength(1));
      expect(repositorio.salidas, hasLength(1));
    });
  });

  group('DetallePlanViewModel', () {
    test('carga el plan o marca no encontrado', () async {
      repositorio.salidas.add(salida(planDePrueba(id: 'p1')));

      final encontrado = DetallePlanViewModel(repositorio, 'p1');
      await encontrado.cargar();
      expect(encontrado.salida?.plan.codigoInvitacion, 'AQP48X');
      expect(encontrado.noEncontrado, isFalse);

      final ajeno = DetallePlanViewModel(repositorio, 'otro');
      await ajeno.cargar();
      expect(ajeno.salida, isNull);
      expect(ajeno.noEncontrado, isTrue);
    });

    test('ordena el grupo: creador, administradores y participantes', () async {
      repositorio.salidas.add(salida(planDePrueba(id: 'p1')));
      repositorio.participantesPorPlan['p1'] = [
        participanteDePrueba('c', minuto: 3),
        participanteDePrueba('b', rol: RolPlan.administrador, minuto: 2),
        participanteDePrueba(
          'a',
          rol: RolPlan.administrador,
          esCreador: true,
          minuto: 1,
        ),
      ];
      final vm = DetallePlanViewModel(repositorio, 'p1');

      await vm.cargar();

      expect(vm.participantes.map((p) => p.perfilId), ['a', 'b', 'c']);
      expect(vm.participantes.first.etiquetaRol, 'Creador · Administrador');
      expect(vm.nombrables.map((p) => p.perfilId), ['c']);
      vm.dispose();
    });

    test('solo un administrador de un plan activo gestiona roles', () async {
      repositorio.salidas.addAll([
        salida(planDePrueba(id: 'p1')),
        salida(planDePrueba(id: 'p2'), rol: RolPlan.administrador),
        salida(
          planDePrueba(id: 'p3', estado: EstadoPlan.cancelado),
          rol: RolPlan.administrador,
        ),
      ]);
      final participante = DetallePlanViewModel(repositorio, 'p1');
      final admin = DetallePlanViewModel(repositorio, 'p2');
      final cancelado = DetallePlanViewModel(repositorio, 'p3');

      await Future.wait([
        participante.cargar(),
        admin.cargar(),
        cancelado.cargar(),
      ]);

      expect(participante.puedeGestionar, isFalse);
      expect(admin.puedeGestionar, isTrue);
      expect(cancelado.puedeGestionar, isFalse);
      expect(
        await participante.nombrarAdministrador(participanteDePrueba('x')),
        isFalse,
      );
      expect(repositorio.nombrados, isEmpty);
    });

    test('nombrar administrador recarga el grupo con el nuevo rol', () async {
      repositorio.salidas.add(
        salida(planDePrueba(id: 'p1'), rol: RolPlan.administrador),
      );
      repositorio.participantesPorPlan['p1'] = [
        participanteDePrueba('u1', rol: RolPlan.administrador, esCreador: true),
        participanteDePrueba('u2', minuto: 5),
      ];
      final vm = DetallePlanViewModel(repositorio, 'p1');
      await vm.cargar();

      final guardado = await vm.nombrarAdministrador(vm.nombrables.single);

      expect(guardado, isTrue);
      expect(repositorio.nombrados, ['u2']);
      expect(vm.participantes.last.rol, RolPlan.administrador);
      expect(vm.nombrables, isEmpty);
      expect(vm.asignando, isFalse);
      vm.dispose();
    });

    test(
      'si falla la asignacion conserva los roles y muestra el error',
      () async {
        repositorio.salidas.add(
          salida(planDePrueba(id: 'p1'), rol: RolPlan.administrador),
        );
        repositorio.participantesPorPlan['p1'] = [
          participanteDePrueba(
            'u1',
            rol: RolPlan.administrador,
            esCreador: true,
          ),
          participanteDePrueba('u2', minuto: 5),
        ];
        repositorio.errorNombrar = const AppException(
          MensajesError.sinConexion,
        );
        final vm = DetallePlanViewModel(repositorio, 'p1');
        await vm.cargar();

        final guardado = await vm.nombrarAdministrador(vm.nombrables.single);

        expect(guardado, isFalse);
        expect(vm.errorAsignacion, MensajesError.sinConexion);
        expect(vm.participantes.last.rol, RolPlan.participante);
        expect(vm.asignando, isFalse);
        vm.dispose();
      },
    );
  });

  group('UnirseViewModel', () {
    test('no consulta al servidor con un codigo mal formado', () async {
      final vm = UnirseViewModel(repositorio);

      expect(await vm.unirse('AQP48'), isNull);

      expect(repositorio.codigosEnviados, isEmpty);
      vm.dispose();
    });

    test('se une con el codigo en minusculas y recarga mis salidas', () async {
      repositorio.planesPorCodigo['TWOMOY'] = planDePrueba(id: 'p9');
      final lista = MisSalidasViewModel(repositorio);
      await lista.cargar();
      final vm = UnirseViewModel(repositorio);

      final resultado = await vm.unirse('twomoy');
      await pumpEventQueue();

      expect(resultado?.planId, 'p9');
      expect(resultado?.yaParticipaba, isFalse);
      expect(repositorio.codigosEnviados, ['TWOMOY']);
      expect(lista.activas.map((s) => s.plan.id), ['p9']);
      expect(lista.activas.single.miRol, RolPlan.participante);
      lista.dispose();
      vm.dispose();
    });

    test('repetir el codigo no duplica la participacion', () async {
      repositorio.planesPorCodigo['TWOMOY'] = planDePrueba(id: 'p9');
      final vm = UnirseViewModel(repositorio);

      await vm.unirse('TWOMOY');
      final segundo = await vm.unirse('TWOMOY');

      expect(segundo?.yaParticipaba, isTrue);
      expect(vm.error, isNull);
      expect(repositorio.salidas, hasLength(1));
      vm.dispose();
    });

    test('codigo inexistente o de plan cancelado muestra el error', () async {
      repositorio.planesPorCodigo['CANCEL'] = planDePrueba(
        id: 'p8',
        estado: EstadoPlan.cancelado,
      );
      final vm = UnirseViewModel(repositorio);

      expect(await vm.unirse('ZZZZZZ'), isNull);
      expect(vm.error, MensajesError.codigoInvalido);
      expect(await vm.unirse('CANCEL'), isNull);
      expect(vm.error, MensajesError.codigoInvalido);
      expect(repositorio.salidas, isEmpty);

      vm.limpiarError();
      expect(vm.error, isNull);
      vm.dispose();
    });

    test('sin conexion conserva el error y libera el boton', () async {
      repositorio.error = const AppException(MensajesError.sinConexion);
      final vm = UnirseViewModel(repositorio);

      expect(await vm.unirse('AQP48X'), isNull);

      expect(vm.error, MensajesError.sinConexion);
      expect(vm.consultando, isFalse);
      vm.dispose();
    });
  });
}

import 'package:app/core/errors/app_exception.dart';
import 'package:app/features/itinerario/data/actividad_model.dart';
import 'package:app/features/itinerario/data/estimacion_presupuesto.dart';
import 'package:app/features/itinerario/presentation/revisar_itinerario_view_model.dart';
import 'package:app/features/salidas/data/plan_model.dart';
import 'package:app/features/salidas/presentation/detalle_plan_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

SalidaModel salida(PlanModel plan, {RolPlan rol = RolPlan.administrador}) =>
    SalidaModel(
      plan: plan,
      miRol: rol,
      esCreador: rol == RolPlan.administrador,
      totalParticipantes: 2,
    );

final _ahora = DateTime.utc(2026, 11, 9, 15);

void main() {
  late FakeSalidasRepository salidas;
  late FakePropuestasRepository propuestas;
  late FakeVotacionRepository votacion;
  late FakeItinerarioRepository itinerario;

  setUp(() {
    salidas = FakeSalidasRepository();
    propuestas = FakePropuestasRepository();
    votacion = FakeVotacionRepository(salidas);
    itinerario = FakeItinerarioRepository(salidas);
  });

  // plan cerrado con dos candidatos seleccionados y sus actividades sin hora
  void sembrarPlanCerrado({RolPlan rol = RolPlan.administrador}) {
    salidas.salidas.add(
      salida(planDePrueba(estado: EstadoPlan.preparandoItinerario), rol: rol),
    );
    votacion.candidatosPorPlan['p1'] = ['l1', 'l2'];
    votacion.totalesCerrados.addAll({'cl1': 2, 'cl2': 1});
    votacion.seleccionados.addAll({'cl1', 'cl2'});
    itinerario.precios.addAll({'l1': 38, 'l2': 32});
    itinerario.sembrar('p1', ['l1', 'l2']);
  }

  RevisarItinerarioViewModel crearVm() => RevisarItinerarioViewModel(
    itinerario,
    salidas,
    votacion,
    'p1',
    reloj: () => _ahora,
  );

  group('EstimacionPresupuesto', () {
    test('calcula exceso y uso limitado a 1', () {
      const e = EstimacionPresupuesto(
        presupuestoSoles: 70,
        totalEstimado: 78,
        actividades: 3,
        sinPrecio: 0,
        incompleta: false,
        excede: true,
      );
      expect(e.exceso, 8);
      expect(e.uso, 1);
    });

    test('sin exceso el uso es proporcional y el presupuesto 0 no divide', () {
      const parcial = EstimacionPresupuesto(
        presupuestoSoles: 80,
        totalEstimado: 40,
        actividades: 2,
        sinPrecio: 1,
        incompleta: true,
        excede: false,
      );
      const cero = EstimacionPresupuesto(
        presupuestoSoles: 0,
        totalEstimado: 0,
        actividades: 1,
        sinPrecio: 1,
        incompleta: true,
        excede: false,
      );
      expect(parcial.exceso, 0);
      expect(parcial.uso, 0.5);
      expect(cero.uso, 0);
    });
  });

  test('ActividadModel lee lugar, horario de atencion e inicio', () {
    final actividad = ActividadModel.fromJson({
      'id': 'a1',
      'plan_id': 'p1',
      'lugar_id': 'l1',
      'posicion': 2,
      'inicio': '2026-11-14T18:30:00+00:00',
      'lugares': {
        'nombre': 'BAWi',
        'categoria': 'restaurantes',
        'zona': 'yanahuara',
        'direccion': ' ',
        'horario_atencion': 'Lun–Dom: 12:00–22:00',
        'precio_estimado_pen': null,
      },
    });
    expect(actividad.posicion, 2);
    expect(actividad.inicio, DateTime.utc(2026, 11, 14, 18, 30));
    expect(actividad.nombreLugar, 'BAWi');
    expect(actividad.direccion, isNull);
    expect(actividad.horarioAtencion, 'Lun–Dom: 12:00–22:00');
    expect(actividad.precioEstimadoPen, isNull);
  });

  group('RevisarItinerarioViewModel', () {
    test('carga actividades y estimacion; confirmar exige horarios', () async {
      sembrarPlanCerrado();
      final vm = crearVm();
      await vm.cargar();

      expect(vm.puedeEditar, isTrue);
      expect(vm.actividades.map((a) => a.lugarId), ['l1', 'l2']);
      expect(vm.estimacion!.totalEstimado, 70);
      expect(vm.estimacion!.excede, isFalse);
      expect(vm.sinHorario, 2);
      expect(vm.puedeConfirmar, isFalse);
      expect(vm.hayCambios, isFalse);
    });

    test('subir y bajar cambian el orden sin guardar', () async {
      sembrarPlanCerrado();
      final vm = crearVm();
      await vm.cargar();

      vm.bajar(0);
      expect(vm.actividades.map((a) => a.lugarId), ['l2', 'l1']);
      expect(vm.hayCambios, isTrue);
      vm.subir(0);
      expect(vm.actividades.map((a) => a.lugarId), ['l2', 'l1']);
      vm.subir(1);
      expect(vm.actividades.map((a) => a.lugarId), ['l1', 'l2']);
      expect(vm.hayCambios, isFalse);
      expect(itinerario.guardados, 0);
    });

    test('rechaza un inicio que no es futuro', () async {
      sembrarPlanCerrado();
      final vm = crearVm();
      await vm.cargar();

      expect(vm.fijarInicio('al1', _ahora), MensajesError.inicioEnPasado);
      expect(vm.actividades.first.inicio, isNull);
      expect(
        vm.fijarInicio('al1', _ahora.add(const Duration(days: 1))),
        isNull,
      );
      expect(vm.actividades.first.inicio, _ahora.add(const Duration(days: 1)));
    });

    test(
      'guardar envia orden y horarios; un error conserva la edicion',
      () async {
        sembrarPlanCerrado();
        final vm = crearVm();
        await vm.cargar();
        vm.bajar(0);
        vm.fijarInicio('al1', _ahora.add(const Duration(hours: 5)));

        itinerario.errorGuardar = const AppException(MensajesError.sinConexion);
        expect(await vm.guardar(), isFalse);
        expect(vm.errorAccion, MensajesError.sinConexion);
        expect(vm.hayCambios, isTrue);
        expect(vm.actividades.map((a) => a.lugarId), ['l2', 'l1']);

        itinerario.errorGuardar = null;
        expect(await vm.guardar(), isTrue);
        expect(vm.hayCambios, isFalse);
        final guardadas = itinerario.actividadesPorPlan['p1']!;
        expect(guardadas.map((a) => (a.lugarId, a.posicion)), [
          ('l2', 1),
          ('l1', 2),
        ]);
        expect(guardadas[1].inicio, _ahora.add(const Duration(hours: 5)));
      },
    );

    test('una recarga conserva la edicion sin guardar', () async {
      sembrarPlanCerrado();
      final vm = crearVm();
      await vm.cargar();
      vm.bajar(0);

      await vm.cargar();

      expect(vm.actividades.map((a) => a.lugarId), ['l2', 'l1']);
      expect(vm.hayCambios, isTrue);
    });

    test('confirmar guarda lo pendiente y luego confirma', () async {
      sembrarPlanCerrado();
      final vm = crearVm();
      await vm.cargar();
      vm.fijarInicio('al1', _ahora.add(const Duration(days: 1)));
      vm.fijarInicio('al2', _ahora.add(const Duration(days: 1, hours: 3)));
      expect(vm.puedeConfirmar, isTrue);

      expect(await vm.confirmar(), isTrue);

      expect(itinerario.guardados, 1);
      expect(itinerario.confirmados, 1);
      expect(vm.confirmado, isTrue);
      expect(vm.puedeEditar, isFalse);
      expect(vm.puedeConfirmar, isFalse);
    });

    test('un rechazo al confirmar no muestra el plan confirmado', () async {
      sembrarPlanCerrado();
      final vm = crearVm();
      await vm.cargar();
      vm.fijarInicio('al1', _ahora.add(const Duration(days: 1)));
      vm.fijarInicio('al2', _ahora.add(const Duration(days: 2)));
      itinerario.errorConfirmar = const AppException(
        MensajesError.empatePendiente,
      );

      expect(await vm.confirmar(), isFalse);

      expect(vm.errorAccion, MensajesError.empatePendiente);
      expect(vm.confirmado, isFalse);
      expect(vm.puedeConfirmar, isTrue);
    });

    test('con empate pendiente no se edita', () async {
      sembrarPlanCerrado();
      // l3 empata con l2 y solo l1 quedo seleccionado
      votacion.candidatosPorPlan['p1'] = ['l1', 'l2', 'l3'];
      votacion.totalesCerrados['cl3'] = 1;
      votacion.seleccionados.remove('cl2');
      itinerario.sembrar('p1', ['l1']);
      final vm = crearVm();
      await vm.cargar();

      expect(vm.empatePendiente, isTrue);
      expect(vm.puedeEditar, isFalse);
      vm.bajar(0);
      expect(
        vm.fijarInicio('al1', _ahora.add(const Duration(days: 1))),
        isNull,
      );
      expect(vm.actividades.first.inicio, isNull);
    });

    test('un participante solo consulta', () async {
      sembrarPlanCerrado(rol: RolPlan.participante);
      final vm = crearVm();
      await vm.cargar();

      expect(vm.puedeEditar, isFalse);
      expect(await vm.guardar(), isFalse);
      expect(await vm.confirmar(), isFalse);
    });
  });

  group('DetallePlanViewModel con itinerario', () {
    test('tras el cierre carga actividades y estimacion', () async {
      sembrarPlanCerrado();
      final vm = DetallePlanViewModel(
        salidas,
        propuestas,
        votacion,
        'p1',
        itinerario: itinerario,
      );
      await vm.cargar();

      expect(vm.actividades, hasLength(2));
      expect(vm.estimacion!.totalEstimado, 70);
      expect(vm.puedeRevisarItinerario, isTrue);
      expect(vm.itinerarioBloqueadoPorEmpate, isFalse);
    });

    test(
      'en votacion no carga itinerario y el participante no lo revisa',
      () async {
        salidas.salidas.addAll([
          salida(planDePrueba(estado: EstadoPlan.enVotacion)),
          salida(
            planDePrueba(id: 'p2', estado: EstadoPlan.preparandoItinerario),
            rol: RolPlan.participante,
          ),
        ]);
        itinerario.sembrar('p1', ['l1']);
        final votando = DetallePlanViewModel(
          salidas,
          propuestas,
          votacion,
          'p1',
          itinerario: itinerario,
        );
        final participante = DetallePlanViewModel(
          salidas,
          propuestas,
          votacion,
          'p2',
          itinerario: itinerario,
        );
        await Future.wait([votando.cargar(), participante.cargar()]);

        expect(votando.actividades, isEmpty);
        expect(votando.estimacion, isNull);
        expect(votando.puedeRevisarItinerario, isFalse);
        expect(participante.puedeRevisarItinerario, isFalse);
        expect(participante.estimacion, isNotNull);
      },
    );
  });
}

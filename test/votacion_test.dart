import 'package:app/core/errors/app_exception.dart';
import 'package:app/core/utils/formato.dart';
import 'package:app/features/lugares/data/lugar_model.dart';
import 'package:app/features/salidas/data/plan_model.dart';
import 'package:app/features/salidas/presentation/crear_plan_view_model.dart';
import 'package:app/features/salidas/presentation/detalle_plan_view_model.dart';
import 'package:app/features/votacion/data/candidato_model.dart';
import 'package:app/features/votacion/presentation/preparar_votacion_view_model.dart';
import 'package:app/features/votacion/presentation/votar_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

SalidaModel salida(PlanModel plan, {RolPlan rol = RolPlan.administrador}) =>
    SalidaModel(
      plan: plan,
      miRol: rol,
      esCreador: rol == RolPlan.administrador,
      totalParticipantes: 2,
    );

final _ahora = DateTime.utc(2026, 10, 25, 15);

void main() {
  late FakeSalidasRepository salidas;
  late FakePropuestasRepository propuestas;
  late FakeVotacionRepository votacion;

  setUp(() {
    salidas = FakeSalidasRepository();
    propuestas = FakePropuestasRepository();
    votacion = FakeVotacionRepository(salidas);
    propuestas.propuestas.addAll([
      propuestaDePrueba(id: 'pr1', lugarId: 'l1'),
      propuestaDePrueba(id: 'pr2', lugarId: 'l2', propuestoPor: 'u2'),
      propuestaDePrueba(id: 'pr3', lugarId: 'l3', propuestoPor: 'u2'),
    ]);
  });

  PrepararVotacionViewModel crearVm([String planId = 'p1']) =>
      PrepararVotacionViewModel(
        salidas,
        propuestas,
        votacion,
        planId,
        ahora: () => _ahora,
      );

  group('modelos y formato', () {
    test('CandidatoModel lee el lugar embebido y tolera lugar oculto', () {
      final completo = CandidatoModel.fromJson({
        'id': 'c1',
        'plan_id': 'p1',
        'lugar_id': 'l1',
        'lugares': {
          'nombre': 'BAWi',
          'categoria': 'cafes_y_postres',
          'zona': 'yanahuara',
          'precio_estimado_pen': 22,
        },
      });
      final oculto = CandidatoModel.fromJson({
        'id': 'c2',
        'plan_id': 'p1',
        'lugar_id': 'l2',
        'lugares': null,
      });
      expect(completo.nombreLugar, 'BAWi');
      expect(completo.precioEstimadoPen, 22);
      expect(completo.zona, ZonaLugar.yanahuara);
      expect(oculto.nombreLugar, isNull);
      expect(oculto.categoria, isNull);
    });

    test('PlanModel lee los plazos opcionales en utc', () {
      final json = {
        'id': 'p1',
        'nombre': 'Plan',
        'estado': 'en_votacion',
        'presupuesto_soles': 50,
        'max_propuestas_por_persona': 3,
        'max_candidatos': 6,
        'max_selecciones': 3,
        'max_actividades': 3,
        'codigo_invitacion': 'AQP48X',
        'creado_por': 'u1',
        'created_at': '2026-10-25T12:00:00Z',
        'fecha_limite_voto': '2026-10-31T01:00:00+00:00',
        'fecha_limite_asistencia': null,
      };
      final plan = PlanModel.fromJson(json);
      expect(plan.fechaLimiteVoto, DateTime.utc(2026, 10, 31, 1));
      expect(plan.fechaLimiteAsistencia, isNull);
    });

    test('la hora de lima es utc menos 5 horas', () {
      final instante = desdeHoraLima(2026, 10, 30, 20, 0);
      expect(instante, DateTime.utc(2026, 10, 31, 1));
      expect(formatearFechaHoraLima(instante), 'vie 30 oct 2026, 20:00');
    });
  });

  group('PrepararVotacionViewModel', () {
    test('carga limites, plazo y candidatos guardados', () async {
      final plazo = DateTime.utc(2026, 10, 30, 1);
      salidas.salidas.add(
        salida(planDePrueba(maxCandidatos: 4, fechaLimiteVoto: plazo)),
      );
      votacion.candidatosPorPlan['p1'] = ['l2'];
      final vm = crearVm();

      await vm.cargar();

      expect(vm.puedePreparar, isTrue);
      expect(vm.valor(LimitePlan.candidatos), 4);
      expect(vm.plazoVoto, plazo);
      expect(vm.seleccion, {'l2'});
      expect(vm.hayCambios, isFalse);
      expect(vm.puedeGuardar, isFalse);
      expect(vm.puedeAbrir, isTrue);
    });

    test('solo un administrador en recibiendo_propuestas prepara', () async {
      salidas.salidas.addAll([
        salida(planDePrueba(id: 'p1'), rol: RolPlan.participante),
        salida(planDePrueba(id: 'p2', estado: EstadoPlan.enVotacion)),
      ]);
      final participante = crearVm('p1');
      final votando = crearVm('p2');

      await Future.wait([participante.cargar(), votando.cargar()]);

      expect(participante.puedePreparar, isFalse);
      expect(votando.puedePreparar, isFalse);
      expect(participante.puedeAbrir, isFalse);
    });

    test('no deja elegir mas candidatos que el maximo', () async {
      salidas.salidas.add(salida(planDePrueba(maxCandidatos: 2)));
      final vm = crearVm();
      await vm.cargar();

      vm.alternar('l1');
      vm.alternar('l2');
      expect(vm.puedeAlternar('l3'), isFalse);
      vm.alternar('l3');
      expect(vm.seleccion, {'l1', 'l2'});

      vm.alternar('l1');
      expect(vm.seleccion, {'l2'});
    });

    test('valida selecciones y candidatos contra el maximo', () async {
      salidas.salidas.add(
        salida(planDePrueba(maxCandidatos: 3, maxSelecciones: 3)),
      );
      final vm = crearVm();
      await vm.cargar();
      vm
        ..alternar('l1')
        ..alternar('l2')
        ..alternar('l3');

      vm.bajar(LimitePlan.candidatos);
      expect(vm.errorLimites, MensajesError.seleccionesMayoresQueCandidatos);
      vm.bajar(LimitePlan.selecciones);
      expect(vm.errorLimites, MensajesError.candidatosSuperanMaximo);
      expect(vm.puedeGuardar, isFalse);
      expect(vm.puedeAbrir, isFalse);

      vm.alternar('l3');
      expect(vm.errorLimites, isNull);
      expect(vm.puedeGuardar, isTrue);
    });

    test('rechaza un plazo nuevo en el pasado', () async {
      salidas.salidas.add(salida(planDePrueba()));
      final vm = crearVm();
      await vm.cargar();

      vm.fijarPlazoVoto(_ahora.subtract(const Duration(minutes: 1)));
      expect(vm.errorPlazo, MensajesError.plazoEnPasado);
      expect(vm.puedeGuardar, isFalse);

      vm.fijarPlazoVoto(_ahora.add(const Duration(days: 1)));
      expect(vm.errorPlazo, isNull);
      expect(vm.puedeGuardar, isTrue);
    });

    test('conserva un plazo guardado aunque ya haya vencido', () async {
      salidas.salidas.add(
        salida(planDePrueba(fechaLimiteVoto: DateTime.utc(2026, 10, 1))),
      );
      final vm = crearVm();
      await vm.cargar();

      expect(vm.errorPlazo, isNull);
    });

    test('recargar conserva lo editado y trae lo nuevo del servidor', () async {
      salidas.salidas.add(salida(planDePrueba()));
      final vm = crearVm();
      await vm.cargar();
      final plazo = _ahora.add(const Duration(days: 2));
      vm
        ..alternar('l1')
        ..alternar('l3')
        ..bajar(LimitePlan.actividades)
        ..fijarPlazoVoto(plazo);
      // mientras tanto se retira una propuesta elegida y llega otra
      propuestas.propuestas
        ..removeWhere((p) => p.lugarId == 'l3')
        ..add(propuestaDePrueba(id: 'pr4', lugarId: 'l4', propuestoPor: 'u2'));

      await vm.cargar();

      expect(vm.seleccion, {'l1'});
      expect(vm.valor(LimitePlan.actividades), 2);
      expect(vm.plazoVoto, plazo);
      expect(vm.propuestas.map((p) => p.lugarId), contains('l4'));
      expect(vm.hayCambios, isTrue);
    });

    test('recargar sin cambios toma los valores del servidor', () async {
      salidas.salidas.add(salida(planDePrueba()));
      final vm = crearVm();
      await vm.cargar();
      // otro administrador guardo cambios
      salidas.salidas[0] = salida(planDePrueba(maxActividades: 5));
      votacion.candidatosPorPlan['p1'] = ['l2'];

      await vm.cargar();

      expect(vm.valor(LimitePlan.actividades), 5);
      expect(vm.seleccion, {'l2'});
      expect(vm.hayCambios, isFalse);
    });

    test('guarda candidatos antes de bajar el maximo', () async {
      salidas.salidas.add(
        salida(planDePrueba(maxCandidatos: 3, maxSelecciones: 2)),
      );
      votacion.candidatosPorPlan['p1'] = ['l1', 'l2', 'l3'];
      final vm = crearVm();
      await vm.cargar();
      vm
        ..alternar('l3')
        ..bajar(LimitePlan.candidatos);

      expect(await vm.guardar(), isTrue);

      expect(votacion.llamadas, ['candidatos:2', 'limites:2/2/3']);
      expect(votacion.candidatosPorPlan['p1'], ['l1', 'l2']);
      expect(vm.hayCambios, isFalse);
    });

    test('sube el maximo antes de guardar mas candidatos', () async {
      salidas.salidas.add(
        salida(planDePrueba(maxCandidatos: 2, maxSelecciones: 2)),
      );
      final vm = crearVm();
      await vm.cargar();
      vm
        ..subir(LimitePlan.candidatos)
        ..alternar('l1')
        ..alternar('l2')
        ..alternar('l3')
        ..fijarPlazoVoto(_ahora.add(const Duration(days: 2)));

      expect(await vm.guardar(), isTrue);

      expect(votacion.llamadas, ['limites:3/2/3', 'candidatos:3', 'plazos']);
      expect(vm.salida!.plan.maxCandidatos, 3);
      expect(vm.salida!.plan.fechaLimiteVoto, isNotNull);
    });

    test(
      'tras una falla parcial el reintento solo envia lo que falta',
      () async {
        salidas.salidas.add(salida(planDePrueba()));
        final vm = crearVm();
        await vm.cargar();
        vm
          ..alternar('l1')
          ..bajar(LimitePlan.actividades);
        votacion.errorLimites = const AppException(MensajesError.sinConexion);

        expect(await vm.guardar(), isFalse);
        expect(vm.errorAccion, MensajesError.sinConexion);
        expect(vm.seleccion, {'l1'});
        expect(vm.valor(LimitePlan.actividades), 2);

        votacion.errorLimites = null;
        expect(await vm.guardar(), isTrue);
        expect(votacion.llamadas, [
          'candidatos:1',
          'limites:6/3/2',
          'limites:6/3/2',
        ]);
      },
    );

    test('abrir guarda lo pendiente, abre y avisa a mis salidas', () async {
      salidas.salidas.add(salida(planDePrueba()));
      var avisos = 0;
      final suscripcion = salidas.cambios.listen((_) => avisos++);
      final vm = crearVm();
      await vm.cargar();
      expect(vm.puedeAbrir, isFalse);
      vm.alternar('l2');

      expect(await vm.abrir(), isTrue);
      await Future<void>.delayed(Duration.zero);

      expect(votacion.llamadas, ['candidatos:1', 'abrir']);
      expect(vm.salida!.plan.estado, EstadoPlan.enVotacion);
      expect(vm.puedePreparar, isFalse);
      expect(avisos, 1);
      await suscripcion.cancel();
    });

    test('si abrir falla no hay exito y el plan sigue preparandose', () async {
      salidas.salidas.add(salida(planDePrueba()));
      votacion.candidatosPorPlan['p1'] = ['l1'];
      votacion.errorAbrir = const AppException(MensajesError.sinConexion);
      final vm = crearVm();
      await vm.cargar();

      expect(await vm.abrir(), isFalse);

      expect(vm.errorAccion, MensajesError.sinConexion);
      expect(vm.salida!.plan.estado, EstadoPlan.recibiendoPropuestas);
      expect(vm.puedeAbrir, isTrue);
    });
  });

  group('DetallePlanViewModel con votacion', () {
    test('desde en_votacion muestra la lista final fija', () async {
      salidas.salidas.addAll([
        salida(planDePrueba(id: 'p1')),
        salida(planDePrueba(id: 'p2', estado: EstadoPlan.enVotacion)),
      ]);
      votacion.candidatosPorPlan['p2'] = ['l1', 'l2'];
      final recibiendo = DetallePlanViewModel(
        salidas,
        propuestas,
        votacion,
        'p1',
      );
      final votando = DetallePlanViewModel(salidas, propuestas, votacion, 'p2');

      await Future.wait([recibiendo.cargar(), votando.cargar()]);

      expect(recibiendo.muestraCandidatos, isFalse);
      expect(recibiendo.puedePrepararVotacion, isTrue);
      expect(votando.muestraCandidatos, isTrue);
      expect(votando.puedePrepararVotacion, isFalse);
      expect(votando.candidatos.map((c) => c.lugarId), ['l1', 'l2']);
      expect(votando.recibePropuestas, isFalse);
    });

    test('un participante no ve preparar votacion', () async {
      salidas.salidas.add(salida(planDePrueba(), rol: RolPlan.participante));
      final vm = DetallePlanViewModel(salidas, propuestas, votacion, 'p1');

      await vm.cargar();

      expect(vm.puedePrepararVotacion, isFalse);
    });
  });

  group('VotarViewModel', () {
    VotarViewModel crearVotar([String planId = 'p1']) =>
        VotarViewModel(salidas, votacion, planId, ahora: () => _ahora);

    void planEnVotacion({
      int maxSelecciones = 2,
      List<String> lugares = const ['l1', 'l2', 'l3'],
      DateTime? plazo,
      RolPlan rol = RolPlan.participante,
    }) {
      salidas.salidas.add(
        salida(
          planDePrueba(
            estado: EstadoPlan.enVotacion,
            maxSelecciones: maxSelecciones,
            fechaLimiteVoto: plazo,
          ),
          rol: rol,
        ),
      );
      votacion.candidatosPorPlan['p1'] = lugares;
    }

    test('carga candidatos, totales y la seleccion guardada', () async {
      planEnVotacion();
      votacion.votosAjenos['cl1'] = 2;
      votacion.misVotosPorPlan['p1'] = {'cl2'};
      final vm = crearVotar();

      await vm.cargar();

      expect(vm.votacionAbierta, isTrue);
      expect(vm.candidatos.map((c) => c.id), ['cl1', 'cl2', 'cl3']);
      expect(vm.total('cl1'), 2);
      expect(vm.total('cl2'), 1);
      expect(vm.total('cl3'), 0);
      expect(vm.seleccion, {'cl2'});
      expect(vm.yaVoto, isTrue);
      expect(vm.hayCambios, isFalse);
      expect(vm.puedeGuardar, isFalse);
    });

    test('el contador respeta el maximo y no deja guardar vacio', () async {
      planEnVotacion();
      final vm = crearVotar();
      await vm.cargar();

      expect(vm.maximo, 2);
      expect(vm.puedeGuardar, isFalse);
      vm.alternar('cl1');
      vm.alternar('cl2');
      expect(vm.puedeAlternar('cl3'), isFalse);
      vm.alternar('cl3');
      expect(vm.seleccion, {'cl1', 'cl2'});
      vm.alternar('cl1');
      expect(vm.puedeAlternar('cl3'), isTrue);
      vm.alternar('cl2');
      expect(vm.seleccion, isEmpty);
      expect(vm.puedeGuardar, isFalse);
    });

    test('el maximo no supera el numero de candidatos', () async {
      planEnVotacion(maxSelecciones: 3, lugares: ['l1', 'l2']);
      final vm = crearVotar();
      await vm.cargar();

      expect(vm.maximo, 2);
    });

    test('guardar confirma con el servidor y actualiza los totales', () async {
      planEnVotacion();
      votacion.votosAjenos['cl1'] = 1;
      final vm = crearVotar();
      await vm.cargar();
      vm.alternar('cl1');
      vm.alternar('cl3');

      expect(await vm.guardar(), isTrue);

      expect(votacion.misVotosPorPlan['p1'], {'cl1', 'cl3'});
      expect(vm.total('cl1'), 2);
      expect(vm.total('cl3'), 1);
      expect(vm.yaVoto, isTrue);
      expect(vm.hayCambios, isFalse);

      // cambiar la seleccion cuenta solo la ultima version guardada
      vm.alternar('cl3');
      vm.alternar('cl2');
      expect(await vm.guardar(), isTrue);
      expect(vm.total('cl1'), 2);
      expect(vm.total('cl2'), 1);
      expect(vm.total('cl3'), 0);
    });

    test('si falla el guardado conserva la edicion y no marca voto', () async {
      planEnVotacion();
      final vm = crearVotar();
      await vm.cargar();
      vm.alternar('cl1');
      votacion.errorGuardarVotos = const AppException(
        MensajesError.sinConexion,
      );

      expect(await vm.guardar(), isFalse);

      expect(vm.errorGuardado, MensajesError.sinConexion);
      expect(vm.yaVoto, isFalse);
      expect(vm.seleccion, {'cl1'});
      expect(vm.total('cl1'), 0);

      votacion.errorGuardarVotos = null;
      expect(await vm.guardar(), isTrue);
      expect(vm.errorGuardado, isNull);
      expect(vm.total('cl1'), 1);
    });

    test('si fallan los totales tras guardar el voto queda guardado', () async {
      planEnVotacion();
      final vm = crearVotar();
      await vm.cargar();
      vm.alternar('cl1');
      votacion.errorTotales = const AppException(MensajesError.sinConexion);

      expect(await vm.guardar(), isTrue);

      expect(vm.yaVoto, isTrue);
      expect(vm.totalesDesactualizados, isTrue);
      votacion.errorTotales = null;
      await vm.cargar();
      expect(vm.totalesDesactualizados, isFalse);
      expect(vm.total('cl1'), 1);
    });

    test('recargar conserva una seleccion sin guardar', () async {
      planEnVotacion();
      votacion.misVotosPorPlan['p1'] = {'cl1'};
      final vm = crearVotar();
      await vm.cargar();
      vm.alternar('cl1');
      vm.alternar('cl2');

      await vm.cargar();

      expect(vm.seleccion, {'cl2'});
      expect(vm.hayCambios, isTrue);
    });

    test('el plazo vencido no impide votar', () async {
      planEnVotacion(plazo: _ahora.subtract(const Duration(hours: 1)));
      final vm = crearVotar();
      await vm.cargar();

      expect(vm.plazoVencido, isTrue);
      vm.alternar('cl1');
      expect(await vm.guardar(), isTrue);
    });

    test('fuera de en_votacion no se puede votar', () async {
      salidas.salidas.addAll([
        salida(planDePrueba(id: 'p1')),
        salida(planDePrueba(id: 'p2', estado: EstadoPlan.preparandoItinerario)),
      ]);
      votacion.candidatosPorPlan['p2'] = ['l1'];
      final preparando = crearVotar('p1');
      final cerrada = crearVotar('p2');

      await Future.wait([preparando.cargar(), cerrada.cargar()]);

      expect(preparando.enPreparacion, isTrue);
      expect(preparando.candidatos, isEmpty);
      expect(cerrada.votacionAbierta, isFalse);
      expect(cerrada.puedeAlternar('cl1'), isFalse);
      expect(cerrada.puedeGuardar, isFalse);
    });

    test('el detalle muestra cuantos votos guardo el usuario', () async {
      planEnVotacion();
      votacion.misVotosPorPlan['p1'] = {'cl1'};
      final vm = DetallePlanViewModel(salidas, propuestas, votacion, 'p1');

      await vm.cargar();

      expect(vm.enVotacion, isTrue);
      expect(vm.misVotos, 1);
      expect(vm.maximoVotos, 2);
    });
  });
}

import 'package:app/core/errors/app_exception.dart';
import 'package:app/features/lugares/data/lugar_model.dart';
import 'package:app/features/lugares/presentation/destino_propuesta.dart';
import 'package:app/features/lugares/presentation/recomendaciones_view_model.dart';
import 'package:app/features/salidas/data/plan_model.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

void main() {
  late FakeLugaresRepository lugares;
  late FakePropuestasRepository propuestas;
  late DestinoPropuesta destino;

  RecomendacionesViewModel crear() =>
      RecomendacionesViewModel(lugares, propuestas, destino);

  void elegirTodo(RecomendacionesViewModel vm, {int tope = 40}) {
    vm
      ..elegirZona(ZonaLugar.yanahuara)
      ..elegirCategoria(CategoriaLugar.cafesYPostres)
      ..elegirTope(tope);
  }

  LugarModel cafe(String id, double? precio, {String? nombre}) => lugarDePrueba(
    id: id,
    nombre: nombre ?? 'Cafe $id',
    zona: ZonaLugar.yanahuara,
    categoria: CategoriaLugar.cafesYPostres,
    precioEstimadoPen: precio,
  );

  setUp(() {
    lugares = FakeLugaresRepository();
    propuestas = FakePropuestasRepository();
    destino = DestinoPropuesta();
  });

  test('las tres entradas son obligatorias para consultar', () async {
    lugares.lugares.add(cafe('a', 10));
    final vm = crear()
      ..elegirZona(ZonaLugar.yanahuara)
      ..elegirCategoria(CategoriaLugar.cafesYPostres);

    expect(vm.puedeConsultar, isFalse);
    await vm.consultar();
    expect(vm.consultado, isFalse);
    expect(vm.recomendaciones, isEmpty);

    vm.elegirTope(20);
    expect(vm.puedeConsultar, isTrue);
  });

  test(
    'filtra por zona, categoria y tope y ordena por precio y nombre',
    () async {
      lugares.lugares.addAll([
        cafe('caro', 45),
        cafe('b', 22, nombre: 'Beta'),
        cafe('a', 22, nombre: 'Alfa'),
        cafe('gratis', 0),
        cafe('sin_precio', null),
        lugarDePrueba(
          id: 'otra_zona',
          zona: ZonaLugar.cayma,
          categoria: CategoriaLugar.cafesYPostres,
          precioEstimadoPen: 5,
        ),
        lugarDePrueba(
          id: 'otra_categoria',
          zona: ZonaLugar.yanahuara,
          categoria: CategoriaLugar.bares,
          precioEstimadoPen: 5,
        ),
      ]);
      final vm = crear();
      elegirTodo(vm);

      await vm.consultar();

      expect(vm.recomendaciones.map((l) => l.id), ['gratis', 'a', 'b']);
      expect(vm.sinOpciones, isFalse);
    },
  );

  test('devuelve como maximo 10 lugares', () async {
    for (var i = 0; i < 12; i++) {
      lugares.lugares.add(cafe('l$i', i.toDouble()));
    }
    final vm = crear();
    elegirTodo(vm);

    await vm.consultar();

    expect(vm.recomendaciones, hasLength(10));
  });

  test('sin lugares compatibles queda en sin opciones', () async {
    lugares.lugares.add(cafe('caro', 90));
    final vm = crear();
    elegirTodo(vm, tope: 20);

    await vm.consultar();

    expect(vm.sinOpciones, isTrue);
    expect(vm.error, isNull);
  });

  test('un error se muestra y no se confunde con sin opciones', () async {
    lugares.error = const AppException(MensajesError.sinConexion);
    final vm = crear();
    elegirTodo(vm);

    await vm.consultar();

    expect(vm.error, MensajesError.sinConexion);
    expect(vm.sinOpciones, isFalse);
  });

  test('cambiar una entrada limpia el resultado anterior', () async {
    lugares.lugares.add(cafe('a', 10));
    final vm = crear();
    elegirTodo(vm);
    await vm.consultar();
    expect(vm.recomendaciones, hasLength(1));

    vm.elegirTope(60);

    expect(vm.recomendaciones, isEmpty);
    expect(vm.consultado, isFalse);
  });

  test('marca ya propuesto solo en el plan destino elegido', () async {
    final plan = planDePrueba();
    propuestas = FakePropuestasRepository(
      salidas: [
        SalidaModel(
          plan: plan,
          miRol: RolPlan.participante,
          esCreador: false,
          totalParticipantes: 2,
        ),
      ],
    );
    propuestas.propuestas.add(
      propuestaDePrueba(id: 'pr1', planId: plan.id, lugarId: 'a'),
    );
    lugares.lugares.addAll([cafe('a', 10), cafe('b', 12)]);
    final vm = crear();
    elegirTodo(vm);

    await vm.consultar();
    expect(vm.yaPropuesto('a'), isFalse);

    destino.fijar(plan);
    await Future<void>.delayed(Duration.zero);

    expect(vm.yaPropuesto('a'), isTrue);
    expect(vm.yaPropuesto('b'), isFalse);
  });
}

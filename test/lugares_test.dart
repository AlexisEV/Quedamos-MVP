import 'package:app/core/errors/app_exception.dart';
import 'package:app/features/lugares/data/lugar_model.dart';
import 'package:app/features/lugares/presentation/explorar_view_model.dart';
import 'package:app/features/lugares/presentation/ficha_lugar_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

void main() {
  group('LugarModel.fromJson', () {
    test('mapea columnas y enums', () {
      final lugar = LugarModel.fromJson({
        'id': 'l1',
        'nombre': 'Lugar',
        'categoria': 'cafes_y_postres',
        'zona': 'centro_historico',
        'direccion': 'Calle 1',
        'horario_atencion': 'Lun a sab 9:00-18:00',
        'precio_estimado_pen': 25,
        'precio_nota': 'cafe y postre',
      });

      expect(lugar.categoria, CategoriaLugar.cafesYPostres);
      expect(lugar.categoria.etiqueta, 'Cafés y Postres');
      expect(lugar.zona.etiqueta, 'Centro Histórico');
      expect(lugar.precioEstimadoPen, 25.0);
      expect(lugar.direccion, 'Calle 1');
    });

    test('null y textos vacios quedan como desconocidos, nunca 0', () {
      final lugar = LugarModel.fromJson({
        'id': 'l2',
        'nombre': 'Lugar',
        'categoria': 'bares',
        'zona': 'cayma',
        'direccion': '  ',
        'horario_atencion': null,
        'precio_estimado_pen': null,
        'precio_nota': '',
      });

      expect(lugar.direccion, isNull);
      expect(lugar.horarioAtencion, isNull);
      expect(lugar.precioEstimadoPen, isNull);
      expect(lugar.precioNota, isNull);
    });

    test('un precio 0 se conserva como gratis', () {
      final lugar = LugarModel.fromJson({
        'id': 'l3',
        'nombre': 'Mirador',
        'categoria': 'entretenimiento_y_cultura',
        'zona': 'yanahuara',
        'precio_estimado_pen': 0,
      });

      expect(lugar.precioEstimadoPen, 0.0);
    });
  });

  group('ExplorarViewModel', () {
    test('carga los lugares en orden alfabetico', () async {
      final vm = ExplorarViewModel(
        FakeLugaresRepository([
          lugarDePrueba(id: 'b', nombre: 'Bar'),
          lugarDePrueba(id: 'a', nombre: 'Antojitos'),
        ]),
      );

      await vm.cargar();

      expect(vm.lugares.map((l) => l.nombre), ['Antojitos', 'Bar']);
      expect(vm.vacio, isFalse);
      expect(vm.error, isNull);
    });

    test('catalogo vacio queda en estado vacio', () async {
      final vm = ExplorarViewModel(FakeLugaresRepository());

      await vm.cargar();

      expect(vm.vacio, isTrue);
    });

    test('un error se muestra y no se confunde con vacio', () async {
      final repo = FakeLugaresRepository()
        ..error = const AppException(MensajesError.sinConexion);
      final vm = ExplorarViewModel(repo);

      await vm.cargar();

      expect(vm.error, MensajesError.sinConexion);
      expect(vm.vacio, isFalse);
    });
  });

  group('FichaLugarViewModel', () {
    test('carga el lugar pedido', () async {
      final vm = FichaLugarViewModel(
        FakeLugaresRepository([lugarDePrueba(id: 'l1')]),
        'l1',
      );

      await vm.cargar();

      expect(vm.lugar?.id, 'l1');
      expect(vm.noEncontrado, isFalse);
    });

    test('un lugar inexistente o no publicado no se encuentra', () async {
      final vm = FichaLugarViewModel(FakeLugaresRepository(), 'x');

      await vm.cargar();

      expect(vm.lugar, isNull);
      expect(vm.noEncontrado, isTrue);
    });

    test('un error conserva el mensaje para reintentar', () async {
      final repo = FakeLugaresRepository()
        ..error = const AppException(MensajesError.sinConexion);
      final vm = FichaLugarViewModel(repo, 'l1');

      await vm.cargar();

      expect(vm.error, MensajesError.sinConexion);
      expect(vm.noEncontrado, isFalse);
    });
  });
}

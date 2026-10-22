import 'package:app/core/errors/app_exception.dart';
import 'package:app/features/perfil/data/perfil_model.dart';
import 'package:app/features/perfil/presentation/perfil_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

void main() {
  late FakePerfilRepository perfiles;
  late FakeAuthRepository auth;
  late PerfilViewModel vm;

  setUp(() {
    perfiles = FakePerfilRepository(
      const PerfilModel(
        id: 'u1',
        nombreVisible: 'Mateo',
        correo: 'mateo@correo.com',
      ),
    );
    auth = FakeAuthRepository();
    vm = PerfilViewModel(perfilRepository: perfiles, authRepository: auth);
  });

  test('cargar obtiene nombre y correo', () async {
    await vm.cargar();

    expect(vm.cargando, isFalse);
    expect(vm.errorCarga, isNull);
    expect(vm.perfil?.nombreVisible, 'Mateo');
    expect(vm.perfil?.correo, 'mateo@correo.com');
  });

  test('cargar con error expone el mensaje', () async {
    perfiles.error = const AppException(MensajesError.sinConexion);

    await vm.cargar();

    expect(vm.perfil, isNull);
    expect(vm.errorCarga, MensajesError.sinConexion);
  });

  test('guardar nombre actualiza el perfil tras la respuesta', () async {
    await vm.cargar();

    final error = await vm.guardarNombreVisible('  Mateo V  ');

    expect(error, isNull);
    expect(vm.guardando, isFalse);
    expect(vm.perfil?.nombreVisible, 'Mateo V');
  });

  test('guardar nombre con error conserva el nombre anterior', () async {
    await vm.cargar();
    perfiles.error = const AppException(MensajesError.nombreInvalido);

    final error = await vm.guardarNombreVisible('Otro');

    expect(error, MensajesError.nombreInvalido);
    expect(vm.perfil?.nombreVisible, 'Mateo');
  });

  test('cerrar sesion llama al repositorio y reporta errores', () async {
    expect(await vm.cerrarSesion(), isNull);
    expect(auth.llamadas, ['cerrarSesion']);

    auth.error = const AppException(MensajesError.sinConexion);
    expect(await vm.cerrarSesion(), MensajesError.sinConexion);
    expect(vm.cerrandoSesion, isFalse);
  });
}
